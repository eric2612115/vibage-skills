# Vibage v2 — Superpowers-grade (Local Complete) — Umbrella Design

**Date:** 2026-07-23  
**Status:** Spec ✅ Approved; human OK → writing-plans (see `docs/superpowers/plans/2026-07-23-vibage-v2-plan-index.md`)  
**Branch:** `feature/vibage-v2-superpowers-grade`  
**Package SSOT:** `/Users/eric.fang/MindOwnBuz/vibage-skills`  
**Doc shape:** This file is the **umbrella** contract. Thick topics get **satellite** specs; implementation is **many small plans** (not one mega-plan).  
**Note on section labels:** Parenthetical marks like “(§3)” in later headings mean **frozen brainstorm section IDs**, not this file’s heading numbers.  
**Supersedes for development:** Conflicting older STATUS / coverage / plans / soft-CTA feature-call copy must be moved to `docs/archive/<date>/` with `DO NOT USE FOR DEV` before they may be deleted at a later version milestone. Do not use `docs/superpowers/specs/2026-07-22-vibage-os-p1-design.md` as the live SSOT once this umbrella is approved (archive or banner it).

### Local DoD letters (plain)

| Letter | Means (owner-plain) |
|--------|---------------------|
| **C** | “找問題” closed loop works: confirm → gate → locate → dual reports + indexes + script tests green |
| **B** | C **plus** optional issue-fix (scoped edit after unlock) **and** 架構檢視 (Service map) usable when map qualifies |

This phase **ships C**. B is designed in (optional tracks + satellites) so we do not redesign later.

---

## 1. Problem

Owners (often non-coders) need a trustworthy loop to find *where* a problem lives in fat / multi-repo / AI-generated trees, with durable footprints, honest gates, and optional later fix / architecture review — without a heavy runtime, without pretending cloud features exist, and without fake-green documentation.

P1 design (2026-07-22) started the parent-folder OS + confirm-before-dig path, but:

1. Contracts, tests, report names, and honesty rules are not yet “superpowers-grade.”
2. Main / current tree can be missing ship-blockers (e.g. `scan_plan_hash`) while STATUS claims green.
3. SaaS / register CTAs and cloud naming collide with local product language.
4. Mid-run failure lacks a SelfOwnBuz-like dual-write handoff for the same chat and for resume.

---

## 2. Goals (this phase — local complete body)

1. **Approach 1 (thin runtime):** Thicken contracts, templates, skills, and **script-backed tests**. No FSM engine, daemon, or orchestrator binary.
2. **Local complete DoD = C → path to B:** Ship **C** (issue-locate loop: indexes, confirm, gate, dual reports, script tests). Design includes optional **issue-fix** and **架構檢視 (Service map)** so the package can grow to **B** without redesign. (See letter table above.)
3. **Hard truth = scripts:** Script fail means definitely wrong. Agent self-claim can be wrong. This-wave ship gate is **Tier-0 script/contract green**, not full agent RED→GREEN.
4. **Owner UX:** One chat end-to-end; plain language in chat; agent **dual-writes** milestone progress into `docs/vibage/` (SelfOwnBuz-like stacking under caps).
5. **Honest Mode / nested / review ladder:** Never fake premium nested or L3; degrade with one OWNER sentence when deliverable is degraded.
6. **Doc hygiene:** Archive conflicting old docs first; thin package STATUS with Designed / On-tree / Proven-green (**scope:** `script` | `agent`).

### Non-goals (this phase)

- SaaS: register, pairing, API keys, cloud upload, hosted Architecture Pass product — **next phase only** (stubs/blanks OK; **no register CTA** in local flow/UI copy).
- Full agent RED→GREEN pressure for all skills — deferred **Focus: agent-pressure** (scenario cards + two fresh subagents + pre-locked checklist + evidence pack; synthetic parent primary).
- Infinite hub dumps, copying microservice business trees into git, or whole-tree fingerprints.
- Claiming publish-ready / CI-green without a remote that runs the same local entry command.

---

## 3. Architecture (Approach 1)

```text
Cursor opens parent folder
  → vibage-init (skills allowlist + hub skeleton)
  → vibage-orient (SCAN_PLAN)
  → ask code-edit preference (default NO) → docs/vibage/OWNER_POLICY.json
  → human CONFIRM + script assert_gate (hash)
  → vibage-issue-locate (indexes; dig confirmed set only; never edit business code)
  → VIBAGE-ISSUE-OWNER.md + VIBAGE-ISSUE-LOCATE.md (+ preview fail-soft)
  → optional vibage-issue-fix (preference ≠ unlock; file-backed scope confirm after report)
  → optional 架構檢視 / Service map (qualified map required; failure blocks only this track)
```

### 3.1 Hub layout (normative)

```text
docs/vibage/
  STATUS.md                 # OS pointer + STOP card (thin)
  RUNS/<run_id>.json        # RunEnvelope (+ handoff SSOT)
  SCAN_PLAN.md
  CONFIRM.json
  OWNER_POLICY.json         # code-edit preference; NOT in scan_plan hash
  DECISIONS.md
  indexes/<root_id>/        # local root indexes
  maps/                     # Service map artifacts
  # optional: model-routing.json, UploadManifest stub (no upload)

Workspace root (deliverable only when complete):
  VIBAGE-ISSUE-OWNER.md
  VIBAGE-ISSUE-LOCATE.md
  vibage-preview/           # fail-soft
```

**Rules:** Hub disk is authority for vibage artifacts. Git tracks vibage docs/maps only — never copy microservice trees. Verify + pollution + size caps apply (§3 locks). Fingerprint: git HEAD+identity when available; no-git cheap signals; **no full-tree** hash; lazy index for `planned_dig_ids` only.

### 3.2 Skills (same install box)

| Skill | Owns | Must not |
|-------|------|----------|
| `vibage-init` | install allowlist, hub skeleton, thin rules entry | dig, reports |
| `vibage-orient` | roots, SCAN_PLAN, awaiting confirm | deep dig |
| `vibage-issue-locate` | indexes, dig after gate, dual reports | edit business code; claim fix/架構 done |
| `vibage-issue-fix` | scoped edits after dual consent + file confirm; prefer branch/PR | run without unlock |
| 架構檢視 (Service map track) | map-qualified architecture review | block locate DONE on map fail |

**This-wave skill directories:** Install/docs may briefly keep a redirect from `vibage-locate` → `vibage-issue-locate`. Report filenames hard-cut immediately; skill folder rename may lag one small plan if install breakage risk is high.
| `research-survey-review` | survey when matrix MUST | pretend MUST when SKIP |
| `section-gate-review` | design-section 3-lens gates | empty theater reviews |

Rename hard cut: reports are **`VIBAGE-ISSUE-OWNER.md`** / **`VIBAGE-ISSUE-LOCATE.md`** only (no legacy name compat). Old `vibage-locate` may briefly redirect in install docs only.

### 3.3 Layers

| Layer | Role |
|-------|------|
| OS | Hub ready; STATUS pointer (`focus_run_id`, `focus_pipeline_id`) + STOP card |
| Pipeline | `locate` / optional fix / 架構檢視 — `pipeline_id` |
| Run | `RunEnvelope` per run — phase, mode, handoff; **not** a global FSM engine |

---

## 4. Pipeline contracts (§2)

### 4.1 Dual consent for code edit

1. **Preference** (may ask early; default NO) → `OWNER_POLICY.json` (not in scan hash).  
2. **Unlock** = after locate report, file-backed scope confirm. Preference ≠ unlock.

**Hard gates:**

- If preference is **NO** (default): agent **must not** enter `vibage-issue-fix` or solicit unlock. Locate may still DONE.  
- If owner later wants fix: update `OWNER_POLICY.json` to YES (plain ask in chat + write file), **then** after a locate report, run unlock (scope confirm file). Both preference=YES **and** unlock file are required before any business-code edit.  
- Unlock without preference=YES is forbidden. Preference=YES without unlock is forbidden.

### 4.2 Confirm + gate

- Human plain confirm (e.g. 「確認」 / “confirm” / clear synonym) triggers writing `CONFIRM.json` with plan hash.  
- Dig requires `assert_gate` success (non-zero + plain reason + **dig forbidden** on fail).  
- Plan change → stale confirm → re-confirm.  
- Resume: if script says confirm still valid → continue **without** re-ask; else re-confirm.

### 4.3 MANIFEST / DoD

- This phase installs issue-fix + 架構檢視 as **optional** tracks.  
- Locate DONE does **not** require them.  
- Local complete body = issue-locate loop + indexes + gates/tests (C). Path to B stays in design.

### 4.4 No register CTA

Local happy path, errors, and preview copy must not push registration. SaaS blanks only.

---

## 5. Maps, reports, caps (§3)

### 5.1 Indexes and maps

- Root indexes: `docs/vibage/indexes/<root_id>/`  
- Service maps: `docs/vibage/maps/`  
- Map qualification: **Hybrid** — quality bar always MEDIUM; scale sets rhythm Tiny / Subset / Large.  
- Map fail blocks **only** 架構檢視 track.

### 5.2 Reports

- Header: two status lines (找問題 / 架構檢視).  
- **Assumption-challenge** fixed section in `VIBAGE-ISSUE-LOCATE.md` (2–5 bullets). OWNER may briefly reference.  
- HTML preview fail-soft.  
- Fingerprint after assert_gate; fingerprint ∉ scan_plan hash.

### 5.3 Caps

- Default cap table; agent may adjust with **WARN**.  
- Hard FAIL raise only via **this-run** RunEnvelope / DECISIONS (+ timestamp).  
- Exception does **not** rewrite default table or future cloud quota.

---

## 6. Nested work and review ladder (§4)

### 6.1 Map-reduce fan-out

- Degrade + record if model missing; never fake premium/nested.  
- Fake full nested: empty-dispatch → verify FAIL. No 100% nested SLA.  
- Thin: skills / templates / existing verify family only.

### 6.2 Review ladder (task difficulty; orthogonal to L0–L3)

| Difficulty | Review |
|------------|--------|
| HIGH | 3× stronger model (e.g. Grok 4.5 high) |
| MED | 3× faster model (e.g. Composer 2.5) |
| LOW | tests / verify / self-check (not empty 3-lens theater) |

- Forbidden: claim done with **zero** evidence/script gate.  
- Owner locate defaults toward **LOW**. HIGH/MED mainly for Vibage self-build / high-risk contracts.  
- OWNER: one plain-language **degrade** sentence when applicable.  
- Model slugs are suggestions only; routing B semantics remain (L0–L3; no fake L3).

---

## 7. Evidence, tests, docs, ship (§5)

### 7.1 Plan 0 — land a single clean main

**Merge recipe (one line):** Commit vibage naming on p1 if still dirty → merge into trunk → on conflict **vibage live paths win** → rewrite any brought-in `docs/war-room/` / `war-room-*` fixtures/smoke/skills to `docs/vibage/` / `vibage-*` → discard live war-room SSOT → archive soft CTA / feature-call / conflicting STATUS.

1. Merge `feature/vibage-os-p1` into the executable line after resolving conflicts.  
2. Discard live `war-room-*` paths; **vibage** names/paths win as live SSOT.  
3. **Path rewrite DoD:** after merge, all live hub paths, fixtures, and smoke scripts use `docs/vibage/` (no live `docs/war-room/`).  
4. Ensure `scan_plan_hash` + gate scripts + tests are on the tree.  
5. Result: **one clean `main` (or equivalent trunk)**; further work lands on that trunk.  
6. Plan 0 DoD **includes** archive of conflicting docs + **unlink** soft CTA / `references/feature-call.md` (and similar) from happy path + thin package STATUS (three-state) — merge alone is not done.

### 7.2 This-wave ship (Tier-0)

- Single local entry: `bash scripts/test-tier0.sh` (smoke + pytest).  
- Must cover: gate **RED** (no dig) → GREEN → verify green; hard-cut report names.  
- **SHIP_MEANS_TIER0_ONLY:** this-wave “可交貨” = Plan 0 + Tier-0 green.  
  - ≠ agent E2E proven  
  - ≠ publish-ready  

### 7.3 Proven scope

| Scope | Meaning |
|-------|---------|
| `script` | Script/contract proven (default ceiling this wave) |
| `agent` | Full agent RED→GREEN per Focus protocol |

Package STATUS uses Designed / On-tree / Proven-green with scope. Hub STATUS is runtime pointer — do not conflate.

### 7.4 Focus: agent-pressure (deferred)

- Listed as a fixed row on **package STATUS** (meta track).  
- **Not** a product `pipeline_id` and **not** the same as STATUS `focus_pipeline_id` (which points at locate/fix/架構檢視 runs).  
- Protocol: scenario card → RED without skill → GREEN with skill → pre-locked checklist + evidence pack.  
- Synthetic parent primary; real project spot-check only.  
- Tier-0 green **must not** mark this track Proven-green (`agent`).

### 7.5 Docs archive

- Move conflicting old docs to `docs/archive/<date>/` + banner `DO NOT USE FOR DEV` + unlink from README / NEW-CHAT / live STATUS.  
- Archive is one-way this wave; reactivation = new Designed item + re-link.  
- Later version milestone may delete archived files.

### 7.6 CI

- Mentioned in design + plans.  
- Local green = this-wave ship.  
- When remote exists, CI mirrors the same entry command.  
- No remote ≠ publish-ready.

### 7.7 Plain language

- Owner-facing sentences vs stable English IDs.  
- ≥3 counterexamples in rules (no invented Phase/Mode synonyms for owners).  
- Prefer “acceptance / tests / proof” over overloaded “evidence” as a section label where it clashes with locate path+quote evidence.

---

## 8. Happy path, errors, handoff (§6)

### 8.1 Dual-write (SelfOwnBuz-like)

On **milestones** (orient done, confirm, gate, locate start/end, success/stop) — not every tool call:

1. **Chat (same conversation SSOT for owner):** plain language progress / STOP. Never paste RunEnvelope JSON / hashes / internal fields as the owner message. Do not assign hub homework on the happy path.  
2. **Disk:** update `docs/vibage/` (STATUS STOP card + RunEnvelope, etc.) under allowlist / pollution / size caps. Never dump full chat logs or business trees into the hub.

### 8.2 Mid-fail

- **No** fake-DONE `VIBAGE-ISSUE-*` reports.  
- Write STATUS STOP + RunEnvelope.handoff.  
- Deliverable degrade (completed but shallow) → OWNER one-liner; mid-fail → chat + disk handoff only.

### 8.3 Handoff fields (RunEnvelope SSOT)

**Envelope root (existing / shared):** `schema_version`, `pipeline_id`, `run_id`, `phase`, `mode`, `supersedes_run_id`, `stopped_at` (optional), nested `handoff` object.

**Prior-run pointer (single rule):**

- After Terminal-then-mint, the **new** run MUST set root `supersedes_run_id` = prior terminal `run_id` (this is the SSOT).  
- `handoff.prior_run_id` is an **optional mirror** for Focus/humans; if present it MUST equal `supersedes_run_id`.  
- On conflict, **root wins**; rewrite the mirror.  
- Fresh runs with no predecessor: both null/omitted.

**Nested `handoff` object only:**

- `stop_reason`  
- structured `progress` (`steps_done`, `dig_ids_done` / `dig_ids_pending`, `confirm_payload_hash`, optional `notes`)  
- `blockers`, `next_action`  
- `artifacts_ok` (`SCAN_PLAN|CONFIRM|OWNER_POLICY` → `reuse|redo|unknown`) with **script/hash > agent**; gate red forces `CONFIRM=redo`. This wave: only `CONFIRM` is expected script-proven via gate; `OWNER_POLICY` / `SCAN_PLAN` may be `unknown|agent` until scripts exist.  
- `artifacts_ok_source` (`script|agent`)  
- `known_incompleteness`  
- optional `track`  
- optional `prior_run_id` (mirror only; see rule above)  
- `handoff_honored` reserved for Focus  

Do **not** duplicate `phase` / `pipeline_id` / `run_id` inside `handoff`.

**STATUS** = pointer + STOP prose (+ optional mirrored `focus_phase`). No dual FSM.

**No live hub-root `HANDOFF.md`.** Optional per-run derivative under `RUNS/<run_id>/` only if needed; JSON wins on conflict.

### 8.4 Resume (Terminal-then-mint)

- Continue same `run_id` until terminal (`done|failed|aborted|stale_confirm`).  
- Further progress after terminal → **new** `run_id` and **MUST** set `supersedes_run_id` per §8.3.  
- Never rewrite old failed/aborted → done.  
- Confirm-valid (script) → no re-ask; plan change / gate red → re-confirm.  
- `artifacts_ok` does **not** cross pipelines by default.

### 8.5 Error table (owner)

| Case | Owner sees (chat) | System |
|------|-------------------|--------|
| Dig before confirm | Cannot dig yet; confirm plan | Gate fail; dig forbidden |
| Stale confirm | Plan changed; confirm again | stale; re-confirm |
| Missing roots | List missing; use visible subset | RootRef missing |
| Degrade | One plain sentence | Footprint actual depth |
| Map underqualified | 架構檢視 blocked; locate may still DONE | Track-local fail |
| Preview fail | MD reports still OK | fail-soft; no CTA |
| Script/verify red | Auto-check failed; not complete | No Proven / fake done |
| Cap / pollution / size hard FAIL | Hub too large or wrong files written; stop and clean | verify FAIL; dig forbidden until fixed; no fake DONE |
| Abort / mid-fail | Stopped + next step | STOP + handoff; no dual reports |

---

## 9. Doc / plan delivery shape

| Layer | Role |
|-------|------|
| Umbrella (this file) | Frozen product + engineering contracts |
| Satellites | Thick topics (see table) |
| Many small plans | Ordered below; not one mega-plan |

### 9.1 First-wave satellites (IDs)

| Satellite ID | Owns |
|--------------|------|
| `SAT-map-schema` | Service map schema, Hybrid Tiny/Subset/Large rhythm, qualification |
| `SAT-issue-fix-unlock` | Unlock file shape, branch/PR default, dual-consent edge cases |
| `SAT-arch-review` | 架構檢視 track behavior given qualified map |
| `SAT-agent-pressure` | Focus protocol details + scenario library |
| `SAT-ci-remote` | CI workflow when origin exists (mirrors `test-tier0.sh`) |
| `SAT-saas-blank` | Reserved blank shapes for next-phase cloud (no local CTA) |

### 9.2 First-wave small plans (order)

| Plan ID | DoD (one line) |
|---------|----------------|
| `P0-merge-main` | Merge p1 → path rewrite `docs/vibage/` → archive/unlink war-room + soft CTA → thin STATUS |
| `P1-report-hardcut` | `VIBAGE-ISSUE-*` names in templates/skills/verify |
| `P2-tier0-entry` | `scripts/test-tier0.sh` green (gate RED→GREEN + hard-cut) |
| `P3-handoff-schema` | RunEnvelope.handoff + STATUS STOP template + milestone dual-write hooks |
| `P4-optional-tracks` | Thin MANIFEST wiring for issue-fix / 架構檢視 (optional; locate DONE independent) |
| `P5-skill-rename` | `vibage-issue-locate` dir + install redirect cleanup |
| `P6-focus-stub` | Package STATUS row for Focus: agent-pressure (no agent runs yet) |
| `P7-ci-when-remote` | Only after origin exists; same command as Tier-0 |

Prior S15–S25 checklist intent is covered by the above IDs; old coverage docs are not live SSOT.

**Ship vs design acceptance:** Tier-0 (`P2`) = this-wave **ship**. One-chat dual-write owner UX (`P3`) = Designed → On-tree → Proven-green(`script`) when tests say so — not agent-proven.

---

## 10. Success criteria (this phase)

1. Clean trunk with working `scan_plan_hash` + `assert_gate` / `write_confirm`.  
2. `bash scripts/test-tier0.sh` green (includes gate RED→GREEN + hard-cut names).  
3. Conflicting old docs archived; soft CTA unlinked; package STATUS honest (three-state + scope).  
4. Owner can complete locate in one chat with dual-write milestones; mid-fail leaves resumable STOP/handoff (**script-proven** when tests cover it; not Focus agent-proven).  
5. No register CTA; SaaS left blank.  
6. Focus: agent-pressure visible as deferred meta row, not marked agent-proven by Tier-0.

---

## 11. Open blanks and expansion seams (intentional)

### 11.1 SaaS reserved seams (local must not invent product CTA)

| Reserved | Local rule |
|----------|------------|
| `docs/vibage/UploadManifest.stub.json` | Schema stub only; no upload |
| Cloud product name **Architecture Pass** | **≠** local track name **架構檢視 / Service map** — local English/IDs stay `service_map` / 架構檢視 |
| Register / pairing / API keys | Next phase only; no copy in local happy path or errors |

### 11.2 Plan-level blanks

- Exact pytest file list inside `test-tier0.sh`.  
- Full RunEnvelope JSON Schema file path (`P3-handoff-schema`).  
- Agent-pressure scenario library (`SAT-agent-pressure`).  
- Optional `docs/archive/<date>/INDEX.md` listing source path + why archived (recommended in `P0`).

---

## 12. Frozen decision index

| ID | Decision |
|----|----------|
| D1 | Approach 1 thin runtime |
| D2 | Ship C now (locate loop); design path to B (fix + 架構檢視) |
| D13 | Preference NO blocks fix; dual consent both hard gates |
| D14 | Focus agent-pressure = package STATUS meta row, not pipeline_id |
| D15 | Plan order P0→P2 ship; satellites SAT-* for thick topics |
| D3 | Names: issue-locate / issue-fix; 架構檢視 = Service map (local) |
| D4 | Dual consent; OWNER_POLICY; no register CTA |
| D5 | Report hard cut `VIBAGE-ISSUE-*` |
| D6 | Hybrid map bar; map fail ≠ locate fail |
| D7 | Review ladder HIGH/MED/LOW; owner locate → LOW default |
| D8 | Tier-0 script ship; Focus agent-pressure deferred |
| D9 | Plan 0 merge p1 → single main; vibage wins |
| D10 | Archive then later delete |
| D11 | Dual-write chat + hub milestones; Terminal-then-mint |
| D12 | Confirm-valid resume without re-ask |
