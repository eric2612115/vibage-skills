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
| Entry OK | Parent routers on disk (`PROJECT_ENTRY_OK`) | Hub / map / dig |
| Hub ready | Checklist folder `docs/vibage/` exists | Map / dig |
| Map draft | Pile index wrote `service_map` (`PILE_INDEX_OK`) | Confirm / dig |
| Confirm | Owner OK on this ticket’s hot path | Dig reports |

## Install phrase / continuum (S01–S04-amended, F9)

Trigger examples: `幫我裝 Vibage` · `Please install Vibage` · Vibage intent on a parent with missing entry.

Agent **must** (owner: do not type bash):

1. Resolve `PKG_ROOT`.
2. If workspace looks like a **child** repo (parent missing entry, skills global only) → explain honestly; **do not** install rules into the child; ask to open the **parent** folder (S03).
3. `bash "$PKG_ROOT/scripts/install.sh"`
4. `bash "$PKG_ROOT/scripts/install.sh" --with-project-rule="$PARENT"` — **required**, not optional. Refuses fake-green without it (S02).
5. `bash "$PKG_ROOT/scripts/verify-project-entry.sh" "$PARENT"` → must print `PROJECT_ENTRY_OK` (includes `alwaysApply: true` on Cursor mdc). **Do not** say “installed” until this passes.
6. `bash "$PKG_ROOT/scripts/verify-pins.sh"`; on fail use `DEPENDENCIES.md` recovery.
7. Plain explain (owner language):
   - init = “set up a small checklist folder here”
   - map / pile-index = “list every app folder and how they seem linked — not read every file”
   - orient = “for this ticket, which hot path on the map?”
   - Explicitly: **not** SaaS signup; **not** Graphify-first
8. If hub missing → `bash "$PKG_ROOT/scripts/install.sh" --init-hub="$PARENT"` (or follow `vibage-init`).
9. Hand to **`vibage-pile-index`** → expect `PILE_INDEX_OK` (map draft on disk). Continuum exit ≠ “intent only” (F15).
10. **Only after map draft:** ask for ticket / what hurts. Do **not** ask “which repos?” as a substitute for full index (F9/F10).
11. **No dig / no dual reports** until CONFIRM.

Canonical paste: `prompts/SAY-INSTALL-VIBAGE.md`.  
Re-run: `bash tests/test_install_phrase_e2e.sh` → `INSTALL_PHRASE_E2E_OK`.

## On session start / unclear intent (S08)

1. Resolve `PKG_ROOT`; verify-pins (agent).
2. Read package `STATUS.md`.
3. Follow **parent** routing (mdc/CLAUDE/AGENTS — hooks may drop; alwaysApply mdc is reliable):
   - No hub → **vibage-init**
   - Hub ready, no qualified map (and no owner `MAP_SKIP`) → **vibage-pile-index**
   - Map ready, no valid CONFIRM → **vibage-orient**
   - CONFIRM OK → **vibage-issue-locate**
4. Dual-STATUS: package `STATUS.md` ≠ hub `docs/vibage/STATUS.md`.
5. Thin entry — no nested locate paste; no register CTA.

## Lifecycle

`install entry → explain → init-hub → pile-index → ticket intake → orient → confirm → locate → finish`

## Finishing (required after locate success)

Owner-language only (no soft CTA / no register / no pairing / no API-key / no Architecture Pass upsell):

1. Optional localhost preview — fail-soft  
2. Handoff / STOP if mid-fail  
3. Stop — local delivery complete  
4. Optional issue-fix / 架構檢視 **only if owner asks**

## Maps / extending

- Map context for agents: `docs/maps/AI-FIRST.md`
- Extending the pack: `docs/EXTENDING.md`

## Hard stops

Obey `$PKG_ROOT/references/hard-stops.md`.
