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

echo "TEST_PACK_HEALTH_OK"
