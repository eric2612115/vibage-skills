#!/usr/bin/env bash
# Thin wrap → env-vacancy-check. Skills MUST parse stdout tokens.
# Exit 0 ≠ full-sweep ≠ continuum-complete (CLEAR/ANSWERED both exit 0).
# Usage: verify-env-vacancy.sh <mother-workspace>
set -euo pipefail
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ $# -lt 1 || -z "${1:-}" ]]; then
  echo "FAIL: parent workspace path required" >&2
  exit 1
fi

PARENT="$(cd "$1" && pwd)" || { echo "FAIL: not a directory: $1" >&2; exit 1; }
exec bash "$PKG_ROOT/scripts/env-vacancy-check.sh" "$PARENT"
