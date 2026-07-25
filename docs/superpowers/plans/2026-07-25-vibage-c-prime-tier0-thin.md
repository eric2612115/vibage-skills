# C′ W4 Tier-0 Thin Subset — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement W4 policy — ship-gate includes graph_floor + ledger only.

**Spec:** `docs/superpowers/specs/2026-07-25-vibage-c-prime-tier0-thin-policy.md`

---

### Task 1: Wire thin tests into `test-tier0.sh`

**Files:** Modify: `scripts/test-tier0.sh`

- [x] Run `tests/test_c_prime_graph_floor.sh` before `TIER0_OK`
- [x] Run `tests/test_c_prime_ledger.sh` before `TIER0_OK`
- [x] Do **not** invoke `test_c_prime_suite.sh` or freshness/vacancy/dimension tests

### Task 2: Firewall test + STATUS

**Files:** Create: `tests/test_tier0_c_prime_thin.sh`; Modify: `STATUS.md`, plan-index, roadmap note

- [x] Assert Tier-0 contains the two thin scripts
- [x] Assert Tier-0 does **not** contain suite / freshness / vacancy / dimension / defi_pile / fixtures / scenes
- [x] Print `TIER0_C_PRIME_THIN_OK`
- [x] STATUS + plan-index mark W4 On-tree
