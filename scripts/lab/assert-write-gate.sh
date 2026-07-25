#!/usr/bin/env bash
# Write gate: path must be under lab staging (or results), never under live allowlist roots.
# Usage:
#   bash assert-write-gate.sh <path> [--staging=<STAGING_PARENT>]
# Exit 0 + LAB_WRITE_GATE_OK, else FAIL.
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=allowlist.sh
source "$LAB_DIR/allowlist.sh"

TARGET="${1:-}"
STAGING=""
shift || true
for arg in "$@"; do
  case "$arg" in
    --staging=*) STAGING="${arg#*=}" ;;
    *) echo "FAIL: unknown arg $arg" >&2; exit 1 ;;
  esac
done

[[ -n "$TARGET" ]] || { echo "Usage: $0 <path> [--staging=STAGING_PARENT]" >&2; exit 2; }

LAB_ROOT_RAW="${VIBAGE_LAB_ROOT:-/tmp/vibage-lab}"
mkdir -p "$LAB_ROOT_RAW"
LAB_ROOT="$(cd "$LAB_ROOT_RAW" && pwd -P)"

# Resolve if exists; otherwise use parent of path for planned writes
if [[ -e "$TARGET" ]]; then
  if [[ -d "$TARGET" ]]; then
    RESOLVED="$(cd "$TARGET" && pwd -P)"
  else
    RESOLVED="$(cd "$(dirname "$TARGET")" && pwd -P)/$(basename "$TARGET")"
  fi
else
  PARENT="$(dirname "$TARGET")"
  mkdir -p "$PARENT" 2>/dev/null || true
  if [[ -d "$PARENT" ]]; then
    RESOLVED="$(cd "$PARENT" && pwd -P)/$(basename "$TARGET")"
  else
    RESOLVED="$TARGET"
  fi
fi

under_lab() {
  local p="$1"
  [[ "$p" == "$LAB_ROOT" || "$p" == "$LAB_ROOT"/* ]]
}

# Never write live mothers (unless somehow also under lab root)
if lab_is_live_allowlist_path "$RESOLVED" && ! under_lab "$RESOLVED"; then
  echo "LAB_WRITE_GATE_FAIL: path under live allowlist: $RESOLVED" >&2
  exit 1
fi

if ! under_lab "$RESOLVED"; then
  echo "LAB_WRITE_GATE_FAIL: path not under lab root $LAB_ROOT: $RESOLVED" >&2
  exit 1
fi

if [[ -n "$STAGING" ]]; then
  STAGING="$(cd "$STAGING" && pwd -P)"
  if ! under_lab "$STAGING"; then
    echo "LAB_WRITE_GATE_FAIL: staging not under lab root: $STAGING" >&2
    exit 1
  fi
  RESULTS_ROOT="$LAB_ROOT/results"
  case "$RESOLVED" in
    "$STAGING"|"$STAGING"/*|"$RESULTS_ROOT"|"$RESULTS_ROOT"/*) ;;
    *)
      echo "LAB_WRITE_GATE_FAIL: path outside staging+results: $RESOLVED (staging=$STAGING)" >&2
      exit 1
      ;;
  esac
fi

echo "LAB_WRITE_GATE_OK path=$RESOLVED"
