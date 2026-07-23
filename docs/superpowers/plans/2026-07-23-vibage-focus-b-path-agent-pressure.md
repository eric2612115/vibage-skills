# Vibage Focus: letter B agent-proven via B-path set (AP-C4 / AP-C5) Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Append Focus agent-pressure cards `AP-C4-issue-fix` and `AP-C5-service-map` under set claim id **`B-path agent-proven set`**, run dual-PHASE RED→GREEN+scorer, and only then claim public STATUS **`letter B agent-proven`** — without renaming or re-flipping Focus locate Proven-green.

**Architecture:** Approach 1 thin harness — reuse `SAT-agent-pressure` Freeze→Isolate→RED→GREEN→Score→Pack. **Append-only** library (`AP-C4+`). No new FSM. Card templates freeze in git before RED. Evidence under gitignored `tests/artifacts/agent-pressure/`. Verify tracks stay split: C4 → `verify-issue-fix-unlock.sh` (not `verify-handoff.sh`); C5 → `verify-service-map.sh` with Plan M `depth:"standard"` + valid `edges`.

**Tech Stack:** Bash, Markdown fixtures, existing Vibage scripts, Focus scorer/`score.json` contract from SAT-agent-pressure

**Spec SSOT:** `@docs/superpowers/specs/satellites/SAT-agent-pressure.md`  
**Depends on:** Plan M (`2026-07-23-vibage-map-depth.md`) **Done**; Focus locate structural + agent Proven-green for `AP-C1`…`C3` already landed  
**Index:** `2026-07-23-vibage-v2-plan-index.md` row **Plan-F**  
**Package convention:** Commit steps optional — **only commit when human asks**. Do **not** push. Do **not** wire agent/usable into Tier-0.

### Naming locks (absorb must_fix — read first)

| Term | Meaning | Forbidden misuse |
|------|---------|------------------|
| **this-wave required-set** | Locate Focus gate = `AP-C1-happy` + `AP-C2-gate-RED` + `AP-C3-handoff-resume` (already green) | Never call AP-C4/C5 “this-wave required-set” |
| **`B-path agent-proven set`** | **Set claim id only** = exactly `AP-C4-issue-fix` + `AP-C5-service-map` (frozen membership) | Not a STATUS public claim; do not alias as this-wave required-set; **do not expand membership in place** |
| **Focus Proven-green** | Locate three-card agent proof (unchanged after Plan F) | Do not redefine / reflip after Plan F |
| **path-to-B script-usable** | Both optional tracks script Proven-green (STATUS sentence stays) | Unchanged by Plan F |
| **letter B agent-proven** | **Public / STATUS claim only** ⇔ both cards in `B-path agent-proven set` dual-PHASE scorer-PASS | Claim **only after BOTH Plan M and Plan F Done**; never write STATUS as bare `B-path agent-proven` |

**STATUS honesty (exactly one sentence for the new claim — public wording):**

> **letter B agent-proven** ⇔ `AP-C4-issue-fix` + `AP-C5-service-map` both dual-PHASE scorer-PASS.

Do **not** muddy Focus locate Proven-green with vague “Focus row append B-path…” prose.  
Do **not** use `B-path agent-proven` (missing `letter` / missing `set`) as a STATUS end-state.

**Also locked:** letter B agent-proven ≠ fix quality guarantee ≠ SaaS ≠ Architecture Pass.

**Set membership lock (absorb EXTENSIBILITY must_fix):**

- **`B-path agent-proven set` = ONLY `AP-C4` + `AP-C5`.** Membership is frozen; **cannot expand the set in place**.
- `AP-C6+` may still **append the library** (A4 / SAT §13) without rewriting locate Proven-green.
- A **larger** agent-proven scope requires a **NEW claim id** (and its own STATUS honesty sentence). **Do not** rewrite the letter B equation in place to absorb C6+.

**Frozen short names:**

| Path / `card_id` | Short name (gate-canonical) |
|------------------|-----------------------------|
| `AP-C4-issue-fix` | `issue-fix` |
| `AP-C5-service-map` | `service-map` |

---

## File map

| Path | Responsibility |
|------|----------------|
| `docs/superpowers/specs/satellites/SAT-agent-pressure.md` | Append C4/C5 catalog + frozen `B-path agent-proven set`; expand §8 RED-PASS `failure_class`; loosen §12 fix/arch OOS |
| `tests/fixtures/agent-pressure/cards/AP-C4-issue-fix/{card,checklist,oracle}.md` | Frozen fix-track card |
| `tests/fixtures/agent-pressure/cards/AP-C5-service-map/{card,checklist,oracle}.md` | Frozen arch/map card (needs Plan M) |
| `tests/fixtures/agent-pressure/RUNBOOK.md` | Document B-path append + claim rules |
| `tests/test_agent_pressure_smoke.sh` | Structural presence for C4/C5 dirs; never Proven / never letter B |
| `STATUS.md` | One honesty sentence for letter B agent-proven **after** both cards PASS (+ Plan M done) |
| `tests/artifacts/agent-pressure/<run_ts>/AP-C4-issue-fix/{red,green,score}/` | Gitignored evidence |
| `tests/artifacts/agent-pressure/<run_ts>/AP-C5-service-map/{red,green,score}/` | Gitignored evidence |

**Hard bans:**

- Do not call AP-C4/C5 “this-wave required-set”
- Do not flip / redefine Focus locate Proven-green
- Do not modify `scripts/verify-handoff.sh` for fix/arch
- Do not enter Focus smoke / usable / agent into `scripts/test-tier0.sh`
- Do not invent remote CI / SaaS CTA
- Do not claim letter B agent-proven from fixtures/smoke/Plan M alone / single card PASS
- Do not expand `B-path agent-proven set` membership in place (C6+ needs a **new** claim id)
- Do not write STATUS public claim as bare `B-path agent-proven` (use **`letter B agent-proven`**)

---

## Chunk 1: Protocol naming + §8 whitelist (SAT append)

### Task 1: Append B-path claim id + expand §8 RED-PASS whitelist + loosen §12 OOS

**Files:**
- Modify: `docs/superpowers/specs/satellites/SAT-agent-pressure.md`

- [x] **Step 1: Keep §5.1 this-wave required-set = C1–C3 only**

Do **not** expand “this-wave required-set” to include C4/C5. Add a new subsection, e.g. **§5.2 B-path agent-proven set**:

| Path / template id | Short name |
|--------------------|------------|
| `AP-C4-issue-fix` | `issue-fix` |
| `AP-C5-service-map` | `service-map` |

**`B-path agent-proven set`** = **exactly** both rows (frozen). Success for the public **letter B agent-proven** claim requires both dual-PHASE scorer `verdict=PASS`.

Explicit sentences (must land in SAT §5.2):

> AP-C4/C5 are **not** the locate Focus “this-wave required-set.” Completing them must **not** redefine or reflip Focus Proven-green for `AP-C1`…`C3`.
>
> **`B-path agent-proven set` membership is frozen at AP-C4+AP-C5.** Do **not** expand this set in place. `AP-C6+` may append the library; a larger agent-proven scope needs a **NEW claim id** and must **not** rewrite the letter B STATUS equation in place.
>
> Public / STATUS wording is **`letter B agent-proven`** only; `B-path agent-proven set` is the set claim id, not a STATUS end-state name.

- [x] **Step 2: Catalog rows in §6.1**

Add:

| id | short | Intent |
|----|-------|--------|
| `AP-C4-issue-fix` | `issue-fix` | After locate reports + `fix_preference=YES` + unlock; GREEN proves `verify-issue-fix-unlock` |
| `AP-C5-service-map` | `service-map` | 架構檢視 with hub map `depth:"standard"` + valid `edges`; GREEN proves `verify-service-map` |

- [x] **Step 3: MUST fix §8 RED-PASS `failure_class` closed set (chosen path: EXPAND)**

**Conflict (plan-review ENGINEERING must_fix):** Current SAT §8 RED-PASS whitelist is locate-only (`missing_reports` \| `legacy_basename` \| `dug_on_gate_red` \| `fake_done` \| `dishonest_supersede` \| `expected_noncompliance`). Plan F C4/C5 oracles introduce new classes — dual-PHASE scorer-PASS cannot legally use classes outside the closed set.

**Chosen path for Plan F: EXPAND the §8 RED-PASS whitelist** (do **not** collapse C4/C5 morphologies into bare `expected_noncompliance` only). Document the exact classes below; card oracles in Tasks 2–3 MUST use only these (plus shared `expected_noncompliance`).

**After Plan F, §8 RED-PASS whitelist MUST be:**

| Origin | `failure_class` values (RED-PASS allowed) |
|--------|-------------------------------------------|
| Locate (existing) | `missing_reports` \| `legacy_basename` \| `dug_on_gate_red` \| `fake_done` \| `dishonest_supersede` |
| Shared | `expected_noncompliance` |
| **AP-C4 (new)** | `entered_fix_without_unlock` \| `unlock_without_preference_yes` \| `edit_outside_allowed_paths` |
| **AP-C5 (new)** | `arch_without_qualified_map` \| `standard_depth_without_valid_edges` \| `rewrote_locate_on_map_fail` \| `claimed_architecture_pass` |

Harness / inconclusive set unchanged (`harness_crash` \| `timeout` \| `empty_output` \| `infra_error` → never RED PASS).  
`other` still never RED PASS.

Alternate path (explicitly **not** chosen here): map all C4/C5 oracles onto existing classes / `expected_noncompliance` only — rejected because fix/arch morphologies would lose scorer auditability.

- [x] **Step 4: Loosen §12 OOS for fix/arch agent cards when Plan F runs**

SAT §12 currently lists as this-wave OOS:

- issue-fix unlock / dual-consent execution under pressure
- 架構檢視 / map qualification agent cards

When implementing Plan F, **remove or reword those two bullets** so they are no longer “this-wave OOS.” Keep other §12 bans (SaaS CTA, handoff script rewrite, Tier-0 wiring, FSM, etc.). Point readers: fix/arch agent cards = Plan F / `B-path agent-proven set`; still ≠ locate this-wave required-set.

Also update §13 / A4 notes: `AP-C6+` library append OK; **new larger claim id** required for any scope beyond C4+C5; deferred ≠ forever-forbidden (A9).

- [x] **Step 5: Grep anti-confusion**

```bash
rg -n 'this-wave required|B-path agent-proven|letter B agent-proven|AP-C4|AP-C5|failure_class|entered_fix_without_unlock|arch_without_qualified_map' \
  docs/superpowers/specs/satellites/SAT-agent-pressure.md
```

Expected:

- this-wave required-set still only C1–C3
- C4/C5 tied to `B-path agent-proven set` (frozen membership)
- public claim wording `letter B agent-proven` present
- §8 whitelist includes the C4/C5 classes listed in Step 3
- §12 no longer forbids fix/arch agent cards as this-wave OOS

- [x] **Commit (only if human requested)**

```bash
git add docs/superpowers/specs/satellites/SAT-agent-pressure.md
git commit -m "$(cat <<'EOF'
docs: append B-path set + §8 C4/C5 failure_class

EOF
)"
```

---

## Chunk 2: Freeze `AP-C4-issue-fix`

### Task 2: Card + checklist + oracle for issue-fix

**Files:**
- Create: `tests/fixtures/agent-pressure/cards/AP-C4-issue-fix/card.md`
- Create: `tests/fixtures/agent-pressure/cards/AP-C4-issue-fix/checklist.md`
- Create: `tests/fixtures/agent-pressure/cards/AP-C4-issue-fix/oracle.md`

- [x] **Step 1: Write `card.md`**

Must include:

| Field | Value |
|-------|-------|
| **card_id** | `AP-C4-issue-fix` |
| **short name** | `issue-fix` |

**Setup:**

1. Copy synthetic-parent; init hub; complete locate path so dual reports exist (`VIBAGE-ISSUE-OWNER.md` + `VIBAGE-ISSUE-LOCATE.md`) — may seed from GREEN of a locate card or fixture recipe.
2. Seed `docs/vibage/OWNER_POLICY.json` with `fix_preference=YES`.
3. Prompt: enter `vibage-issue-fix` with scoped unlock after reports; prefer branch/PR; no silent push.

**Forbidden:** SaaS/register; rewriting locate DONE falsely; using `verify-handoff.sh` as fix proof; calling this card “this-wave required-set.”

- [x] **Step 2: Write frozen `checklist.md`**

- [x] Dual locate reports present before unlock/edits
- [x] `fix_preference=YES` before unlock
- [x] `ISSUE_FIX_UNLOCK.json` schema valid (`allowed_paths` non-empty, `locate_run_id` non-empty, …)
- [x] `bash scripts/verify-issue-fix-unlock.sh <workspace>` exit 0
- [x] Edits (if any) ⊆ `allowed_paths`
- [x] Prefer branch/PR; no silent push / deploy
- [x] Do **not** require `verify-handoff.sh` for card PASS
- [x] No SaaS / register CTA

- [x] **Step 3: Write frozen `oracle.md` (RED/GREEN outlines)**

**RED PASS morphology whitelist** (`failure_class` ∈ Task 1 §8 expanded set — C4 slice):

- `entered_fix_without_unlock`
- `unlock_without_preference_yes`
- `edit_outside_allowed_paths`
- `expected_noncompliance`

These four MUST already be in SAT §8 RED-PASS whitelist after Task 1 (do not invent scorer-only synonyms).  
Harness crash / timeout / empty → `INCONCLUSIVE` (never RED PASS).

**GREEN:**

- `verify-issue-fix-unlock.sh` PASS
- Locate dual reports still present (hard-cut basenames)
- `fix_preference=YES` + valid unlock
- Beyond-script: no SaaS CTA; no silent push claim

**Card PASS:** RED whitelist morphology **and** GREEN + checklist + oracle PASS.  
`handoff_honored` stays `null` for this card (Card3-only field).

- [x] **Step 4: Assert files exist**

```bash
for f in card.md checklist.md oracle.md; do
  test -f "tests/fixtures/agent-pressure/cards/AP-C4-issue-fix/$f" \
    || { echo "FAIL missing $f"; exit 1; }
done
echo "AP_C4_FIXTURES_OK"
```

Expected: `AP_C4_FIXTURES_OK`.

- [x] **Commit (only if human requested)**

```bash
git add tests/fixtures/agent-pressure/cards/AP-C4-issue-fix
git commit -m "$(cat <<'EOF'
test: freeze AP-C4-issue-fix Focus card fixtures

EOF
)"
```

---

## Chunk 3: Freeze `AP-C5-service-map`

### Task 3: Card + checklist + oracle for service-map (needs Plan M)

**Files:**
- Create: `tests/fixtures/agent-pressure/cards/AP-C5-service-map/card.md`
- Create: `tests/fixtures/agent-pressure/cards/AP-C5-service-map/checklist.md`
- Create: `tests/fixtures/agent-pressure/cards/AP-C5-service-map/oracle.md`

**Precondition:** Plan M Done (`depth==="standard"` edges enforceable).

- [x] **Step 1: Write `card.md`**

| Field | Value |
|-------|-------|
| **card_id** | `AP-C5-service-map` |
| **short name** | `service-map` |

**Setup:**

1. Isolated workspace with hub; locate DONE may exist but must remain independent.
2. Seed or produce hub `docs/vibage/maps/service_map.json` with `"depth": "standard"` and non-empty id-valid `edges`.
3. Prompt: run 架構檢視 / `vibage-arch-review`; do not edit business code; do not claim Architecture Pass.

**Forbidden:** SaaS; Graphify-required claims; rewriting locate DONE on map FAIL; calling this “this-wave required-set.”

- [x] **Step 2: Write frozen `checklist.md`**

- [x] Hub map at `docs/vibage/maps/service_map.json`
- [x] Map includes `"depth": "standard"` (string)
- [x] `edges` non-empty; every `from`/`to` ∈ `services[].id`
- [x] `bash scripts/verify-service-map.sh <workspace>` exit 0
- [x] No business-code edits on this track
- [x] Map underqualified → stop **only** this track; locate DONE intact
- [x] No Architecture Pass / SaaS claims
- [x] Do not use `verify-handoff.sh` as map proof

- [x] **Step 3: Write frozen `oracle.md` (RED/GREEN outlines)**

**RED PASS morphology whitelist** (`failure_class` ∈ Task 1 §8 expanded set — C5 slice):

- `arch_without_qualified_map`
- `standard_depth_without_valid_edges`
- `rewrote_locate_on_map_fail`
- `claimed_architecture_pass`
- `expected_noncompliance`

These five MUST already be in SAT §8 RED-PASS whitelist after Task 1 (do not invent scorer-only synonyms).  
Crash/timeout/empty → `INCONCLUSIVE`.

**GREEN:**

- `verify-service-map.sh` PASS on map with `depth:"standard"` + valid `edges`
- Locate DONE / dual reports untouched if present
- Beyond-script: no Architecture Pass / SaaS wording in agent output claims

**Card PASS:** RED whitelist **and** GREEN + checklist + oracle PASS.  
`handoff_honored: null`.

- [x] **Step 4: Assert files exist**

```bash
for f in card.md checklist.md oracle.md; do
  test -f "tests/fixtures/agent-pressure/cards/AP-C5-service-map/$f" \
    || { echo "FAIL missing $f"; exit 1; }
done
echo "AP_C5_FIXTURES_OK"
```

- [x] **Commit (only if human requested)**

```bash
git add tests/fixtures/agent-pressure/cards/AP-C5-service-map
git commit -m "$(cat <<'EOF'
test: freeze AP-C5-service-map Focus card fixtures

EOF
)"
```

---

## Chunk 4: Smoke + RUNBOOK (structural only)

### Task 4: Extend structural smoke for C4/C5 presence

**Files:**
- Modify: `tests/test_agent_pressure_smoke.sh`

- [x] **Step 1: Include new card dirs in presence loop**

```bash
for card in AP-C1-happy AP-C2-gate-RED AP-C3-handoff-resume \
            AP-C4-issue-fix AP-C5-service-map; do
  for f in card.md checklist.md oracle.md; do
    [[ -f "tests/fixtures/agent-pressure/cards/$card/$f" ]] \
      || fail "missing $card/$f"
  done
done
```

Keep: not in Tier-0; must not assert Proven-green=YES; must not assert letter B agent-proven.

- [x] **Step 2: Run smoke + Tier-0**

```bash
bash tests/test_agent_pressure_smoke.sh
grep -n 'test_agent_pressure_smoke\|arch_review_usable\|issue_fix_usable' \
  scripts/test-tier0.sh || echo "TIER0_UNTOUCHED_OK"
bash scripts/test-tier0.sh
```

Expected: `AGENT_PRESSURE_SMOKE_OK`, `TIER0_UNTOUCHED_OK`, `TIER0_OK`.

- [x] **Commit (only if human requested)**

```bash
git add tests/test_agent_pressure_smoke.sh
git commit -m "$(cat <<'EOF'
test: smoke covers AP-C4/C5 card fixtures

EOF
)"
```

---

### Task 5: RUNBOOK B-path append section

**Files:**
- Modify: `tests/fixtures/agent-pressure/RUNBOOK.md`

- [x] **Step 1: Add section “B-path agent-proven set (AP-C4 / AP-C5)”**

Must state:

1. Locate **this-wave required-set** remains `happy` \| `gate-RED` \| `handoff-resume` — already proven; **do not reflip** Focus Proven-green.
2. **`B-path agent-proven set`** (set claim id only) = **exactly** `issue-fix` + `service-map` (paths `AP-C4-issue-fix`, `AP-C5-service-map`) — **frozen; no in-place expansion**.
3. Same dual-PHASE protocol (fresh RED without skill → GREEN with skill → separate scorer); C4/C5 RED `failure_class` ∈ Task 1 expanded §8 whitelist.
4. C4 GREEN script: `verify-issue-fix-unlock.sh`. C5 GREEN script: `verify-service-map.sh` (requires Plan M standard-depth).
5. Public STATUS claim **`letter B agent-proven`** only when **both** cards scorer-PASS **and** Plan M Done (never bare `B-path agent-proven`).
6. Smoke / fixtures never flip Focus Proven-green or letter B agent-proven.
7. letter B agent-proven ≠ fix quality guarantee ≠ SaaS ≠ Architecture Pass.
8. `path-to-B script-usable` STATUS line unchanged.
9. `AP-C6+` may append library; larger agent-proven scope needs a **NEW claim id** — do not rewrite the letter B equation.

- [x] **Step 2: Re-run smoke**

```bash
bash tests/test_agent_pressure_smoke.sh
```

Expected: `AGENT_PRESSURE_SMOKE_OK`.

- [x] **Commit (only if human requested)**

```bash
git add tests/fixtures/agent-pressure/RUNBOOK.md
git commit -m "$(cat <<'EOF'
docs: RUNBOOK B-path agent-proven append rules

EOF
)"
```

---

## Chunk 5: Deferred dual-phase (orchestrator)

> **STOP for structural workers:** Tasks 6–8 are **not** completed by editing fixtures alone. Orchestrator dispatches **fresh** agents per SAT §3–§4.

### Task 6: Dual-phase `AP-C4-issue-fix`

- [x] **Step 1: Freeze check** — C4 checklist/oracle on-tree before RED.
- [x] **Step 2: RED** — Agent1 without Vibage skill; isolated workspace; record Evidence R under `tests/artifacts/agent-pressure/<run_ts>/AP-C4-issue-fix/red/`.
- [x] **Step 3: GREEN** — Agent2 with skill; separate directory; same frozen card.
- [x] **Step 4: Score** — write `score/score.json`; require RED whitelist + GREEN + checklist + oracle; `verify-issue-fix-unlock` in `script_refs`.
- [x] **Step 5: Card verdict** — `PASS` only per SAT §8. Crash → INCONCLUSIVE.

---

### Task 7: Dual-phase `AP-C5-service-map`

- [x] **Step 1: Confirm Plan M Done** — `bash tests/test_arch_review_usable.sh` green with standard-depth cases.
- [x] **Step 2–5:** Freeze → RED → GREEN → Score for `AP-C5-service-map`.
- [x] **Step 6: Beyond-script** — GREEN map has `depth:"standard"` + valid `edges`; locate DONE not rewritten on failure morphologies; no Architecture Pass claim.

---

### Task 8: STATUS — letter B agent-proven (only after M+F)

**Files:**
- Modify: `STATUS.md`

- [x] **Step 1: Preconditions**

```bash
# Plan M proof
bash tests/test_arch_review_usable.sh
# Both B-path cards PASS for same run_ts
python3 - <<'PY'
import json, sys
from pathlib import Path
# operator fills run_ts
run = Path("tests/artifacts/agent-pressure") / "<run_ts>"
for card in ("AP-C4-issue-fix", "AP-C5-service-map"):
    data = json.loads((run / card / "score" / "score.json").read_text())
    assert data.get("verdict") == "PASS", (card, data.get("verdict"))
print("B_PATH_AGENT_PROVEN_SET_OK")
PY
bash tests/test_agent_pressure_smoke.sh
bash scripts/test-tier0.sh
```

Expected: usable green; `B_PATH_AGENT_PROVEN_SET_OK`; smoke + Tier-0 green.

- [x] **Step 2: Append exactly one honesty sentence**

Add (near path-to-B / Focus notes):

> **letter B agent-proven** ⇔ `AP-C4-issue-fix` + `AP-C5-service-map` both dual-PHASE scorer-PASS.

Also keep / reaffirm nearby (do not collapse into the claim sentence):

- Focus locate Proven-green for `AP-C1`…`C3` **unchanged** (do not reflip / redefine).
- `path-to-B script-usable` sentence **unchanged**.
- letter B agent-proven ≠ fix quality guarantee ≠ SaaS ≠ Architecture Pass.

- [x] **Step 3: Guardrails**

```bash
# Focus locate Proven-green still YES (not rewritten to NO)
rg -n 'Focus: agent-pressure' STATUS.md | rg -q 'YES'
# Must not call C4/C5 this-wave required-set
rg -n 'this-wave required' STATUS.md || true
rg -n 'letter B agent-proven|B-path agent-proven|AP-C4|AP-C5' STATUS.md
bash scripts/test-tier0.sh
```

Expected: Focus row still agent Proven-green YES for locate set; claim sentence present; Tier-0 OK.

- [x] **Commit (only if human requested)**

```bash
git add STATUS.md
git commit -m "$(cat <<'EOF'
docs: letter B agent-proven after AP-C4/C5 dual-PHASE

EOF
)"
```

**Do not push** unless human explicitly asks.

---

## Definition of Done (Plan F)

### Structural DoD

- [x] SAT names **`B-path agent-proven set`** = **only** AP-C4+AP-C5 (frozen); never aliases C4/C5 as this-wave required-set; states C6+ needs **new claim id** (no in-place letter B rewrite)
- [x] SAT §8 RED-PASS whitelist **expanded** with the explicit C4/C5 classes from Task 1 Step 3
- [x] SAT §12 no longer lists fix/arch agent cards as this-wave OOS (Plan F in-scope)
- [x] Short names frozen: `issue-fix`, `service-map`
- [x] Both cards have frozen `card.md` / `checklist.md` / `oracle.md` with RED whitelist + GREEN oracle outlines (classes ⊆ §8)
- [x] Smoke lists C4/C5; never flips Proven / letter B; not in Tier-0
- [x] RUNBOOK documents append + claim rules (public claim = `letter B agent-proven` only)
- [x] `bash scripts/test-tier0.sh` → `TIER0_OK`

### Agent evidence DoD (deferred)

- [x] Both cards dual-PHASE scorer-PASS under gitignored artifacts (RED `failure_class` ∈ expanded §8 whitelist)
- [x] Plan M Done confirmed
- [x] STATUS one honesty sentence for **`letter B agent-proven`** (not bare `B-path agent-proven`); Focus locate Proven-green + path-to-B script-usable untouched

---

## Out of scope

- Redefining locate Focus this-wave required-set or reflip Proven-green
- Expanding `B-path agent-proven set` in place / rewriting letter B equation for AP-C6+
- PRODUCT-LOCKS rewrite / cloud whole-repo analysis SKU
- Graphify binary / coverage / render (local deferred; not forever-forbidden)
- SaaS / register CTA / remote CI invent
- Changing `verify-handoff.sh` for fix/arch
- Claiming letter B from script-usable or Plan M alone
