#!/usr/bin/env bash
# Usage: verify-matrix-substantive.sh <workspace_root>
# Exit 0 and print MATRIX_SWEEP_SUBSTANTIVE_OK when all real-env cells are proven.
# env_vacancy_waiver never grants this token.
set -euo pipefail
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

WS="${1:-}"
if [[ -z "$WS" || ! -d "$WS" ]]; then
  echo "FAIL: Usage: $0 <workspace_root>" >&2
  exit 2
fi

fail() { echo "FAIL: $*" >&2; exit 1; }

# Requires ENV_BRANCH_MATRIX_OK first
out="$(bash "$PKG_ROOT/scripts/verify-env-branch-matrix.sh" "$WS")" || fail "ENV_BRANCH_MATRIX_OK required"
[[ "$out" == "ENV_BRANCH_MATRIX_OK" ]] || fail "expected ENV_BRANCH_MATRIX_OK, got: $out"

MATRIX="$WS/docs/vibage/maps/env_branch_matrix.json"

python3 - "$MATRIX" <<'PY'
import json, sys

matrix_path = sys.argv[1]

def die(msg: str) -> None:
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)

matrix = json.load(open(matrix_path, encoding="utf-8"))
cells = matrix.get("cells") or []
SPECIAL = {"missing-env-config", "unknown-env"}

for i, c in enumerate(cells):
    eid = c.get("env_id")
    if eid == "unknown-env":
        die("unknown-env blocks MATRIX_SWEEP_SUBSTANTIVE_OK")
    if eid == "missing-env-config":
        die("missing-env-config blocks MATRIX_SWEEP_SUBSTANTIVE_OK (waiver never grants 掃透)")

real = [c for c in cells if c.get("env_id") not in SPECIAL]
if len(real) < 1:
    die("need ≥1 real-env cell for MATRIX_SWEEP_SUBSTANTIVE_OK")

for i, c in enumerate(real):
    if c.get("state") != "proven":
        die(f"real-env cell not proven: {c.get('repo_id')}@{c.get('branch_ref')}/{c.get('env_id')} state={c.get('state')}")
    ptrs = c.get("pointers") or []
    if not isinstance(ptrs, list) or not ptrs:
        # allow evidence_hash on cell as alternate
        if not c.get("evidence_hash"):
            die(f"real-env cell missing pointers/evidence_hash: {c.get('repo_id')}@{c.get('branch_ref')}/{c.get('env_id')}")
        continue
    ok = False
    for p in ptrs:
        if not isinstance(p, dict):
            continue
        path = (p.get("path") or "").strip()
        quote = (p.get("quote") or "").strip()
        eh = (p.get("evidence_hash") or "").strip()
        if path and (quote or eh):
            # prefer matching branch_ref/env_id when present
            br = p.get("branch_ref")
            en = p.get("env_id")
            if br is not None and br != c.get("branch_ref"):
                continue
            if en is not None and en != c.get("env_id"):
                continue
            ok = True
            break
    if not ok and not c.get("evidence_hash"):
        die(
            f"real-env cell lacks non-empty path+quote for "
            f"{c.get('repo_id')}@{c.get('branch_ref')}/{c.get('env_id')}"
        )

sys.exit(0)
PY

echo "MATRIX_SWEEP_SUBSTANTIVE_OK"
