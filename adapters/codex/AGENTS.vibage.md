<!-- vibage:start -->
# Vibage (agent entry)

Product SSOT: vibage-skills package (skills + `references/`). Thin entry only — follow the skill bodies.
Package capability SSOT: package root `STATUS.md` (hub `docs/vibage/STATUS.md` is init/orient only).
Thin entry only — do not paste nested locate procedure.
Session routing: follow **using-vibage** (pointer skill). Parent routers remain SSOT — no second state machine.
Owner: do not type bash; agent runs install/verify/pins scripts. no register CTA.
If owner says **幫我裝 Vibage** / install Vibage → follow using-vibage § Install continuum:
entry (`PROJECT_ENTRY_OK`) → plain explain → init-hub → **vibage-pile-index** (`PILE_INDEX_OK`) → then ask ticket/pain.
Do not claim installed without verify. Do not dig yet.

## Skill routing

1. No `docs/vibage/STATUS.md` → **vibage-init** (install + hub; no dig, no dual reports).
2. Hub ready, no qualified map (unless MAP_SKIP) → **vibage-pile-index**.
3. Map ready, no valid CONFIRM (= owner OK on the scan plan; file `docs/vibage/CONFIRM.json`) → **vibage-orient** (stop until owner confirms).
4. CONFIRM OK → **vibage-issue-locate** (runs gate; nested dig + dual reports; legacy `vibage-locate` OK).
5. Paste NEW-CHAT / unclear install → **vibage-bootstrap** or **vibage-init** (then using-vibage).
6. Optional (not required for locate DONE): **vibage-issue-fix**, **vibage-arch-review**.

Read package `STATUS.md` first (capability SSOT) before expanding scope.
After locate DONE → finishing options in **using-vibage** (required).

Best-available on Codex/AGENTS: this always-on block (Cursor-only hook files are **not** required). See `references/host-best-session-entry.md`.

## PKG_ROOT

```bash
bash /path/to/vibage-skills/scripts/resolve-pkg-root.sh
```

Or probe `~/.cursor/skills` → `~/.claude/skills` → `~/.agents/skills` for `vibage-init` then `vibage-issue-locate` (realpath → dirname/dirname).

## Hard stops

Read and obey `$PKG_ROOT/references/hard-stops.md`. no register CTA (SaaS reserved blank).
<!-- vibage:end -->
