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
</EXTREMELY-IMPORTANT>

# Using Vibage

Thin router only. **Parent project entry** (`.cursor/rules/vibage.mdc` / `CLAUDE.md` / `AGENTS.md`) is the routing table SSOT. This skill does **not** invent a second init→orient→locate state machine.

## Install phrase (owner may say only this)

Trigger examples: `幫我裝 Vibage` · `Please install Vibage` · `install vibage for this folder`.

Agent **must** (owner: do not type bash):

1. Resolve `PKG_ROOT`.
2. `bash "$PKG_ROOT/scripts/install.sh"` (default cursor,claude,codex).
3. `bash "$PKG_ROOT/scripts/install.sh" --with-project-rule="$PARENT"` (PARENT = this workspace root).
4. `bash "$PKG_ROOT/scripts/verify-project-entry.sh" "$PARENT"` → expect `PROJECT_ENTRY_OK`.
5. `bash "$PKG_ROOT/scripts/verify-pins.sh"`; on fail use owner-language recovery from `DEPENDENCIES.md`.
6. Stop. Tell the owner install is ready; ask what hurts in plain language. **Do not dig yet.**

Canonical paste: `prompts/SAY-INSTALL-VIBAGE.md`. Fixture: `tests/fixtures/install-vibage-phrase.md`.

## Owner path (non-coder)

- Owner: do not type bash. The agent runs install/verify/pins scripts.
- After install: owner only answers “yes/no / which apps matter” style confirms.
- Plain words: **CONFIRM** = your OK on the scan plan. **Hub checklist** = `docs/vibage/STATUS.md`. **Product capability table** = package `STATUS.md`.

## On session start / unclear intent

1. Resolve `PKG_ROOT`.
2. Run `verify-pins.sh` (agent).
3. Read package `STATUS.md` before expanding scope.
4. Follow **parent** routing:
   - No hub checklist → **vibage-init**
   - Hub ready, no CONFIRM → **vibage-orient**
   - CONFIRM OK → **vibage-issue-locate**
5. Dual-STATUS: package `STATUS.md` ≠ hub `docs/vibage/STATUS.md`.
6. Thin entry — do not paste nested locate procedure. no register CTA.

## Lifecycle

`install (optional) → route → work (init|orient|locate|optional) → finish`

## Finishing (required after locate success)

When dual reports exist / phase `done`, **must** offer owner-language options (no soft CTA / no register):

1. Optional localhost preview — fail-soft  
2. Handoff / STOP if mid-fail  
3. Stop — local delivery complete  
4. Optional issue-fix / 架構檢視 **only if owner asks**

Map context for agents: `docs/maps/AI-FIRST.md`. Extending the pack: `docs/EXTENDING.md`.

## Hard stops

Obey `$PKG_ROOT/references/hard-stops.md`.
