# Vibage

**Find which service owns the bug — before the agent writes code.**

For teams with **many repos / microservices / AI-generated folder piles**.  
Works with **Cursor**, **Claude Code**, and **Codex**.

MIT · [github.com/eric2612115/vibage-skills](https://github.com/eric2612115/vibage-skills) · **0.9.3.3**

**This GitHub repo is public** — you can clone it. That is still **≠** Cursor/Claude marketplace listing; **≠** “officially launched product”; **≠** SaaS.

```bash
git clone https://github.com/eric2612115/vibage-skills.git
```

Plugin manifests ship in-repo (`.cursor-plugin/` · `.claude-plugin/`) — see [`docs/install/MARKETPLACE.md`](docs/install/MARKETPLACE.md). Listing still needs host review.

---

## Who this is for

**Use Vibage if you:**

- Have **multiple app folders / microservices** in one parent workspace
- Waste hours (or days) asking “which repo is this bug in?”
- Already use Cursor / Claude Code / Codex and want a **locate-first** workflow

**Skip Vibage if you:**

- Work in a **single clean repo**
- Mainly want autocomplete / faster code writing
- Need an on-call / logs / incident bot (that’s a different product)

This is **not** another coding skill pack.  
It is a **problem-location layer**: decide *where* to dig, then dig only there.

---

## What you get

| Result | Plain meaning |
|--------|----------------|
| App list | Every child app folder indexed (`PILE_INDEX_OK` = shallow map, not “system understood”) |
| Scan plan | “We’ll look in these places — OK?” |
| Your OK | You confirm the hot path before deep dig (**CONFIRM**) |
| Owner report | Short brief a human can read |
| Engineer report | Paths + evidence for someone who will fix |

Typical story people care about: **messy multi-service tickets that used to take 1–2 days of wandering → often under an hour once the right service is found.**  
(Your mileage varies. We are collecting more public before/after write-ups.)

---

## Stranger start (parent folder only)

## What you say

**Try it — 3 steps:**

1. Clone this repo (above).
2. In Cursor / Claude / Codex, open the **parent** folder that contains your many apps — **not** one child repo alone.
3. Say:

> Install Vibage

You should not type bash. The agent runs install scripts.

Then paste a ticket or describe the symptom. When the agent proposes a hot path, say OK (**CONFIRM**).  
You get two reports. No sign-up links.

More install paths: [`docs/install/`](docs/install/) · [`docs/install/MARKETPLACE.md`](docs/install/MARKETPLACE.md).

Proof: [`prompts/SAY-INSTALL-VIBAGE.md`](prompts/SAY-INSTALL-VIBAGE.md) · `bash tests/test_install_phrase_e2e.sh` → `INSTALL_PHRASE_E2E_OK`

---

## What “Install Vibage” does (owner language)

1. Wires parent chat rules so the next session still uses Vibage  
2. Creates a small checklist folder under `docs/vibage/`  
3. Indexes child app folders (a nameplate map — **not** “we understand your whole system”)  
4. Asks whether you want a costlier deepen pass (pasting a ticket usually means skip)  
5. Drafts a scan plan → waits for your OK → then locates

It must **not** stop after install only, and must **not** dig before you confirm.

---

## Language

Package files (skills, adapters, scripts, tests, references) are **English**.  
Owner chat may be any language. Product phrases the agent must recognize stay English (`Install Vibage`, etc.).

---

## Honesty

- **No SaaS / no register CTA** in this pack.
- Public GitHub clone ≠ marketplace listing ≠ SaaS.
- Map / index ≠ full understanding ≠ dig finished.
- `PROJECT_ENTRY_OK` ≠ hub ready ≠ `PILE_INDEX_OK` ≠ “scan confirmed” ≠ “locate finished”.

---

## For agents / operators

Capability table: [`STATUS.md`](STATUS.md)  
Per-IDE install: [`docs/install/`](docs/install/)  
Routing scope: [`references/routing-scope.md`](references/routing-scope.md)  
Hard stops: [`references/hard-stops.md`](references/hard-stops.md)  
Maps for agents: [`docs/maps/AI-FIRST.md`](docs/maps/AI-FIRST.md)  
Extend: [`docs/EXTENDING.md`](docs/EXTENDING.md)

| Check | Command | OK token |
|-------|---------|----------|
| Install continuum | `tests/test_install_phrase_e2e.sh` | `INSTALL_PHRASE_E2E_OK` |
| Pile index | `scripts/pile-index.sh <parent>` | `PILE_INDEX_OK` |
| Pack health | `scripts/pack-health.sh <parent>` | `PACK_HEALTH_OK` |
| Ship gate | `scripts/test-tier0.sh` | `TIER0_OK` |

### Operator commands (owner should not need these)

```bash
bash /path/to/vibage-skills/scripts/install.sh
bash /path/to/vibage-skills/scripts/install.sh --with-project-rule=/path/to/parent
bash /path/to/vibage-skills/scripts/verify-project-entry.sh /path/to/parent
# expect: PROJECT_ENTRY_OK
```

### License

MIT — [`LICENSE`](LICENSE). Copyright (c) 2026 Eric Fang.
