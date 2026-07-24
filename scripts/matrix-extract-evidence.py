#!/usr/bin/env python3
"""Extract path+quote evidence for one matrix cell (repo, branch_ref, env_id).

Usage: matrix-extract-evidence.py <parent> <repo_id> <branch_ref> <env_id>

Stdout: JSON object {"pointers":[{path,quote,branch_ref,env_id}, ...]}
For non-current branch_ref, reads via `git show branch_ref:path`.
Exit 0 on success with ≥1 pointer; exit 1 on failure.
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

COMPOSE_NAMES = (
    "docker-compose.yml",
    "docker-compose.yaml",
    "compose.yml",
    "compose.yaml",
)
COMPOSE_ENV_FILE_RE = re.compile(
    r"^(?:docker-)?compose[.-]([A-Za-z][A-Za-z0-9._-]*)\.(?:ya?ml)$", re.I
)
# Use [ \t] not \s so "environment:\n  APP_ENV" does not capture APP_ENV as env id
APP_ENV_RE = re.compile(
    r"^[ \t]*(?:APP_ENV|NODE_ENV|DEPLOY_ENV|ENVIRONMENT|ENV)[ \t]*[:=][ \t]*[\"']?([A-Za-z][A-Za-z0-9._-]*)",
    re.I | re.M,
)
GH_ENV_RE = re.compile(r"^[ \t]*environment[ \t]*:[ \t]*([A-Za-z][A-Za-z0-9._-]*)[ \t]*$", re.M)


def die(msg: str) -> None:
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)


def run_git(repo_root: Path, *args: str, timeout: int = 30) -> tuple[int, str, str]:
    try:
        r = subprocess.run(
            ["git", "-C", str(repo_root), *args],
            capture_output=True,
            text=True,
            timeout=timeout,
        )
    except subprocess.TimeoutExpired:
        return 124, "", "timeout"
    except OSError as e:
        return 1, "", str(e)
    return r.returncode, r.stdout or "", r.stderr or ""


def current_branch(repo_root: Path) -> str:
    code, out, _ = run_git(repo_root, "rev-parse", "--abbrev-ref", "HEAD")
    if code != 0:
        return ""
    return out.strip()


def read_file_at_branch(repo_root: Path, branch_ref: str, rel_path: str) -> str | None:
    """Read file content at branch_ref. Prefer git show for non-current."""
    cur = current_branch(repo_root)
    abs_path = repo_root / rel_path
    if cur and cur == branch_ref and abs_path.is_file():
        try:
            return abs_path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            return None
    # Always use git show for non-current (and as fallback)
    code, out, _ = run_git(repo_root, "show", f"{branch_ref}:{rel_path}")
    if code != 0:
        # try HEAD-relative if branch missing file
        if cur and cur == branch_ref:
            return None
        return None
    return out


def resolve_repo_root(parent: Path, repo_id: str) -> Path:
    map_path = parent / "docs" / "vibage" / "maps" / "service_map.json"
    if map_path.is_file():
        try:
            smap = json.loads(map_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            smap = {}
        for repo in smap.get("repos") or smap.get("services") or []:
            if not isinstance(repo, dict):
                continue
            candidates = {
                repo.get("path"),
                repo.get("repo_id"),
                repo.get("id"),
                repo.get("name"),
            }
            if repo_id in candidates:
                path = repo.get("path") or repo.get("repo_id") or repo_id
                if path in (".", ""):
                    return parent
                return parent / path
    # fallback: treat repo_id as relative path
    if repo_id in (".", ""):
        return parent
    return parent / repo_id


def candidate_paths(repo_root: Path, env_id: str) -> list[str]:
    paths: list[str] = []
    # compose.{env}.yml first
    if repo_root.is_dir():
        for p in sorted(repo_root.iterdir()):
            if not p.is_file():
                continue
            m = COMPOSE_ENV_FILE_RE.match(p.name)
            if m and m.group(1).lower() == env_id.lower():
                paths.append(p.name)
        for fname in COMPOSE_NAMES:
            if (repo_root / fname).is_file():
                paths.append(fname)
        for base in ("deploy", "envs", "environments", "k8s"):
            d = repo_root / base / env_id
            if d.is_dir():
                paths.append(f"{base}/{env_id}")
        wf = repo_root / ".github" / "workflows"
        if wf.is_dir():
            for p in sorted(wf.glob("*.y*ml")):
                paths.append(f".github/workflows/{p.name}")
    return paths


def quote_for_env(text: str, env_id: str, path: str) -> str | None:
    if not text and path:
        # directory pointer
        return f"dir:{path}"
    # Prefer APP_ENV-style lines matching env_id
    for m in APP_ENV_RE.finditer(text or ""):
        if m.group(1).lower() == env_id.lower():
            return m.group(0).strip()[:200]
    for m in GH_ENV_RE.finditer(text or ""):
        if m.group(1).lower() == env_id.lower():
            return m.group(0).strip()[:200]
    # filename match compose.staging.yml
    base = Path(path).name
    m = COMPOSE_ENV_FILE_RE.match(base)
    if m and m.group(1).lower() == env_id.lower():
        # return a content line if possible, else filename
        for line in (text or "").splitlines():
            if line.strip():
                return line.strip()[:200]
        return base
    # any line mentioning env_id
    for line in (text or "").splitlines():
        if env_id.lower() in line.lower():
            return line.strip()[:200]
    return None


def main() -> None:
    if len(sys.argv) < 5:
        die("Usage: matrix-extract-evidence.py <parent> <repo_id> <branch_ref> <env_id>")
    parent = Path(sys.argv[1]).resolve()
    repo_id = sys.argv[2]
    branch_ref = sys.argv[3]
    env_id = sys.argv[4]

    if env_id in ("missing-env-config", "unknown-env"):
        die(f"cannot extract evidence for special env_id={env_id}")

    repo_root = resolve_repo_root(parent, repo_id)
    if not (repo_root / ".git").exists():
        die(f"not a git repo: {repo_root}")

    pointers = []
    for rel in candidate_paths(repo_root, env_id):
        abs_p = repo_root / rel
        if abs_p.is_dir():
            quote = f"dir:{rel}"
            text = ""
        else:
            text = read_file_at_branch(repo_root, branch_ref, rel)
            if text is None:
                continue
            quote = quote_for_env(text, env_id, rel)
            if not quote:
                continue
        parent_rel = (
            f"{repo_id}/{rel}" if repo_id not in (".", "") else rel
        )
        # If repo_id is path already and rel is under it, avoid double prefix when
        # resolve used path == repo_id
        pointers.append(
            {
                "path": parent_rel,
                "quote": quote,
                "branch_ref": branch_ref,
                "env_id": env_id,
            }
        )
        break  # one solid pointer is enough

    if not pointers:
        die(f"no evidence for {repo_id}@{branch_ref}/{env_id}")

    print(json.dumps({"pointers": pointers}, ensure_ascii=False))


if __name__ == "__main__":
    main()
