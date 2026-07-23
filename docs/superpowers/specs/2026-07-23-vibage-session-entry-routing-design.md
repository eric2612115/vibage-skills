# Vibage — Session entry routing (parent workspace) — Design

**Date:** 2026-07-23  
**Status:** Approach **A** locked; eng/ext must_fix absorbed; ready for plan/impl  
**Package SSOT:** `/Users/eric.fang/MindOwnBuz/vibage-skills`  
**Umbrella:** `docs/superpowers/specs/2026-07-23-vibage-v2-superpowers-grade-design.md`  
**Related:** `docs/superpowers/specs/2026-07-23-vibage-entry-docs-saas-blank-design.md` (entry docs / SaaS blank; distinct wave)

**Current audit (2026-07-23):** MindOwnBuz parent has **no** `.cursor/rules/vibage.mdc`, no Claude vibage block / `.claude/vibage-entry.md`, no AGENTS.md vibage block. Global skills alone ≠ project session routing.

---

## 1. Problem

Agents open sessions on a multi-repo parent workspace (e.g. MindOwnBuz) without a reliable, up-to-date **project-local** thin router:

1. **Skills installed globally** (`~/.cursor/skills`, etc.) do not equal **project entry routing**. Without parent adapters, sessions miss init→orient→issue-locate gates.
2. **`install.sh --with-project-rule`** already writes three platforms, but Cursor **skips** if `vibage.mdc` exists → **stale adapter** after package routing changes.
3. **No verify** proves a chosen parent has all platforms + key routing markers; easy to confuse “skills linked” with “parent entry green.”
4. Risk of **per-child-repo** rule sprawl or pasting nested locate procedure into entry surfaces.

---

## 2. Goals

**Approach A (locked):** parent-only install + verify of thin three-platform session routers.

1. Install/verify project entry **only** on the **parent workspace** (e.g. MindOwnBuz) — **not** every child repo.
2. Three platforms at parent:
   - Cursor: `.cursor/rules/vibage.mdc`
   - Claude: `CLAUDE.md` `<!-- vibage -->` block + `.claude/vibage-entry.md`
   - Codex: `AGENTS.md` vibage block (shared adapter OK)
3. Thin session routing content (markers required by verify):
   - hub missing → **vibage-init**
   - no valid CONFIRM → **vibage-orient**
   - CONFIRM OK → **vibage-issue-locate**
   - read package root **`STATUS.md` first** (capability SSOT)
   - **dual-STATUS** (package vs hub `docs/vibage/STATUS.md`)
   - **no** register CTA
   - **no** paste of nested locate procedure
4. New script: `scripts/verify-project-entry.sh <parent>` — **FAIL** if any platform missing or missing key routing markers; if no parent arg → **honest** message (do **not** pretend global skills == project routing).
5. Refresh stale adapters on update: prefer overwrite/update package-owned vibage markers, and/or `--force-project-entry` (see Design §4.3). Today’s “Skip if mdc exists” is a defect for this wave.
6. Keep `bash scripts/test-tier0.sh` → **`TIER0_OK`** after edits. Optional regression test ∉ Tier-0.
7. DoD includes: chosen parent (e.g. MindOwnBuz) **verify green** after install/refresh.

---

## 3. Non-goals (Out)

| Out | Why |
|-----|-----|
| SaaS / register / pairing / cloud Architecture Pass | Reserved blank; other SAT |
| Graphify deepen / map letter work | Separate maps plans |
| Marketplace publish | Not this wave |
| Per-child-repo rules (install under each nested `.git`) | Parent-only lock |
| Product skill body rewrites / dig procedure in adapters | Thin entry only |
| Claiming publish-ready or SaaS shipped | Honesty |

---

## 4. Design

### 4.1 Scope boundary (normative)

| In | Out |
|----|-----|
| Parent path passed to `--with-project-rule=<parent>` and `verify-project-entry.sh <parent>` | Recursive install into child repos |
| Package-owned adapter templates under `adapters/` | Editing unrelated owner CLAUDE/AGENTS content outside vibage markers |
| Thin routing + STATUS pointers + hard-stops pointer | Nested dig steps, dual-report templates, register CTA |

**Rule:** Global skill symlinks prove package install; **project entry verify** proves parent routers.

### 4.2 Thin routing contract (all three platforms)

Adapters remain short. Normative content (verify must detect via markers / rg):

| Marker / idea | Required |
|---------------|----------|
| Hub missing → vibage-init | Yes |
| No valid CONFIRM → vibage-orient | Yes |
| CONFIRM OK → vibage-issue-locate (legacy `vibage-locate` OK) | Yes |
| Package `STATUS.md` first | Yes |
| Dual-STATUS (package ≠ hub STATUS) | Yes |
| No register CTA | Yes (deny or explicit “no register CTA”) |
| No nested locate procedure paste | Yes (thin; no dig step lists) |
| Hard-stops → `$PKG_ROOT/references/hard-stops.md` | Preferred (pointer) |

Platform paths (parent `$PARENT`):

| Platform | Paths |
|----------|--------|
| Cursor | `$PARENT/.cursor/rules/vibage.mdc` |
| Claude | `$PARENT/CLAUDE.md` (marked block) + `$PARENT/.claude/vibage-entry.md` |
| Codex | `$PARENT/AGENTS.md` (marked block; **SSOT body** = `adapters/shared/AGENTS.vibage.md` only; keep `adapters/codex/` copy aligned for humans, install must not diverge) |

### 4.3 Install refresh (stale adapter fix)

**Today:** `install_project_rules` **skips** Cursor copy when `vibage.mdc` exists; Claude/AGENTS already **upsert** marked blocks / rewrite `vibage-entry.md`. Also gates writes on `--surfaces=` → Claude-only install can leave Cursor/Codex missing while product promises three-platform verify.

**Required change (Approach A):**

1. **`--with-project-rule=<parent>` always writes all three platforms** — **ignore** `--surfaces=` for project-entry paths (surfaces still filter global skill links only).
2. **Default refresh:** overwrite Cursor `vibage.mdc` from package adapter every time (no Skip-forever). Claude: upsert + overwrite `vibage-entry.md`. Codex: upsert from **shared** AGENTS adapter only.
3. `--force-project-entry` is optional **alias** for the same refresh (no second conservative code path).
4. Do **not** delete owner content outside vibage markers (or Cursor whole-file package-owned rule).
5. Legacy `vibage-locate.mdc`: note only; **no auto-delete** this wave.
6. Future per-child entry = **new Approach** — must not silently recurse `--with-project-rule`.

### 4.4 Verify script

`scripts/verify-project-entry.sh <parent>`:

| Case | Behavior |
|------|----------|
| No `<parent>` arg | Exit non-zero; print honest help: global skills ≠ project routing; usage requires parent path |
| Parent missing / not a dir | FAIL |
| Any of three platforms missing files/blocks | FAIL |
| Files present but missing key routing markers (init / orient / issue-locate / STATUS-first / dual-STATUS / no CTA) | FAIL |
| Positive CTA / Soft CTA / nested-procedure dump (executable denylist) | FAIL |
| All present + markers | Print OK (`PROJECT_ENTRY_OK`) exit 0 |

**Marker SSOT:** one list inside `verify-project-entry.sh` (or a tiny shared marker file). Adapters consume the same required strings; do not invent per-platform marker dialects.

**Negative rules (executable):** rg denylist for Soft CTA / register-now class phrases; require explicit thin-entry phrase e.g. `do not paste nested locate procedure`. Skill names (vibage-issue-locate) are allowed; **procedure dump** is not.

`PROJECT_ENTRY_OK` ≠ hub CONFIRM / locate DONE.

Not wired into Tier-0. Optional `tests/test_verify_project_entry.sh` — **∉** `test-tier0.sh`.

### 4.5 Relationship to docs-saas-blank wave

- That wave owns README / NEW-CHAT / `SAT-saas-blank` honesty.
- This wave owns **parent adapter install + verify + stale refresh**.
- Shared locks: dual-STATUS, STATUS-first, no register CTA, thin dispatcher (no nested locate paste).

### 4.6 Approach comparison (locked)

| Approach | Summary | Decision |
|----------|---------|----------|
| **A** | Parent-only three-platform thin routers + verify + refresh-on-update | **Locked** |
| B | Per-child-repo rules | Rejected — sprawl |
| C | Rely on global skills only | Rejected — audit shows MindOwnBuz has no project entry |

---

## 5. Files

| Path | Action |
|------|--------|
| `docs/superpowers/specs/2026-07-23-vibage-session-entry-routing-design.md` | This design (create) |
| `adapters/cursor/vibage.mdc` | Ensure thin contract markers; package SSOT for Cursor |
| `adapters/claude/CLAUDE.vibage.md` | Same markers; feeds CLAUDE.md block + vibage-entry |
| `adapters/shared/AGENTS.vibage.md` (and/or `adapters/codex/AGENTS.vibage.md`) | Same markers; keep bodies aligned |
| `scripts/install.sh` | Refresh Cursor mdc; optional `--force-project-entry`; keep `--with-project-rule=<parent>` |
| `scripts/verify-project-entry.sh` | Create |
| `tests/test_verify_project_entry.sh` | Optional; **∉** Tier-0 |
| Parent (e.g. MindOwnBuz) entry files | Produced by install — **outside** package tree; DoD via verify |

**Out of touch this wave:** SaaS product, Graphify deepen, marketplace, child-repo rule trees, Tier-0 suite membership.

---

## 6. Success criteria (auditable)

1. `bash scripts/install.sh --with-project-rule=<parent>` (plus any force flag if required) writes/refreshes all three platforms on `<parent>`.
2. `bash scripts/verify-project-entry.sh <parent>` → green (`PROJECT_ENTRY_OK` or equivalent) for chosen parent (DoD: **MindOwnBuz** after install — currently red / missing).
3. `verify-project-entry.sh` with **no args** fails honestly (no false green from global skills).
4. Re-running install after adapter template change **updates** Cursor `vibage.mdc` (no permanent Skip-stale).
5. `bash scripts/test-tier0.sh` still ends with **`TIER0_OK`**.
6. Optional verify unit test green if present — still **≠** Tier-0 membership.

**Explicitly not success:**

- ≠ publish-ready / remote CI / marketplace  
- ≠ SaaS shipped  
- ≠ Graphify / letter-map Proven rewrite  

---

## 7. Honesty

- Global skill install **≠** parent session routing until verify is green.
- Parent entry green **≠** hub CONFIRM / locate DONE.
- Package `STATUS.md` remains capability SSOT; hub STATUS remains init/orient only.
- Success of this design **≠** publish-ready **≠** SaaS.
- Current MindOwnBuz audit: entry missing — do not claim routing until verify passes.

---

## 8. Frozen locks (index)

| ID | Lock |
|----|------|
| A0 | Approach A — parent-only three-platform thin routers + verify + refresh |
| A1 | Install/verify **parent workspace only** — not every child repo |
| A2 | Platforms: Cursor `.cursor/rules/vibage.mdc`; Claude `CLAUDE.md` block + `.claude/vibage-entry.md`; Codex `AGENTS.md` block |
| A3 | Thin routing: hub missing→init; no CONFIRM→orient; CONFIRM→issue-locate; package STATUS first; dual-STATUS; no register CTA; no nested locate paste |
| A4 | `scripts/verify-project-entry.sh <parent>` — FAIL on missing platform/markers; honest fail if no parent arg |
| A5 | Stale adapter fix: update/overwrite package-owned vibage markers and/or `--force-project-entry` (end state: no Skip-forever stale mdc) |
| A6 | Optional verify test ∉ Tier-0; **`TIER0_OK` required** after edits |
| A7 | Out: SaaS, Graphify deepen, marketplace, per-child-repo rules |
| A8 | Success ≠ publish-ready ≠ SaaS |
| A9 | DoD: verify green for chosen parent (MindOwnBuz) after install — audit today: no vibage.mdc |
| A10 | `--with-project-rule` writes **all three** platforms; ignore `--surfaces=` for entry files |
| A11 | Cursor mdc always overwrite on project-rule; `--force-project-entry` alias only |
| A12 | AGENTS body SSOT = `adapters/shared/AGENTS.vibage.md` |
| A13 | Verify marker/denylist executable + centralized; no auto-delete legacy mdc |
| A14 | `PROJECT_ENTRY_OK` ≠ CONFIRM / locate DONE |
