#!/usr/bin/env bash
# Validate + ledger-append one dimension_* claim (W3a P0).
# Usage: dimension-search.sh <mother> <repo_id> <claim_class> <claim.json-file>
# Does not invent claims. Heuristic minting refused unless VIBAGE_DIMENSION_HEURISTIC=1.
set -euo pipefail
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIB="$PKG_ROOT/scripts/lib/dimension_fill.py"

if [[ $# -lt 4 || -z "${1:-}" || -z "${2:-}" || -z "${3:-}" || -z "${4:-}" ]]; then
  cat >&2 <<EOF
FAIL: Usage: $0 <mother> <repo_id> <claim_class> <claim.json-file>
EOF
  exit 1
fi

MOTHER="$(cd "$1" && pwd)" || { echo "FAIL: not a directory: $1" >&2; exit 1; }
REPO_ID="$2"
CLAIM_CLASS="$3"
CLAIM_JSON="$4"

[[ -f "$LIB" ]] || { echo "FAIL: missing $LIB" >&2; exit 1; }
[[ -f "$CLAIM_JSON" || "$CLAIM_JSON" == "-" ]] || {
  echo "FAIL: claim JSON not found: $CLAIM_JSON" >&2
  exit 1
}

exec python3 "$LIB" search "$MOTHER" "$REPO_ID" "$CLAIM_CLASS" "$CLAIM_JSON"
