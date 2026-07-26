# C′ Wave-4 — Tier-0 Thin Subset Policy

**Date:** 2026-07-25  
**Status:** Policy-LOCKED for implement  
**Roadmap:** `docs/superpowers/specs/2026-07-25-vibage-c-prime-next-waves-roadmap.md`  
**Prereq:** W3a On-tree (`DIMENSION_FILL_W3A_P2_OK`)

## Decision (YES)

Wire a **thin C′ subset** into `scripts/test-tier0.sh` so ship-gate fails if floor or ledger honesty regresses:

| Include in Tier-0 | Script |
|-------------------|--------|
| Graph floor | `tests/test_c_prime_graph_floor.sh` |
| Ledger + rollup (no matrix required) | `tests/test_c_prime_ledger.sh` |

## Explicit excludes (MUST NOT enter Tier-0)

- Whole `tests/test_c_prime_suite.sh` / suite glob orchestration  
- Freshness (`test_freshness_w1.sh`, `verify-freshness.sh`)  
- Env-vacancy / matrix / scenes / fixtures / defi_pile  
- Dimension-fill / map-deepen migrate tests  
- Pack-health (remains separate)

## Honesty

- Thin Tier-0 C′ ≠ C′ Proven-green ≠ letter B ≠ Gate B ≠ full-sweep  
- `TIER0_OK` with thin C′ still ≠ Sync contract DONE ≠ dimension understood  
- W1–W3 scripts remain out of Tier-0 required path except the two named tests above  

## Exit token

After green Tier-0 + firewall test: `TIER0_C_PRIME_THIN_OK` from `tests/test_tier0_c_prime_thin.sh`.
