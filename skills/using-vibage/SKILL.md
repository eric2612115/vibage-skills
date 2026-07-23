---
name: using-vibage
description: >-
  Use when starting any Vibage conversation on a parent workspace, or when
  routing is unclear. Establishes session routing via parent entry + package
  STATUS. Do not paste nested locate procedure here.
---

# Using Vibage

Thin router only. **Parent project entry** (`.cursor/rules/vibage.mdc` / `CLAUDE.md` / `AGENTS.md`) is the routing table SSOT. This skill does **not** invent a second init→orient→locate state machine.

## Owner path (non-coder)

- Owner: do not type bash. The agent runs install/verify/pins scripts.
- Prefer opening a chat on the **parent** workspace after `install.sh --with-project-rule=<parent>` (agent/operator runs that once).
- Pasting `prompts/NEW-CHAT.md` is optional when session entry + this skill already route.

## On session start / unclear intent

1. Resolve `PKG_ROOT` (`scripts/resolve-pkg-root.sh` or skill-home probe).
2. Run `scripts/verify-pins.sh` (agent runs it). On fail → owner-language pin recovery from `DEPENDENCIES.md`.
3. Read package root `STATUS.md` (capability SSOT) before expanding scope.
4. Follow **parent** skill routing:
   - No hub `docs/vibage/STATUS.md` → **vibage-init**
   - Hub ready, no valid CONFIRM → **vibage-orient**
   - CONFIRM OK → **vibage-issue-locate**
5. Dual-STATUS: package `STATUS.md` ≠ hub `docs/vibage/STATUS.md`.
6. Thin entry only — do not paste nested locate procedure. no register CTA.

## Lifecycle

`route → work (init|orient|locate|optional) → finish`

## Finishing (required after locate success)

When locate reaches dual reports / phase `done`, **must** offer owner-language options (no soft CTA / no register):

1. Optional localhost preview (`serve-preview.sh`) — fail-soft
2. Handoff / STOP next step if mid-fail
3. Stop — local delivery complete
4. Optional tracks only if owner asks: issue-fix / 架構檢視 (locate DONE independent)

Do not invent cloud deepen / Architecture Pass from finishing.

## Hard stops

Obey `$PKG_ROOT/references/hard-stops.md`.
