# Vibage

**Find where a problem lives** across many messy / AI-built app folders — in plain language.

Works with **Cursor**, **Claude Code**, and **Codex**.

**Public repo:** [github.com/eric2612115/vibage-skills](https://github.com/eric2612115/vibage-skills) (MIT)

```bash
git clone https://github.com/eric2612115/vibage-skills.git
```

## Stranger start (parent folder only)

1. Clone this repo (above).  
2. In Cursor / Claude / Codex, open the **parent** folder that contains your many apps — **not** a single child repo.  
3. Say:

> 幫我裝 Vibage

Or just describe the pain (“checkout is broken”) — the agent must still wire parent rules first if missing.

You should not type bash. The agent runs scripts.

## What you say (no typing commands)

**First time — install continuum:**

> 幫我裝 Vibage

The agent must: wire **parent** routers (`PROJECT_ENTRY_OK`) → create the checklist folder → build a **draft map of every app folder** (`PILE_INDEX_OK`) → then ask for your ticket or symptom.  
It must **not** stop after install only, and must **not** dig yet.  
Proof: [`prompts/SAY-INSTALL-VIBAGE.md`](prompts/SAY-INSTALL-VIBAGE.md) · `bash tests/test_install_phrase_e2e.sh` → `INSTALL_PHRASE_E2E_OK`

**Then — find the problem:**

1. Stay in the parent folder chat.  
2. Paste a ticket link and/or describe what hurts (empty ticket body is OK — say the symptom).  
3. Confirm the hot path when asked (**CONFIRM** = your OK). You do **not** need to list every repo first — the map already indexed them.  
4. Get two reports: one for you, one for engineers (with file paths). External systems (DB/logs) show up as gaps if not connected.  
5. Agent offers preview or stop — no sign-up links.

## What you get

| You get | Plain meaning |
|---------|----------------|
| Parent routers | Chat keeps using Vibage next time (Cursor rule always on) |
| App map draft | Every child app folder listed — not “read every file” |
| Scan plan | “We’ll dig this hot path — OK?” |
| Owner report | Short brief you can read |
| Engineer report | Paths and evidence for a fixer |
| Optional later | Fix helpers / architecture glance — only if you ask |

## Checks (for agents / operators)

| Check | Command / link | OK token |
|-------|----------------|----------|
| Install continuum | `tests/test_install_phrase_e2e.sh` | `INSTALL_PHRASE_E2E_OK` |
| Pile index | `scripts/pile-index.sh <parent>` | `PILE_INDEX_OK` |
| Pack health | `scripts/pack-health.sh <parent>` | `PACK_HEALTH_OK` |
| Ship gate | `scripts/test-tier0.sh` | `TIER0_OK` |
| Capability table | [`STATUS.md`](STATUS.md) | — |
| Per IDE | [`docs/install/`](docs/install/) | — |
| Plugin manifests | [`docs/install/MARKETPLACE.md`](docs/install/MARKETPLACE.md) | `PLUGIN_MANIFESTS_OK` |
| Maps (agents) | [`docs/maps/AI-FIRST.md`](docs/maps/AI-FIRST.md) | — |
| Add a skill | [`docs/EXTENDING.md`](docs/EXTENDING.md) | — |

**Honesty (do not conflate):**
- **SaaS / sign-up** = blank (no register CTA in this pack).
- **This GitHub repo is public** — you can clone it. That is still **≠** Cursor/Claude marketplace listing; **≠** “officially launched product”; **≠** SaaS.
- Plugin manifests are on-tree (`.cursor-plugin/` · `.claude-plugin/`) — see [`docs/install/MARKETPLACE.md`](docs/install/MARKETPLACE.md). **≠** store listing until you submit and pass review.
- `PROJECT_ENTRY_OK` ≠ hub ready ≠ `PILE_INDEX_OK` ≠ “scan confirmed” ≠ “locate finished”.
- Pile-index map ≠ Architecture Pass; Graphify optional / fail-soft.

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
