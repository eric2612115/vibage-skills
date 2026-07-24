#!/usr/bin/env bash
# Usage: verify-ledger-slice.sh <parent> <subject_id> <class1,class2,...>
# Exit 0 and print LEDGER_SLICE_PROVEN iff every listed class has a proven claim.
set -euo pipefail

fail() { echo "FAIL: $*" >&2; exit 1; }

PARENT="${1:-}"
SUBJECT_ID="${2:-}"
CLASSES_CSV="${3:-}"

if [[ -z "$PARENT" || -z "$SUBJECT_ID" || -z "$CLASSES_CSV" ]]; then
  echo "FAIL: Usage: $0 <workspace_root> <subject_id> <class1,class2,...>" >&2
  exit 2
fi

[[ -d "$PARENT" ]] || fail "parent is not a directory: $PARENT"

CLAIMS="$PARENT/docs/vibage/ledger/claims.jsonl"
[[ -f "$CLAIMS" ]] || fail "missing $CLAIMS"

python3 - "$CLAIMS" "$SUBJECT_ID" "$CLASSES_CSV" <<'PY'
import json, sys

claims_path = sys.argv[1]
subject_id = sys.argv[2]
classes = [c.strip() for c in sys.argv[3].split(",") if c.strip()]

def die(msg: str) -> None:
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)

if not classes:
    die("no claim classes specified")

# Latest claim per (subject_id, claim_class) wins
latest = {}
with open(claims_path, encoding="utf-8") as f:
    for lineno, line in enumerate(f, 1):
        line = line.strip()
        if not line:
            continue
        try:
            claim = json.loads(line)
        except json.JSONDecodeError as e:
            die(f"claims.jsonl line {lineno}: {e}")
        if not isinstance(claim, dict):
            continue
        if claim.get("subject_id") != subject_id:
            continue
        cls = claim.get("claim_class")
        if not cls:
            continue
        latest[cls] = claim

missing = []
for cls in classes:
    claim = latest.get(cls)
    if not claim or claim.get("state") != "proven":
        missing.append(cls)

if missing:
    die(
        f"subject={subject_id} not proven for: {','.join(missing)}"
    )

sys.exit(0)
PY

echo "LEDGER_SLICE_PROVEN"
