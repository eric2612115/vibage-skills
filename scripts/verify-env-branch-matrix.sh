#!/usr/bin/env bash
# Usage: verify-env-branch-matrix.sh <workspace_root>
# Exit 0 and print exactly ENV_BRANCH_MATRIX_OK when matrix terminal rules hold.
set -euo pipefail

WS="${1:-}"
if [[ -z "$WS" || ! -d "$WS" ]]; then
  echo "FAIL: Usage: $0 <workspace_root>" >&2
  exit 2
fi

MATRIX="$WS/docs/vibage/maps/env_branch_matrix.json"
MANIFEST="$WS/docs/vibage/maps/inventory_manifest.json"
POLICY="$WS/docs/vibage/OWNER_POLICY.json"

fail() { echo "FAIL: $*" >&2; exit 1; }

[[ -f "$MATRIX" ]] || fail "missing $MATRIX"
[[ -f "$MANIFEST" ]] || fail "missing $MANIFEST"

python3 - "$MATRIX" "$MANIFEST" "$POLICY" <<'PY'
import json, sys
from pathlib import Path

matrix_path, manifest_path, policy_path = sys.argv[1], sys.argv[2], sys.argv[3]

def die(msg: str) -> None:
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)

try:
    matrix = json.load(open(matrix_path, encoding="utf-8"))
except Exception as e:
    die(f"env_branch_matrix.json unreadable: {e}")

try:
    manifest = json.load(open(manifest_path, encoding="utf-8"))
except Exception as e:
    die(f"inventory_manifest.json unreadable: {e}")

if not isinstance(matrix, dict):
    die("env_branch_matrix.json must be a JSON object")
if not isinstance(manifest, dict):
    die("inventory_manifest.json must be a JSON object")

status = matrix.get("status", "ok")
if status == "overflow":
    die("matrix status=overflow (raise max_matrix_cells or tighten globs)")

cells = matrix.get("cells")
if not isinstance(cells, list):
    die("cells must be a list")

rows = manifest.get("rows")
if not isinstance(rows, list):
    die("inventory_manifest.rows must be a list")

def cell_key(c):
    return (c.get("repo_id"), c.get("branch_ref"), c.get("env_id"))

cell_keys = [cell_key(c) for c in cells]
row_keys = [cell_key(r) for r in rows]

if len(cell_keys) != len(row_keys):
    die(f"manifest/matrix row count mismatch: manifest={len(row_keys)} matrix={len(cell_keys)}")

if sorted(cell_keys, key=lambda x: (str(x[0]), str(x[1]), str(x[2]))) != sorted(
    row_keys, key=lambda x: (str(x[0]), str(x[1]), str(x[2]))
):
    die("inventory_manifest rows are not 1:1 with matrix cells")

SPECIAL = {"missing-env-config", "unknown-env"}

for i, c in enumerate(cells):
    if not isinstance(c, dict):
        die(f"cells[{i}] must be an object")
    for k in ("repo_id", "branch_ref", "env_id", "state"):
        if k not in c:
            die(f"cells[{i}] missing {k}")
    st = c.get("state")
    if st == "unproven":
        die(f"cells[{i}] is unproven (terminal rule: proven|failed only)")
    if st not in ("proven", "failed"):
        die(f"cells[{i}].state must be proven|failed, got {st!r}")
    if c.get("env_id") == "unknown-env":
        die("unknown-env cells present (must resolve before ENV_BRANCH_MATRIX_OK)")

if len(cells) == 0:
    die("matrix has zero cells")

env_ids = {c.get("env_id") for c in cells}
real_envs = env_ids - SPECIAL
only_vacant = len(real_envs) == 0 and (
    "missing-env-config" in env_ids or "unknown-env" in env_ids
)

waiver = False
reason = ""
pp = Path(policy_path)
if pp.is_file():
    try:
        pol = json.load(open(pp, encoding="utf-8"))
    except Exception:
        pol = {}
    waiver = bool(pol.get("env_vacancy_waiver") is True)
    reason = str(pol.get("env_vacancy_reason") or pol.get("reason") or "").strip()

if only_vacant:
    if not waiver:
        die("all cells are missing-env-config/unknown-env without env_vacancy_waiver")
    if not reason:
        die("env_vacancy_waiver requires a non-empty reason")

sys.exit(0)
PY

echo "ENV_BRANCH_MATRIX_OK"
