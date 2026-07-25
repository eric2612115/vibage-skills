#!/usr/bin/env bash
# Round 1 + Round 2 script matrices. LAB_NO_DELETE.
# Usage: bash run-round12.sh [--parallel=2] [--fixtures-only]
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
export LAB_NO_DELETE=1
RUN_ROOT="${VIBAGE_LAB_ROOT:-/tmp/vibage-lab}"
PARALLEL=2
EXTRA=()

for arg in "$@"; do
  case "$arg" in
    --parallel=*) PARALLEL="${arg#*=}" ;;
    --fixtures-only) EXTRA+=(--fixtures-only) ;;
    --run-root=*) RUN_ROOT="${arg#*=}" ;;
    *) echo "FAIL: unknown arg $arg" >&2; exit 1 ;;
  esac
done

SNAP="$RUN_ROOT/live-snapshots/before-round12-$(date -u +%Y%m%dT%H%M%SZ).json"
mkdir -p "$(dirname "$SNAP")"
bash "$LAB_DIR/assert-live-untouched.sh" --snapshot="$SNAP"

echo "LAB_ROUND12_START parallel=$PARALLEL"
set +e
bash "$LAB_DIR/run-matrix.sh" --round=1 --parallel="$PARALLEL" --run-root="$RUN_ROOT" "${EXTRA[@]+"${EXTRA[@]}"}"
R1=$?
bash "$LAB_DIR/run-matrix.sh" --round=2 --parallel="$PARALLEL" --run-root="$RUN_ROOT" "${EXTRA[@]+"${EXTRA[@]}"}"
R2=$?
set -e

bash "$LAB_DIR/assert-live-untouched.sh" --check="$SNAP"
echo "LAB_ROUND12_DONE r1=$R1 r2=$R2 live untouched; artifacts under $RUN_ROOT (owner cleans /tmp)"
[[ "$R1" -eq 0 && "$R2" -eq 0 ]]
