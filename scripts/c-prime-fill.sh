#!/usr/bin/env bash
# C′ fill orchestrator: graph-floor → matrix-inventory → parallel cell sweep.
# Usage: c-prime-fill.sh <parent-workspace>
# Parallelism: min(8, n_cells) via xargs -P. Cell timeout → failed + continue.
set -euo pipefail
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

fail() { echo "FAIL: $*" >&2; exit 1; }

if [[ $# -lt 1 || -z "${1:-}" ]]; then
  cat >&2 <<EOF
FAIL: parent workspace path required.

Usage: $0 /path/to/parent-workspace
EOF
  exit 1
fi

PARENT="$(cd "$1" && pwd)" || fail "parent is not a directory: $1"
CELL_TIMEOUT="${VIBAGE_MATRIX_CELL_TIMEOUT:-60}"

bash "$PKG_ROOT/scripts/graph-floor.sh" "$PARENT" || fail "graph-floor failed"
bash "$PKG_ROOT/scripts/matrix-inventory.sh" "$PARENT" || fail "matrix-inventory failed"

MATRIX="$PARENT/docs/vibage/maps/env_branch_matrix.json"
[[ -f "$MATRIX" ]] || fail "missing matrix after inventory"

# Build cell list: repo_id|branch_ref|env_id
CELL_LIST="$(mktemp)"
trap 'rm -f "$CELL_LIST"' EXIT

python3 - "$MATRIX" "$CELL_LIST" <<'PY'
import json, sys
from pathlib import Path

matrix = json.load(open(sys.argv[1], encoding="utf-8"))
out = Path(sys.argv[2])
lines = []
for c in matrix.get("cells") or []:
    # skip already terminal branch_cap — still sweep others; branch_cap left alone by sweep
    rid = c.get("repo_id") or ""
    br = c.get("branch_ref") or ""
    eid = c.get("env_id") or ""
    if not rid or not br or not eid:
        continue
    lines.append(f"{rid}|{br}|{eid}")
out.write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")
print(len(lines))
PY

n="$(wc -l <"$CELL_LIST" | tr -d ' ')"
if [[ "$n" -eq 0 ]]; then
  fail "no matrix cells to sweep"
fi

# parallelism min(8, n)
if [[ "$n" -lt 8 ]]; then
  P="$n"
else
  P=8
fi
[[ "$P" -lt 1 ]] && P=1

echo "OK: sweeping n_cells=$n parallelism=$P timeout=${CELL_TIMEOUT}s"

sweep_one() {
  local line="$1"
  local rid br eid
  IFS='|' read -r rid br eid <<<"$line"
  # per-cell timeout → failed + continue
  if command -v timeout >/dev/null 2>&1; then
    if ! timeout "$CELL_TIMEOUT" bash "$PKG_ROOT/scripts/matrix-sweep-cell.sh" \
      "$PARENT" "$rid" "$br" "$eid" --sweep-started; then
      # ensure terminal failed on timeout/kill
      python3 - "$PARENT/docs/vibage/maps/env_branch_matrix.json" "$rid" "$br" "$eid" <<'PY'
import json, sys
from datetime import datetime, timezone
from pathlib import Path
p = Path(sys.argv[1])
rid, br, eid = sys.argv[2], sys.argv[3], sys.argv[4]
obj = json.loads(p.read_text(encoding="utf-8"))
now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
for c in obj.get("cells") or []:
    if c.get("repo_id")==rid and c.get("branch_ref")==br and c.get("env_id")==eid:
        if c.get("state") == "unproven":
            c["state"] = "failed"
            c["reason"] = "timeout"
            c["updated_at"] = now
            if not c.get("pointers"):
                c["pointers"] = [{"path": rid, "quote": "timeout", "branch_ref": br, "env_id": eid}]
        break
p.write_text(json.dumps(obj, indent=2) + "\n", encoding="utf-8")
PY
    fi
  else
    bash "$PKG_ROOT/scripts/matrix-sweep-cell.sh" \
      "$PARENT" "$rid" "$br" "$eid" --sweep-started || true
  fi
}
export -f sweep_one
export PKG_ROOT PARENT CELL_TIMEOUT

# xargs -P parallel; continue on individual failures
set +e
cat "$CELL_LIST" | xargs -P "$P" -I{} bash -c 'sweep_one "$@"' _ {}
set -e

# Final: force any leftover unproven → failed (sweep started)
python3 - "$MATRIX" <<'PY'
import json, sys
from datetime import datetime, timezone
from pathlib import Path
p = Path(sys.argv[1])
obj = json.loads(p.read_text(encoding="utf-8"))
now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
n = 0
for c in obj.get("cells") or []:
    if c.get("state") == "unproven":
        c["state"] = "failed"
        c["reason"] = c.get("reason") or "sweep_forced_terminal"
        c["updated_at"] = now
        if not c.get("pointers"):
            c["pointers"] = [{
                "path": c.get("repo_id") or ".",
                "quote": "unproven after sweep",
                "branch_ref": c.get("branch_ref") or "",
                "env_id": c.get("env_id") or "",
            }]
        n += 1
p.write_text(json.dumps(obj, indent=2) + "\n", encoding="utf-8")
print(f"OK: forced_terminal={n}")
PY

echo "OK: c-prime-fill complete parent=$PARENT"
