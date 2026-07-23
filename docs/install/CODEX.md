# Vibage on Codex (short)

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
| Parent file | `AGENTS.md` vibage block |
| Verify | `PROJECT_ENTRY_OK` |

Best-available injection = always-on `AGENTS.md` block (Cursor hook files are **not** required for Codex).  
Open chat on the parent; agent follows **using-vibage**.

Owner: do not type bash; ask in plain language.
