#!/usr/bin/env bash
# Mechanical review-record gate for guarded paths. ∉ Tier-0.
# Usage:
#   bash verify-review-record.sh [<pkg_root>]
# Tokens (parse stdout; exit 0 ≠ REVIEW_RECORD_OK):
#   REVIEW_RECORD_SKIP | REVIEW_RECORD_OK | REVIEW_RECORD_FAIL
# Fixture tokens (direct library invocation with --paths-file= / --base= only):
#   REVIEW_RECORD_FIXTURE_PASS | REVIEW_RECORD_FIXTURE_SKIP | REVIEW_RECORD_FIXTURE_FAIL
# Not a required git pre-commit hook. See references/looping-review.md.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_DEFAULT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB="$SCRIPT_DIR/lib/review_record.py"

# These diagnostics echo argv and paths, so a token spelled in either would reach a
# stream consumers grep. Same rule as redact() in the library, kept in step by a test
# that runs both over one table. Documentation below deliberately names the tokens;
# --help is a human request, not a gate run, and prints no outcome.
redact() {
  sed -E 's/REVIEW_RECORD_(FIXTURE(_(PASS|SKIP|FAIL))?|OK|SKIP|FAIL|PASS)/REVIEW_RECORD_<redacted>/g'
}

PKG=""
for arg in "$@"; do
  case "$arg" in
    -h|--help)
      sed -n '2,12p' "$0" >&2
      exit 0
      ;;
    --*)
      printf 'FAIL: unknown flag %s\n' "$arg" | redact >&2
      exit 2
      ;;
    *)
      PKG="$arg"
      ;;
  esac
done
PKG="${PKG:-$PKG_DEFAULT}"
[[ -d "$PKG" ]] || { printf 'FAIL: not a directory: %s\n' "$PKG" | redact >&2; exit 1; }
[[ -f "$LIB" ]] || { printf 'FAIL: missing %s\n' "$LIB" | redact >&2; exit 1; }

# Header honesty always (avoid printing the OK token literally)
echo "NOTE: exit 0 is not the OK token (same class as freshness)"
exec python3 "$LIB" "$PKG"
