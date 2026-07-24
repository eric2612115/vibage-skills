#!/usr/bin/env bash
# Prove or fail one matrix cell using matrix-extract-evidence.py.
# Usage: matrix-sweep-cell.sh <parent> <repo_id> <branch_ref> <env_id> [--sweep-started]
# After --sweep-started (or always): never leave the cell unproven.
set -euo pipefail
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

fail() { echo "FAIL: $*" >&2; exit 1; }

if [[ $# -lt 4 ]]; then
  cat >&2 <<EOF
FAIL: Usage: $0 <parent> <repo_id> <branch_ref> <env_id> [--sweep-started]
EOF
  exit 1
fi

PARENT="$(cd "$1" && pwd)" || fail "parent is not a directory: $1"
REPO_ID="$2"
BRANCH_REF="$3"
ENV_ID="$4"
SWEEP_STARTED=false
if [[ "${5:-}" == "--sweep-started" ]]; then
  SWEEP_STARTED=true
fi

MATRIX="$PARENT/docs/vibage/maps/env_branch_matrix.json"
[[ -f "$MATRIX" ]] || fail "missing $MATRIX"
LOCK="${MATRIX}.lock"

update_cell() {
  # stdin: JSON patch {"state","reason"?,"pointers"?}
  # Use fcntl (portable on macOS/Linux) — `flock` CLI is often missing on Darwin.
  local patch
  patch="$(cat)"
  python3 - "$MATRIX" "$LOCK" "$REPO_ID" "$BRANCH_REF" "$ENV_ID" "$patch" <<'PY'
import fcntl
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

matrix_path = Path(sys.argv[1])
lock_path = Path(sys.argv[2])
repo_id, branch_ref, env_id = sys.argv[3], sys.argv[4], sys.argv[5]
patch = json.loads(sys.argv[6])
now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

lock_path.parent.mkdir(parents=True, exist_ok=True)
with open(lock_path, "a+", encoding="utf-8") as lf:
    fcntl.flock(lf.fileno(), fcntl.LOCK_EX)
    obj = json.loads(matrix_path.read_text(encoding="utf-8"))
    cell = None
    for c in obj.get("cells") or []:
        if (
            c.get("repo_id") == repo_id
            and c.get("branch_ref") == branch_ref
            and c.get("env_id") == env_id
        ):
            cell = c
            break
    if cell is None:
        print(f"FAIL: cell not found {repo_id}@{branch_ref}/{env_id}", file=sys.stderr)
        sys.exit(1)
    if cell.get("reason") == "branch_cap" and cell.get("state") == "failed":
        print("OK: leave branch_cap failed cell")
        sys.exit(0)
    if "pointers" in patch and patch["pointers"] is not None:
        cell["pointers"] = patch["pointers"]
    if "state" in patch:
        cell["state"] = patch["state"]
    if "reason" in patch:
        if patch["reason"] is None:
            cell.pop("reason", None)
        else:
            cell["reason"] = patch["reason"]
    elif patch.get("state") == "proven":
        cell.pop("reason", None)
    cell["updated_at"] = now
    if cell.get("state") == "unproven":
        cell["state"] = "failed"
        cell["reason"] = "sweep_forced_terminal"
    matrix_path.write_text(json.dumps(obj, indent=2) + "\n", encoding="utf-8")
    print(f"OK: cell {cell['state']} {repo_id}@{branch_ref}/{env_id}")
PY
}

# Special env ids: mark failed with reason, no extract
if [[ "$ENV_ID" == "missing-env-config" || "$ENV_ID" == "unknown-env" ]]; then
  printf '%s\n' "{\"state\":\"failed\",\"reason\":\"$ENV_ID\",\"pointers\":[{\"path\":\"$REPO_ID\",\"quote\":\"$ENV_ID\",\"branch_ref\":\"$BRANCH_REF\",\"env_id\":\"$ENV_ID\"}]}" \
    | update_cell
  exit 0
fi

ERR_TMP="$(mktemp)"
set +e
ext_out="$(
  python3 "$PKG_ROOT/scripts/matrix-extract-evidence.py" \
    "$PARENT" "$REPO_ID" "$BRANCH_REF" "$ENV_ID" 2>"$ERR_TMP"
)"
ext_rc=$?
set -e
rm -f "$ERR_TMP"

if [[ "$ext_rc" -eq 0 && -n "${ext_out// }" ]]; then
  printf '%s\n' "$ext_out" | python3 -c '
import json,sys
data=json.load(sys.stdin)
ptrs=data.get("pointers") or []
print(json.dumps({"state":"proven","reason":None,"pointers":ptrs}))
' | update_cell
else
  reason="extract_error"
  [[ "$ext_rc" -eq 124 ]] && reason="timeout"
  printf '%s\n' "{\"state\":\"failed\",\"reason\":\"$reason\",\"pointers\":[{\"path\":\"$REPO_ID\",\"quote\":\"extract failed\",\"branch_ref\":\"$BRANCH_REF\",\"env_id\":\"$ENV_ID\"}]}" \
    | update_cell
fi
