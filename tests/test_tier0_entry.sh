#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENTRY="$ROOT/scripts/test-tier0.sh"
[[ -x "$ENTRY" || -f "$ENTRY" ]] || { echo "FAIL: missing $ENTRY"; exit 1; }
# fail-closed: entry must not swallow child failures
grep -q 'set -euo pipefail' "$ENTRY"
grep -q 'test_p1_smoke.sh' "$ENTRY"
grep -q 'test_report_names.sh' "$ENTRY"
grep -q 'TIER0_OK' "$ENTRY"
# must NOT ignore smoke/report failures
if grep -E 'test_p1_smoke\.sh.*\|\| true|test_report_names\.sh.*\|\| true' "$ENTRY"; then
  echo "FAIL: entry ignores child failures"; exit 1
fi
echo "ENTRY_CONTRACT_OK"
