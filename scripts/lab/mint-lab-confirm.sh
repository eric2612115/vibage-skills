#!/usr/bin/env bash
# Mint CONFIRM.json inside a STAGING parent only (lab agent substitute for owner OK).
# Refuses if workspace looks like a live allowlist root.
# Usage: bash mint-lab-confirm.sh <STAGING_PARENT> [confirmed_by]
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_ROOT="$(cd "$LAB_DIR/../.." && pwd)"
# shellcheck source=allowlist.sh
source "$LAB_DIR/allowlist.sh"

WS="${1:-}"
BY="${2:-lab-orchestrator}"
[[ -n "$WS" && -d "$WS" ]] || { echo "Usage: $0 <STAGING_PARENT> [confirmed_by]" >&2; exit 2; }
WS="$(cd "$WS" && pwd -P)"

# Must be under lab root (resolve for macOS /tmp -> /private/tmp)
LAB_ROOT_RAW="${VIBAGE_LAB_ROOT:-/tmp/vibage-lab}"
mkdir -p "$LAB_ROOT_RAW"
LAB_ROOT="$(cd "$LAB_ROOT_RAW" && pwd -P)"
case "$WS" in
  "$LAB_ROOT"|"$LAB_ROOT"/*) ;;
  *)
    echo "LAB_CONFIRM_FAIL: staging must be under $LAB_ROOT, got $WS" >&2
    exit 1
    ;;
esac

# Refuse if this path IS a live mother root
for m in "${LAB_NAMED_MOTHERS[@]}"; do
  if [[ -d "$m" ]]; then
    live="$(cd "$m" && pwd -P)"
    if [[ "$WS" == "$live" ]]; then
      echo "LAB_CONFIRM_FAIL: refusing to confirm live mother $live" >&2
      exit 1
    fi
  fi
done

PLAN="$WS/docs/vibage/SCAN_PLAN.md"
[[ -f "$PLAN" ]] || { echo "LAB_CONFIRM_FAIL: missing $PLAN — run continuum/orient first" >&2; exit 1; }

bash "$PKG_ROOT/scripts/write_confirm.sh" "$WS" "$BY"
bash "$PKG_ROOT/scripts/assert_gate.sh" "$WS"
echo "LAB_CONFIRM_OK staging=$WS"
