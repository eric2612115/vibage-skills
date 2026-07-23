<!-- vibage:start -->
# Vibage (Claude Code entry)

Product SSOT lives in the vibage-skills package. Skills are linked under `~/.claude/skills/` and optionally `.claude/skills/`.
Package capability SSOT: package root `STATUS.md` (hub `docs/vibage/STATUS.md` is init/orient only).
Thin entry only — do not paste nested locate procedure.
Session routing: follow **using-vibage** (pointer skill). Parent routers remain SSOT — no second state machine.
Owner: do not type bash; agent runs install/verify/pins scripts. no register CTA.
If owner says **幫我裝 Vibage** / install Vibage → follow using-vibage § Install continuum:
entry (`PROJECT_ENTRY_OK`) → plain explain → init-hub → **vibage-pile-index** (`PILE_INDEX_OK`) → then ask ticket/pain.
Do not claim installed without verify. Do not dig yet. Cursor hook files are **not** required for Claude success.

## Skill routing

1. No `docs/vibage/STATUS.md` → Read/follow **vibage-init**.
2. Hub ready, no qualified map (unless MAP_SKIP) → **vibage-pile-index**.
3. Map ready, no valid CONFIRM (= owner OK on the scan plan) → **vibage-orient** (stop until owner confirms).
4. CONFIRM OK → **vibage-issue-locate** (gate then dig; legacy `vibage-locate` OK).
5. NEW-CHAT / install unclear → **vibage-bootstrap** or **vibage-init** (then using-vibage).
6. Optional (not required for locate DONE): **vibage-issue-fix**, **vibage-arch-review**.

Read package `STATUS.md` first (capability SSOT) before expanding scope.
After locate DONE → finishing options in **using-vibage** (required).

Best-available on Claude: this always-on block (Cursor-only hook files are **not** required). See `references/host-best-session-entry.md`.

## PKG_ROOT

Prefer: `bash <vibage-skills>/scripts/resolve-pkg-root.sh`  
Fallback: realpath `~/.claude/skills/vibage-init` (then `vibage-issue-locate`) → dirname/dirname.

## Nested / browser

Use Claude Code Agent/subagents when available; else `Mode: degraded`. Preview is fail-soft — no register CTA.

## Hard stops

`$PKG_ROOT/references/hard-stops.md`
<!-- vibage:end -->
