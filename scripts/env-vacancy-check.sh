#!/usr/bin/env bash
# W2 env vacancy check — print one ENV_VACANCY_* token.
# Exit 0 for CLEAR/ANSWERED; ≠0 for ASK/BLOCKED. Exit 0 ≠ 掃透.
# Usage: env-vacancy-check.sh <mother-workspace>
set -euo pipefail
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIB="$PKG_ROOT/scripts/lib/env_vacancy.py"

if [[ $# -lt 1 || -z "${1:-}" ]]; then
  echo "FAIL: Usage: $0 <mother-workspace>" >&2
  exit 1
fi

PARENT="$(cd "$1" && pwd)" || { echo "FAIL: not a directory: $1" >&2; exit 1; }
[[ -f "$LIB" ]] || { echo "FAIL: missing $LIB" >&2; exit 1; }

exec python3 "$LIB" check "$PARENT"
