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

python3 - "$PARENT" "$MAP" "$DISCOVER_MODE" "$DISCOVER_MAX_DEPTH" "$INCLUDE_SUBMODULES" "$CAND_FILE" <<'PY'
import json, os, re, sys
from datetime import datetime, timezone
from pathlib import Path

parent = Path(sys.argv[1]).resolve()
map_path = Path(sys.argv[2])
discover_mode = sys.argv[3]
discover_max_depth = int(sys.argv[4])
include_submodules = sys.argv[5] == "true"
cand_file = Path(sys.argv[6])

WHITELIST = (
    "README.md", "README", "readme.md",
    "package.json", "pyproject.toml", "go.mod", "Cargo.toml",
    "docker-compose.yml", "docker-compose.yaml", "compose.yml", "compose.yaml",
    "Dockerfile",
)


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

edges = []
seen = set()
for root in children:
    for frm, to in compose_depends(root):
        a = name_to_id.get(frm) or name_to_id.get(slug(frm))
        b = name_to_id.get(to) or name_to_id.get(slug(to))
        if a and b and a != b and (a, b) not in seen:
            seen.add((a, b))
            edges.append({"from": a, "to": b})

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

echo "OK: discover_mode=$DISCOVER_MODE services=$svc_count children=$child_count"
