#!/usr/bin/env bash
# W1 freshness check — mother HARD / child SOFT.
# Usage: freshness-check.sh --mode=mother|child [--repo=<id>] [--json] <path>
# Exit 0 ≠ FRESHNESS_OK (waived-stale also exits 0). Skills MUST parse stdout tokens.
set -euo pipefail
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIB="$PKG_ROOT/scripts/lib/freshness.py"

MODE=""
REPO=""
PATH_ARG="."
JSON=0

usage() {
  cat >&2 <<EOF
Usage: $0 --mode=mother|child [--repo=<id>] [--json] <path>

Mother: FRESHNESS_OK | STALE_BLOCKS_MOTHER count=N | FRESHNESS_WAIVED + STALE_DISCLOSED
Child: always exit 0; FRESHNESS_CHILD_WARN / VIBAGE_PARENT_UNRESOLVED / escalate
EOF
  exit 1
}

for arg in "$@"; do
  case "$arg" in
    --mode=*) MODE="${arg#*=}" ;;
    --repo=*) REPO="${arg#*=}" ;;
    --json) JSON=1 ;;
    -h|--help) usage ;;
    *)
      if [[ "$arg" == --* ]]; then
        echo "FAIL: unknown flag $arg" >&2
        usage
      fi
      PATH_ARG="$arg"
      ;;
  esac
done

[[ "$MODE" == "mother" || "$MODE" == "child" ]] || usage
[[ -f "$LIB" ]] || { echo "FAIL: missing $LIB" >&2; exit 1; }

# --json reserved: same tokens today; optional machine line on stderr
if [[ "$JSON" -eq 1 ]]; then
  echo "NOTE: --json emits same tokens; stale details on stderr" >&2
fi

ARGS=(check --mode "$MODE")
if [[ -n "$REPO" ]]; then
  ARGS+=(--repo "$REPO")
fi
ARGS+=("$PATH_ARG")

exec python3 "$LIB" "${ARGS[@]}"
