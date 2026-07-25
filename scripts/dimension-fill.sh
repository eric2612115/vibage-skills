#!/usr/bin/env bash
# W3a P1 orchestrator: consent → synth → optional claims-dir search → verify.
# Usage: dimension-fill.sh <mother> [--claims-dir=<path>]
# Never prints MAP_DEEPEN_OK. exit 0 ≠ DIMENSION_FILL_OK (PARTIAL also exits 0).
set -euo pipefail
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIB="$PKG_ROOT/scripts/lib/dimension_fill.py"

MOTHER=""
CLAIMS_DIR=""

usage() {
  cat >&2 <<EOF
Usage: $0 <mother> [--claims-dir=<path>]
EOF
  exit 1
}

for arg in "$@"; do
  case "$arg" in
    --claims-dir=*) CLAIMS_DIR="${arg#*=}" ;;
    -h|--help) usage ;;
    *)
      if [[ "$arg" == --* ]]; then
        echo "FAIL: unknown flag $arg" >&2
        usage
      fi
      MOTHER="$arg"
      ;;
  esac
done

[[ -n "$MOTHER" ]] || usage
[[ -f "$LIB" ]] || { echo "FAIL: missing $LIB" >&2; exit 1; }

ARGS=(fill "$MOTHER")
if [[ -n "$CLAIMS_DIR" ]]; then
  ARGS+=(--claims-dir "$CLAIMS_DIR")
fi
exec python3 "$LIB" "${ARGS[@]}"
