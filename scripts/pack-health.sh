#!/usr/bin/env bash
# Composite pack proof — NOT capability SSOT, NOT Tier-0.
# Remote CI runs this via a separate job (tests/test_pack_health.sh); that job
# is still ≠ TIER0_OK (own check-run name: pack-health).
# Usage: bash scripts/pack-health.sh /path/to/parent-workspace
set -euo pipefail
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PKG_ROOT"

fail() { echo "FAIL: $*" >&2; exit 1; }

if [[ $# -lt 1 || -z "${1:-}" ]]; then
  cat >&2 <<EOF
FAIL: parent workspace path required.

Usage: $0 /path/to/parent-workspace

This is a composite check (pins + parent entry + entry-docs +
owner-zero-bash + install-phrase + install-phrase-e2e).
PACK_HEALTH_OK ≠ TIER0_OK ≠ letter B.
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

echo "== pack-health: test_install_phrase =="
bash "$PKG_ROOT/tests/test_install_phrase.sh"

echo "== pack-health: test_install_phrase_e2e =="
bash "$PKG_ROOT/tests/test_install_phrase_e2e.sh"

echo "== pack-health: test_plugin_manifests =="
bash "$PKG_ROOT/tests/test_plugin_manifests.sh"

echo "== pack-health: test_pile_index =="
bash "$PKG_ROOT/tests/test_pile_index.sh"

echo "== pack-health: proven-green lock =="
bash "$PKG_ROOT/scripts/verify-proven-lock.sh" "$PKG_ROOT"

cat <<EOF
PACK_HEALTH_OK parent=$PARENT
Honesty: PACK_HEALTH_OK ≠ TIER0_OK ≠ letter B.
Capability SSOT: package STATUS.md (not this script).
CI: separate job pack-health may mirror tests/test_pack_health.sh; still ≠ TIER0_OK.
PROVEN_LOCK_OK = parsed capability rows match the last signature + every YES names
an in-package path that exists. It is ≠ "the evidence supports the claim"
≠ "the claims are true" ≠ letter B ≠ live-panel re-run. Scope caveat prose is
outside the signature by design.
Plugin manifests on-tree ≠ Cursor/Claude store listing approved.
PILE_INDEX_OK ≠ DIMENSION_FILL_OK ≠ Architecture Pass ≠ locate DONE.
MAP_DEEPEN_OK brand retired (W3a); dimension-fill optional and not part of this pack-health gate.
EOF
