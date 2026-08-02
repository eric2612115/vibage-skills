# Work Continue Memory Implementation Plan

> **For agentic workers:** TDD for every gate. Prefer mother-agent for thin narrative edits; cold subagents for review only. Spec: `docs/superpowers/specs/2026-08-02-work-continue-memory-design.md`. Branch: `feat/work-continue-memory` only until ship. Open plan todos are **not** main SSOT.

**Goal:** Post-locate hub `WORK_CONTINUE.md` + verify gate so locate DONE cannot false-green; resume reads contract, skips continuum dig, still discloses freshness/matrix.

**Architecture:** Template + install seed + verify script + locate D1 finishing + routing/adapters/hard-stops + phrase tests outside Tier-0. No child PROGRESS (Deferred).

**Tech Stack:** Markdown, bash verify/tests, existing skill/adapter surfaces.

**Owner locks:** A=no child PROGRESS · B=4 adapters · C=verify script · D1=block DONE · E=freshness/matrix disclose + short-circuit continuum dig.

**Process:** Plan-loop reviews recorded outside this body. Cursor Plan UI is not authoritative.

---

## File map

| Path | Responsibility |
|------|----------------|
| `references/hub/WORK_CONTINUE.md` | Template + MUST-NOT + field docs + path resolution |
| `scripts/install.sh` | `init_hub` seeds WORK_CONTINUE |
| `scripts/verify-work-continue.sh` | Light deliverable lint → `WORK_CONTINUE_VERIFY_OK` |
| `skills/vibage-issue-locate/SKILL.md` | D1 order; resume; write+verify before DONE |
| `skills/using-vibage/SKILL.md` | Finishing + routing resume (E) + S08 carve-out |
| `references/routing-scope.md` | Continue carve-out + gold example |
| `references/hard-stops.md` | Anti pretend-no-memory; anti side-quest without bookmark; D1 |
| `references/scenario-matrix.md` | S12 resume priority |
| 4 thin adapters | One-line WORK_CONTINUE pointer |
| `tests/test_work_continue_memory.sh` | Phrase/fixture → `WORK_CONTINUE_FIXTURE_OK` |
| `tests/fixtures/work_continue/*` | ok / missing field / blocked path samples |

**Deferred (not in tasks):** `PROGRESS.child.md`, sessionStart continue dump, migrate script, Tier-0 wire.

---

### Task 1: Template + fixtures + failing phrase test

**Files:**
- Create: `references/hub/WORK_CONTINUE.md`
- Create: `tests/fixtures/work_continue/ok.md`
- Create: `tests/fixtures/work_continue/missing_work_root.md`
- Create: `tests/test_work_continue_memory.sh`

- [ ] **Step 1: Write failing test**

Require template headings: `work_root`, `run_id`, `dual_report_uris`, `inherited_finding_ids`, `next_step`, `phase`, `side_quest`, `forbidden`, `updated_at`.  
Require MUST-NOT / path-resolution phrases.  
`check_required_fields file` → ok.md pass; missing_work_root.md fail with `FAIL:`.  
Success echo: `WORK_CONTINUE_FIXTURE_OK`. Comment: phrase gate ≠ Proven-green.

- [ ] **Step 2: Run — expect FAIL** (`exit != 0`, stdout contains `FAIL:`)

```bash
bash tests/test_work_continue_memory.sh
```

- [ ] **Step 3: Add template + fixtures**

- [ ] **Step 4: Run — expect PASS** (`WORK_CONTINUE_FIXTURE_OK`)

- [ ] **Step 5: Commit** `test+docs(hub): WORK_CONTINUE template and fixture gate`

---

### Task 2: verify script + install seed (C)

**Files:**
- Create: `scripts/verify-work-continue.sh`
- Modify: `scripts/install.sh` (`init_hub` copy WORK_CONTINUE)
- Modify: `tests/test_work_continue_memory.sh`
- Modify: init-hub / install manifest test if present (`tests/test_install_manifest.sh` or equivalent — grep first)

- [ ] **Step 1: Failing tests** — verify rejects missing_work_root; accepts ok when paths exist or phase blocked; install/init-hub must produce hub file; success tokens `WORK_CONTINUE_VERIFY_OK` / fixture OK

- [ ] **Step 2: Run — expect FAIL**

- [ ] **Step 3: Implement verify + install copy**

- [ ] **Step 4: Run — expect PASS**

- [ ] **Step 5: Commit** `feat(verify): WORK_CONTINUE lint and init-hub seed`

---

### Task 3: Locate D1 + using-vibage finishing/resume

**Files:**
- Modify: `skills/vibage-issue-locate/SKILL.md`
- Modify: `skills/using-vibage/SKILL.md` (Finishing + Routing + session-start carve-out)
- Modify: `references/scenario-matrix.md` (S12)
- Modify: `tests/test_work_continue_memory.sh`
- Smoke only: `tests/test_session_hooks.sh` (do **not** extend hook to field-level WORK_CONTINUE)

- [ ] **Step 1: Failing phrase asserts** — D1 order; `verify-work-continue`; cannot claim DONE without verify; resume read-before-edit; E freshness/matrix still required

- [ ] **Step 2: Run — expect FAIL**

- [ ] **Step 3: Minimal skill + S12 edits**

- [ ] **Step 4: Run** `test_work_continue_memory.sh` + `test_session_hooks.sh` — expect PASS / no regress

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
- Modify: `tests/test_work_continue_memory.sh` (**required** grep on 4 adapters)
- Optionally extend: `tests/test_entry_docs_sync.sh` if needed for sync

- [ ] **Step 1: Failing asserts** — continue carve-out; short-circuit continuum dig; freshness/matrix disclose; hard-stops D1 + side_quest bookmark; each adapter mentions `WORK_CONTINUE`

- [ ] **Step 2: Run — expect FAIL**

- [ ] **Step 3: Prose edits** (one standard sentence for adapters)

- [ ] **Step 4: Run** fixture test + `test_entry_docs_sync.sh`

- [ ] **Step 5: Commit** `feat(routing): resume WORK_CONTINUE with freshness disclose`

---

### Task 5: Firewall

**Files:**
- Modify: `tests/test_work_continue_memory.sh` (assert not in `scripts/test-tier0.sh` / pack-health)

- [ ] **Step 1–2:** Assert firewall; run `bash scripts/test-tier0.sh` → `TIER0_OK` + `WORK_CONTINUE_FIXTURE_OK`

- [ ] **Step 3: Commit** if needed `test(work-continue): keep gates outside Tier-0`

---

## Deferred (wave 2+)

- Child PROGRESS template + tests (owner lock A)  
- sessionStart continue summary  
- Hub migrate script  
- Richer verify schema  

## Done when

- All tasks checked; `WORK_CONTINUE_FIXTURE_OK` + `WORK_CONTINUE_VERIFY_OK` + `TIER0_OK`  
- Owner resume works without pile-index; DONE blocked without verify (D1)  
- Impl narrative changes have looping-review records (outside this plan)  
- **Not** claimed: Proven-green / full-sweep / system-understood  
