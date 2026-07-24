> **ARCHIVED · DO NOT EXECUTE as live SSOT.**
> Live C′ plan: `docs/superpowers/plans/2026-07-25-vibage-c-prime-graph-brief-ledger.md`

# Plan-S — Scorecard to ≥9 (exclude remote/CI class)

> **For agentic workers:** Use subagent-driven-development or executing-plans. Checkboxes track steps.
> **Human gate:** User must approve this plan before implementation waves start.

**Goal:** Raise every scorecard dimension that is currently **&lt; 9** to **≥ 9**, **except** the remote/CI class (git origin, GitHub Actions mirroring Tier-0, publish-ready claims). **Marketplace = Plan-P only** (zero marketplace implementation in Plan-S).

**Status:** **W1+W2+W3 done.** Post-W3 re-scorecard: all non-exempt dims ≥9 (dim4 closed at 9 after OWNER_ZERO_BASH_OK); dim13 EXEMPT (~3). Plan-S success claim **ALLOWED** with explicit remote/CI exemption.

**Architecture:** Three implementation waves (W1 auto-trigger + pack feel → W2 stranger/owner UX + clarity → W3 local pack-health + map/handoff polish). Each wave has evidence DoD (no “plausibly ≥9”). Do **not** flip STATUS capability greens without proof. Do **not** put pack-health into `test-tier0.sh`.

**Tech Stack:** Markdown adapters/hooks, bash verify scripts, existing install.sh, Cursor/Claude/Codex entry surfaces.

**Baseline (2026-07-23 multi-agent scorecard):** overall ~7.7; local DoD ~8.5–9; public dim ~3. Target: all non-remote/CI dims ≥ 9.

**Excluded from “must ≥9” (remote/CI class):**
- Dim **13** Public-release readiness (no origin / no workflows / LICENSE TBD may stay until user opens public wave)
- Any claim of remote CI Proven / publish-ready
- Wiring marketplace that **requires** public GitHub as hard dependency → defer to **Plan-P (public)** separate file later

**Honesty:** ≥9 on a dimension = auditable local evidence in this package + parent install path — **≠** “average slogan 9” ≠ SaaS ≠ Architecture Pass.

---

## Three-lens gate (absorbed must_fix)

| ID | Lock |
|----|------|
| S1 | **Dim4:** After parent install, owner chat path = **0 owner-typed bash** (agent runs verifies). Evidence: transcript fixture or scripted chat log. Markdown-only → product **VETO** on dim4 ≥9. |
| S2 | **Dim14:** Mandatory `using-vibage` + **forced finishing pointer after locate DONE** (not OR-section). Lifecycle: route → work → finish. |
| S3 | **Dim12:** Host-best matrix (below). No slogan “all three SessionStart identical.” Marker phrase alone ≠ ≥9; need hooks file/schema check where Cursor; Claude/Codex may use always-on parent blocks as best-available. |
| S4 | Delete “plausibly ≥9” from any wave DoD. |
| S5 | **Dim10 tied to Dim12:** `PROJECT_ENTRY_OK` alone insufficient; at least Cursor proves open-chat auto-route path. |
| S6 | `install.sh --with-project-rule` **must install** Cursor hooks templates (+ Claude/Codex per matrix). |
| S7 | Focus summary commit path **outside** gitignored `tests/artifacts/agent-pressure/` (e.g. `docs/evidence/focus/`). |
| S8 | `pack-health.sh` = composite proof command, **not** capability SSOT. Print: `PACK_HEALTH_OK ≠ TIER0_OK ≠ remote CI ≠ letter B`. Order: pins → project-entry → entry-docs-sync. |
| S9 | `test_pack_health.sh` asserts **not** wired into Tier-0. |
| S10 | Dim20 checklist = grep-able OK tokens only. |
| S11 | Plan-R parent routers remain routing SSOT; `using-vibage`/hooks only **point** — no second state machine; no child-repo rule spread. |
| S12 | No new cloud/API/pricing/UX beyond `SAT-saas-blank`; finishing menu: no soft CTA. Marketplace: **zero** in Plan-S. |

### Host-best auto-trigger matrix (normative for dim12)

| Host | Best-available injection | Verify bar |
|------|--------------------------|------------|
| Cursor | Real `sessionStart` hook (install under parent) + existing `vibage.mdc` | Hook file present + schema/dry-run check ∉ Tier-0 |
| Claude | Always-on `CLAUDE.md` / vibage-entry (SessionStart hook optional if host supports) | Parent blocks + markers; **do not** require Cursor-only hook files for Claude green |
| Codex | `AGENTS.md` vibage block (hooks if feature on) | Same as Claude honesty |

Dim12 ≥9 = **parent session routes without paste NEW-CHAT on each host via best-available**, not “identical SessionStart binaries.”

---

## Dimension → wave map

| Dim | Now | Target | Wave | Primary work |
|----:|----:|-------:|:----:|--------------|
| 1 Product clarity | 7.0 | ≥9 | W2 | Stranger README hero: one sentence + 60s path |
| 3 Entry docs sync | 8.5 | ≥9 | W2 | NEW-CHAT ↔ Plan-R / PROJECT_ENTRY_OK pointer |
| 4 Owner non-coder UX | 6.0 | ≥9 | W1+W2 | Plain-language bootstrap + auto route; less bash ritual in chat |
| 5 Scope discipline | 8.5 | ≥9 | W2 | Trim jargon in entry; keep satellites deferred |
| 6 Script ship gate | 8.0 | ≥9 | W3 | Local `pack-health.sh` (pin+entry+docs) documented; Tier-0 unchanged |
| 7 Optional tracks | 8.5 | ≥9 | W3 | One README/STATUS “how to prove usable” card (no Tier-0 lie) |
| 8 Focus / letter B | 8.5 | ≥9 | W3 | Scorer summary stub committed (no secrets); packs stay gitignore |
| 9 Pin & install | 7.5 | ≥9 | W1+W3 | install tip → run verify-pins; pack-health includes pins |
| 10 Parent session entry | 8.0 | ≥9 | W1 | SessionStart/hooks + install default docs for parent path |
| 11 Multi-surface docs | 7.0 | ≥9 | W2 | Per-surface 20-line INSTALL snippets (Cursor/Claude/Codex) |
| 12 Auto-trigger / hooks | 6.0 | ≥9 | **W1** | SessionStart / using-vibage injection |
| 14 Skill-pack feel | 6.5 | ≥9 | W1 | `using-vibage` thin skill + finishing options after dual reports |
| 16 Local map usable | 8.0 | ≥9 | W3 | Document AI-first use of JSON+mmd; one-command prettier path |
| 18 Handoff contract | 8.0 | ≥9 | W3 | STATUS/satellite note: locate-wave shaped; checklist for owners |
| 20 C + path-to-B confidence | 8.0 | ≥9 | W3 | Single “local complete checklist” page pointing at proofs |
| 13 Public / remote CI | 3.0 | **exempt** | — | Plan-P later |
| 2,15,17,19 | ≥9 | keep | — | No rewrite that weakens honesty |

---

## Wave 1 — Auto-trigger + pack feel (dims 12, 14, 4↑, 10↑, 9↑)

**Goal:** Opening a chat on a parent workspace routes without pasting NEW-CHAT every time.

### Task 1.1: `using-vibage` thin skill (router pointer only)

**Files:**
- Create: `skills/using-vibage/SKILL.md`
- Modify: `skills/MANIFEST.txt`
- Modify: adapters — point to using-vibage; **do not** duplicate init/orient/locate state machine (Plan-R remains SSOT)

- [ ] **Step 1:** Skill: session/unclear → package STATUS → follow parent router (init/orient/locate); no nested dig paste; no register CTA; owner language (“agent runs scripts”).
- [ ] **Step 2:** MANIFEST + install link.
- [ ] **Step 3:** Fixture: skill + MANIFEST membership (∉ Tier-0).

### Task 1.2: SessionStart / platform hooks (host-best)

**Files:**
- Create: `adapters/cursor/hooks/` (sessionStart → inject using-vibage pointer)
- Modify: `scripts/install.sh` — `--with-project-rule` copies Cursor hooks + refreshes Claude/Codex blocks
- Modify: `scripts/verify-project-entry.sh` + new `tests/test_session_hooks.sh` (∉ Tier-0)

- [ ] **Step 1:** Lock host-best matrix in tree (this plan § matrix).
- [ ] **Step 2:** Cursor: real sessionStart hook installed to parent; dry-run/schema test.
- [ ] **Step 3:** Claude/Codex: strengthen always-on parent blocks with using-vibage pointer; optional native SessionStart only if documented — **never** require Cursor hook files for their PROJECT_ENTRY_OK.
- [ ] **Step 4:** Markers additive; MindOwnBuz re-install → `PROJECT_ENTRY_OK`.

### Task 1.3: Finishing (mandatory pack feel)

**Files:**
- Create: finishing section **inside** `using-vibage` (preferred) or dedicated skill **required** from issue-locate after DONE
- Modify: `skills/vibage-issue-locate/SKILL.md` — after dual reports DONE → **must** point to finishing (preview / handoff / stop; no soft CTA)

- [ ] **Step 1:** Owner-language finishing menu.
- [ ] **Step 2:** Hard pointer from issue-locate (not optional prose).
- [ ] **Step 3:** Dim4 evidence: owner path fixture with **0 owner-typed bash**.

**W1 DoD (hard):** Cursor hook + schema test green; three-platform parent verify green; finishing wired; owner 0-bash fixture; `TIER0_OK`; **no** “plausibly”; no remote/CI.

---

## Wave 2 — Stranger + owner clarity (dims 1, 3, 4, 5, 11)

**Goal:** A stranger understands and installs in ~60 seconds of reading; non-coder sees less jargon.

### Task 2.1: README stranger hero

**Files:** `README.md`

- [ ] **Step 1:** Top of README = brand + one sentence + three commands (install, parent-rule, verify-project-entry) + paste NEW-CHAT **or** “hooks will route”.
- [ ] **Step 2:** Move STATUS/plan deep links below the fold.
- [ ] **Step 3:** Keep honesty lines (≠ SaaS, ≠ publish-ready).

### Task 2.2: Per-surface INSTALL snippets

**Files:**
- Create: `docs/install/CURSOR.md`, `CLAUDE.md`, `CODEX.md` (short)
- Link from README

- [ ] **Step 1:** Each ≤ ~40 lines: install → parent rule → how you know it worked (`PROJECT_ENTRY_OK`).
- [ ] **Step 2:** `test_entry_docs_sync.sh` extended: README links these OR embeds equivalent.

### Task 2.3: NEW-CHAT + owner language pass

**Files:** `prompts/NEW-CHAT.md`, adapters

- [ ] **Step 1:** NEW-CHAT mentions parent entry verify / using-vibage.
- [ ] **Step 2:** Replace insider acronyms in entry surfaces with one plain sentence each (CONFIRM = “your OK on the scan plan”).
- [ ] **Step 3:** Re-run `test_entry_docs_sync.sh`.

**W2 DoD:** Dims 1,3,4,5,11 ≥9 by re-score rubric (see §Rubric); `TIER0_OK`.

---

## Wave 3 — Local pack-health + proof polish (dims 6, 7, 8, 9, 16, 18, 20)

**Goal:** One local command proves “pack is healthy” without lying that Tier-0 includes everything; map/handoff owner-facing clarity.

### Task 3.1: `scripts/pack-health.sh` (composite, not SSOT)

**Files:**
- Create: `scripts/pack-health.sh`
- Create: `tests/test_pack_health.sh` (∉ Tier-0; asserts not in test-tier0.sh)

- [ ] **Step 1:** Order: `verify-pins.sh` → `verify-project-entry.sh <parent>` → `tests/test_entry_docs_sync.sh` → `PACK_HEALTH_OK`.
- [ ] **Step 2:** Banner honesty lines (≠ Tier-0 ≠ remote CI ≠ letter B). STATUS documents three layers: TIER0 / PACK_HEALTH / PROJECT_ENTRY.
- [ ] **Step 3:** DoD parent: MindOwnBuz.

### Task 3.2: Optional-track “how to prove” card

**Files:** thin STATUS section or `docs/superpowers/specs/satellites/SAT-optional-proof.md`

- [ ] **Step 1:** Table: command → YES means → not.
- [ ] **Step 2:** Link usable tests + Focus summary path.

### Task 3.3: Focus evidence stub (git-safe)

**Files:** `docs/evidence/focus/` summaries only (NOT under gitignored `tests/artifacts/agent-pressure/`)

- [ ] **Step 1:** Commit run_ts + PASS/FAIL indices for Focus + B-path.
- [ ] **Step 2:** How to re-run scorer; full packs stay gitignore.

### Task 3.4: Map + handoff + local-complete checklist

**Files:** thin doc or STATUS

- [ ] **Step 1:** AI-first: JSON + mmd; human preview optional; one-command prettier.
- [ ] **Step 2:** Handoff locate-wave shaped checklist.
- [ ] **Step 3:** Local complete checklist = OK tokens only (`TIER0_OK`, `PROJECT_ENTRY_OK`, `PACK_HEALTH_OK`, optional usable OKs, focus summary path).

**W3 DoD:** Evidence for dims 6,7,8,9,16,18,20; pack-health green on MindOwnBuz; Tier-0 membership unchanged; then **mandatory 20-dim re-scorecard**.

---

## Out of this plan (Plan-P public — separate; **zero marketplace in Plan-S**)

| Item | Why separate |
|------|----------------|
| git remote / origin | User-owned |
| `.github/workflows` Tier-0 mirror | Needs origin (`SAT-ci-remote`) |
| Fill LICENSE copyright name | Legal identity |
| Cursor/Claude marketplace listing | Plan-P only |
| Claiming publish-ready | Honesty |

When user wants Plan-P: LICENSE → remote → workflow → stranger clone test → **then** dim 13 can move toward 9.

---

## Rubric (how we know “≥9”)

Re-score with **three lenses** (product / eng / ext) after each wave. A dimension is ≥9 only if:

1. **Evidence on tree** (script OK line, skill file, or install path) — not aspirational prose alone.
2. **Stranger or owner can hit the path in ≤3 commands** for UX dims.
3. **No honesty regression** (no fake SaaS/CI/Proven).

If a lens returns APPROVE_WITH_CHANGES, absorb must_fix before claiming the wave done.

---

## Suggested execution order

1. User approves this Plan-S.
2. Execute **W1** → 3-lens review → commit.
3. Execute **W2** → 3-lens review → commit.
4. Execute **W3** → 3-lens review → multi-agent **re-scorecard** (same 20 dims; expect dim 13 still low).
5. Only then offer **Plan-P** for remote/CI/marketplace.

---

## Success (Plan-S) — claim gate

**May claim “all non-exempt dims ≥9” only if ALL of:**

1. S1–S12 locks implemented.
2. W1–W3 DoDs green (no “plausibly”).
3. Post-W3 **same 20-dim multi-agent re-scorecard** returns ≥9 on every non-exempt dim.
4. Dim13 / marketplace / remote CI explicitly excluded in the claim sentence.
5. No honesty regression.

If dim4/12/14 lack behavior/fixture evidence, product lens **VETO** — do not claim Plan-S success.
