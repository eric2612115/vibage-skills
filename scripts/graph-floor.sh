#!/usr/bin/env bash
# Graph floor: discover git repos → docs/vibage/maps/service_map.json
# Compatible evolution of pile-index map + C′ fields (discover_mode, repos[]).
# Token verified separately via verify-graph-floor.sh → GRAPH_FLOOR_OK.
set -euo pipefail
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

fail() { echo "FAIL: $*" >&2; exit 1; }

if [[ $# -lt 1 || -z "${1:-}" ]]; then
  cat >&2 <<EOF
FAIL: parent workspace path required.

Usage: $0 /path/to/parent-workspace

Writes docs/vibage/maps/service_map.json from discovered git checkouts.
EOF
  exit 1
fi

PARENT="$(cd "$1" && pwd)" || fail "parent is not a directory: $1"
MAP_DIR="$PARENT/docs/vibage/maps"
mkdir -p "$MAP_DIR"
MAP="$MAP_DIR/service_map.json"
POLICY="$PARENT/docs/vibage/OWNER_POLICY.json"

# Defaults (flat); nested when OWNER_POLICY.discover_nested_git=true
DISCOVER_NESTED=false
DISCOVER_MAX_DEPTH=3
INCLUDE_SUBMODULES=false
if [[ -f "$POLICY" ]]; then
  eval "$(python3 - "$POLICY" <<'PY'
import json, sys
try:
    p = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception:
    p = {}
nested = bool(p.get("discover_nested_git") is True)
depth = p.get("discover_max_depth", 3)
try:
    depth = int(depth)
except (TypeError, ValueError):
    depth = 3
if depth < 1:
    depth = 1
inc = bool(p.get("include_submodules") is True)
print("DISCOVER_NESTED=%s" % ("true" if nested else "false"))
print("DISCOVER_MAX_DEPTH=%d" % depth)
print("INCLUDE_SUBMODULES=%s" % ("true" if inc else "false"))
PY
)"
fi

CAND_FILE="$(mktemp)"
trap 'rm -f "$CAND_FILE"' EXIT

if [[ "$DISCOVER_NESTED" == "true" ]]; then
  # .git at depth 2..max_depth+1 → repo root depth 1..max_depth
  find "$PARENT" -mindepth 2 -maxdepth $((DISCOVER_MAX_DEPTH + 1)) \
    \( -type d -name .git -o -type f -name .git \) -print 2>/dev/null \
    | sort \
    | while IFS= read -r gitpath; do
        root="$(dirname "$gitpath")"
        base="$(basename "$root")"
        case "$base" in .* ) continue ;; esac
        case "$root" in */.git|*/.git/*) continue ;; esac
        printf '%s\n' "$root"
      done >"$CAND_FILE"
  DISCOVER_MODE="nested"
else
  find "$PARENT" -mindepth 1 -maxdepth 1 -type d -print 2>/dev/null \
    | sort \
    | while IFS= read -r d; do
        base="$(basename "$d")"
        case "$base" in .* ) continue ;; esac
        if [[ -d "$d/.git" || -f "$d/.git" ]]; then
          printf '%s\n' "$d"
        fi
      done >"$CAND_FILE"
  DISCOVER_MODE="flat"
  DISCOVER_MAX_DEPTH=1
fi

python3 - "$PARENT" "$MAP" "$DISCOVER_MODE" "$DISCOVER_MAX_DEPTH" "$INCLUDE_SUBMODULES" "$CAND_FILE" "$PKG_ROOT" "$POLICY" <<'PY'
import fnmatch
import json, os, re, sys
from datetime import datetime, timezone
from pathlib import Path

parent = Path(sys.argv[1]).resolve()
map_path = Path(sys.argv[2])
discover_mode = sys.argv[3]
discover_max_depth = int(sys.argv[4])
include_submodules = sys.argv[5] == "true"
cand_file = Path(sys.argv[6])
pkg_root = Path(sys.argv[7]).resolve()
policy_path = Path(sys.argv[8])

WHITELIST = (
    "README.md", "README", "readme.md",
    "package.json", "pyproject.toml", "go.mod", "Cargo.toml",
    "docker-compose.yml", "docker-compose.yaml", "compose.yml", "compose.yaml",
    "Dockerfile",
)

pol = {}
if policy_path.is_file():
    try:
        pol = json.load(open(policy_path, encoding="utf-8"))
    except Exception:
        pol = {}

HARD_EXCLUDE_GLOBS = [
    "vibage-skills",
    "vibage-skills-*",
    "war-room-skills",
    "war-room-skills-*",
]
policy_globs = pol.get("exclude_repo_globs") or []
if isinstance(policy_globs, str):
    policy_globs = [policy_globs]
if not isinstance(policy_globs, list):
    policy_globs = []
# Union: hard defaults cannot be dropped by OWNER_POLICY
exclude_globs = list(HARD_EXCLUDE_GLOBS)
for g in policy_globs:
    if isinstance(g, str) and g and g not in exclude_globs:
        exclude_globs.append(g)


def is_tooling_repo(root: Path) -> bool:
    """Skip PKG sibling / skill packs so they do not pollute product map."""
    try:
        if root.resolve() == pkg_root:
            return True
    except OSError:
        pass
    base = root.name
    for g in exclude_globs:
        if fnmatch.fnmatch(base, g):
            return True
    # Heuristic: vibage-skills layout only (not broad *skills)
    if (root / "skills" / "MANIFEST.txt").is_file() and (
        root / "scripts" / "resolve-pkg-root.sh"
    ).is_file():
        return True
    return False


def die(msg: str) -> None:
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)


def resolve_git(root: Path):
    """Return (kind, canonical_git_dir_str|None). kind: regular|submodule|worktree|unknown."""
    git_path = root / ".git"
    if git_path.is_dir():
        return "regular", str(git_path.resolve())
    if git_path.is_file():
        try:
            line = git_path.read_text(encoding="utf-8", errors="ignore").splitlines()[0]
        except (OSError, IndexError):
            return "unknown", None
        if not line.startswith("gitdir:"):
            return "unknown", None
        gitdir = line[len("gitdir:") :].strip()
        if not gitdir:
            return "unknown", None
        abs_git = Path(gitdir) if os.path.isabs(gitdir) else (root / gitdir)
        try:
            abs_s = str(abs_git.resolve())
        except OSError:
            abs_s = str(abs_git)
        if "/.git/modules/" in abs_s or abs_s.endswith("/.git/modules"):
            return "submodule", abs_s
        if "/worktrees/" in abs_s:
            # main .git is parent of worktrees/<name>
            main_git = str(Path(abs_s).parent.parent)
            try:
                main_git = str(Path(main_git).resolve())
            except OSError:
                pass
            return "worktree", main_git
        return "regular", abs_s
    return "unknown", None


raw_candidates = []
if cand_file.is_file():
    for line in cand_file.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line:
            raw_candidates.append(Path(line))

children = []
canon_to_idx = {}
extra_worktrees = {}  # primary Path -> worktree abs path

for root in raw_candidates:
    if is_tooling_repo(root):
        continue
    kind, canon = resolve_git(root)
    if kind == "submodule" and not include_submodules:
        continue
    if kind == "unknown" and not (root / ".git").exists():
        continue
    if canon and canon in canon_to_idx:
        primary = children[canon_to_idx[canon]]
        if primary not in extra_worktrees:
            extra_worktrees[primary] = str(root)
        continue
    if canon:
        canon_to_idx[canon] = len(children)
    children.append(root)

# Fallback: parent alone if it is a git repo
if not children:
    if (parent / ".git").exists():
        children = [parent]
    else:
        die("no git repos discovered")


def slug(name: str) -> str:
    s = re.sub(r"[^a-zA-Z0-9._-]+", "-", name).strip("-").lower()
    return s or "service"


def short_def(root: Path) -> str:
    for name in ("README.md", "README", "readme.md"):
        p = root / name
        if p.is_file():
            try:
                text = p.read_text(encoding="utf-8", errors="ignore")
            except OSError:
                break
            for line in text.splitlines():
                line = line.strip()
                if not line:
                    continue
                line = re.sub(r"^#+\s*", "", line).strip()
                if line:
                    return line[:160]
            break
    pkg = root / "package.json"
    if pkg.is_file():
        try:
            data = json.loads(pkg.read_text(encoding="utf-8"))
            if isinstance(data.get("description"), str) and data["description"].strip():
                return data["description"].strip()[:160]
        except (OSError, json.JSONDecodeError):
            pass
    return f"Checkout at {root.name} (role uncertain — shallow index)"


def compose_depends(root: Path):
    edges = []
    for fname in ("docker-compose.yml", "docker-compose.yaml", "compose.yml", "compose.yaml"):
        p = root / fname
        if not p.is_file():
            continue
        try:
            text = p.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        current = None
        in_depends = False
        for line in text.splitlines():
            m = re.match(r"^([A-Za-z0-9._-]+):\s*$", line)
            if m and not line.startswith(" "):
                current = m.group(1)
                in_depends = False
                continue
            if current and re.match(r"^\s+depends_on:\s*$", line):
                in_depends = True
                continue
            if in_depends:
                item = re.match(r"^\s+-\s+([A-Za-z0-9._-]+)\s*$", line)
                if item:
                    edges.append((current, item.group(1)))
                elif re.match(r"^\S", line) or (
                    line.strip() and not line.startswith(" ") and not line.startswith("\t")
                ):
                    in_depends = False
        break
    return edges


def compose_top_services(root: Path):
    """Top-level keys under services: (regex-only; no YAML lib)."""
    names = []
    for fname in ("docker-compose.yml", "docker-compose.yaml", "compose.yml", "compose.yaml"):
        p = root / fname
        if not p.is_file():
            continue
        try:
            text = p.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        in_services = False
        for line in text.splitlines():
            if re.match(r"^services:\s*$", line):
                in_services = True
                continue
            if in_services:
                if re.match(r"^\S", line) and not line.startswith("#"):
                    break
                m = re.match(r"^  ([A-Za-z0-9._-]+):\s*(?:#.*)?$", line)
                if m:
                    names.append(m.group(1))
        break
    return names


def package_name_tokens(root: Path):
    """Cheap identity tokens from package.json / go.mod (max useful for edges)."""
    tokens = []
    pkg = root / "package.json"
    if pkg.is_file():
        try:
            data = json.loads(pkg.read_text(encoding="utf-8"))
            name = data.get("name")
            if isinstance(name, str) and name.strip():
                raw = name.strip()
                tokens.append(raw)
                tokens.append(raw.split("/")[-1])
        except (OSError, json.JSONDecodeError):
            pass
    gomod = root / "go.mod"
    if gomod.is_file():
        try:
            for line in gomod.read_text(encoding="utf-8", errors="ignore").splitlines():
                m = re.match(r"^module\s+(\S+)", line)
                if m:
                    mod = m.group(1).rstrip("/")
                    tokens.append(mod)
                    tokens.append(mod.split("/")[-1])
                    break
        except OSError:
            pass
    # dedupe preserve order
    seen_t = set()
    out = []
    for t in tokens:
        key = t.lower()
        if key and key not in seen_t:
            seen_t.add(key)
            out.append(t)
    return out


services = []
id_set = set()
for root in children:
    rel = "." if root.resolve() == parent else str(root.resolve().relative_to(parent))
    sid = slug(root.name if root.resolve() != parent else parent.name)
    base = sid
    n = 2
    while sid in id_set:
        sid = f"{base}-{n}"
        n += 1
    id_set.add(sid)
    services.append(
        {
            "id": sid,
            "name": root.name if root.resolve() != parent else parent.name,
            "path": rel,
            "definition": short_def(root),
        }
    )

name_to_id = {s["name"]: s["id"] for s in services}
name_to_id.update({s["id"]: s["id"] for s in services})
# also map slug(name) → id for compose service keys
for s in services:
    name_to_id.setdefault(slug(s["name"]), s["id"])

edges = []
seen = set()


def add_edge(a: str, b: str) -> None:
    if a and b and a != b and (a, b) not in seen:
        seen.add((a, b))
        edges.append({"from": a, "to": b})


# A) compose depends_on
for root in children:
    host = None
    for s, r in zip(services, children):
        if r == root:
            host = s["id"]
            break
    for frm, to in compose_depends(root):
        a = name_to_id.get(frm) or name_to_id.get(slug(frm)) or host
        b = name_to_id.get(to) or name_to_id.get(slug(to))
        if a and b:
            add_edge(a, b)

# B) compose services: keys that match sibling repo names
for root, svc in zip(children, services):
    for svc_name in compose_top_services(root):
        b = name_to_id.get(svc_name) or name_to_id.get(slug(svc_name))
        if b and b != svc["id"]:
            add_edge(svc["id"], b)

# C) package.json / go.mod name ↔ sibling basename (cap 8 edges per repo)
for root, svc in zip(children, services):
    n_added = 0
    for tok in package_name_tokens(root):
        if n_added >= 8:
            break
        b = name_to_id.get(tok) or name_to_id.get(slug(tok))
        if b and b != svc["id"]:
            before = len(edges)
            add_edge(svc["id"], b)
            if len(edges) > before:
                n_added += 1
# reverse: sibling basename matches our package token already covered via name_to_id
for root, svc in zip(children, services):
    n_added = 0
    for other, other_svc in zip(children, services):
        if other_svc["id"] == svc["id"] or n_added >= 8:
            continue
        for tok in package_name_tokens(other):
            if tok == svc["name"] or slug(tok) == slug(svc["name"]):
                before = len(edges)
                add_edge(other_svc["id"], svc["id"])
                if len(edges) > before:
                    n_added += 1
                break


repos = []
for root, svc in zip(children, services):
    repo = {
        "id": svc["id"],
        "repo_id": svc["path"],
        "name": svc["name"],
        "path": svc["path"],
        "definition": svc["definition"],
    }
    wt = extra_worktrees.get(root)
    if wt:
        wt_path = Path(wt)
        try:
            repo["worktree_path"] = (
                "." if wt_path.resolve() == parent else str(wt_path.resolve().relative_to(parent))
            )
        except ValueError:
            repo["worktree_path"] = wt
    repos.append(repo)

scale = "Tiny" if len(services) <= 3 else ("Subset" if len(services) <= 12 else "Large")
obj = {
    "schema_version": "1",
    "pipeline_id": "service_map",
    "scale": scale,
    "quality_bar": "MEDIUM",
    "discover_mode": discover_mode,
    "discover_max_depth": discover_max_depth,
    "services": [
        {"id": s["id"], "name": s["name"], "path": s["path"], "definition": s["definition"]}
        for s in services
    ],
    "repos": repos,
    "notes": (
        "graph-floor / pile-index shallow map — discovered git checkouts. "
        "≠ Architecture Pass. ≠ deep-read. Graphify optional fail-soft."
    ),
    "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "pile_index": {
        "child_git_count": len(children),
        "service_count": len(services),
        "max_files_per_child": len(WHITELIST),
        "whitelist": list(WHITELIST),
    },
}
if edges:
    obj["depth"] = "standard"
    obj["edges"] = edges
else:
    obj["edges"] = []

map_path.parent.mkdir(parents=True, exist_ok=True)
map_path.write_text(json.dumps(obj, indent=2) + "\n", encoding="utf-8")
print(f"Wrote {map_path}")
print(f"OK: services={len(services)} children={len(children)} edges={len(edges)}")
PY

# Note: Python die() already exits 1 with FAIL: no git repos discovered

bash "$PKG_ROOT/scripts/verify-service-map.sh" "$PARENT" || fail "verify-service-map failed after graph-floor"

svc_count="$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["services"]))' "$MAP")"
child_count="$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1])).get("repos") or json.load(open(sys.argv[1]))["services"]))' "$MAP")"
if [[ "$svc_count" -lt 1 ]]; then
  fail "service_count=$svc_count < 1"
fi

# Floor ledger: floor_identity + floor_deps per repo (proven when verifiable, else failed+ROLLUP)
python3 - "$PARENT" "$MAP" "$PKG_ROOT" <<'PY'
import hashlib, json, subprocess, sys
from datetime import datetime, timezone
from pathlib import Path

parent = Path(sys.argv[1]).resolve()
map_path = Path(sys.argv[2])
pkg_root = Path(sys.argv[3])
append_sh = pkg_root / "scripts" / "ledger-append.sh"

obj = json.load(open(map_path, encoding="utf-8"))
repos = obj.get("repos") or []
edges = obj.get("edges") or []
now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def run_append(claim: dict) -> None:
    raw = json.dumps(claim, ensure_ascii=False)
    r = subprocess.run(
        ["bash", str(append_sh), str(parent), raw],
        capture_output=True,
        text=True,
    )
    if r.returncode != 0:
        sys.stderr.write(r.stderr or r.stdout or "ledger-append failed\n")
        sys.exit(r.returncode or 1)


def ehash(*parts: str) -> str:
    h = hashlib.sha256()
    for p in parts:
        h.update(p.encode("utf-8", errors="replace"))
        h.update(b"\0")
    return h.hexdigest()[:16]


for repo in repos:
    rid = repo.get("id") or ""
    rpath = repo.get("path") or rid
    root = parent if rpath in (".", "") else parent / rpath
    definition = (repo.get("definition") or "").strip()
    name = repo.get("name") or rid

    # --- floor_identity ---
    id_path = None
    id_quote = ""
    for cand in ("README.md", "README", "readme.md"):
        p = root / cand
        if p.is_file():
            try:
                text = p.read_text(encoding="utf-8", errors="ignore")
            except OSError:
                text = ""
            for line in text.splitlines():
                if line.strip():
                    id_quote = line.strip()[:200]
                    break
            id_path = f"{rpath}/{cand}" if rpath not in (".", "") else cand
            break
    if id_path is None:
        id_path = rpath if rpath not in (".", "") else "."
        id_quote = f"repo:{name}"

    identity_ok = root.exists() and (root / ".git").exists()
    statement = definition or f"Repo {name} at {rpath}"
    claim_id = f"floor_identity:{rid}:{ehash(rid, statement, id_path)}"
    run_append(
        {
            "id": claim_id,
            "subject_type": "repo",
            "subject_id": rid,
            "claim_class": "floor_identity",
            "statement": statement,
            "pointers": [
                {
                    "path": id_path,
                    "quote": id_quote or statement[:80],
                    "branch_ref": "HEAD",
                    "env_id": "",
                }
            ],
            "state": "proven" if identity_ok else "failed",
            "updated_at": now,
            "evidence_hash": ehash(rid, "floor_identity", id_path, id_quote),
        }
    )

    # --- floor_deps (present-or-absent with evidence) ---
    compose_names = (
        "docker-compose.yml",
        "docker-compose.yaml",
        "compose.yml",
        "compose.yaml",
    )
    compose_rel = None
    for fname in compose_names:
        if (root / fname).is_file():
            compose_rel = f"{rpath}/{fname}" if rpath not in (".", "") else fname
            break

    related = [e for e in edges if e.get("from") == rid or e.get("to") == rid]
    if compose_rel and related:
        deps_stmt = f"compose deps: {len(related)} edge(s)"
        deps_quote = "depends_on present"
        deps_path = compose_rel
        deps_ok = True
    elif compose_rel:
        deps_stmt = "compose present; no cross-repo depends_on edges"
        deps_quote = "compose file; no mapped depends_on"
        deps_path = compose_rel
        deps_ok = True
    else:
        deps_stmt = "no compose deps"
        deps_quote = "absent"
        deps_path = rpath if rpath not in (".", "") else "."
        deps_ok = root.exists()

    claim_id = f"floor_deps:{rid}:{ehash(rid, deps_stmt, deps_path)}"
    run_append(
        {
            "id": claim_id,
            "subject_type": "repo",
            "subject_id": rid,
            "claim_class": "floor_deps",
            "statement": deps_stmt,
            "pointers": [
                {
                    "path": deps_path,
                    "quote": deps_quote,
                    "branch_ref": "HEAD",
                    "env_id": "",
                }
            ],
            "state": "proven" if deps_ok else "failed",
            "updated_at": now,
            "evidence_hash": ehash(rid, "floor_deps", deps_path, deps_quote),
        }
    )
PY

echo "OK: discover_mode=$DISCOVER_MODE services=$svc_count children=$child_count"
