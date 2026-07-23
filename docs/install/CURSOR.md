# Vibage on Cursor (short)

**Parent workspace only** — do not install routers into every child repo.  
Commands below are for operator/agent; owner can ask in plain language after setup.

Plugin manifest: `.cursor-plugin/plugin.json` (skills + `adapters/cursor/vibage.mdc`).  
Marketplace submit steps: [`MARKETPLACE.md`](MARKETPLACE.md). Plugin install ≠ `PROJECT_ENTRY_OK`.

After parent entry: agent continuum is init-hub → `pile-index.sh` (`PILE_INDEX_OK`) → ask ticket.  
`vibage.mdc` must stay `alwaysApply: true` (verify enforces this).

## Install

```bash
bash /path/to/vibage-skills/scripts/install.sh --surfaces=cursor,claude,codex
bash /path/to/vibage-skills/scripts/install.sh \
  --with-project-rule=/path/to/parent-workspace
bash /path/to/vibage-skills/scripts/verify-project-entry.sh \
  /path/to/parent-workspace
# expect: PROJECT_ENTRY_OK
```

## How you know it worked

| Check | Expect |
|-------|--------|
| Parent file | `.cursor/rules/vibage.mdc` |
| Hooks | `.cursor/hooks.json` + `.cursor/hooks/vibage-session-start.sh` |
| Verify | `PROJECT_ENTRY_OK` |

Open a chat on the **parent** folder. Agent follows **using-vibage** + the rule.  
If hook context is dropped (known Cursor race), the `.mdc` rule still routes — see `references/host-best-session-entry.md`.

Owner: do not type bash; ask in plain language.
