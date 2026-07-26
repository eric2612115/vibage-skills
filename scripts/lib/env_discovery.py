"""Shared env discovery for matrix inventory + evidence extract (C′).

Rules (priority; normalize + aliases; dedupe):
1) compose[.-]<env>.(yml|yaml) filename → env=<env>
2) compose body APP_ENV|NODE_ENV|DEPLOY_ENV|ENVIRONMENT literals
3) deploy|envs|environments|k8s|helm|terraform/<env>/ dirs
4) .github/workflows `environment: <name>`
5) .env.example / .env.sample / .env.template KEY= lines (never real .env)
6) if still empty: bare compose → synthetic env_id=local
7) elif still empty: example file present (even empty/comment keys) → local
8) still empty → caller may emit missing-env-config

Presence-local (6/7) is the same class as bare-compose→local for matrix
terminal proven; it is NOT full-sweep by itself.

Never reads real `.env` / secret dotenv files.
"""
from __future__ import annotations

import re
from pathlib import Path
from typing import Dict, List, Optional

COMPOSE_NAMES = (
    "docker-compose.yml",
    "docker-compose.yaml",
    "compose.yml",
    "compose.yaml",
)

DOTENV_EXAMPLE_NAMES = (
    ".env.example",
    ".env.sample",
    ".env.template",
)

ENV_NAME_RE = re.compile(r"^[A-Za-z][A-Za-z0-9._-]{0,63}$")
COMPOSE_ENV_FILE_RE = re.compile(
    r"^(?:docker-)?compose[.-]([A-Za-z][A-Za-z0-9._-]*)\.(?:ya?ml)$", re.I
)
# Use [ \t] not \s so "environment:\n  APP_ENV" does not capture APP_ENV as env id
APP_ENV_RE = re.compile(
    r"^[ \t]*(?:APP_ENV|NODE_ENV|DEPLOY_ENV|ENVIRONMENT|ENV)[ \t]*[:=][ \t]*[\"']?([A-Za-z][A-Za-z0-9._-]*)",
    re.I | re.M,
)
GH_ENV_RE = re.compile(
    r"^[ \t]*environment[ \t]*:[ \t]*([A-Za-z][A-Za-z0-9._-]*)[ \t]*$", re.M
)
DOTENV_LINE_RE = re.compile(
    r"^[ \t]*([A-Za-z_][A-Za-z0-9_]*)[ \t]*=[ \t]*(.*)$", re.M
)
ENV_VALUE_HINTS = {
    "staging",
    "prod",
    "production",
    "dev",
    "development",
    "local",
    "test",
    "testing",
    "qa",
    "uat",
}
ENV_KEY_HINT_RE = re.compile(
    r"(?:^|_)(?:ENV|ENVIRONMENT|STAGE|DEPLOY|APP_ENV|NODE_ENV)(?:$|_)",
    re.I,
)
SKIP_ENV_LITERALS = {"true", "false", "null", "none", "latest", "image"}

# Real dotenv / secrets — never open these for discovery or extract
SECRET_DOTENV_NAMES = frozenset(
    {
        ".env",
        ".env.local",
        ".env.development",
        ".env.production",
        ".env.staging",
        ".env.test",
    }
)


def normalize_env(name: str, env_aliases: Optional[dict] = None) -> str:
    n = (name or "").strip()
    if not n:
        return ""
    aliases = env_aliases or {}
    if n in aliases:
        n = str(aliases[n])
    if n in ("missing-env-config", "unknown-env"):
        return n
    if not ENV_NAME_RE.match(n):
        return ""
    if n.lower() in SKIP_ENV_LITERALS:
        return ""
    return n


def list_compose_files(repo_root: Path) -> List[Path]:
    out: List[Path] = []
    if not repo_root.is_dir():
        return out
    for fname in COMPOSE_NAMES:
        p = repo_root / fname
        if p.is_file():
            out.append(p)
    for p in sorted(repo_root.iterdir()):
        if p.is_file() and COMPOSE_ENV_FILE_RE.match(p.name):
            if p not in out:
                out.append(p)
    return out


def _rel(repo_rel: str, *parts: str) -> str:
    joined = "/".join(parts)
    if repo_rel in (".", ""):
        return joined
    return f"{repo_rel}/{joined}"


def discover_envs(
    repo_root: Path,
    repo_rel: str,
    env_aliases: Optional[dict] = None,
) -> Dict[str, List[dict]]:
    """Return env_id -> list of {path, quote} evidence hints."""
    found: Dict[str, List[dict]] = {}
    aliases = env_aliases if isinstance(env_aliases, dict) else {}

    def add(env_id: str, path: str, quote: str) -> None:
        eid = normalize_env(env_id, aliases)
        if not eid or eid in ("missing-env-config", "unknown-env"):
            return
        found.setdefault(eid, []).append({"path": path, "quote": (quote or "")[:200]})

    # 1) Filename patterns: docker-compose.staging.yml
    if repo_root.is_dir():
        for p in repo_root.iterdir():
            if not p.is_file():
                continue
            m = COMPOSE_ENV_FILE_RE.match(p.name)
            if m:
                add(m.group(1), _rel(repo_rel, p.name), p.name)

    # 2) Compose content APP_ENV etc.
    for fname in COMPOSE_NAMES:
        p = repo_root / fname
        if not p.is_file():
            continue
        try:
            text = p.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        rel = _rel(repo_rel, fname)
        for m in APP_ENV_RE.finditer(text):
            add(m.group(1), rel, m.group(0).strip()[:200])

    # 3) deploy/{env}/, envs/, …
    for base in ("deploy", "envs", "environments", "k8s", "helm", "terraform"):
        d = repo_root / base
        if not d.is_dir():
            continue
        for child in d.iterdir():
            if child.is_dir() and not child.name.startswith("."):
                eid = normalize_env(child.name, aliases)
                if eid:
                    add(eid, _rel(repo_rel, base, child.name), f"dir:{base}/{child.name}")

    # 4) .github/workflows environment:
    wf = repo_root / ".github" / "workflows"
    if wf.is_dir():
        for p in wf.glob("*.y*ml"):
            try:
                text = p.read_text(encoding="utf-8", errors="ignore")
            except OSError:
                continue
            rel = _rel(repo_rel, ".github", "workflows", p.name)
            for m in GH_ENV_RE.finditer(text):
                add(m.group(1), rel, m.group(0).strip()[:200])

    # 5) .env.example / sample / template (+ compose*.env.example)
    example_files: List[Path] = []
    for name in DOTENV_EXAMPLE_NAMES:
        p = repo_root / name
        if p.is_file():
            example_files.append(p)
    if repo_root.is_dir():
        for p in repo_root.iterdir():
            if not p.is_file():
                continue
            low = p.name.lower()
            if low.endswith(".env.example") or low.endswith(".env.sample"):
                if p not in example_files:
                    example_files.append(p)

    for p in example_files:
        if p.name in SECRET_DOTENV_NAMES or p.name == ".env":
            continue
        try:
            text = p.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        rel = _rel(repo_rel, p.name)
        for m in DOTENV_LINE_RE.finditer(text):
            key = m.group(1)
            raw_val = (m.group(2) or "").strip().strip("\"'")
            # strip inline comments
            if " #" in raw_val:
                raw_val = raw_val.split(" #", 1)[0].strip()
            line = m.group(0).strip()[:200]
            if raw_val.lower() in ENV_VALUE_HINTS:
                add(raw_val, rel, line)
            elif ENV_KEY_HINT_RE.search(key) and normalize_env(raw_val, aliases):
                add(raw_val, rel, line)

    # 6) bare compose → local when nothing else found (prefer compose pointer)
    if not found and list_compose_files(repo_root):
        compose_path = None
        for fname in COMPOSE_NAMES:
            if (repo_root / fname).is_file():
                compose_path = _rel(repo_rel, fname)
                break
        if compose_path is None:
            named = list_compose_files(repo_root)[0]
            compose_path = _rel(repo_rel, named.name)
        add(
            "local",
            compose_path,
            "compose present; no named APP_ENV (default local)",
        )

    # 7) example file present (even empty/comment-only keys) → local
    if not found and example_files:
        ex = example_files[0]
        if ex.name not in SECRET_DOTENV_NAMES and ex.name != ".env":
            add(
                "local",
                _rel(repo_rel, ex.name),
                "env example present; no named APP_ENV (default local)",
            )

    return found


def candidate_paths(repo_root: Path, env_id: str) -> List[str]:
    """Ordered relative paths to try for evidence extract."""
    paths: List[str] = []
    if not repo_root.is_dir():
        return paths

    for p in sorted(repo_root.iterdir()):
        if not p.is_file():
            continue
        m = COMPOSE_ENV_FILE_RE.match(p.name)
        if m and m.group(1).lower() == env_id.lower():
            paths.append(p.name)

    for fname in COMPOSE_NAMES:
        if (repo_root / fname).is_file():
            paths.append(fname)

    for base in ("deploy", "envs", "environments", "k8s", "helm", "terraform"):
        d = repo_root / base / env_id
        if d.is_dir():
            paths.append(f"{base}/{env_id}")

    wf = repo_root / ".github" / "workflows"
    if wf.is_dir():
        for p in sorted(wf.glob("*.y*ml")):
            paths.append(f".github/workflows/{p.name}")

    for name in DOTENV_EXAMPLE_NAMES:
        if (repo_root / name).is_file():
            paths.append(name)
    for p in sorted(repo_root.iterdir()):
        if not p.is_file():
            continue
        low = p.name.lower()
        if low.endswith(".env.example") or low.endswith(".env.sample"):
            if p.name not in paths and p.name not in SECRET_DOTENV_NAMES:
                paths.append(p.name)

    return paths


def quote_for_env(text: str, env_id: str, path: str) -> Optional[str]:
    """Return a visible quote proving env_id for this path/content, or None."""
    base = Path(path).name
    if base in SECRET_DOTENV_NAMES or path.endswith("/.env") or base == ".env":
        return None

    if not text and path:
        return f"dir:{path}"

    for m in APP_ENV_RE.finditer(text or ""):
        if m.group(1).lower() == env_id.lower():
            return m.group(0).strip()[:200]

    for m in GH_ENV_RE.finditer(text or ""):
        if m.group(1).lower() == env_id.lower():
            return m.group(0).strip()[:200]

    m = COMPOSE_ENV_FILE_RE.match(base)
    if m and m.group(1).lower() == env_id.lower():
        for line in (text or "").splitlines():
            if line.strip():
                return line.strip()[:200]
        return base

    # dotenv example KEY= matching env value or key hint
    is_example = (
        base.startswith(".env.")
        or base.endswith(".env.example")
        or base.endswith(".env.sample")
        or base.endswith(".env.template")
        or base in DOTENV_EXAMPLE_NAMES
    )
    if is_example:
        for m in DOTENV_LINE_RE.finditer(text or ""):
            key = m.group(1)
            raw_val = (m.group(2) or "").strip().strip("\"'")
            if " #" in raw_val:
                raw_val = raw_val.split(" #", 1)[0].strip()
            line = m.group(0).strip()[:200]
            if raw_val.lower() == env_id.lower():
                return line
            if ENV_KEY_HINT_RE.search(key) and raw_val.lower() == env_id.lower():
                return line
        # presence-local: empty/comment-only example still proves surface
        if env_id.lower() == "local":
            for line in (text or "").splitlines():
                stripped = line.strip()
                if not stripped or stripped.startswith("#"):
                    continue
                if "=" in stripped:
                    return stripped[:200]
            return "env example present; no named APP_ENV (default local)"

    # bare compose / default local: services: or any non-empty line
    if env_id.lower() == "local" and base in COMPOSE_NAMES:
        for line in (text or "").splitlines():
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                continue
            if stripped.startswith("services:") or stripped:
                return stripped[:200]
        return "compose present; no named APP_ENV (default local)"

    for line in (text or "").splitlines():
        if env_id.lower() in line.lower():
            return line.strip()[:200]
    return None


def has_compose(repo_root: Path) -> bool:
    return bool(list_compose_files(repo_root))
