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
owner-zero-bash + install-phrase + install-phrase-e2e + matrix durability +
install pin reporting).
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

# Matrix durability + pin ordering are script-correctness regressions, so they
# ride pack-health (matrix/freshness stay out of Tier-0 by policy).
echo "== pack-health: test_c_prime_matrix_durability =="
bash "$PKG_ROOT/tests/test_c_prime_matrix_durability.sh"

echo "== pack-health: test_install_pins_report =="
bash "$PKG_ROOT/tests/test_install_pins_report.sh"

echo "== pack-health: proven-green lock =="
bash "$PKG_ROOT/scripts/verify-proven-lock.sh" "$PKG_ROOT"

echo "== pack-health: verify-review-record =="
# SKIP allow-list (Batch 3 E3): only no_trigger_paths | git_scope_mismatch pass.
# Any other SKIP reason (and all FAIL, incl. vacuous_base / hidden_worktree) fail pack-health.
# exit 0 ≠ REVIEW_RECORD_OK.
set +e
RR_OUT="$(bash "$PKG_ROOT/scripts/verify-review-record.sh" "$PKG_ROOT" 2>&1)"
RR_EC=$?
set -e
printf '%s\n' "$RR_OUT"
# Anchored: the gate prints its token at the start of a line, while diagnostics carry
# paths and record content that can spell a token. Matching anywhere let an input decide
# the verdict — harmless for a pass, since exit 0 only happens on OK|SKIP, but enough to
# turn a real pass red.
if printf '%s\n' "$RR_OUT" | grep -Eq '^REVIEW_RECORD_FAIL([^A-Za-z0-9_]|$)'; then
  fail "verify-review-record FAIL (incl. no_git_base — not a pass)"
fi
if [[ "$RR_EC" -ne 0 ]]; then
  fail "verify-review-record exit=$RR_EC"
fi
if ! printf '%s\n' "$RR_OUT" | grep -Eq '^REVIEW_RECORD_(OK|SKIP)([^A-Za-z0-9_]|$)'; then
  fail "verify-review-record missing SKIP|OK token"
fi
if printf '%s\n' "$RR_OUT" | grep -Eq '^REVIEW_RECORD_SKIP([^A-Za-z0-9_]|$)'; then
  RR_SKIP_LINE="$(printf '%s\n' "$RR_OUT" | grep -E '^REVIEW_RECORD_SKIP([^A-Za-z0-9_]|$)' | head -1)"
  if ! printf '%s\n' "$RR_SKIP_LINE" | grep -Eq 'reason=(no_trigger_paths|git_scope_mismatch)([^A-Za-z0-9_]|$)'; then
    fail "verify-review-record SKIP reason not allow-listed: $RR_SKIP_LINE"
  fi
fi

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
REVIEW_RECORD_SKIP OK for pack-health only when reason=no_trigger_paths or
reason=git_scope_mismatch; any other SKIP reason fails. SKIP ≠ reviewed.
REVIEW_RECORD_FAIL (incl. no_git_base / vacuous_base / hidden_worktree) must fail
pack-health — not a silent pass.
exit 0 ≠ REVIEW_RECORD_OK; REVIEW_RECORD_OK ≠ review quality ≠ adversarial proof.
EOF
