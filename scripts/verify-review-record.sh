#!/usr/bin/env bash
# Mechanical review-record gate for guarded paths. ∉ Tier-0.
# Usage:
#   bash verify-review-record.sh [<pkg_root>]
#   bash verify-review-record.sh --paths-file=FILE [--base=LABEL] [<pkg_root>]
# Tokens (parse stdout; exit 0 ≠ REVIEW_RECORD_OK):
#   REVIEW_RECORD_SKIP | REVIEW_RECORD_OK | REVIEW_RECORD_FAIL
# Not a required git pre-commit hook. See references/looping-review.md.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_DEFAULT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB="$SCRIPT_DIR/lib/review_record.py"

ARGS=()
PKG=""
for arg in "$@"; do
  case "$arg" in
    --paths-file=*|--base=*) ARGS+=("$arg") ;;
    -h|--help)
      sed -n '2,10p' "$0" >&2
      exit 0
      ;;
    --*)
      echo "FAIL: unknown flag $arg" >&2
      exit 2
      ;;
    *)
      PKG="$arg"
      ;;
  esac
done
PKG="${PKG:-$PKG_DEFAULT}"
[[ -d "$PKG" ]] || { echo "FAIL: not a directory: $PKG" >&2; exit 1; }
[[ -f "$LIB" ]] || { echo "FAIL: missing $LIB" >&2; exit 1; }

# Header honesty always (avoid printing the OK token literally)
echo "NOTE: exit 0 is not the OK token (same class as freshness)"
if [[ ${#ARGS[@]} -gt 0 ]]; then
  exec python3 "$LIB" "$PKG" "${ARGS[@]}"
fi
exec python3 "$LIB" "$PKG"