# Vibage plugin / marketplace materials

**Honesty:** These manifests ship skills for Cursor / Claude Code.  
They are **≠** parent `PROJECT_ENTRY_OK`, **≠** Cursor official listing until you submit and pass review, **≠** SaaS.

Capability SSOT: package [`STATUS.md`](../../STATUS.md).

## What is in the repo

| Path | Host |
|------|------|
| `.cursor-plugin/plugin.json` | Cursor plugin manifest (skills + thin rule) |
| `.claude-plugin/plugin.json` | Claude Code plugin identity |
| `.claude-plugin/marketplace.json` | Claude marketplace catalog (`source: ./`) |
| `assets/logo.svg` | Cursor listing logo (relative path) |
| `skills/` | Discovered by both hosts |

Parent routers / Cursor `sessionStart` hooks still come from `install.sh --with-project-rule=<parent>` (see [`CURSOR.md`](CURSOR.md) / [`CLAUDE.md`](CLAUDE.md)).

## Cursor — local test then submit

1. Repo must be **public** for marketplace review.
2. Local load (operator): follow [Cursor plugins](https://cursor.com/docs/plugins) — e.g. copy/link into `~/.cursor/plugins/local` or your host’s local plugin path, then open a chat and invoke **using-vibage**.
3. Still wire the **parent** workspace: say **幫我裝 Vibage** or run install with `--with-project-rule`.
4. Submit: sign in → [cursor.com/marketplace/publish](https://cursor.com/marketplace/publish) → paste  
   `https://github.com/eric2612115/vibage-skills`  
5. Manual review may take days; listing ≠ SaaS ≠ publish-ready slogan.

## Claude Code — marketplace add / install

From Claude Code (public or local git clone):

```text
/plugin marketplace add eric2612115/vibage-skills
/plugin install vibage@vibage
```

Or test a checkout without publishing:

```bash
claude --plugin-dir /path/to/vibage-skills
```

Then on the **parent** workspace, still run parent entry (幫我裝 Vibage / `install.sh --with-project-rule`).

Validate locally if your Claude CLI supports it:

```bash
claude plugin validate .
```

## Owner checklist (you, not the agent)

- [ ] GitHub repo **Public**
- [ ] Cursor: submit URL + accept Publisher Terms
- [ ] Claude: share `marketplace add` / `install` lines with users (community official catalog is a separate Anthropic process)
- [ ] Do **not** claim “on Cursor Marketplace” until the listing is live
- [ ] SaaS / website still out of this pack
