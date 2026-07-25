# Honesty Follow-up Implementation Plan (①②③)

> **For agentic workers:** Use TDD where scripts exist. Checkboxes for tracking.

**Goal:** Ship STATUS table lint, report Held-token lint, and MindOwn live Gate B locate evidence — without Tier-0 bloat; without flipping C′ / Focus / letter B Proven-green; W3a column realign may set `YES|YES|YES` from `DIMENSION_FILL_W3A_P2_OK` (scope=`script`) only.

**Architecture:** Approach 1 thin — bash/Python verify helpers + templates + one live evidence pack. Spec: `docs/superpowers/specs/2026-07-25-vibage-honesty-followup-design.md`.

**Honesty locks:** ③ is deliverable-report token lint only — does **not** replace C′ Proven-green live panel / `PRESSURE_PASS`. ② claims `GATE_B_LOCATE_OK` only — ≠ 掃透 ≠ C′ Proven flip. Slogan claims need Held **and** Token evidence fence (not Held alone).

**Tech Stack:** bash, Python 3, existing verify-report / assert_gate / graph-floor.

---

## Task 1: ① STATUS W3a fix + lint test

**Files:**
- Modify: `STATUS.md`
- Create: `tests/test_status_capability_table.sh`

- [x] **Step 1:** Fix W3a row to `YES | YES | YES | script (\`DIMENSION_FILL_W3A_P2_OK\`; P0–P2; ...)`
- [x] **Step 2:** Write failing-then-passing lint test per design §3.2; echo `STATUS_CAPABILITY_TABLE_OK`
- [x] **Step 3:** Confirm not wired into `scripts/test-tier0.sh` **or** `scripts/pack-health.sh`

## Task 2: ③ report_token_lint

**Files:**
- Create: `scripts/lib/report_token_lint.py`
- Modify: `scripts/verify-report.sh`
- Modify: `references/owner-report-template.md`, `references/locate-report-template.md`
- Modify: `skills/vibage-issue-locate/SKILL.md` (Held tokens duty)
- Modify: `skills/using-vibage/SKILL.md` (one honesty line)
- Create: `tests/test_verify_report_tokens.sh` + `tests/fixtures/report_tokens/*`

- [x] **Step 1:** Fixtures: bad_saotou, bad_scene, bad_same_line_negation (`已掃透；≠ SaaS`), ok_negation (`≠ 掃透`), ok_held+evidence fence, ok_clean; OWNER bad
- [x] **Step 2:** Implement lint (adjacent negation only; Held + Token evidence; OWNER+LOCATE)
- [x] **Step 3:** `verify-scene-cover.sh` prints `SCENE_COVER_OK`; wire lint into `verify-report.sh` before OK
- [x] **Step 4:** `VERIFY_REPORT_TOKENS_OK`; firewall ∉ tier0/pack-health; existing report fixtures still green

## Task 3: ② MindOwn Gate B live evidence

**Files:**
- Create: `docs/evidence/c-prime/GATE-B-LOCATE-<run_ts>.md` + `gate-b-locate-<run_ts>/`

- [x] **Step 1:** init-hub + graph-floor on MindOwnBuz; verify map
- [x] **Step 2:** SCAN_PLAN `scan_plan_v1` with SelfAutoBuz in root_refs/hot_path/planned_dig_ids; write_confirm; ASSERT_GATE_OK
- [x] **Step 3:** Degraded dig + dual reports (no 掃透/立體/全懂 slogans) + RUNS; verify-report **OWNER+LOCATE**
- [x] **Step 4:** Copy evidence; index NOT-claims; **assert** C′/Focus/letter B Proven columns unchanged vs `e8aa1eb`
- [x] **Step 5:** Restore parent hub/reports; do not flip those Proven columns

## Task 4: Verify / pressure

- [x] `bash tests/test_status_capability_table.sh`
- [x] `bash tests/test_verify_report_tokens.sh`
- [x] `bash scripts/test-tier0.sh` → `TIER0_OK`
- [x] Confirm Gate B evidence files present; hubs restored

## Task 5: Commit

- [x] Single or split commits: `test+fix(status)`, `feat(report-token-lint)`, `docs(c-prime): GATE-B-LOCATE evidence`
