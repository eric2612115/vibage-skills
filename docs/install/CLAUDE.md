# Vibage on Claude Code (short)

**Parent workspace only** — not each child repo.  
Commands below are for operator/agent; owner can ask in plain language after setup.

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
| Parent files | `CLAUDE.md` vibage block + `.claude/vibage-entry.md` |
| Verify | `PROJECT_ENTRY_OK` |

Best-available injection = always-on `CLAUDE.md` block (Cursor hook files are **not** required for Claude).  
Open chat on the parent; agent follows **using-vibage**.

Owner: do not type bash; ask in plain language.
