<!-- vibage:start -->
# Vibage (Claude Code entry)

Product SSOT lives in the vibage-skills package. Skills are linked under `~/.claude/skills/` and optionally `.claude/skills/`.
Package capability SSOT: package root `STATUS.md` (hub `docs/vibage/STATUS.md` is init/orient only).
Thin entry only — do not paste nested locate procedure.
Session routing: follow **using-vibage** (pointer skill). Parent routers remain SSOT — no second state machine.
Owner: do not type bash; agent runs install/verify/pins scripts. no register CTA.
If owner says **幫我裝 Vibage** / install Vibage → follow using-vibage § Install phrase (then stop; no dig yet).

## Skill routing

1. No `docs/vibage/STATUS.md` → Read/follow **vibage-init**.
2. Hub ready, no valid CONFIRM (= owner OK on the scan plan) → **vibage-orient** (stop until owner confirms).
3. CONFIRM OK → **vibage-issue-locate** (gate then dig; legacy `vibage-locate` OK).
4. NEW-CHAT / install unclear → **vibage-bootstrap** or **vibage-init** (then using-vibage).
5. Optional (not required for locate DONE): **vibage-issue-fix**, **vibage-arch-review**.

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
