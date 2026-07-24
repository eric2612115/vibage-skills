---
name: using-vibage
description: >-
  Use when starting any Vibage conversation, when the owner says install Vibage
  / 幫我裝 Vibage, or when routing is unclear. Must run before dig. Do not paste
  nested locate procedure here.
---

<EXTREMELY-IMPORTANT>
If the owner mentions Vibage, install, parent workspace routing, or locate/where
a problem lives — invoke this skill first. Prefer Skill tool / Read this file
before improvising shell or dig steps.
Never claim install success without PROJECT_ENTRY_OK on the PARENT workspace.
</EXTREMELY-IMPORTANT>

# Using Vibage

Thin router only. **Parent project entry** (`.cursor/rules/vibage.mdc` / `CLAUDE.md` / `AGENTS.md`) is the routing table SSOT. This skill does **not** invent a second state machine.

## Plain milestones (F11 — owner chat)

Say these in owner language (no jargon):

| Done | Means | Not yet |
|------|-------|---------|
| Entry OK | Parent routers on disk (`PROJECT_ENTRY_OK`) | Hub / graph / dig |
| Hub ready | Checklist folder `docs/vibage/` exists | Graph / dig |
| Graph floor | Structural index (`GRAPH_FLOOR_OK`; `PILE_INDEX_OK` = wrapper echo) | Matrix / dig |
| Matrix sweep | Env×branch cells terminal; 掃透 only if `MATRIX_SWEEP_SUBSTANTIVE_OK` | Dig |
| Scene brief | When a scene is set: `SCENE_BRIEF_OK` (+ cover via `verify-scene-cover`) | Confirm / dig |
| Confirm | Owner OK on this ticket’s hot path | Dig reports |

Optional nested dossiers (`MAP_DEEPEN_OK`) / dimension fill are **deferred** this wave — never Gate A “understood” / never “ready after install alone.”

## Gate A slogans (narrative honesty — ≠ dig auth)

| Claim language | Requires |
|----------------|----------|
| Floor / qualified map narrative | `UNDERSTANDING_ROLLUP_OK` (matrix not required) |
| 矩陣終態／無漏掃 | `ENV_BRANCH_MATRIX_OK` |
| 全環境全 branch 掃透 | **`MATRIX_SWEEP_SUBSTANTIVE_OK` only** |
| 多領域立體場景切換 | `SCENE_BRIEF_OK` + `verify-scene-cover.sh` exit 0 |

Gate A ≠ Gate B (orient → CONFIRM → `assert_gate` → dig).  
`PILE_INDEX_OK` / `MAP_DEEPEN_OK` must **not** be narrated as full-understanding or dig-ready by themselves.

## Install phrase / continuum (C′)

Trigger examples: `幫我裝 Vibage` · `Please install Vibage` · Vibage intent on a parent with missing entry.

**Authoritative continuum:**

`PROJECT_ENTRY_OK` → hub → `GRAPH_FLOOR_OK` → matrix sweep → **optional deferred dimension fill** → ticket **or** scene switch → **`SCENE_BRIEF_OK` when scene set** → orient → CONFIRM → locate.

Agent **must** (owner: do not type bash):

1. Resolve `PKG_ROOT`.
2. If workspace looks like a **child** repo (parent missing entry, skills global only) → explain honestly; **do not** install rules into the child; ask to open the **parent** folder (S03).
3. `bash "$PKG_ROOT/scripts/install.sh"`
4. `bash "$PKG_ROOT/scripts/install.sh" --with-project-rule="$PARENT"` — **required**, not optional. Refuses fake-green without it (S02).
5. `bash "$PKG_ROOT/scripts/verify-project-entry.sh" "$PARENT"` → must print `PROJECT_ENTRY_OK` (includes `alwaysApply: true` on Cursor mdc). **Do not** say “installed” until this passes.
6. `bash "$PKG_ROOT/scripts/verify-pins.sh"`; on fail use `DEPENDENCIES.md` recovery.
7. Plain explain (owner language):
   - init = “set up a small checklist folder here”
   - graph / pile-index = “list every app folder and how they seem linked — not read every file”
   - matrix = “check env/branch evidence cells (掃透 only when substantive OK)”
   - orient = “for this ticket, which hot path on the map?”
   - Explicitly: **not** SaaS signup; **not** Graphify-first; **not** embedding pipelines as memory
8. If hub missing → `bash "$PKG_ROOT/scripts/install.sh" --init-hub="$PARENT"` (or follow `vibage-init`).
9. Hand to **`vibage-pile-index`** → expect `GRAPH_FLOOR_OK` (script also echoes `PILE_INDEX_OK` for freeze compat). Continuum exit ≠ “intent only” (F15).
10. After graph floor: run matrix path (`c-prime-fill` / inventory + cell sweep). May accept ticket with honest “matrix incomplete” disclosure; **never** claim 掃透 without `MATRIX_SWEEP_SUBSTANTIVE_OK`. Dimension fill = **deferred** (skip).
11. Ticket / pain **or** scene switch: if scene set → `scene-brief` + expect `SCENE_BRIEF_OK`; stereoscopic cover via `verify-scene-cover.sh` (independent of matrix).
12. Hand to **`vibage-orient`** → CONFIRM → **`vibage-issue-locate`**. **No dig / no dual reports** until CONFIRM. Optional `MAP_DEEPEN_OK` ≠ CONFIRM ≠ dig-all ≠ Gate A understood.

Canonical paste: `prompts/SAY-INSTALL-VIBAGE.md`.  
Re-run: `bash tests/test_install_phrase_e2e.sh` → `INSTALL_PHRASE_E2E_OK`.

## On session start / unclear intent (S08)

1. Resolve `PKG_ROOT`; verify-pins (agent).
2. Read package `STATUS.md`.
3. Follow **parent** routing (mdc/CLAUDE/AGENTS — hooks may drop; alwaysApply mdc is reliable):
   - No hub → **vibage-init**
   - Hub ready, no graph floor (and no owner `MAP_SKIP`) → **vibage-pile-index** → then matrix sweep (`c-prime-fill` path)
   - Scene set / switch → scene-brief → `SCENE_BRIEF_OK`; 多領域立體場景切換 also needs `verify-scene-cover.sh` exit 0
   - Map/graph ready, no valid CONFIRM → **vibage-orient**
   - CONFIRM OK → **vibage-issue-locate**
4. Dual-STATUS: package `STATUS.md` ≠ hub `docs/vibage/STATUS.md`.
5. Thin entry — no nested locate paste; no register CTA.

## Lifecycle

`PROJECT_ENTRY_OK → hub → GRAPH_FLOOR_OK → matrix sweep → (optional deferred dimension fill) → ticket or scene → SCENE_BRIEF_OK when scene set → orient → CONFIRM → locate → finish`

## Finishing (required after locate success)

Owner-language only (no soft CTA / no register / no pairing / no API-key / no Architecture Pass upsell):

1. Optional localhost preview — fail-soft  
2. Handoff / STOP if mid-fail  
3. Stop — local delivery complete  
4. Optional issue-fix / 架構檢視 **only if owner asks**

### Cost / deepen talk (any time)

Stay **local**: skip optional deepen/dimension fill, thin graph + hot path, shrink `planned_dig_ids`, `Mode: degraded`.  
Do **not** push register / cloud / “Architecture Pass is cheaper.” SaaS stays blank in package `STATUS.md`.

## Maps / extending

- Map context for agents: `docs/maps/AI-FIRST.md`
- Extending the pack: `docs/EXTENDING.md`
- C′ freeze-lift: `docs/superpowers/specs/2026-07-25-vibage-c-prime-freeze-lift.md`

## Hard stops

Obey `$PKG_ROOT/references/hard-stops.md`.
