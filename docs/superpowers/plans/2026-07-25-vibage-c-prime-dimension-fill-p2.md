# C′ W3a Dimension Fill — P2 Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate legacy map-deepen → dimension-fill; **retire `MAP_DEEPEN_OK` brand** per W3a design §2 / §10 P2.

**Architecture:** `verify-map-deepen.sh` becomes a migrate shim: never print `MAP_DEEPEN_OK`; with `dimension_yes` consent wrap `verify-dimension-fill.sh`; else hard-fail migrate text + `DIMENSION_FILL_BLOCKED reason=deepen_retired`. Skill `vibage-map-deepen` becomes thin pointer to dimension-fill (no “system understood”). Scrub STATUS / adapters / using-vibage proof advertising. Extend tests; print `DIMENSION_FILL_W3A_P2_OK`.

**Spec:** `docs/superpowers/specs/2026-07-25-vibage-c-prime-dimension-fill-design.md`

**Prereq:** P1 On-tree (`DIMENSION_FILL_W3A_P1_OK`)

**Out of P2:** W4 Tier-0 policy; inventing searcher heuristics for production.

---

### Task 1: `verify-map-deepen.sh` migrate shim

**Files:** Modify: `scripts/verify-map-deepen.sh`

- [x] Never emit `MAP_DEEPEN_OK` on any path
- [x] If `dimension_yes` freeze present → exec `verify-dimension-fill.sh` (DIMENSION_FILL_* only)
- [x] Else hard-fail: migrate message + `DIMENSION_FILL_BLOCKED reason=deepen_retired` (exit ≠0)
- [x] Keep ∉ Tier-0 / pack-health / assert_gate

### Task 2: Skill + STATUS / adapter scrub

**Files:** Modify: `skills/vibage-map-deepen/SKILL.md`, `STATUS.md`, adapters, `skills/using-vibage/SKILL.md` (proof brand lines), README / LOCAL-COMPLETE as needed

- [x] Skill: thin pointer to dimension-fill; forbid narrating understood / dig-ready; success = DIMENSION_FILL_* not MAP_DEEPEN_OK
- [x] STATUS proof layers: retire MAP_DEEPEN_OK advertising; point optional path to DIMENSION_FILL_*
- [x] Adapters / using-vibage: MAP_DEEPEN_OK ≠ brand success (retired / ignore-as-auth only)

### Task 3: Tests

**Files:** Modify: `tests/test_verify_map_deepen.sh`; optionally extend `tests/test_dimension_fill_w3a.sh`

- [x] Legacy happy deepen path → no MAP_DEEPEN_OK; BLOCKED deepen_retired
- [x] Dimension consent wrap → DIMENSION_FILL_* (never MAP_DEEPEN_OK)
- [x] Skill greps updated for pointer + never claim MAP_DEEPEN_OK success
- [x] Firewall still holds; print `DIMENSION_FILL_W3A_P2_OK` (and keep/retire MAP_DEEPEN_TEST_OK honestly)
