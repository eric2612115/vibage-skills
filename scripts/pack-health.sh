#!/usr/bin/env bash
# Composite local pack proof — NOT capability SSOT, NOT Tier-0, NOT remote CI.
# Usage: bash scripts/pack-health.sh /path/to/parent-workspace
set -euo pipefail
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PKG_ROOT"

fail() { echo "FAIL: $*" >&2; exit 1; }

if [[ $# -lt 1 || -z "${1:-}" ]]; then
  cat >&2 <<EOF
FAIL: parent workspace path required.

Usage: $0 /path/to/parent-workspace

This is a composite check (pins + parent entry + entry-docs sync).
PACK_HEALTH_OK ≠ TIER0_OK ≠ remote CI ≠ letter B.
Capability SSOT remains package STATUS.md.
EOF
  exit 1
fi

PARENT="$(cd "$1" && pwd)" || fail "parent is not a directory: $1"

echo "== pack-health: verify-pins =="
bash "$PKG_ROOT/scripts/verify-pins.sh"

echo "== pack-health: verify-project-entry =="
bash "$PKG_ROOT/scripts/verify-project-entry.sh" "$PARENT"

echo "== pack-health: test_entry_docs_sync =="
bash "$PKG_ROOT/tests/test_entry_docs_sync.sh"

echo "== pack-health: test_owner_zero_bash =="
bash "$PKG_ROOT/tests/test_owner_zero_bash.sh"

cat <<EOF
PACK_HEALTH_OK parent=$PARENT
Honesty: PACK_HEALTH_OK ≠ TIER0_OK ≠ remote CI ≠ letter B.
Capability SSOT: package STATUS.md (not this script).
EOF
