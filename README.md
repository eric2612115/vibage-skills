# Vibage

**Find where a problem lives** across many messy / AI-built app folders — in plain language.

Works with **Cursor**, **Claude Code**, and **Codex**.

## What you say (no typing commands)

**First time — install:**

> 幫我裝 Vibage

The agent installs everything and wires this **parent** folder.  
Proof: [`prompts/SAY-INSTALL-VIBAGE.md`](prompts/SAY-INSTALL-VIBAGE.md) · re-run: `bash tests/test_install_phrase_e2e.sh` → `INSTALL_PHRASE_E2E_OK`

**Then — find the problem:**

1. Stay in the parent folder chat (the folder that contains your apps).  
2. Describe what hurts in everyday words.  
3. Confirm the scan plan when asked (**CONFIRM** = your OK).  
4. Get two reports: one for you, one for engineers (with file paths).  
5. Agent offers preview or stop — no sign-up links.

You should not type bash. The agent runs scripts.

## What you get

| You get | Plain meaning |
|---------|----------------|
| Scan plan | “We’ll look here — OK?” |
| Owner report | Short brief you can read |
| Engineer report | Paths and evidence for a fixer |
| Optional later | Fix helpers / architecture glance — only if you ask |

## Checks (for agents / operators)

| Check | Command / link | OK token |
|-------|----------------|----------|
| Install phrase | `tests/test_install_phrase_e2e.sh` | `INSTALL_PHRASE_E2E_OK` |
| Pack health | `scripts/pack-health.sh <parent>` | `PACK_HEALTH_OK` |
| Ship gate | `scripts/test-tier0.sh` | `TIER0_OK` |
| Capability table | [`STATUS.md`](STATUS.md) | — |
| Per IDE | [`docs/install/`](docs/install/) | — |
| Plugin manifests | [`docs/install/MARKETPLACE.md`](docs/install/MARKETPLACE.md) | `PLUGIN_MANIFESTS_OK` |
| Maps (agents) | [`docs/maps/AI-FIRST.md`](docs/maps/AI-FIRST.md) | — |
| Add a skill | [`docs/EXTENDING.md`](docs/EXTENDING.md) | — |

**Honesty (do not conflate):**
- **SaaS / sign-up** = blank (no register CTA in this pack).
- **Public GitHub** = share/clone the skill pack; **≠** Cursor/Claude marketplace listing; **≠** “officially launched product”; **≠** SaaS.
- Plugin manifests are on-tree (`.cursor-plugin/` · `.claude-plugin/`) — see [`docs/install/MARKETPLACE.md`](docs/install/MARKETPLACE.md). **≠** store listing until you submit and pass review.
- `PROJECT_ENTRY_OK` ≠ “scan confirmed” ≠ “locate finished”.

---

## Deeper (agents)

- Spec: `docs/superpowers/specs/2026-07-23-vibage-v2-superpowers-grade-design.md`  
- Plans: `docs/superpowers/plans/2026-07-23-vibage-v2-plan-index.md`  
- Optional paste: [`prompts/NEW-CHAT.md`](prompts/NEW-CHAT.md)  
- Hard stops: [`references/hard-stops.md`](references/hard-stops.md)  
- GitHub + CI: `https://github.com/eric2612115/vibage-skills`  

### Operator commands (owner should not need these)

```bash
bash /path/to/vibage-skills/scripts/install.sh
bash /path/to/vibage-skills/scripts/install.sh --with-project-rule=/path/to/parent
bash /path/to/vibage-skills/scripts/verify-project-entry.sh /path/to/parent
# PROJECT_ENTRY_OK
```

### License

MIT — [`LICENSE`](LICENSE). Copyright (c) 2026 Eric Fang.
