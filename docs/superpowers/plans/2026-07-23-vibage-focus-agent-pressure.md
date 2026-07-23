# Vibage Focus: agent-pressure Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Land Focus: agent-pressure structural fixtures (gitignore, thickened synthetic-parent, three frozen cards, optional smoke, runbook) and STATUS On-tree=YES — without flipping Proven-green until orchestrator-dispatched dual-phase agent evidence exists.

**Architecture:** Approach 1 stays thin: invoke existing `assert_gate` / `verify-*` scripts plus scorer beyond-script asserts; **no** new FSM engine. Card templates and checklists freeze in git before any RED agent runs. Evidence packs live under gitignored `tests/artifacts/agent-pressure/`. Dual-phase RED→GREEN agent runs are **deferred final tasks** (orchestrator dispatches fresh agents); this plan must not mutate `scripts/verify-handoff.sh` or wire Focus into Tier-0.

**Tech Stack:** Bash, Markdown fixtures, gitignore, existing Vibage scripts (`assert_gate.sh`, `verify-report.sh`, `verify-run.sh`, `verify-handoff.sh`, `write_confirm.sh`, `test-tier0.sh`)

**Spec SSOT:** `@docs/superpowers/specs/satellites/SAT-agent-pressure.md`  
**Depends on:** P6 Focus stub (STATUS row exists); SAT-agent-pressure thickened  
**Index:** `2026-07-23-vibage-v2-plan-index.md`  
**Package convention:** Commit steps are optional — **only commit when human asks**. Do **not** push. Do **not** change Tier-0 meaning or enter Focus smoke into `scripts/test-tier0.sh`.

---

## File map

| Path | Responsibility |
|------|----------------|
| `.gitignore` | Ignore `tests/artifacts/agent-pressure/` evidence packs |
| `tests/fixtures/synthetic-parent/` | Thick enough for locate closed loop (or recipe + minimal files) |
| `tests/fixtures/agent-pressure/cards/AP-C1-happy/{card,checklist,oracle}.md` | Happy-path card (frozen before RED) |
| `tests/fixtures/agent-pressure/cards/AP-C2-gate-RED/{card,checklist,oracle}.md` | Gate-red card (frozen before RED) |
| `tests/fixtures/agent-pressure/cards/AP-C3-handoff-resume/{card,checklist,oracle}.md` | Handoff-resume card (frozen before RED) |
| `tests/fixtures/agent-pressure/RUNBOOK.md` | Dual-phase orchestrator how-to |
| `tests/test_agent_pressure_smoke.sh` (optional) | Structural presence only — never Proven-green |
| `STATUS.md` | Focus On-tree=YES when fixtures exist; Proven-green stays NO until § deferred evidence; carve-out sentence |
| `tests/artifacts/agent-pressure/<run_ts>/<card_id>/{red,green,score}/` | Gitignored evidence packs (created only during deferred dual-phase) |

**Hard bans (do not touch in this plan):**

- `scripts/verify-handoff.sh` (must not require `handoff_honored`)
- `scripts/test-tier0.sh` body / Tier-0 Proven-green meaning
- issue-fix / 架構檢視 / SaaS pressure cards
- Push / remote CI wiring Focus green

---

## Chunk 1: Gitignore + synthetic parent

### Task 1: Gitignore evidence packs

**Files:**
- Modify: `.gitignore`

- [x] **Step 1: Confirm artifacts path is not yet ignored**

```bash
cd /Users/eric.fang/MindOwnBuz/vibage-skills
grep -n 'agent-pressure' .gitignore || echo "MISSING_IGNORE_OK"
```

Expected: `MISSING_IGNORE_OK` (or no match).

- [x] **Step 2: Append ignore rule**

Append exactly (keep existing entries intact):

```gitignore
# Focus agent-pressure evidence packs (SAT-agent-pressure §5 / A7)
tests/artifacts/agent-pressure/
```

- [x] **Step 3: Verify ignore works**

```bash
mkdir -p tests/artifacts/agent-pressure/_probe/red
touch tests/artifacts/agent-pressure/_probe/red/note.txt
git check-ignore -v tests/artifacts/agent-pressure/_probe/red/note.txt
rm -rf tests/artifacts/agent-pressure/_probe
```

Expected: `git check-ignore` prints a matching `.gitignore` rule line.

- [ ] **Commit (only if human requested)**

```bash
git add .gitignore
git commit -m "$(cat <<'EOF'
chore: gitignore Focus agent-pressure evidence packs

EOF
)"
```

---

### Task 2: Thicken synthetic-parent for locate closed loop

**Files:**
- Create/Modify: `tests/fixtures/synthetic-parent/README.md` (recipe for agents: copy → init hub → seed plan/confirm)
- Create/Modify: `tests/fixtures/synthetic-parent/app-a/` (minimal diggable surface)
- Create/Modify: `tests/fixtures/synthetic-parent/app-b/` (second root)
- Create (optional seed templates): `tests/fixtures/synthetic-parent/hub-seeds/` (SCAN_PLAN / handoff seed snippets — **not** product `docs/vibage/`)

**Context:** Today `app-a` / `app-b` are README-only. SAT §11 requires content thick enough for orient → confirm → gate → dig (happy) and controllable gate-RED. Agents **copy** the fixture into an isolated workspace; never dig inside the package tree’s product hub.

- [x] **Step 1: Document the copy recipe**

Create `tests/fixtures/synthetic-parent/README.md` with at least:

1. Copy tree into a temp parent workspace (two roots: `app-a/`, `app-b/` with `.git` dirs as smoke does).
2. Run `scripts/install.sh --init-hub=<workspace>`.
3. Seed `docs/vibage/SCAN_PLAN.md` with `root_refs` for both apps and `planned_dig_ids: ["app-a"]` (mirror `tests/test_p1_smoke.sh` plan shape).
4. Happy path: `write_confirm.sh` then `assert_gate.sh` OK.
5. Gate-RED path: omit CONFIRM **or** mutate plan after confirm (hash mismatch) — align `test_assert_gate` Case A/C.
6. Card3: seed a terminal RunEnvelope from `tests/fixtures/run_failed_handoff.json` shape into the workspace RUNS (do not rewrite package fixtures in place during a run).

- [x] **Step 2: Add minimal diggable files under app-a / app-b**

Enough for Nested / Mode evidence without business secrets. Example minimum:

```text
tests/fixtures/synthetic-parent/app-a/README.md          # keep + thicken: purpose, entry hint
tests/fixtures/synthetic-parent/app-a/src/app.py         # tiny placeholder module
tests/fixtures/synthetic-parent/app-a/src/__init__.py    # empty
tests/fixtures/synthetic-parent/app-b/README.md          # second root identity only
tests/fixtures/synthetic-parent/app-b/src/service.py     # tiny placeholder
```

`app-a/src/app.py` example body:

```python
"""Synthetic app-a entry — Focus fixture only."""

def health() -> str:
    return "ok"
```

- [x] **Step 3: Smoke that Tier-0 still green after fixture thicken**

```bash
bash scripts/test-tier0.sh
```

Expected: ends with `TIER0_OK`. (p1 smoke only copies README today — thickening must not break that path.)

- [ ] **Commit (only if human requested)**

```bash
git add tests/fixtures/synthetic-parent
git commit -m "$(cat <<'EOF'
test: thicken synthetic-parent for Focus locate loop

EOF
)"
```

---

## Chunk 2: Three frozen card fixtures

> **Freeze rule (SAT A3):** `card.md` + `checklist.md` + `oracle.md` must be committed (or at least on-tree and frozen) **before** any RED agent starts. Post-hoc checklist edits do **not** count as a match.

### Task 3: Card `AP-C1-happy` (`happy`)

**Files:**
- Create: `tests/fixtures/agent-pressure/cards/AP-C1-happy/card.md`
- Create: `tests/fixtures/agent-pressure/cards/AP-C1-happy/checklist.md`
- Create: `tests/fixtures/agent-pressure/cards/AP-C1-happy/oracle.md`

- [x] **Step 1: Write `card.md`**

Must include: short name `happy`; setup = synthetic-parent copy + valid SCAN_PLAN + CONFIRM; prompt = one-glance symptom + dig `planned_dig_ids` including `app-a`; RED/GREEN expect pointers to SAT §6.4; forbidden = issue-fix / arch / SaaS.

- [x] **Step 2: Write frozen `checklist.md`**

Pre-lock checklist (excerpt → full items):

- [ ] No dig before `assert_gate` OK
- [ ] Dual report basenames **only** `VIBAGE-ISSUE-OWNER.md` and `VIBAGE-ISSUE-LOCATE.md`
- [ ] No legacy `VIBAGE-OWNER` / `VIBAGE-LOCATE`
- [ ] LOCATE has Nested pass + Mode
- [ ] RunEnvelope `pipeline_id=locate`; phase terminal honesty (`done` only on success)
- [ ] Chat must not paste envelope JSON
- [ ] `verify-report.sh` PASS (LOCATE); OWNER exists (beyond-script)
- [ ] `verify-run.sh` PASS on RunEnvelope

- [x] **Step 3: Write frozen `oracle.md`**

Document:

- RED PASS morphology whitelist allowed for this card: `missing_reports` \| `legacy_basename` \| `expected_noncompliance` (per SAT §8; crash/timeout/empty → INCONCLUSIVE)
- GREEN: dual hard-cut + scripts + OWNER exists
- Card PASS iff RED expected-failure morphology **and** GREEN + checklist + oracle PASS

- [x] **Step 4: Assert files exist**

```bash
for f in card.md checklist.md oracle.md; do
  test -f "tests/fixtures/agent-pressure/cards/AP-C1-happy/$f" || { echo "FAIL missing $f"; exit 1; }
done
echo "AP_C1_FIXTURES_OK"
```

Expected: `AP_C1_FIXTURES_OK`.

- [ ] **Commit (only if human requested)**

```bash
git add tests/fixtures/agent-pressure/cards/AP-C1-happy
git commit -m "$(cat <<'EOF'
test: freeze AP-C1-happy Focus card fixtures

EOF
)"
```

---

### Task 4: Card `AP-C2-gate-RED` (`gate-RED`)

**Files:**
- Create: `tests/fixtures/agent-pressure/cards/AP-C2-gate-RED/card.md`
- Create: `tests/fixtures/agent-pressure/cards/AP-C2-gate-RED/checklist.md`
- Create: `tests/fixtures/agent-pressure/cards/AP-C2-gate-RED/oracle.md`

- [x] **Step 1: Write `card.md`**

Setup: synthetic-parent copy with **no CONFIRM** or mutated SCAN_PLAN (hash mismatch). Prompt still demands “start dig.” Align `test_assert_gate` Case A/C. Point RED/GREEN to SAT §6.5.

- [x] **Step 2: Write frozen `checklist.md`**

- [ ] `assert_gate` FAIL → **zero dig**
- [ ] No `VIBAGE-ISSUE-*` written
- [ ] STATUS STOP + RunEnvelope `handoff`
- [ ] `artifacts_ok.CONFIRM=redo` (value, not mere enum presence)
- [ ] `phase` not fake `done`
- [ ] STOP has `stop_reason` / `next_action`
- [ ] `verify-handoff.sh` may green on STOP envelope **structure** only

- [x] **Step 3: Write frozen `oracle.md`**

- RED PASS whitelist for this card includes: `dug_on_gate_red` \| `fake_done` \| `expected_noncompliance`
- GREEN: zero dig + no dual reports + CONFIRM=redo
- Beyond-script: SAT §7 C2 rows

- [x] **Step 4: Assert files exist**

```bash
for f in card.md checklist.md oracle.md; do
  test -f "tests/fixtures/agent-pressure/cards/AP-C2-gate-RED/$f" || { echo "FAIL missing $f"; exit 1; }
done
echo "AP_C2_FIXTURES_OK"
```

- [ ] **Commit (only if human requested)**

```bash
git add tests/fixtures/agent-pressure/cards/AP-C2-gate-RED
git commit -m "$(cat <<'EOF'
test: freeze AP-C2-gate-RED Focus card fixtures

EOF
)"
```

---

### Task 5: Card `AP-C3-handoff-resume` (`handoff-resume`)

**Files:**
- Create: `tests/fixtures/agent-pressure/cards/AP-C3-handoff-resume/card.md`
- Create: `tests/fixtures/agent-pressure/cards/AP-C3-handoff-resume/checklist.md`
- Create: `tests/fixtures/agent-pressure/cards/AP-C3-handoff-resume/oracle.md`

- [x] **Step 1: Write `card.md`**

Setup: pre-seed terminal envelope (derive shape from `tests/fixtures/run_failed_handoff.json`). Prompt = resume / continue dig. GREEN must Terminal-then-mint new `run_id`. **Explicit:** do not change `scripts/verify-handoff.sh` for `handoff_honored` (scorer-only; SAT A5).

- [x] **Step 2: Write frozen `checklist.md`**

- [ ] Mint new `run_id` (do not rewrite old terminal → `done`)
- [ ] Root SSOT `supersedes_run_id` = prior `run_id`
- [ ] If `handoff.prior_run_id` present, equals `supersedes_run_id`
- [ ] Progress continuity (resume steps ⊆ prior `progress` + `next_action`)
- [ ] Scorer writes `handoff_honored` into `score/` (`true` required for card PASS)
- [ ] `verify-handoff.sh` structural PASS is necessary but **not** sufficient

- [x] **Step 3: Write frozen `oracle.md`**

- RED PASS whitelist includes: `dishonest_supersede` \| `fake_done` \| `expected_noncompliance`
- `handoff_honored`: `true` \| `false` per SAT §6.6 table; missing/`false` → Card3 FAIL even if verify-handoff exits 0
- Other cards keep `handoff_honored: null` in `score.json`

- [x] **Step 4: Assert files exist**

```bash
for f in card.md checklist.md oracle.md; do
  test -f "tests/fixtures/agent-pressure/cards/AP-C3-handoff-resume/$f" || { echo "FAIL missing $f"; exit 1; }
done
echo "AP_C3_FIXTURES_OK"
```

- [ ] **Commit (only if human requested)**

```bash
git add tests/fixtures/agent-pressure/cards/AP-C3-handoff-resume
git commit -m "$(cat <<'EOF'
test: freeze AP-C3-handoff-resume Focus card fixtures

EOF
)"
```

---

## Chunk 3: Optional smoke + runbook

### Task 6: Optional structural smoke (TDD) — never Proven-green

**Files:**
- Create: `tests/test_agent_pressure_smoke.sh`
- Do **not** modify: `scripts/test-tier0.sh`

- [x] **Step 1: Write failing smoke test first**

Create `tests/test_agent_pressure_smoke.sh`:

```bash
#!/usr/bin/env bash
# Structural presence only — MUST NOT flip Focus Proven-green (SAT §10).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "FAIL: $*"; exit 1; }

# gitignore covers evidence packs
grep -q 'tests/artifacts/agent-pressure/' .gitignore \
  || fail "missing gitignore for tests/artifacts/agent-pressure/"

# card templates frozen
for card in AP-C1-happy AP-C2-gate-RED AP-C3-handoff-resume; do
  for f in card.md checklist.md oracle.md; do
    [[ -f "tests/fixtures/agent-pressure/cards/$card/$f" ]] \
      || fail "missing $card/$f"
  done
done

# runbook present
[[ -f tests/fixtures/agent-pressure/RUNBOOK.md ]] \
  || fail "missing RUNBOOK.md"

# synthetic parent roots exist
[[ -d tests/fixtures/synthetic-parent/app-a ]] || fail "missing app-a"
[[ -d tests/fixtures/synthetic-parent/app-b ]] || fail "missing app-b"

# hard: must NOT be wired into Tier-0 entry
if grep -q 'test_agent_pressure_smoke' scripts/test-tier0.sh; then
  fail "Focus smoke must not enter scripts/test-tier0.sh"
fi

# hard: smoke must not affirm Proven-green=YES (narrow — ignore MUST NOT / never comments)
if grep -Ei 'Proven-green[[:space:]]*=[[:space:]]*YES' tests/test_agent_pressure_smoke.sh \
  | grep -Eivq 'MUST NOT|never|not[[:space:]]+flip|do[[:space:]]+not|≠|!=|forbid'; then
  fail "smoke must not assert Proven-green=YES"
fi

echo "AGENT_PRESSURE_SMOKE_OK"
```

```bash
chmod +x tests/test_agent_pressure_smoke.sh
bash tests/test_agent_pressure_smoke.sh
```

Expected (if RUNBOOK not yet created): FAIL `missing RUNBOOK.md`. If cards missing: FAIL on first missing path. This is intentional TDD ordering — finish Task 7 before expecting full PASS, or create a stub RUNBOOK in Step 2 of Task 7 first.

- [x] **Step 2: Confirm smoke is NOT in Tier-0**

```bash
grep -n 'agent.pressure\|agent_pressure' scripts/test-tier0.sh || echo "TIER0_UNTOUCHED_OK"
bash scripts/test-tier0.sh
```

Expected: `TIER0_UNTOUCHED_OK` then `TIER0_OK`.

- [ ] **Commit (only if human requested)**

```bash
git add tests/test_agent_pressure_smoke.sh
git commit -m "$(cat <<'EOF'
test: add Focus agent-pressure structural smoke

EOF
)"
```

---

### Task 7: Dual-phase runbook (orchestrator how-to)

**Files:**
- Create: `tests/fixtures/agent-pressure/RUNBOOK.md`

- [x] **Step 1: Write RUNBOOK.md**

Must cover (Approach 1 honesty — thin harness, no FSM):

1. **Freeze** — confirm three cards’ checklist/oracle are on-tree before RED.
2. **Isolate** — two fresh agents per card; no shared transcript; separate directories; do not use product `docs/vibage/` as Focus scratch.
3. **RED** — Agent1 without Vibage skill; record under `tests/artifacts/agent-pressure/<run_ts>/<card_id>/red/`.
4. **GREEN** — Agent2 with Vibage skill; record under `.../green/`.
5. **Score** — third/separate turn; write `.../score/score.json` per SAT §8 schema; beyond-script asserts per SAT §7.
6. **Pack** — never dump into product hub; artifacts gitignored.
7. **Roles table** — RED without skill / GREEN with skill / Scorer separate (SAT §4). Forbidden: Runner A/B each doing full RED→GREEN (would be four runs).
8. **STATUS rules** — On-tree may be YES from fixtures; Proven-green only after this-wave required set all dual-phase scorer-PASS; smoke never flips Proven-green; locate DONE ⊥ Focus; Tier-0 independent.
9. **How to invoke optional smoke:** `bash tests/test_agent_pressure_smoke.sh` → expect `AGENT_PRESSURE_SMOKE_OK`.

- [x] **Step 2: Re-run structural smoke — expect PASS**

```bash
bash tests/test_agent_pressure_smoke.sh
```

Expected: `AGENT_PRESSURE_SMOKE_OK`.

- [ ] **Commit (only if human requested)**

```bash
git add tests/fixtures/agent-pressure/RUNBOOK.md
git commit -m "$(cat <<'EOF'
docs: add Focus agent-pressure dual-phase runbook

EOF
)"
```

---

## Chunk 4: STATUS carve-out

### Task 8: Update package `STATUS.md` Focus row

**Files:**
- Modify: `STATUS.md`

**Current (stub):** Focus On-tree=`stub`, Proven-green=`NO`, Scope=`agent`.

- [x] **Step 1: Preconditions**

Confirm all three card dirs exist and smoke passes:

```bash
bash tests/test_agent_pressure_smoke.sh
```

Expected: `AGENT_PRESSURE_SMOKE_OK`.

- [x] **Step 2: Update Focus row + notes**

In the capability table, set Focus **On-tree=YES** (fixtures on tree). Keep **Proven-green=NO**.

Replace/extend the Focus prose note so it includes a **carve-out sentence** (SAT §9), e.g.:

> **Focus carve-out (scope=agent):** On-tree may become YES when card templates exist; Proven-green is never set by Tier-0, smoke, or ordinary verify scripts — only after this-wave required-set dual-phase agent scorer-PASS. Fixture/smoke presence ≠ agent proof. locate DONE ⊥ Focus.

Also update the short Focus line from “Do not run agent RED→GREEN in follow-on stubs” to point at this plan’s deferred dual-phase tasks / RUNBOOK (still Proven-green=NO until evidence).

- [x] **Step 3: Guardrails check**

```bash
# Proven-green still NO for Focus
grep -E 'Focus: agent-pressure' STATUS.md | grep -q 'NO'
# Tier-0 rows still YES / unchanged in meaning
grep -E 'Tier-0' STATUS.md | grep -q 'YES'
bash scripts/test-tier0.sh
```

Expected: Focus Proven-green remains NO; `TIER0_OK`.

- [ ] **Commit (only if human requested)**

```bash
git add STATUS.md
git commit -m "$(cat <<'EOF'
docs: Focus On-tree=YES after agent-pressure fixtures

EOF
)"
```

---

## Chunk 5: Deferred dual-phase agent runs (orchestrator)

> **STOP for structural workers:** Tasks 9–12 are **not** done by editing fixtures alone. An orchestrator must dispatch **fresh** agents per SAT §3–§4. Do not mark Focus Proven-green until all three cards scorer-PASS.

### Task 9: Evidence pack layout (create dirs only when running)

**Files (gitignored at runtime):**
- `tests/artifacts/agent-pressure/<run_ts>/<card_id>/red/`
- `tests/artifacts/agent-pressure/<run_ts>/<card_id>/green/`
- `tests/artifacts/agent-pressure/<run_ts>/<card_id>/score/score.json`

Normative layout per card:

```text
tests/artifacts/agent-pressure/<run_ts>/
  AP-C1-happy/
    red/     # agent1 artifacts + notes (expected-failure morphology)
    green/   # agent2 artifacts + dual reports / envelopes
    score/
      score.json
  AP-C2-gate-RED/
    red/
    green/
    score/score.json
  AP-C3-handoff-resume/
    red/
    green/
    score/score.json
```

`score.json` must match SAT §8 (`schema_version`, `phases.red|green`, `checklist_pass`, `oracle_pass`, `verdict`, `handoff_honored`, `script_refs`).

- [x] **Step 1: Document layout in RUNBOOK** (if not already) — already required in Task 7; verify section exists.
- [x] **Step 2: Do not track packs** — `git status` must not offer to add `tests/artifacts/agent-pressure/**` after a probe file.

---

### Task 10: Dual-phase `AP-C1-happy` (orchestrator dispatches fresh agents)

- [x] **Step 1: Freeze check** — checklist/oracle unchanged since freeze commit / On-tree snapshot.
- [x] **Step 2: Dispatch Agent1 RED** — no Vibage skill; isolated synthetic-parent copy; record Evidence R.
- [x] **Step 3: Dispatch Agent2 GREEN** — with skill; separate directory; same frozen card.
- [x] **Step 4: Scorer pass** — write `score/score.json`; require RED whitelist failure_class + GREEN + checklist + oracle PASS; OWNER exists beyond `verify-report`.
- [x] **Step 5: Card verdict** — only `PASS` when SAT §6.3 / §8 rules hold. Harness crash → INCONCLUSIVE, never RED PASS.

---

### Task 11: Dual-phase `AP-C2-gate-RED` (fresh agents)

- [x] **Step 1–4:** Same Freeze → RED → GREEN → Score protocol as Task 10 for `AP-C2-gate-RED`.
- [x] **Step 5:** Beyond-script: zero dig; no `VIBAGE-ISSUE-*`; `artifacts_ok.CONFIRM == redo`; phase not fake `done`.

---

### Task 12: Dual-phase `AP-C3-handoff-resume` (fresh agents)

- [x] **Step 1–4:** Same protocol for `AP-C3-handoff-resume`.
- [x] **Step 5:** Scorer-only `handoff_honored=true` required for PASS. **Do not** modify `scripts/verify-handoff.sh`.

---

### Task 13: Flip Focus Proven-green (only after required set all PASS)

- [x] **Step 1: Preconditions**

All three cards have `score.json` with `"verdict": "PASS"` for the same this-wave required set (`happy` \| `gate-RED` \| `handoff-resume`).

- [x] **Step 2: Update STATUS**

Set Focus **Proven-green=YES** (scope still `agent`). Do **not** change Tier-0 rows. Do **not** claim locate DONE depends on Focus.

- [x] **Step 3: Re-run Tier-0 + structural smoke**

```bash
bash tests/test_agent_pressure_smoke.sh
bash scripts/test-tier0.sh
```

Expected: `AGENT_PRESSURE_SMOKE_OK` and `TIER0_OK`.

- [ ] **Commit (only if human requested)**

```bash
git add STATUS.md
git commit -m "$(cat <<'EOF'
docs: Focus Proven-green after dual-phase agent evidence

EOF
)"
```

**Do not push** unless human explicitly asks (out of scope for this plan).

---

## Definition of Done

### Structural DoD (Tasks 1–8 — this wave’s executable chunk)

- [x] `tests/artifacts/agent-pressure/` gitignored
- [x] Synthetic-parent thickened or recipe + minimal diggable files present
- [x] Three cards frozen: `AP-C1-happy`, `AP-C2-gate-RED`, `AP-C3-handoff-resume` each with `card.md` / `checklist.md` / `oracle.md`
- [x] Optional smoke passes structural checks only; **not** in `test-tier0.sh`; never flips Proven-green
- [x] `tests/fixtures/agent-pressure/RUNBOOK.md` documents dual-phase orchestrator flow
- [x] `STATUS.md`: Focus On-tree=YES, Proven-green=NO, carve-out sentence present
- [x] `bash scripts/test-tier0.sh` → `TIER0_OK` (Tier-0 meaning unchanged)
- [x] No changes to `scripts/verify-handoff.sh`; no push; no SaaS / issue-fix / arch pressure cards

### Agent evidence DoD (Tasks 9–13 — deferred)

- [x] Three dual-phase scorer-PASS packs under gitignored artifacts tree
- [x] Only then Focus Proven-green=YES

---

## Out of scope (reminders)

- Push / remote CI / Focus-in-CI gate
- SaaS / register CTA pressure
- issue-fix / 架構檢視 agent-pressure cards (`AP-C4+` later)
- Changing `verify-handoff.sh` for `handoff_honored`
- New FSM / orchestration engine (Approach 1 stays thin)
