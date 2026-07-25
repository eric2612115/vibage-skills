#!/usr/bin/env bash
# W4: Tier-0 thin C′ policy firewall. Not itself wired into Tier-0.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail() { echo "FAIL: $*"; exit 1; }

T0=scripts/test-tier0.sh
[[ -f "$T0" ]] || fail "missing test-tier0.sh"

# Must include thin pair
grep -Fq 'tests/test_c_prime_graph_floor.sh' "$T0" \
  || fail "Tier-0 missing test_c_prime_graph_floor.sh"
grep -Fq 'tests/test_c_prime_ledger.sh' "$T0" \
  || fail "Tier-0 missing test_c_prime_ledger.sh"

# Must NOT fat-wire
! grep -Eq 'test_c_prime_suite\.sh' "$T0" \
  || fail "Tier-0 must not run whole C′ suite"
! grep -Eq 'test_freshness|verify-freshness|FRESHNESS_' "$T0" \
  || fail "Tier-0 must not wire freshness"
! grep -Eq 'test_env_vacancy|verify-env-vacancy|ENV_VACANCY' "$T0" \
  || fail "Tier-0 must not wire env-vacancy"
! grep -Eq 'test_dimension_fill|dimension-fill|dimension_fill' "$T0" \
  || fail "Tier-0 must not wire dimension-fill"
! grep -Eq 'test_verify_map_deepen|verify-map-deepen' "$T0" \
  || fail "Tier-0 must not wire map-deepen"
! grep -Eq 'test_c_prime_fixtures|test_c_prime_scenes|test_c_prime_defi' "$T0" \
  || fail "Tier-0 must not wire fixtures/scenes/defi_pile"
! grep -Eq 'test_c_prime_matrix|env.branch.matrix|c-prime-fill' "$T0" \
  || fail "Tier-0 must not wire matrix sweep"

# Thin scripts themselves stay green
bash tests/test_c_prime_graph_floor.sh >/dev/null
bash tests/test_c_prime_ledger.sh >/dev/null

echo "TIER0_C_PRIME_THIN_OK"
