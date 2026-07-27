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
#
# LC_ALL=C because BSD sed rejects an illegal UTF-8 byte with "RE error: illegal byte
# sequence" under a UTF-8 locale, and argv can carry any byte. Under `set -e` that
# failure replaced the diagnostic with sed's own error and took the exit code with it —
# an unknown flag returned 1 instead of 2. The pattern is ASCII, so matching bytes
# costs nothing. The callers below still build the message before exiting, so the
# contract's exit code does not depend on the redaction succeeding.
redact() {
  LC_ALL=C sed -E 's/REVIEW_RECORD_(FIXTURE(_(PASS|SKIP|FAIL))?|OK|SKIP|FAIL|PASS)/REVIEW_RECORD_<redacted>/g'
}

diagnose() {
  printf '%s\n' "$1" | redact || printf '%s\n' "(diagnostic withheld: undisplayable)"
}

PKG=""
for arg in "$@"; do
  case "$arg" in
    -h|--help)
      sed -n '2,12p' "$0" >&2
      exit 0
      ;;
    --*)
      diagnose "FAIL: unknown flag $arg" >&2
      exit 2
      ;;
    *)
      PKG="$arg"
      ;;
  esac
done
PKG="${PKG:-$PKG_DEFAULT}"
[[ -d "$PKG" ]] || { diagnose "FAIL: not a directory: $PKG" >&2; exit 1; }
[[ -f "$LIB" ]] || { diagnose "FAIL: missing $LIB" >&2; exit 1; }

# Header honesty always (avoid printing the OK token literally)
echo "NOTE: exit 0 is not the OK token (same class as freshness)"
exec python3 "$LIB" "$PKG"
