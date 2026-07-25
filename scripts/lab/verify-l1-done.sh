#!/usr/bin/env bash
# Verify one Round-3 L1 staging finished dig (dual reports) without deletes.
# Usage: bash verify-l1-done.sh <STAGING_PARENT> <RESULTS_DIR>
set -euo pipefail
WS="${1:-}"
RES="${2:-}"
[[ -n "$WS" && -d "$WS" ]] || { echo "Usage: $0 <STAGING_PARENT> [RESULTS_DIR]" >&2; exit 2; }
WS="$(cd "$WS" && pwd -P)"
OWNER="$WS/docs/vibage/VIBAGE-ISSUE-OWNER.md"
LOCATE="$WS/docs/vibage/VIBAGE-ISSUE-LOCATE.md"
ok=1
[[ -f "$OWNER" ]] || { echo "MISSING $OWNER"; ok=0; }
[[ -f "$LOCATE" ]] || { echo "MISSING $LOCATE"; ok=0; }
if [[ -n "$RES" ]]; then
  mkdir -p "$RES"
  [[ -f "$OWNER" ]] && cp -f "$OWNER" "$RES/VIBAGE-ISSUE-OWNER.md"
  [[ -f "$LOCATE" ]] && cp -f "$LOCATE" "$RES/VIBAGE-ISSUE-LOCATE.md"
  printf 'DONE\n' >"$RES/DIG_STATUS"
fi
if [[ "$ok" -eq 1 ]]; then
  echo "LAB_L1_DONE_OK staging=$WS"
  exit 0
fi
echo "LAB_L1_DONE_FAIL staging=$WS" >&2
exit 1
