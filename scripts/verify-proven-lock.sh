#!/usr/bin/env bash
# Proven-green lock — assert_gate applied to STATUS.md itself.
# Usage:
#   verify-proven-lock.sh [<pkg_root>]              → PROVEN_LOCK_OK | *_MISMATCH | *_NO_EVIDENCE
#   verify-proven-lock.sh --since <ref> [<pkg_root>] → PROVEN_DIFF / PROVEN_DIFF_NONE
#   verify-proven-lock.sh --sign  [<pkg_root>]      → re-sign (deliberate act; review the diff)
#
# Parse the token, not the exit code alone.
# PROVEN_LOCK_OK means: the rows the parser sees in the single `## Capability`
# table match the last signature, and each Proven-green=YES names an in-package
# path that exists (and, for run-kind, contains the declared run_ts).
# It does NOT mean the claims are true, that the evidence supports them, letter B,
# or a live-panel re-run. Scope caveat prose is outside the signature by design.
# ∉ Tier-0 (STATUS lints stay out of the ship gate).
set -euo pipefail
PKG_ROOT_DEFAULT="$(cd "$(dirname "$0")/.." && pwd)"
LIB="$PKG_ROOT_DEFAULT/scripts/lib/proven_lock.py"

MODE="check"
SINCE=""
PKG_ROOT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --since)
      MODE="diff"
      SINCE="${2:-}"
      [[ -n "$SINCE" ]] || { echo "FAIL: --since requires a git ref" >&2; exit 1; }
      shift 2
      ;;
    --since=*)
      MODE="diff"
      SINCE="${1#*=}"
      shift
      ;;
    --sign)
      MODE="sign"
      shift
      ;;
    -h|--help)
      sed -n '2,12p' "$0" >&2
      exit 0
      ;;
    --*)
      echo "FAIL: unknown flag $1" >&2
      exit 1
      ;;
    *)
      PKG_ROOT="$1"
      shift
      ;;
  esac
done

PKG_ROOT="${PKG_ROOT:-$PKG_ROOT_DEFAULT}"
[[ -d "$PKG_ROOT" ]] || { echo "FAIL: not a directory: $PKG_ROOT" >&2; exit 1; }
[[ -f "$LIB" ]] || { echo "FAIL: missing $LIB" >&2; exit 1; }

case "$MODE" in
  check) exec python3 "$LIB" check "$PKG_ROOT" ;;
  sign)  exec python3 "$LIB" sign "$PKG_ROOT" ;;
  diff)  exec python3 "$LIB" diff "$PKG_ROOT" --since "$SINCE" ;;
esac
