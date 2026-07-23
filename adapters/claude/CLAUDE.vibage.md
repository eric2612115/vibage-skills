<!-- vibage:start -->
# Vibage (Claude Code entry)

Product SSOT lives in the vibage-skills package. Skills are linked under `~/.claude/skills/` and optionally `.claude/skills/`.

## Skill routing

1. No `docs/vibage/STATUS.md` → Read/follow **vibage-init**.
2. Hub ready, no valid CONFIRM → **vibage-orient** (stop at awaiting_confirm).
3. CONFIRM OK → **vibage-issue-locate** (`assert_gate` then dig; legacy `vibage-locate` OK).
4. NEW-CHAT / install unclear → **vibage-bootstrap** or **vibage-init**.
5. SelfAutoBuz doc taxonomy → **docs-hygiene**, not locate.

## PKG_ROOT

Prefer: `bash <vibage-skills>/scripts/resolve-pkg-root.sh`  
Fallback: realpath `~/.claude/skills/vibage-init` (then `vibage-issue-locate`) → dirname/dirname.

## Nested / browser

Use Claude Code Agent/subagents when available; else `Mode: degraded`. Soft CTA: open site URL in browser/MCP or give the human the URL — agent sessions usually lack the site's httpOnly cookie.

## Hard stops

`$PKG_ROOT/references/hard-stops.md`
<!-- vibage:end -->
