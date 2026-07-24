#!/usr/bin/env bash
# Usage: verify-matrix-substantive.sh <workspace_root>
# Exit 0 and print MATRIX_SWEEP_SUBSTANTIVE_OK when all real-env cells are proven
# with non-empty path+quote pointers (evidence_hash alone NEVER suffices).
# env_vacancy_waiver never grants this token.
set -euo pipefail
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

WS="${1:-}"
if [[ -z "$WS" || ! -d "$WS" ]]; then
  echo "FAIL: Usage: $0 <workspace_root>" >&2
  exit 2
fi

fail() { echo "FAIL: $*" >&2; exit 1; }

out="$(bash "$PKG_ROOT/scripts/verify-env-branch-matrix.sh" "$WS")" || fail "ENV_BRANCH_MATRIX_OK required"
[[ "$out" == "ENV_BRANCH_MATRIX_OK" ]] || fail "expected ENV_BRANCH_MATRIX_OK, got: $out"

MATRIX="$WS/docs/vibage/maps/env_branch_matrix.json"

python3 - "$MATRIX" <<'PY'
import json, re, sys

matrix_path = sys.argv[1]

# Invisible / format-only chars that must not count as a real quote
_INVIS = re.compile(
    r"[\u200b\u200c\u200d\u2060\ufeff\u00ad\u200e\u200f\u202a-\u202e\u2066-\u2069]+"
)

def visible_text(s: str) -> str:
    s = _INVIS.sub("", s or "")
    return "".join(ch for ch in s if not ch.isspace()).strip()

def die(msg: str) -> None:
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)

matrix = json.load(open(matrix_path, encoding="utf-8"))
cells = matrix.get("cells") or []
SPECIAL = {"missing-env-config", "unknown-env"}

for c in cells:
    eid = c.get("env_id")
    if eid == "unknown-env":
        die("unknown-env blocks MATRIX_SWEEP_SUBSTANTIVE_OK")
    if eid == "missing-env-config":
        die("missing-env-config blocks MATRIX_SWEEP_SUBSTANTIVE_OK (waiver never grants 掃透)")

real = [c for c in cells if c.get("env_id") not in SPECIAL]
if len(real) < 1:
    die("need ≥1 real-env cell for MATRIX_SWEEP_SUBSTANTIVE_OK")

for c in real:
    if c.get("state") != "proven":
        die(
            f"real-env cell not proven: {c.get('repo_id')}@{c.get('branch_ref')}/{c.get('env_id')} "
            f"state={c.get('state')}"
        )
    ptrs = c.get("pointers") or []
    if not isinstance(ptrs, list) or not ptrs:
        die(
            f"real-env cell missing pointers (evidence_hash alone never suffices): "
            f"{c.get('repo_id')}@{c.get('branch_ref')}/{c.get('env_id')}"
        )
    ok = False
    for p in ptrs:
        if not isinstance(p, dict):
            continue
        path = visible_text(p.get("path") or "")
        quote = visible_text(p.get("quote") or "")
        if not path or not quote:
            continue
        br = p.get("branch_ref")
        en = p.get("env_id")
        if br is not None and br != c.get("branch_ref"):
            continue
        if en is not None and en != c.get("env_id"):
            continue
        ok = True
        break
    if not ok:
        die(
            f"real-env cell lacks visible path+quote "
            f"(evidence_hash / invisible-only quote rejected): "
            f"{c.get('repo_id')}@{c.get('branch_ref')}/{c.get('env_id')}"
        )

sys.exit(0)
PY

echo "MATRIX_SWEEP_SUBSTANTIVE_OK"
