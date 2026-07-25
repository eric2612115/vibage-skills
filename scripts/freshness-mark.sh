#!/usr/bin/env bash
# W1 freshness mark — fail-closed --success / soft --refuse
# Usage:
#   freshness-mark.sh --success <mother> <repo_id>
#   freshness-mark.sh --refuse  <mother> <repo_id>
set -euo pipefail
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIB="$PKG_ROOT/scripts/lib/freshness.py"

ACTION=""
MOTHER=""
REPO=""

usage() {
  cat >&2 <<EOF
Usage:
  $0 --success <mother> <repo_id>
  $0 --refuse  <mother> <repo_id>

--success requires every matrix cell for repo_id to be proven|failed (zero cells ⇒ fail).
EOF
  exit 1
}

[[ $# -ge 3 ]] || usage
ACTION="$1"
MOTHER="$2"
REPO="$3"

case "$ACTION" in
  --success) exec python3 "$LIB" mark --success "$MOTHER" "$REPO" ;;
  --refuse)  exec python3 "$LIB" mark --refuse "$MOTHER" "$REPO" ;;
  *) usage ;;
esac
