#!/usr/bin/env bash
# W1 bounded refresh for one repo (not silent full c-prime-fill).
# Usage: freshness-refresh-repo.sh <mother> <repo_id>
set -euo pipefail
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

fail() { echo "FAIL: $*" >&2; exit 1; }

[[ $# -ge 2 ]] || fail "usage: $0 <mother> <repo_id>"
PARENT="$(cd "$1" && pwd)" || fail "mother not a directory: $1"
REPO_ID="$2"
STATUS="$PARENT/docs/vibage/STATUS.md"
MAP="$PARENT/docs/vibage/maps/service_map.json"
MATRIX="$PARENT/docs/vibage/maps/env_branch_matrix.json"

[[ -f "$STATUS" ]] || fail "mother missing docs/vibage/STATUS.md"

in_map=0
if [[ -f "$MAP" ]]; then
  in_map="$(python3 - "$MAP" "$REPO_ID" <<'PY'
import json, sys
obj = json.load(open(sys.argv[1], encoding="utf-8"))
rid = sys.argv[2]
ids = set()
for r in obj.get("repos") or []:
    if isinstance(r, dict):
        ids.add(str(r.get("repo_id") or r.get("path") or r.get("id") or ""))
for s in obj.get("services") or []:
    if isinstance(s, dict):
        ids.add(str(s.get("path") or s.get("id") or ""))
print(1 if rid in ids else 0)
PY
)"
fi

if [[ "$in_map" != "1" ]]; then
  bash "$PKG_ROOT/scripts/graph-floor.sh" "$PARENT" || fail "graph-floor failed"
  echo "FULL_MOTHER_FLOOR_REFRESH"
fi

bash "$PKG_ROOT/scripts/matrix-inventory.sh" "$PARENT" || fail "matrix-inventory failed"
[[ -f "$MATRIX" ]] || fail "missing matrix after inventory"

CELL_LIST="$(mktemp)"
trap 'rm -f "$CELL_LIST"' EXIT
python3 - "$MATRIX" "$REPO_ID" "$CELL_LIST" <<'PY'
import json, sys
from pathlib import Path
matrix = json.load(open(sys.argv[1], encoding="utf-8"))
rid = sys.argv[2]
out = Path(sys.argv[3])
lines = []
for c in matrix.get("cells") or []:
    if (c.get("repo_id") or "") != rid:
        continue
    br = c.get("branch_ref") or ""
    eid = c.get("env_id") or ""
    if br and eid:
        lines.append(f"{rid}|{br}|{eid}")
out.write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")
print(len(lines))
PY

n="$(wc -l <"$CELL_LIST" | tr -d ' ')"
[[ "$n" -ge 1 ]] || fail "no matrix cells for repo_id=$REPO_ID"

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  IFS='|' read -r rid br eid <<<"$line"
  bash "$PKG_ROOT/scripts/matrix-sweep-cell.sh" "$PARENT" "$rid" "$br" "$eid" --sweep-started \
    || fail "sweep failed for $rid $br $eid"
done <"$CELL_LIST"

bash "$PKG_ROOT/scripts/freshness-mark.sh" --success "$PARENT" "$REPO_ID" \
  || fail "mark --success failed (cells not all terminal?)"
echo "OK: freshness-refresh-repo repo=$REPO_ID"
