#!/usr/bin/env bash
# Thin wrap → dimension_fill.py verify. Skills MUST parse stdout tokens.
# Exit 0 ≠ DIMENSION_FILL_OK (PARTIAL also exits 0).
# Usage: verify-dimension-fill.sh <mother-workspace>
set -euo pipefail
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIB="$PKG_ROOT/scripts/lib/dimension_fill.py"

if [[ $# -lt 1 || -z "${1:-}" ]]; then
  echo "FAIL: parent workspace path required" >&2
  exit 1
fi

PARENT="$(cd "$1" && pwd)" || { echo "FAIL: not a directory: $1" >&2; exit 1; }
[[ -f "$LIB" ]] || { echo "FAIL: missing $LIB" >&2; exit 1; }

exec python3 "$LIB" verify "$PARENT"
