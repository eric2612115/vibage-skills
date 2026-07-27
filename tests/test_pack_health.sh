#!/usr/bin/env bash
# MUST NOT be wired into scripts/test-tier0.sh.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "FAIL: $*"; exit 1; }

if grep -q 'pack-health\|test_pack_health' scripts/test-tier0.sh; then
  fail "pack-health must not enter scripts/test-tier0.sh"
fi

[[ -x scripts/pack-health.sh ]] || fail "pack-health.sh not executable"

if bash scripts/pack-health.sh >/tmp/ph-noarg.out 2>/tmp/ph-noarg.err; then
  fail "pack-health with no args must fail"
fi
grep -Eiq 'parent workspace|PACK_HEALTH_OK ≠|TIER0' /tmp/ph-noarg.err \
  || fail "no-arg fail must mention parent / honesty"

FIX="$(mktemp -d)"
trap 'rm -rf "$FIX"' EXIT
bash scripts/install.sh --with-project-rule="$FIX" >/dev/null
bash scripts/pack-health.sh "$FIX" | tee /tmp/ph-ok.out
grep -Fq 'PACK_HEALTH_OK' /tmp/ph-ok.out || fail "expected PACK_HEALTH_OK"
grep -Fq '≠ TIER0_OK' /tmp/ph-ok.out || fail "expected honesty banner"

# Batch 3 E3: pack-health SKIP allow-list (consumer contract)
grep -Fq 'reason=(no_trigger_paths|git_scope_mismatch)' scripts/pack-health.sh \
  || fail "pack-health must allow-list SKIP reasons"
# Synthetic stdout through the same anchored rules pack-health uses
simulate_ph_skip() {
  local out="$1"
  if printf '%s\n' "$out" | grep -Eq '^REVIEW_RECORD_SKIP([^A-Za-z0-9_]|$)'; then
    local line
    line="$(printf '%s\n' "$out" | grep -E '^REVIEW_RECORD_SKIP([^A-Za-z0-9_]|$)' | head -1)"
    if ! printf '%s\n' "$line" | grep -Eq 'reason=(no_trigger_paths|git_scope_mismatch)([^A-Za-z0-9_]|$)'; then
      return 1
    fi
  fi
  return 0
}
simulate_ph_skip $'review_record_mode=none\nREVIEW_RECORD_SKIP reason=no_trigger_paths\n' \
  || fail "E3 simulate: no_trigger_paths must pass"
simulate_ph_skip $'REVIEW_RECORD_SKIP reason=git_scope_mismatch\n' \
  || fail "E3 simulate: git_scope_mismatch must pass"
simulate_ph_skip $'REVIEW_RECORD_SKIP reason=synthetic\n' \
  && fail "E3 simulate: unknown SKIP reason must fail"

echo "TEST_PACK_HEALTH_OK"
