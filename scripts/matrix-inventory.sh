#!/usr/bin/env bash
# Sparse env×branch inventory → env_branch_matrix.json + inventory_manifest.json
# Caps: max_branches_per_repo=30, max_matrix_cells=500. branch_cap ≠ overflow.
set -euo pipefail
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

fail() { echo "FAIL: $*" >&2; exit 1; }

if [[ $# -lt 1 || -z "${1:-}" ]]; then
  cat >&2 <<EOF
FAIL: parent workspace path required.

Usage: $0 /path/to/parent-workspace

Requires docs/vibage/maps/service_map.json (GRAPH_FLOOR). Writes sparse matrix.
EOF
  exit 1
fi

PARENT="$(cd "$1" && pwd)" || fail "parent is not a directory: $1"
MAP="$PARENT/docs/vibage/maps/service_map.json"
[[ -f "$MAP" ]] || fail "missing service_map.json — run graph-floor first"

python3 - "$PARENT" "$MAP" <<'PY'
import fnmatch
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

parent = Path(sys.argv[1]).resolve()
map_path = Path(sys.argv[2])
policy_path = parent / "docs" / "vibage" / "OWNER_POLICY.json"
out_matrix = parent / "docs" / "vibage" / "maps" / "env_branch_matrix.json"
out_manifest = parent / "docs" / "vibage" / "maps" / "inventory_manifest.json"

def die(msg: str) -> None:
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)

try:
    smap = json.load(open(map_path, encoding="utf-8"))
except Exception as e:
    die(f"service_map unreadable: {e}")

pol = {}
if policy_path.is_file():
    try:
        pol = json.load(open(policy_path, encoding="utf-8"))
    except Exception:
        pol = {}

max_branches = int(pol.get("max_branches_per_repo") or 30)
max_cells = int(pol.get("max_matrix_cells") or 500)
if max_branches < 1:
    max_branches = 30
if max_cells < 1:
    max_cells = 500

default_globs = ["main", "master", "develop", "release/*", "staging", "prod", "production"]
branch_globs = pol.get("branch_globs") or default_globs
if isinstance(branch_globs, str):
    branch_globs = [g.strip() for g in branch_globs.split("|") if g.strip()]
branch_enumerate_all = pol.get("branch_enumerate") == "all"
env_aliases = pol.get("env_aliases") or {}
if not isinstance(env_aliases, dict):
    env_aliases = {}

repos = smap.get("repos") or smap.get("services") or []
if not repos:
    die("no repos in service_map")

# Global env set across mother-dir (for sparse attach via deploy edges)
global_envs = set()
edges = smap.get("edges") or []
# deploy participation: any edge involving the repo counts as deploy participation
repos_with_deploy = set()
for e in edges:
    if isinstance(e, dict):
        if e.get("from"):
            repos_with_deploy.add(e["from"])
        if e.get("to"):
            repos_with_deploy.add(e["to"])


def run_git(repo_root: Path, *args: str) -> str:
    try:
        r = subprocess.run(
            ["git", "-C", str(repo_root), *args],
            capture_output=True,
            text=True,
            timeout=30,
        )
    except (OSError, subprocess.TimeoutExpired):
        return ""
    if r.returncode != 0:
        return ""
    return (r.stdout or "").strip()


def list_local_branches(repo_root: Path):
    out = run_git(repo_root, "for-each-ref", "--format=%(refname:short)", "refs/heads")
    if not out:
        return []
    return [b.strip() for b in out.splitlines() if b.strip()]


def default_branch(repo_root: Path) -> str:
    sym = run_git(repo_root, "symbolic-ref", "--short", "refs/remotes/origin/HEAD")
    if sym.startswith("origin/"):
        return sym[len("origin/") :]
    # fallback: main/master if present, else current
    heads = list_local_branches(repo_root)
    for cand in ("main", "master"):
        if cand in heads:
            return cand
    cur = run_git(repo_root, "rev-parse", "--abbrev-ref", "HEAD")
    if cur and cur != "HEAD":
        return cur
    return heads[0] if heads else "main"


def current_branch(repo_root: Path) -> str:
    cur = run_git(repo_root, "rev-parse", "--abbrev-ref", "HEAD")
    if cur and cur != "HEAD":
        return cur
    return ""


def matches_globs(name: str, globs) -> bool:
    for g in globs:
        if fnmatch.fnmatch(name, g):
            return True
    return False


COMPOSE_NAMES = (
    "docker-compose.yml",
    "docker-compose.yaml",
    "compose.yml",
    "compose.yaml",
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
GH_ENV_RE = re.compile(r"^[ \t]*environment[ \t]*:[ \t]*([A-Za-z][A-Za-z0-9._-]*)[ \t]*$", re.M)


def normalize_env(name: str) -> str:
    n = (name or "").strip()
    if not n:
        return ""
    if n in env_aliases:
        n = str(env_aliases[n])
    if n in ("missing-env-config", "unknown-env"):
        return n
    if not ENV_NAME_RE.match(n):
        return ""
    # skip generic values that are not deploy envs
    if n.lower() in ("true", "false", "null", "none", "latest", "image"):
        return ""
    return n


def discover_envs(repo_root: Path, repo_rel: str):
    """Return dict env_id -> list of evidence dicts {path, quote, branch_hint?}."""
    found = {}

    def add(env_id: str, path: str, quote: str):
        eid = normalize_env(env_id)
        if not eid or eid in ("missing-env-config", "unknown-env"):
            return
        found.setdefault(eid, []).append({"path": path, "quote": quote[:200]})

    # Filename patterns: docker-compose.staging.yml
    for p in repo_root.iterdir() if repo_root.is_dir() else []:
        if not p.is_file():
            continue
        m = COMPOSE_ENV_FILE_RE.match(p.name)
        if m:
            rel = f"{repo_rel}/{p.name}" if repo_rel not in (".", "") else p.name
            add(m.group(1), rel, p.name)

    # Compose content APP_ENV etc.
    for fname in COMPOSE_NAMES:
        p = repo_root / fname
        if not p.is_file():
            continue
        try:
            text = p.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        rel = f"{repo_rel}/{fname}" if repo_rel not in (".", "") else fname
        for m in APP_ENV_RE.finditer(text):
            line = m.group(0).strip()
            add(m.group(1), rel, line[:200])

    # deploy/{env}/, envs/{env}/, environments/{env}/, k8s/{env}/
    for base in ("deploy", "envs", "environments", "k8s", "helm", "terraform"):
        d = repo_root / base
        if not d.is_dir():
            continue
        for child in d.iterdir():
            if child.is_dir() and not child.name.startswith("."):
                eid = normalize_env(child.name)
                if eid:
                    rel = (
                        f"{repo_rel}/{base}/{child.name}"
                        if repo_rel not in (".", "")
                        else f"{base}/{child.name}"
                    )
                    add(eid, rel, f"dir:{base}/{child.name}")

    # .github/workflows environment:
    wf = repo_root / ".github" / "workflows"
    if wf.is_dir():
        for p in wf.glob("*.y*ml"):
            try:
                text = p.read_text(encoding="utf-8", errors="ignore")
            except OSError:
                continue
            rel = (
                f"{repo_rel}/.github/workflows/{p.name}"
                if repo_rel not in (".", "")
                else f".github/workflows/{p.name}"
            )
            for m in GH_ENV_RE.finditer(text):
                add(m.group(1), rel, m.group(0).strip()[:200])

    return found


def branches_named_in_configs(repo_root: Path, repo_rel: str):
    names = set()
    patterns = [
        re.compile(r"\b(?:branch|ref|branches)\s*:\s*[\"']?([A-Za-z0-9._/-]+)", re.I),
        re.compile(r"\bon\s*:\s*\n(?:\s+\w+:.*\n)*?\s+branches\s*:\s*\[([^\]]+)\]", re.I),
    ]
    search_roots = [
        repo_root / ".github" / "workflows",
        repo_root / "deploy",
        repo_root / ".gitlab-ci.yml",
    ]
    files = []
    for sr in search_roots:
        if sr.is_file():
            files.append(sr)
        elif sr.is_dir():
            files.extend([p for p in sr.rglob("*") if p.is_file()][:40])
    for p in files[:80]:
        try:
            text = p.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        for m in re.finditer(
            r"(?:branches|only|except)\s*:\s*\n((?:\s+-\s+[A-Za-z0-9._/*-]+\n?)+)",
            text,
        ):
            for line in m.group(1).splitlines():
                item = re.sub(r"^\s*-\s*", "", line).strip().strip("\"'")
                if item and "/" not in item[:1]:
                    names.add(item)
        for m in re.finditer(r"\bref\s*:\s*[\"']?([A-Za-z0-9._/-]+)", text):
            names.add(m.group(1))
    return names


cells = []
overflow = False
now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

# First pass: collect per-repo branch sets and envs
repo_info = []
for repo in repos:
    if not isinstance(repo, dict):
        continue
    rid = repo.get("path") or repo.get("repo_id") or repo.get("id")
    sid = repo.get("id") or rid
    if not rid:
        continue
    root = parent if rid in (".", "") else parent / rid
    if not root.exists():
        continue

    all_heads = list_local_branches(root)
    dflt = default_branch(root)
    cur = current_branch(root)
    deploy_named = branches_named_in_configs(root, rid)

    selected = []
    seen = set()

    def push(b: str):
        if not b or b in seen:
            return
        seen.add(b)
        selected.append(b)

    push(dflt)
    if cur:
        push(cur)
    for b in all_heads:
        if matches_globs(b, branch_globs):
            push(b)
    for b in deploy_named:
        if b in all_heads or b == dflt:
            push(b)

    branch_cap_extras = []
    if branch_enumerate_all:
        for b in all_heads:
            if b not in seen:
                if len(selected) < max_branches:
                    push(b)
                else:
                    branch_cap_extras.append(b)
    else:
        # still enforce cap on selected
        if len(selected) > max_branches:
            branch_cap_extras = selected[max_branches:]
            selected = selected[:max_branches]

    # extras beyond cap that matched globs but exceeded max → branch_cap
    if len(selected) > max_branches:
        branch_cap_extras = selected[max_branches:] + branch_cap_extras
        selected = selected[:max_branches]

    envs = discover_envs(root, rid)
    for eid in envs:
        global_envs.add(eid)

    # deploy participation via compose presence or edges
    has_deploy = sid in repos_with_deploy or rid in repos_with_deploy
    if not has_deploy:
        for fname in COMPOSE_NAMES:
            if (root / fname).is_file():
                has_deploy = True
                break
        if not has_deploy:
            for p in root.iterdir() if root.is_dir() else []:
                if p.is_file() and COMPOSE_ENV_FILE_RE.match(p.name):
                    has_deploy = True
                    break

    repo_info.append(
        {
            "repo_id": rid,
            "service_id": sid,
            "root": root,
            "default": dflt,
            "branches": selected,
            "branch_cap_extras": branch_cap_extras,
            "envs": envs,
            "has_deploy": has_deploy,
        }
    )


def add_cell(repo_id, branch_ref, env_id, state, pointers=None, reason=None):
    global overflow
    if overflow:
        return
    if len(cells) >= max_cells:
        overflow = True
        return
    cell = {
        "repo_id": repo_id,
        "branch_ref": branch_ref,
        "env_id": env_id,
        "pointers": pointers or [],
        "state": state,
        "updated_at": now,
    }
    if reason:
        cell["reason"] = reason
    cells.append(cell)


# Sparse product
for info in repo_info:
    rid = info["repo_id"]
    dflt = info["default"]
    envs = info["envs"]
    branches = info["branches"]

    if not envs:
        # one missing-env-config failed cell
        search_roots = f"{rid}/(compose|deploy|envs|.github/workflows)"
        add_cell(
            rid,
            dflt,
            "missing-env-config",
            "failed",
            pointers=[
                {
                    "path": rid if rid not in (".", "") else ".",
                    "quote": f"no env configs under {search_roots}",
                    "branch_ref": dflt,
                    "env_id": "missing-env-config",
                }
            ],
            reason="missing-env-config",
        )
        # still record branch_cap extras as failed if any
        for b in info["branch_cap_extras"]:
            add_cell(
                rid,
                b,
                "missing-env-config",
                "failed",
                pointers=[
                    {
                        "path": rid if rid not in (".", "") else ".",
                        "quote": "branch_cap",
                        "branch_ref": b,
                        "env_id": "missing-env-config",
                    }
                ],
                reason="branch_cap",
            )
        continue

    # envs attached to this repo
    attached = set(envs.keys())
    # plus global envs if repo has deploy participation
    if info["has_deploy"]:
        attached |= set(global_envs)

    # sparse: for each attached env × each bounded branch
    for env_id in sorted(attached):
        # mandatory default_branch cell
        branch_set = list(branches)
        if dflt not in branch_set:
            branch_set = [dflt] + branch_set
        for br in branch_set:
            # initial state unproven (sweep fills); inventory may leave pointers hint
            hints = envs.get(env_id) or []
            ptrs = []
            for h in hints[:1]:
                ptrs.append(
                    {
                        "path": h["path"],
                        "quote": h.get("quote") or env_id,
                        "branch_ref": br,
                        "env_id": env_id,
                    }
                )
            add_cell(rid, br, env_id, "unproven", pointers=ptrs)

    # branch_cap extras → failed cells (not overflow)
    for b in info["branch_cap_extras"]:
        # attach to first real env or missing
        env_id = sorted(attached)[0] if attached else "missing-env-config"
        add_cell(
            rid,
            b,
            env_id,
            "failed",
            pointers=[
                {
                    "path": rid if rid not in (".", "") else ".",
                    "quote": "branch_cap",
                    "branch_ref": b,
                    "env_id": env_id,
                }
            ],
            reason="branch_cap",
        )

status = "overflow" if overflow else "ok"

# Deduplicate cells by key (keep first)
seen_keys = set()
deduped = []
for c in cells:
    k = (c["repo_id"], c["branch_ref"], c["env_id"])
    if k in seen_keys:
        continue
    seen_keys.add(k)
    deduped.append(c)
cells = deduped

# If we overflowed mid-way, keep what we have and mark overflow
matrix = {
    "schema_version": "1",
    "status": status,
    "max_branches_per_repo": max_branches,
    "max_matrix_cells": max_cells,
    "generated_at": now,
    "cells": cells,
}
manifest = {
    "schema_version": "1",
    "generated_at": now,
    "rows": [
        {"repo_id": c["repo_id"], "branch_ref": c["branch_ref"], "env_id": c["env_id"]}
        for c in cells
    ],
}

out_matrix.parent.mkdir(parents=True, exist_ok=True)
out_matrix.write_text(json.dumps(matrix, indent=2) + "\n", encoding="utf-8")
out_manifest.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
print(f"Wrote {out_matrix}")
print(f"Wrote {out_manifest}")
print(f"OK: cells={len(cells)} status={status}")
PY
