#!/usr/bin/env bash
# Machine-filled coverage box for VIBAGE-ISSUE-* reports.
# Usage:
#   coverage-box.sh emit  <workspace> [--run=<RUNS/x.json>]
#   coverage-box.sh check <report.md> [--workspace=<ws>] [--run=<RUNS/x.json>]
#
# emit  → prints the `## Coverage (machine-filled)` section to paste into a report
# check → re-derives from the hub and fails if the box was hand-edited, or if
#         `## Held tokens` claims a token the workspace does not actually hold
#
# Parse the token, not the exit code alone:
#   COVERAGE_BOX_OK | COVERAGE_BOX_SKIPPED reason=... (both exit 0)
# SKIPPED means no hub was derivable — it is NOT a pass.
#
# This does not judge findings. It bounds them: numbers the agent cannot author
# sit above the prose, so an overclaiming sentence contradicts its own header.
set -euo pipefail
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIB="$PKG_ROOT/scripts/lib/coverage_box.py"
[[ -f "$LIB" ]] || { echo "FAIL: missing $LIB" >&2; exit 1; }

[[ $# -ge 2 ]] || {
  sed -n '2,12p' "$0" >&2
  exit 1
}

MODE="$1"
shift
TARGET="$1"
shift

ARGS=()
for arg in "$@"; do
  case "$arg" in
    --run=*) ARGS+=(--run "${arg#*=}") ;;
    --workspace=*) ARGS+=(--workspace "${arg#*=}") ;;
    --run|--workspace) echo "FAIL: use $arg=<value>" >&2; exit 1 ;;
    *) echo "FAIL: unknown arg $arg" >&2; exit 1 ;;
  esac
done

case "$MODE" in
  emit|check) exec python3 "$LIB" "$MODE" "$TARGET" "${ARGS[@]+"${ARGS[@]}"}" ;;
  *) echo "FAIL: mode must be emit|check" >&2; exit 1 ;;
esac
