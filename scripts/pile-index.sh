#!/usr/bin/env bash
# Shallow pile-index: one-level child .git repos → docs/vibage/maps/service_map.json
# Token: PILE_INDEX_OK. NOT Tier-0. ≠ Architecture Pass. ≠ deep-read all files.
set -euo pipefail
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

fail() { echo "FAIL: $*" >&2; exit 1; }

if [[ $# -lt 1 || -z "${1:-}" ]]; then
  cat >&2 <<EOF
FAIL: parent workspace path required.

Usage: $0 /path/to/parent-workspace

Writes docs/vibage/maps/service_map.json from one-level child git checkouts.
Shallow only (README/compose/package names). No deep dig. No locate reports.
EOF
  exit 1
fi

PARENT="$(cd "$1" && pwd)" || fail "parent is not a directory: $1"
MAP_DIR="$PARENT/docs/vibage/maps"
mkdir -p "$MAP_DIR"
MAP="$MAP_DIR/service_map.json"

# Collect one-level children with .git (dir or file for worktrees)
children=()
while IFS= read -r -d '' d; do
  base="$(basename "$d")"
  [[ "$base" == .* ]] && continue
  if [[ -d "$d/.git" || -f "$d/.git" ]]; then
    children+=("$d")
  fi
done < <(find "$PARENT" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

# Fallback: if parent itself is a single git repo with no child gits, index parent
if [[ ${#children[@]} -eq 0 ]]; then
  if [[ -d "$PARENT/.git" || -f "$PARENT/.git" ]]; then
    children=("$PARENT")
  else
    fail "no one-level child .git checkouts (and parent is not a git repo)"
  fi
fi

python3 - "$PARENT" "$MAP" "${children[@]}" <<'PY'
import json, os, re, sys
from datetime import datetime, timezone
from pathlib import Path

parent = Path(sys.argv[1])
map_path = Path(sys.argv[2])
children = [Path(p) for p in sys.argv[3:]]

WHITELIST = (
    "README.md", "README", "readme.md",
    "package.json", "pyproject.toml", "go.mod", "Cargo.toml",
    "docker-compose.yml", "docker-compose.yaml", "compose.yml", "compose.yaml",
    "Dockerfile",
)

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

def compose_depends(root: Path) -> list[tuple[str, str]]:
    """Return (from_service, to_service) using compose service names ≈ dir names when possible."""
    edges = []
    for fname in ("docker-compose.yml", "docker-compose.yaml", "compose.yml", "compose.yaml"):
        p = root / fname
        if not p.is_file():
            continue
        try:
            text = p.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        # Very shallow: depends_on: blocks with list items "- name"
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
                elif re.match(r"^\S", line) or (line.strip() and not line.startswith(" ") and not line.startswith("\t")):
                    in_depends = False
        break
    return edges

services = []
id_set = set()
for root in children:
    sid = slug(root.name if root != parent else parent.name)
    base = sid
    n = 2
    while sid in id_set:
        sid = f"{base}-{n}"
        n += 1
    id_set.add(sid)
    services.append({
        "id": sid,
        "name": root.name if root != parent else parent.name,
        "path": str(root.relative_to(parent)) if root != parent else ".",
        "definition": short_def(root),
    })

# Map compose service names → our ids when they match basename
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

scale = "Tiny" if len(services) <= 3 else ("Subset" if len(services) <= 12 else "Large")
obj = {
    "schema_version": "1",
    "pipeline_id": "service_map",
    "scale": scale,
    "quality_bar": "MEDIUM",
    "services": [{"id": s["id"], "name": s["name"], "path": s["path"], "definition": s["definition"]} for s in services],
    "notes": (
        "pile-index shallow map — all one-level child git checkouts. "
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
# depth=standard only when we have real edges; else floor qualify (empty edges fail-soft)
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

# Verify floor (and standard edges when present)
bash "$PKG_ROOT/scripts/verify-service-map.sh" "$PARENT" || fail "verify-service-map failed after pile-index"

# Count ≈ children (allow single-repo parent fallback)
svc_count="$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["services"]))' "$MAP")"
child_count="${#children[@]}"
if [[ "$svc_count" -lt "$child_count" ]]; then
  fail "service_count=$svc_count < child_git_count=$child_count"
fi

echo "PILE_INDEX_OK parent=$PARENT services=$svc_count children=$child_count"
echo "Honesty: PILE_INDEX_OK ≠ Architecture Pass ≠ locate DONE ≠ Graphify required."
