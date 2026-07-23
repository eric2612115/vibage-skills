# Host-best session entry (Plan-S / Plan-R)

Parent workspace only. Global skills ≠ project routing.

| Host | Best-available injection | Reliable path today | Verify bar |
|------|--------------------------|---------------------|------------|
| Cursor | Project `.cursor/hooks.json` `sessionStart` → `.cursor/hooks/vibage-session-start.sh` | **Also** alwaysApply `.cursor/rules/vibage.mdc` (Cursor may drop `additional_context` due to known race — mdc is the reliable router) | Hook files present + script dry-run JSON; mdc markers |
| Claude | Always-on `CLAUDE.md` vibage block + `.claude/vibage-entry.md` | Same | Markers; do **not** require Cursor hook files |
| Codex | `AGENTS.md` vibage block | Same | Markers; do **not** require Cursor hook files |

Dim12 ≥9 means: parent session can route **without pasting NEW-CHAT** via best-available per host — **not** identical SessionStart binaries on all three.

Hooks / using-vibage only **point** at parent routers — no second state machine. No child-repo rule spread.
