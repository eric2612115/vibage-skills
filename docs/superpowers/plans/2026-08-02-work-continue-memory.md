# Work Continue Memory Implementation Plan

> **For agentic workers:** TDD for every gate. Prefer mother-agent for thin narrative edits; cold subagents for review only. Spec: `docs/superpowers/specs/2026-08-02-work-continue-memory-design.md`. Branch: `feat/work-continue-memory` only until ship.

**Goal:** Post-locate live `WORK_CONTINUE.md` + strict verify so locate DONE cannot false-green; resume reads contract, skips continuum dig, still discloses freshness/matrix.

**Architecture:** Seed template (verify FAIL) + live contract (verify OK) + D1 skills + routing/adapters + phrase tests. No child PROGRESS. Verify ∉ Tier-0 / pack-health / `assert_gate`.

**Tech Stack:** Markdown, bash, existing skill/adapter surfaces.

**Owner locks:** A=no PROGRESS · B=4 adapters · C=verify · D1=block DONE · E=freshness/matrix + short-circuit continuum dig.

**Process:** Plan-loop outside this body. Cursor Plan UI not authoritative.

---

## File map

| Path | Responsibility |
|------|----------------|
| `references/hub/WORK_CONTINUE.md` | Seed template with placeholders; MUST-NOT; path rules |
| `scripts/install.sh` | `init_hub` seeds WORK_CONTINUE (verify must FAIL on seed) |
| `scripts/verify-work-continue.sh` | Strict live lint → `WORK_CONTINUE_VERIFY_OK` (≠ locate DONE) |
| `skills/vibage-issue-locate/SKILL.md` | D1 order (+ legacy symlink target) |
| `skills/using-vibage/SKILL.md` | Finishing + routing resume (E) |
| `references/routing-scope.md` | Continue carve-out |
| `references/hard-stops.md` | D1 + bookmark + no fabricate |
| `references/scenario-matrix.md` | S12 resume priority |
| 4 thin adapters | One-line `WORK_CONTINUE` pointer |
| `tests/test_work_continue_memory.sh` | → `WORK_CONTINUE_FIXTURE_OK` |
| `tests/fixtures/work_continue/*` | ok, missing_work_root, phase_blocked, empty_forbidden, missing_dual_reports, seed_placeholders, empty_inherited, tbd_next_step |
| `tests/test_install_manifest.sh` | Assert init-hub seeds WORK_CONTINUE |

---

### Task 1: Template + fixtures + failing phrase test

**Files:**
- Create: `references/hub/WORK_CONTINUE.md` (seed: `FILL_AFTER_LOCATE` + `phase: blocked`)
- Create: `tests/fixtures/work_continue/{ok,missing_work_root,phase_blocked,empty_forbidden,missing_dual_reports,seed_placeholders,empty_inherited,tbd_next_step}.md`
- Create: `tests/test_work_continue_memory.sh`

- [ ] **Step 1: Write failing test**

Headings required: `work_root`, `run_id`, `dual_report_uris`, `inherited_finding_ids`, `next_step`, `phase`, `side_quest`, `forbidden`, `updated_at`.  
Template must contain `FILL_AFTER_LOCATE` and MUST-NOT / hub-relative path text.  
`fail()` prints `FAIL: …`; success ends with `WORK_CONTINUE_FIXTURE_OK`. Comment: ≠ Proven-green ≠ locate DONE.

- [ ] **Step 2: Run — expect FAIL** (`exit != 0`, `FAIL:`)

```bash
bash tests/test_work_continue_memory.sh
```

- [ ] **Step 3: Add template + fixtures**

- [ ] **Step 4: Run — expect PASS** (`WORK_CONTINUE_FIXTURE_OK`)

- [ ] **Step 5: Commit** `test+docs(hub): WORK_CONTINUE seed template and fixtures`

---

### Task 2: Strict verify + install seed (C)

**Files:**
- Create: `scripts/verify-work-continue.sh`
- Modify: `scripts/install.sh`
- Modify: `tests/test_work_continue_memory.sh`
- Modify: `tests/test_install_manifest.sh`

- [ ] **Step 1: Failing tests**

Verify on fixtures (exact tokens):

| Fixture | Expected |
|---------|----------|
| ok (+ temp dual report files + existing work_root dir) | exit 0, `WORK_CONTINUE_VERIFY_OK` |
| missing_work_root | exit ≠ 0, `FAIL:` |
| phase_blocked | exit ≠ 0, `FAIL:` |
| empty_forbidden | exit ≠ 0, `FAIL:` |
| missing_dual_reports | exit ≠ 0, `FAIL:` |
| seed_placeholders / package template | exit ≠ 0, `FAIL:` |
| empty_inherited | exit ≠ 0, `FAIL:` |
| tbd_next_step | exit ≠ 0, `FAIL:` |

Verify must enforce: `inherited_finding_ids` ≥1 pipe-triple line; reject `TBD` / `TODO_*` in `next_step`/`run_id`/finding lines; `run_id` non-empty (spec §6).

Install: after `init_hub` on temp parent, hub has `WORK_CONTINUE.md` **and** verify on that hub **FAILS**.  
Assert `verify-work-continue.sh` string **absent** from `scripts/assert_gate.sh`, `scripts/test-tier0.sh`, `scripts/pack-health.sh`.

- [ ] **Step 2: Run — expect FAIL**

```bash
bash tests/test_work_continue_memory.sh
```

- [ ] **Step 3: Implement verify + install copy**

- [ ] **Step 4: Run — expect PASS**

```bash
bash tests/test_work_continue_memory.sh   # WORK_CONTINUE_FIXTURE_OK
bash tests/test_install_manifest.sh       # existing OK token(s) still pass
```

- [ ] **Step 5: Commit** `feat(verify): strict WORK_CONTINUE lint; seed fails verify`

---

### Task 3: Locate D1 + using-vibage (+ exception file)

**Files:**
- Modify: `skills/vibage-issue-locate/SKILL.md` (note: legacy `vibage-locate` install symlink → this SKILL)
- Modify: `skills/using-vibage/SKILL.md`
- Modify: `references/scenario-matrix.md` (S12)
- Modify: `tests/test_work_continue_memory.sh`
- Smoke: `tests/test_session_hooks.sh` (no hook field dump)

- [ ] **Step 1: Failing phrase asserts (add + retire)**

**Must appear:** dual → write → `verify-work-continue` → plain `locate DONE`; `WORK_CONTINUE_VERIFY_OK` ≠ locate DONE; exception only via `locate DONE (WORK_CONTINUE_EXCEPTION)`; E freshness tokens + matrix disclose.

**Must retire (tests fail if still present as sole success auth):** in `vibage-issue-locate` / `using-vibage`, wording that authorizes finishing or DONE from dual reports / `phase: done` **alone** (e.g. “After dual reports exist / phase `done`” without verify). Replace those sentences; do not leave dual-track auth.

- [ ] **Step 2: Run — expect FAIL**

- [ ] **Step 3: Edit skills + S12 — add D1 order and delete/replace sole dual⇒DONE auth**

- [ ] **Step 4: Run**

```bash
bash tests/test_work_continue_memory.sh
bash tests/test_session_hooks.sh
```

- [ ] **Step 5: Commit** `feat(skills): D1 WORK_CONTINUE blocks locate DONE`

---

### Task 4: Routing + hard-stops + 4 adapters (B, E)

**Files:**
- Modify: `references/routing-scope.md`
- Modify: `references/hard-stops.md`
- Modify: `adapters/cursor/vibage.mdc`
- Modify: `adapters/claude/CLAUDE.vibage.md`
- Modify: `adapters/shared/AGENTS.vibage.md`
- Modify: `adapters/codex/AGENTS.vibage.md`
- Modify: `tests/test_work_continue_memory.sh` (required grep ×4)

- [ ] **Step 1: Failing asserts** — carve-out; short-circuit continuum dig; freshness/matrix; hard-stops; each adapter `WORK_CONTINUE`

- [ ] **Step 2: Run — expect FAIL**

- [ ] **Step 3: Prose edits**

- [ ] **Step 4: Run**

```bash
bash tests/test_work_continue_memory.sh
bash tests/test_entry_docs_sync.sh
```

- [ ] **Step 5: Commit** `feat(routing): resume WORK_CONTINUE with freshness disclose`

---

### Task 5: Firewall (separate commands)

**Files:**
- Modify: `tests/test_work_continue_memory.sh` (negative greps: not referenced from tier0 / pack-health / assert_gate)

- [ ] **Step 1: Add failing firewall asserts** (if not already from Task 2)

- [ ] **Step 2: Run RED then GREEN for fixture test only**

```bash
bash tests/test_work_continue_memory.sh
# expect: WORK_CONTINUE_FIXTURE_OK
```

- [ ] **Step 3: Separate Tier-0 smoke (must NOT print WORK_CONTINUE_FIXTURE_OK)**

```bash
bash scripts/test-tier0.sh
# expect: TIER0_OK
# expect: stdout does NOT contain WORK_CONTINUE_FIXTURE_OK
```

- [ ] **Step 4: Commit** if needed `test(work-continue): firewall outside Tier-0 and assert_gate`

---

## Deferred (wave 2+) — mirrors spec §7

1. Child `PROGRESS.md` / `.vibage/progress.md` + must-not-override-hub tests  
2. Richer verify / stale finding lint  
3. sessionStart continue summary  
4. Ralph / stop-hook grind consuming this contract  
5. Hub migrate script for pre-existing parents  

## Done when

- Tasks 1–5 checked  
- Separately: `WORK_CONTINUE_FIXTURE_OK` from `test_work_continue_memory.sh`; `TIER0_OK` from `test-tier0.sh` (no work-continue token from tier0)  
- Fresh seed fails verify; live ok fixture passes verify  
- Plain `locate DONE` only on verified path; exception uses exact `locate DONE (WORK_CONTINUE_EXCEPTION)`  
- Sole dual-reports⇒DONE auth removed from skills  
- **Not** claimed: Proven-green / full-sweep / system-understood / locate DONE from verify token alone  
