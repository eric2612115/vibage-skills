#!/usr/bin/env bash
# W2 record skip | classify | point into env_vacancy_answers.json.
# Usage:
#   env-vacancy-answer.sh --skip|--classify=<class>|--point=<relpath> \
#     --reason=... --repo=... --branch=... [--env=missing-env-config] <mother>
set -euo pipefail
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIB="$PKG_ROOT/scripts/lib/env_vacancy.py"

usage() {
  cat >&2 <<EOF
FAIL: Usage:
  $0 --skip|--classify=<class>|--point=<relpath> \\
    --reason=... --repo=... --branch=... [--env=missing-env-config] <mother>
EOF
  exit 1
}

[[ $# -ge 1 ]] || usage
[[ -f "$LIB" ]] || { echo "FAIL: missing $LIB" >&2; exit 1; }

PY_ARGS=()
MOTHER=""
ACTION_SET=0

for arg in "$@"; do
  case "$arg" in
    --skip)
      PY_ARGS+=(--skip)
      ACTION_SET=1
      ;;
    --classify=*)
      PY_ARGS+=(--classify "${arg#*=}")
      ACTION_SET=1
      ;;
    --point=*)
      PY_ARGS+=(--point "${arg#*=}")
      ACTION_SET=1
      ;;
    --reason=*)
      PY_ARGS+=(--reason "${arg#*=}")
      ;;
    --repo=*)
      PY_ARGS+=(--repo "${arg#*=}")
      ;;
    --branch=*)
      PY_ARGS+=(--branch "${arg#*=}")
      ;;
    --env=*)
      PY_ARGS+=(--env "${arg#*=}")
      ;;
    -h|--help)
      usage
      ;;
    --*)
      echo "FAIL: unknown flag $arg" >&2
      usage
      ;;
    *)
      if [[ -n "$MOTHER" ]]; then
        echo "FAIL: unexpected arg: $arg" >&2
        usage
      fi
      MOTHER="$arg"
      ;;
  esac
done

[[ -n "$MOTHER" ]] || usage
[[ "$ACTION_SET" -eq 1 ]] || usage
PARENT="$(cd "$MOTHER" && pwd)" || { echo "FAIL: not a directory: $MOTHER" >&2; exit 1; }

exec python3 "$LIB" answer "${PY_ARGS[@]}" "$PARENT"
