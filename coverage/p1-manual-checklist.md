# P1 manual scenario checklist (S1–S14)

Use after scripts smoke is green. Each row is an agent-run checkbox.

## Prep

- [x] Package installed via `scripts/install.sh` (final MANIFEST)
  <!-- 2026-07-22: proven by tests/test_install_manifest.sh (MANIFEST symlinks + hub skeleton). Isolated HOME only; re-run install into real ~/.cursor after merge if needed. -->
- [x] Pins green: `scripts/verify-pins.sh`
  <!-- 2026-07-22: OK superpowers@363923f74aa9cd7b470c0aaa73dee629a8bfdc90 -->
- [ ] Fresh parent folder workspace open in Cursor

## Scenarios

- [x] **S1 Empty parent** — init+orient; SCAN_PLAN with empty/missing roots; stop at awaiting_confirm; no dig
  <!-- Mechanical only: install --init-hub on empty parent seeds root_refs=[] / planned_dig_ids=[]; assert_gate blocks dig (test_assert_gate Case A). Live orient → awaiting_confirm UX still agent-pending. -->
- [x] **S1b Repos added later** — re-orient; old CONFIRM becomes stale; assert_gate fails until re-confirm
  <!-- Mechanical: plan mutate → ASSERT_GATE_FAIL payload_hash mismatch; re-CONFIRM restores (test_assert_gate Case C, test_p1_smoke). Live re-orient after adding repos still agent-pending. -->
- [x] **S2 Many `.git` roots** — orient lists roots; CONFIRM; locate digs planned subset only (budgets)
  <!-- Mechanical: synthetic two-root parent + SCAN_PLAN planned_dig_ids=[app-a] only; write_confirm + assert_gate OK (test_p1_smoke). Live orient listing + locate dig of subset only still agent-pending. -->
- [x] **S3 Vibing single repo** — still writes light SCAN_PLAN + CONFIRM before dig
  <!-- Mechanical: single-root synthetic plan still fails assert_gate without CONFIRM; OK after write_confirm.sh. Agent still must draft the light SCAN_PLAN (not skipped). -->
- [ ] **S4 Path iron evidence** — locate delivers dual MD; survey SKIP
- [ ] **S5 Missing deploy/infra on hot path** — GapQuestion; research MUST if hot-path missing/external
- [ ] **S6 Missing Grafana/DB/…** — ask after analysis (GapQuestion), not 30-question intake
- [ ] **S7 One-line install+analyze** — stops at awaiting_confirm (does not auto-dig)
- [x] **S8 Pin fail** — verify-pins fail blocks analyzing; owner-language recovery
  <!-- Mechanical: SUPERPOWERS_ROOT=/nonexistent → verify-pins non-zero. Agent owner-language recovery + refuse analyzing still agent-pending. -->
- [ ] **S9 Design section gate** — section-gate-review runs; `go_next` is not Mode
- [ ] **S10 User skips web** — survey SKIP despite optional curiosity
- [ ] **S11 Post-CONFIRM delivery** — dual MD + RUNS + preview fail-soft + soft CTA (preview fail still DONE)
- [x] **S12 Resume** — STATUS/RUNS read; CONFIRM not wiped by re-init
  <!-- Mechanical: re-init hub preserves CONFIRM.json (test_install_manifest.sh). Live STATUS/RUNS resume conversation still agent-pending. -->
- [x] **S13 Reject/change plan** — clear/re-CONFIRM; hash mismatch blocks analyzing
  <!-- Mechanical: mutate plan → assert_gate FAIL; write_confirm restores (test_assert_gate, test_p1_smoke). -->
- [ ] **S14 Stale CONFIRM** — phase stale_confirm; re-orient/confirm
  <!-- Gate mismatch covered with S1b/S13; RunEnvelope phase=stale_confirm write still agent-pending. -->

## Mechanical gates (scripted already; re-check in agent path)

- [x] assert_gate blocks dig without CONFIRM
  <!-- tests/test_assert_gate.sh Case A; also test_p1_smoke.sh -->
- [x] Fake `Mode: full nested` / RUNS without investigators+reviewers fails verify-run
  <!-- tests/test_verify_run.sh (full_fake + verify-report fake full); tests/test_p1_smoke.sh -->
- [ ] Soft CTA never blocks local reports
  <!-- Contract in references/feature-call.md + locate preview_error fail-soft; no dedicated automated test. Needs agent-path re-check with preview fail / TBD site. -->

## Package tracker

- [ ] Root `STATUS.md` P1 capability rows set YES only when above are honestly true

## Agent-pending notes

Still need a **live Cursor agent** (fresh parent workspace) for:

| ID | Needed |
|----|--------|
| Prep | Open a fresh parent-folder workspace in Cursor (not just tmp fixtures). |
| S1 | Live `war-room-orient` stop at `awaiting_confirm` (no dig) on empty parent. |
| S1b | Add real repos after first CONFIRM; agent re-orient; human re-confirm. |
| S2 | Live orient root listing + locate dig **only** `planned_dig_ids` under budgets. |
| S3 | Agent drafts light SCAN_PLAN+CONFIRM on vibing single-repo (not skip gate). |
| S4 | Full locate dig → dual MD with path+quote iron; survey SKIP. |
| S5 | Hot-path missing/external deploy → GapQuestion + research-survey-review MUST. |
| S6 | Observability/DB gaps asked **after** analysis (GapQuestion), not intake dump. |
| S7 | One-line “install+analyze” → stop at awaiting_confirm (no auto-dig). |
| S8 | Pin fail → owner-language recovery; agent refuses `analyzing`. |
| S9 | Live section-gate-review; prove `go_next` ≠ Mode (contract text exists). |
| S10 | User “skip web” → survey SKIP. |
| S11 | Post-CONFIRM dual MD + RUNS + preview fail-soft + soft CTA; preview fail still DONE. |
| S12 | Live resume from STATUS/RUNS (CONFIRM preserve already scripted). |
| S14 | Agent sets RunEnvelope `phase: stale_confirm` then re-orient/confirm. |
| Soft CTA | Agent-path: preview fail / TBD site must not block or delete local reports. |
| Capability YES | Do **not** flip STATUS capability matrix until remaining agent rows are honest. |
