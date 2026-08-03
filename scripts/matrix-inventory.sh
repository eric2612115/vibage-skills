#!/usr/bin/env bash
# Sparse env×branch inventory → env_branch_matrix.json + inventory_manifest.json
# Caps: max_branches_per_repo=30, max_matrix_cells=500. branch_cap ≠ overflow.
#
# Terminal cell states (proven|failed) are DURABLE by default: re-running
# inventory re-derives the cell set for every repo but does not downgrade a
# swept cell back to unproven — provided its evidence still resolves at that
# branch AND still yields env evidence when re-derived. Carried quotes are
# refreshed to the re-derived value, so a carried cell never cites text it can no
# longer produce. Structure is always recomputed, so deleted branches cannot
# survive as ghost proven cells. --reset opts into a true rebuild.
set -euo pipefail
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

fail() { echo "FAIL: $*" >&2; exit 1; }

if [[ $# -lt 1 || -z "${1:-}" ]]; then
  cat >&2 <<EOF
FAIL: parent workspace path required.

Usage: $0 /path/to/parent-workspace [--reset]

  --reset   Rebuild every cell as unproven (drops prior sweep results).

Requires docs/vibage/maps/service_map.json (GRAPH_FLOOR). Writes sparse matrix.
Default (no flags) keeps terminal proven|failed cells whose evidence still
resolves; cells with vanished evidence fall back to unproven (fail-closed).
EOF
  exit 1
fi

PARENT="$(cd "$1" && pwd)" || fail "parent is not a directory: $1"
shift
RESET=0
for arg in "$@"; do
  case "$arg" in
    --reset) RESET=1 ;;
    *) fail "unknown flag: $arg" ;;
  esac
done

MAP="$PARENT/docs/vibage/maps/service_map.json"
[[ -f "$MAP" ]] || fail "missing service_map.json — run graph-floor first"

python3 - "$PARENT" "$MAP" "$PKG_ROOT" "$RESET" <<'PY'
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
pkg_root = Path(sys.argv[3])
reset = sys.argv[4] == "1"
TERMINAL_STATES = ("proven", "failed")
sys.path.insert(0, str(pkg_root / "scripts"))
from lib.env_discovery import (  # noqa: E402
    COMPOSE_ENV_FILE_RE,
    COMPOSE_NAMES,
    SECRET_DOTENV_NAMES,
    discover_envs,
    quote_for_env,
)

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


def git_ok(repo_root: Path, *args: str) -> bool:
    try:
        r = subprocess.run(
            ["git", "-C", str(repo_root), *args],
            capture_output=True,
            text=True,
            timeout=30,
        )
    except (OSError, subprocess.TimeoutExpired):
        return False
    return r.returncode == 0


def git_object_kind(repo_root: Path, rev_path: str) -> str:
    try:
        r = subprocess.run(
            ["git", "-C", str(repo_root), "cat-file", "-t", rev_path],
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

    envs = discover_envs(root, rid, env_aliases)

    repo_info.append(
        {
            "repo_id": rid,
            "service_id": sid,
            "root": root,
            "default": dflt,
            "branches": selected,
            "branch_cap_extras": branch_cap_extras,
            "envs": envs,
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

    # Only envs discovered in this repo (no cross-repo global_envs fan-out)
    attached = set(envs.keys())

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


def cell_key(c):
    return (c.get("repo_id"), c.get("branch_ref"), c.get("env_id"))


prev_by_key = {}
if not reset and out_matrix.is_file():
    try:
        prev_obj = json.load(open(out_matrix, encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        prev_obj = {}
    for pc in prev_obj.get("cells") or []:
        if not isinstance(pc, dict):
            continue
        k = cell_key(pc)
        if None in k:
            continue
        prev_by_key[k] = pc

roots_by_repo = {info["repo_id"]: info["root"] for info in repo_info}


def evidence_resolves(repo_id, branch_ref, env_id, pointers):
    """Does every carried pointer still PROVE its env AT THAT BRANCH?

    Returns the pointer list to store (quotes refreshed) or None to refuse the
    carry. A carried verdict is only as honest as its evidence, so this checks
    two things:

    1. The path still exists at that branch. Branch identity matters — a
       working-tree hit proves nothing about another branch, so git is asked
       first, and disk existence only counts for the checked-out branch (the one
       case extract also reads disk, hence accepts untracked evidence).
    2. The file content still yields env evidence, re-derived with the same
       `quote_for_env` the sweep uses. A file that keeps its name while losing
       its env line would otherwise carry a `proven` verdict whose quote no
       longer matches. Directory/tree evidence has no text to re-derive, so
       existence is the whole test there.

    String-comparing the stored quote false-reds a large share of healthy cells
    (measured 4 of 13 on one design fixture: `dir:` pointers and synthesised
    presence quotes are not file substrings at all), so the check re-derives
    instead, and the refreshed quote is written back — a carried cell never cites
    text it can no longer produce.
    """
    root = roots_by_repo.get(repo_id)
    if root is None or not pointers:
        return None
    cur = current_branch(root)
    refreshed = []
    for p in pointers:
        if not isinstance(p, dict):
            return None
        path = str(p.get("path") or "").strip()
        if not path:
            return None
        rel = path
        prefix = f"{repo_id}/"
        if repo_id not in (".", "") and path.startswith(prefix):
            rel = path[len(prefix) :]
        if not rel:
            return None

        kind = git_object_kind(root, f"{branch_ref}:{rel}")
        on_disk = parent / path
        disk_ok = bool(cur) and cur == branch_ref and on_disk.exists()
        if not kind and not disk_ok:
            return None

        # Tree/dir evidence: no text to re-derive, so existence is the whole test.
        if kind == "tree" or (disk_ok and on_disk.is_dir()):
            refreshed.append(dict(p))
            continue
        # Secret dotenv: extract never emits these, so such a pointer can only
        # come from a hand-edited or foreign matrix. Carrying it on existence
        # alone would launder a verdict citing content nothing is allowed to
        # read, so refuse and make the sweep re-derive from a readable path.
        if Path(rel).name in SECRET_DOTENV_NAMES or Path(rel).name == ".env":
            return None

        text = None
        if kind == "blob":
            r = subprocess.run(
                ["git", "-C", str(root), "show", f"{branch_ref}:{rel}"],
                capture_output=True,
                text=True,
                timeout=30,
            )
            if r.returncode == 0:
                text = r.stdout or ""
        if text is None and disk_ok and on_disk.is_file():
            try:
                text = on_disk.read_text(encoding="utf-8", errors="ignore")
            except OSError:
                text = None
        if text is None:
            return None

        new_quote = quote_for_env(text, env_id, rel)
        if not new_quote:
            return None
        carried = dict(p)
        if new_quote != carried.get("quote"):
            # The hash described the quote we just replaced; keeping it would
            # pair a fresh citation with stale provenance.
            carried.pop("evidence_hash", None)
        carried["quote"] = new_quote
        refreshed.append(carried)
    return refreshed


# Terminal states are durable, but only while their evidence still resolves.
preserved = 0
dropped_stale_evidence = 0
if not reset:
    for c in cells:
        pc = prev_by_key.get(cell_key(c))
        if not pc:
            continue
        if pc.get("state") not in TERMINAL_STATES:
            continue
        if c.get("state") != "unproven":
            # Structural verdicts (branch_cap / missing-env-config) still recompute.
            continue
        carried_pointers = evidence_resolves(
            c.get("repo_id"),
            c.get("branch_ref"),
            c.get("env_id"),
            pc.get("pointers"),
        )
        if carried_pointers is None:
            dropped_stale_evidence += 1
            continue
        c["state"] = pc["state"]
        if pc.get("reason"):
            c["reason"] = pc["reason"]
        c["pointers"] = carried_pointers
        if pc.get("evidence_hash"):
            c["evidence_hash"] = pc["evidence_hash"]
        c["updated_at"] = pc.get("updated_at") or c["updated_at"]
        preserved += 1

status = "overflow" if overflow else "ok"

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
mode = "reset" if reset else "merge"
print(
    f"OK: cells={len(cells)} status={status} mode={mode} "
    f"preserved_terminal={preserved} dropped_stale_evidence={dropped_stale_evidence}"
)
if reset:
    print("NOTE: --reset dropped prior sweep results (all cells unproven)")
if dropped_stale_evidence:
    print(
        "NOTE: evidence no longer resolves for "
        f"{dropped_stale_evidence} cell(s) — left unproven, re-sweep required"
    )
PY
