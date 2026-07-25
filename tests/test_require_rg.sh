#!/usr/bin/env bash
# Fail-closed ripgrep wiring. ∉ Tier-0 / pack-health.
# Presence check ≠ slogan semantic coverage; ≠ C′ Proven flip.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "FAIL: $*"; exit 1; }
pass() { echo "PASS: $*"; }

if grep -qE 'test_require_rg' scripts/test-tier0.sh 2>/dev/null; then
  fail "must not wire into test-tier0.sh"
fi
if grep -qE 'test_require_rg' scripts/pack-health.sh 2>/dev/null; then
  fail "must not wire into pack-health.sh"
fi

grep -Eq '^ripgrep=required[[:space:]]*$' DEPENDENCIES.md \
  || fail "DEPENDENCIES.md must declare ripgrep=required"

# Every test that invokes rg must source require_rg (fail-closed).
# Note: avoid `mapfile` (macOS /bin/bash 3.2).
count=0
while IFS= read -r f; do
  [[ -n "$f" ]] || continue
  count=$((count + 1))
  if [[ "$(basename "$f")" == "test_require_rg.sh" ]]; then
    continue
  fi
  grep -Fq 'scripts/lib/require_rg.sh' "$f" \
    || fail "$f calls rg but does not source require_rg.sh"
done < <(grep -lE '(^|[[:space:]])rg( |$)' tests/*.sh | sort -u)
[[ "$count" -ge 7 ]] || fail "expected ≥7 rg-using tests, got $count"
pass "rg-using tests source require_rg"

# Missing rg → exit 1 (not silent pass).
set +e
out="$(
  env -i PATH="/nonexistent" HOME="$HOME" /bin/bash -c \
    'source "'"$ROOT"'/scripts/lib/require_rg.sh"; echo UNREACHABLE' \
    2>&1
)"
rc=$?
set -e
[[ "$rc" -ne 0 ]] || fail "require_rg must fail when rg absent; got rc=0 out=$out"
echo "$out" | grep -Fq 'ripgrep' || fail "require_rg stderr must name ripgrep; got: $out"
pass "require_rg fail-closed without rg"

# verify-pins must refuse missing rg (and declare pin line).
grep -Fq 'ripgrep' scripts/verify-pins.sh || fail "verify-pins.sh must check ripgrep"
pass "verify-pins mentions ripgrep"

echo "REQUIRE_RG_OK"
