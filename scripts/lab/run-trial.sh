#!/usr/bin/env bash
# One lab trial: allowlist/fixture → excluded copy → continuum → SCOREBOARD.
# LAB_NO_DELETE: never rm staging, never docker rm. Owner cleans /tmp later.
# Usage:
#   bash run-trial.sh --fixture=synthetic-parent
#   bash run-trial.sh --source=/Users/eric.fang/MindOwnBuz [--model=composer --slot=a]
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_ROOT="$(cd "$LAB_DIR/../.." && pwd)"
# shellcheck source=allowlist.sh
source "$LAB_DIR/allowlist.sh"

export LAB_NO_DELETE=1

SOURCE=""
FIXTURE=""
MODEL="script"
SLOT="0"
RUN_ROOT="${VIBAGE_LAB_ROOT:-/tmp/vibage-lab}"

for arg in "$@"; do
  case "$arg" in
    --source=*) SOURCE="${arg#*=}" ;;
    --fixture=*) FIXTURE="${arg#*=}" ;;
    --model=*) MODEL="${arg#*=}" ;;
    --slot=*) SLOT="${arg#*=}" ;;
    --run-root=*) RUN_ROOT="${arg#*=}" ;;
    --mode=*)
      echo "FAIL: Docker mode removed (LAB_NO_DELETE). Use host staging only." >&2
      exit 1
      ;;
    --keep)
      # Accepted for back-compat; keep is always on.
      ;;
    *) echo "FAIL: unknown arg: $arg" >&2; exit 1 ;;
  esac
done

TS="$(date -u +%Y%m%dT%H%M%SZ)"
CASE_ID="case"
if [[ -n "$FIXTURE" ]]; then
  CASE_ID="fix-${FIXTURE}"
elif [[ -n "$SOURCE" ]]; then
  CASE_ID="copy-$(basename "$SOURCE")"
fi
# Include model+slot so parallel trials never collide on results/
TRIAL="$RUN_ROOT/$TS-$CASE_ID-$MODEL-$SLOT-$$"
PARENT_COPY="$TRIAL/parent"
OUT="$TRIAL/out"
mkdir -p "$PARENT_COPY" "$OUT"

# No trap that deletes. Only announce keep on exit.
on_exit() {
  local ec=$?
  echo "LAB_KEEP trial=$TRIAL ec=$ec"
  echo "LAB_NO_DELETE=1 owner cleans /tmp later"
  return "$ec"
}
trap on_exit EXIT

echo "LAB_TRIAL_START case=$CASE_ID model=$MODEL slot=$SLOT trial=$TRIAL"
echo "Honesty: LAB_OK ≠ live mutated ≠ TIER0_OK ≠ 掃透 ≠ letter B"
echo "LAB_NO_DELETE=1"

if [[ -n "$FIXTURE" ]]; then
  bash "$LAB_DIR/copy-parent.sh" --fixture="$FIXTURE" --dest="$PARENT_COPY"
else
  [[ -n "$SOURCE" ]] || { echo "FAIL: --source or --fixture required" >&2; exit 1; }
  lab_assert_source_allowed "$SOURCE"
  bash "$LAB_DIR/copy-parent.sh" --source="$SOURCE" --dest="$PARENT_COPY"
fi

bash "$LAB_DIR/continuum.sh" "$PARENT_COPY" "$PKG_ROOT" "$OUT"
EC=$?

KEEP_DIR="$RUN_ROOT/results/$TS-$CASE_ID-$MODEL-$SLOT"
mkdir -p "$KEEP_DIR"
if [[ -f "$OUT/SCOREBOARD.json" ]]; then
  cp -f "$OUT/SCOREBOARD.json" "$KEEP_DIR/SCOREBOARD.json"
  cp -f "$OUT/continuum.log" "$KEEP_DIR/continuum.log" 2>/dev/null || true
fi
printf '%s\n' "$PARENT_COPY" >"$KEEP_DIR/STAGING_PARENT"
printf '%s\n' "$TRIAL" >"$KEEP_DIR/TRIAL_ROOT"
echo "LAB_RESULTS path=$KEEP_DIR"
echo "STAGING_PARENT=$PARENT_COPY"

exit "$EC"
