# C′ W3a Dimension Fill — P0 Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Implement W3a **P0 only** per `docs/superpowers/specs/2026-07-25-vibage-c-prime-dimension-fill-design.md` — validate+append searcher + scope verify tokens. No orchestrator, synth, or deepen migrate.

**Architecture:** `scripts/lib/dimension_fill.py` owns claim validation, DECISIONS `dimension_yes` freeze load, required classes/scope, and `tally_and_token` (consent / GRAPH_FLOOR / matrix·vacancy probes / tally). Thin bash wrappers `dimension-search.sh` and `verify-dimension-fill.sh` print one primary `DIMENSION_FILL_*` token (or append OK). Skills parse tokens; `exit 0 ≠ DIMENSION_FILL_OK`. Tests in `tests/test_dimension_fill_w3a.sh` (outside suite glob; ∉ Tier-0 / pack-health).

**Tech Stack:** bash + python3 JSON; reuse `env_discovery.SECRET_DOTENV_NAMES`; `ledger-append.sh`; existing `verify-graph-floor.sh` / `verify-env-branch-matrix.sh` / `verify-env-vacancy.sh`.

**Spec:** `docs/superpowers/specs/2026-07-25-vibage-c-prime-dimension-fill-design.md` (§5.1 searcher, §7 tokens, §9 tests, §10 P0 chunk)

**Out of P0:** `dimension-fill.sh` orchestrator, `dimension-synth-repo.sh`, deepen/`MAP_DEEPEN_OK` migrate, STATUS scrub (P1/P2).

---

### Task 1: `scripts/lib/dimension_fill.py` + search/verify wrappers

**Files:**
- Create: `scripts/lib/dimension_fill.py`
- Create: `scripts/dimension-search.sh`
- Create: `scripts/verify-dimension-fill.sh`

- [x] `DIMENSION_CLASSES`; `validate_claim`; `load_freeze`; `required_classes`; `scope_ids`; `tally_and_token`
- [x] CLI `verify <mother>` / `search <mother> <repo_id> <claim_class> <claim.json|->`
- [x] Refuse heuristic unless `VIBAGE_DIMENSION_HEURISTIC=1` (fixture/test path)
- [x] Wrappers executable; one primary token on verify

### Task 2: P0 tests + firewall

**Files:**
- Create: `tests/test_dimension_fill_w3a.sh`

- [x] Tier-0 / pack-health / suite-glob firewall
- [x] No consent → `DIMENSION_FILL_BLOCKED`
- [x] Happy path → `DIMENSION_FILL_OK tally=proven:4,failed:0`
- [x] Secret dotenv pointer → search fails; not OK
- [x] Vacancy ASK → `DIMENSION_FILL_PARTIAL`; not OK
- [x] Name outside `test_c_prime_*.sh`; print `DIMENSION_FILL_W3A_P0_OK`

### Task 3: Plan index pointer (P0 only)

**Files:**
- Create: this plan
- Modify: `docs/superpowers/plans/2026-07-25-vibage-c-prime-plan-index.md` W3a row → mention P0 plan

- [x] W3a row points at P0 plan (design remains SSOT for full wave)
