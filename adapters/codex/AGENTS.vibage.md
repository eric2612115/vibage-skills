<!-- vibage:start -->
# Vibage (agent entry)

Product SSOT: vibage-skills package (skills + `references/`). Thin entry only — follow the skill bodies.
Package capability SSOT: package root `STATUS.md` (hub `docs/vibage/STATUS.md` is init/orient only).

## Skill routing

1. No `docs/vibage/STATUS.md` → **vibage-init** (install + hub; no dig, no dual reports).
2. Hub ready, no valid `docs/vibage/CONFIRM.json` → **vibage-orient** (SCAN_PLAN; stop at awaiting_confirm).
3. CONFIRM OK → **vibage-issue-locate** (runs `assert_gate`; nested dig + dual reports; legacy `vibage-locate` OK).
4. Paste NEW-CHAT / unclear install → **vibage-bootstrap** or **vibage-init**.
5. Optional (not required for locate DONE): **vibage-issue-fix**, **vibage-arch-review**.

## PKG_ROOT

```bash
bash /path/to/vibage-skills/scripts/resolve-pkg-root.sh
```

Or probe `~/.cursor/skills` → `~/.claude/skills` → `~/.agents/skills` for `vibage-init` then `vibage-issue-locate` (realpath → dirname/dirname).

## Hard stops

Read and obey `$PKG_ROOT/references/hard-stops.md`. No register CTA (SaaS reserved blank).
<!-- vibage:end -->
