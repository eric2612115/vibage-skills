---
name: vibage-pile-index
description: >-
  Use after hub init when the parent has many apps and there is no qualified
  service_map / graph floor, or the owner cannot name which repos matter.
  Runs structural index (graph-floor) for discovered git checkouts; prints
  PILE_INDEX_OK as freeze-compat wrapper after GRAPH_FLOOR_OK path. Do not dig
  locate reports here. Do not require Graphify. After floor: anti-illusion —
  nameplate only (not full-understanding); then matrix sweep (c-prime-fill).
---

# Vibage Pile Index (graph floor)

Goal: structural **graph floor** of the mother directory before locate — every discovered checkout gets an id + short definition; cheap edges when compose reveals them. Script path: `pile-index.sh` → `graph-floor.sh` → echo `PILE_INDEX_OK` (compat); verify with `verify-graph-floor.sh` → `GRAPH_FLOOR_OK`.

## When / Not

| When | Not |
|------|-----|
| Hub ready (`docs/vibage/STATUS.md`) and map/graph missing / underqualified | Write `VIBAGE-ISSUE-*` |
| Owner cannot name repos / only pasted a ticket | Deep-read every file in 22 repos |
| Continuum after install + init-hub | Cloud Architecture Pass / SaaS CTA |
| Parent workspace only | Install/deepen into a child checkout (S03) |
| Before matrix sweep | Claim 掃透 / dig-ready-after-install / full-understanding |

## PKG_ROOT

```bash
bash /path/to/vibage-skills/scripts/resolve-pkg-root.sh
```

## Owner language (chat)

Say plain words only:

- “I’m building a structural map of every app folder in this parent.”
- “This is not reading every file — just names, READMEs, and obvious links.”
- “Next we fill env/branch evidence cells; 掃透 only when that substantive gate passes.”
- “When the floor is ready, paste the ticket or switch scene — or say what hurts.”

Do **not** ask “which repos?” as a substitute for indexing the discovery set.
Do **not** say SCAN_PLAN / RootRef / Graphify / payload to the owner.
Do **not** claim full-understanding, or dig-ready after install alone, from this skill.

## Budgets (F14)

| Knob | Cap |
|------|-----|
| Scope | Discovery set from graph-floor (`flat` one-level children, or `nested` per OWNER_POLICY) |
| Per child | Whitelist only: README*, package.json, pyproject.toml, go.mod, Cargo.toml, compose/Dockerfile |
| Wall | Prefer finish in one agent turn; if too large → STOP + handoff, do not infinite-index |
| Depth | Prefer edges when cheap; empty edges OK (omit `depth: standard`) |

## Procedure

1. Require hub: if `docs/vibage/STATUS.md` missing → hand to `vibage-init` (`--init-hub`).
2. If workspace looks like a **child** (S03) → refuse whole-pile index/deepen; ask to open **parent**. Do not `--with-project-rule` / init-hub into the child.
3. Run:
   ```bash
   bash "$PKG_ROOT/scripts/pile-index.sh" "$WORKSPACE"
   ```
   Expect stdout token **`PILE_INDEX_OK`** and `verify-service-map` green. Also verify:
   ```bash
   bash "$PKG_ROOT/scripts/verify-graph-floor.sh" "$WORKSPACE"
   ```
   Expect **`GRAPH_FLOOR_OK`**.
4. Optional fail-soft:
   ```bash
   bash "$PKG_ROOT/scripts/generate-service-map-graph.sh" "$WORKSPACE" || true
   ```
   `OK:GRAPHIFY_SKIP` is fine. Plan-L Mermaid/Graphify prettier ≠ nested deepen ≠ Gate A.
5. **Anti-illusion (required after floor):** tell owner plainly:
   - This is a **nameplate / structural floor**, not a deep review.
   - **`GRAPH_FLOOR_OK` / `PILE_INDEX_OK` ≠ Architecture Pass ≠ full-understanding ≠ dig-ready-after-install ≠ locate DONE.**
   - Do **not** treat the map as permission to change business code.
6. **Matrix sweep (continuum next):** prefer
   ```bash
   bash "$PKG_ROOT/scripts/c-prime-fill.sh" "$WORKSPACE"
   ```
   (or inventory + cell sweep). Aim `ENV_BRANCH_MATRIX_OK`; claim 掃透 **only** with `MATRIX_SWEEP_SUBSTANTIVE_OK`. Incomplete matrix → disclose; tickets still OK.
7. Dimension fill / optional `vibage-map-deepen` = **deferred** this plan — do not block continuum; never narrate deepen as understood.
8. Ticket / pain **or** scene switch → if scene set, scene-brief → `SCENE_BRIEF_OK`; hand to `vibage-orient`. Owner-stated names **correct** hot path only — never shrink the full discovery index (F10).

## Completion token (F15)

- Floor success = `GRAPH_FLOOR_OK` + hub `docs/vibage/maps/service_map.json` verifies (`PILE_INDEX_OK` wrapper echo OK).
- “Started indexing” / intent alone ≠ done.
- Timeout / cannot finish → STOP + handoff; do not pretend map complete.
- Do **not** claim `MATRIX_SWEEP_SUBSTANTIVE_OK`, `SCENE_BRIEF_OK`, or `MAP_DEEPEN_OK` from pile-index alone.
- Do **not** claim dig-ready-after-install from this skill.

## Hard stops

Obey `$PKG_ROOT/references/hard-stops.md`.

- No dig / no dual reports.
- No register CTA / no SaaS upsell in cost talk.
- ≠ Architecture Pass.
- Do not install project rules into each child repo.
- Do not run `vibage-issue-fix` from thin map alone.
