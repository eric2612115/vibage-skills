# C′ W1 Freshness — evidence index

## Claim

| Field | Value |
|-------|-------|
| Claim | **W1 freshness On-tree (HEAD+TTL subset) ≠ Sync contract DONE** |
| `run_ts` | `20260724T205853Z` |
| Script proof | `bash tests/test_freshness_w1.sh` → `FRESHNESS_W1_OK` |
| Suite firewall | ∉ `test_c_prime_*.sh` glob; `C_PRIME_SUITE_OK` unchanged |
| Tier-0 | ∉ `scripts/test-tier0.sh` / pack-health (`TIER0_OK` still green) |
| Live parents | DefiStrategy + MindOwnBuz |
| Live result | `PRESSURE_PASS` (fill → `FRESHNESS_OK` → mutate HEAD → `STALE_BLOCKS_MOTHER` + child warn) |
| Logs | `docs/evidence/c-prime/freshness-w1-20260724T205853Z/` |

## NOT claims

- ≠ Sync contract (§2.5) DONE
- ≠ letter B / Gate B / dig-ready
- ≠ full-pile 掃透
- ≠ Tier-0 membership
- ≠ dimension fill
