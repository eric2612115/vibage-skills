---
name: vibage-pile-index
description: >-
  Use after hub init when the parent has many apps and there is no qualified
  service_map, or the owner cannot name which repos matter. Builds a shallow
  pile index / service_map for all one-level child git checkouts. Do not dig
  locate reports here. Do not require Graphify.
---

# Vibage Pile Index (map-first)

Goal: give a **map of the garbage pile** before locate — every one-level child checkout gets an id + short definition; cheap edges when compose reveals them.

## When / Not

| When | Not |
|------|-----|
| Hub ready (`docs/vibage/STATUS.md`) and map missing / underqualified | Write `VIBAGE-ISSUE-*` |
| Owner cannot name repos / only pasted a ticket | Deep-read every file in 22 repos |
| Continuum after install + init-hub | Cloud Architecture Pass / SaaS CTA |

## PKG_ROOT

```bash
bash /path/to/vibage-skills/scripts/resolve-pkg-root.sh
```

## Owner language (chat)

Say plain words only:

- “I’m building a draft map of every app folder in this parent.”
- “This is not reading every file — just names, READMEs, and obvious links.”
- “When the map is ready, paste the ticket or say what hurts.”

Do **not** ask “which repos?” as a substitute for indexing all children.
Do **not** say SCAN_PLAN / RootRef / Graphify / payload to the owner.

## Budgets (F14)

| Knob | Cap |
|------|-----|
| Scope | One-level child dirs with `.git` only |
| Per child | Whitelist only: README*, package.json, pyproject.toml, go.mod, Cargo.toml, compose/Dockerfile |
| Wall | Prefer finish in one agent turn; if too large → STOP + handoff, do not infinite-index |
| Depth | Prefer edges when cheap; empty edges OK (omit `depth: standard`) |

## Procedure

1. Require hub: if `docs/vibage/STATUS.md` missing → hand to `vibage-init` (`--init-hub`).
2. Run:
   ```bash
   bash "$PKG_ROOT/scripts/pile-index.sh" "$WORKSPACE"
   ```
   Expect stdout token **`PILE_INDEX_OK`** and `verify-service-map` green.
3. Optional fail-soft:
   ```bash
   bash "$PKG_ROOT/scripts/generate-service-map-graph.sh" "$WORKSPACE" || true
   ```
   `OK:GRAPHIFY_SKIP` is fine.
4. Tell owner: map draft ready (N apps). **Then** ask for ticket / pain (F9).
5. Hand to `vibage-orient` (map × ticket → hot path). Owner-stated names **correct** hot path only — never shrink the full index (F10).

## Completion token (F15)

- Success = `PILE_INDEX_OK` + hub `docs/vibage/maps/service_map.json` verifies.
- “Started indexing” / intent alone ≠ done.
- Timeout / cannot finish → STOP + handoff; do not pretend map complete.

## Hard stops

Obey `$PKG_ROOT/references/hard-stops.md`.

- No dig / no dual reports.
- No register CTA.
- ≠ Architecture Pass.
- Do not install project rules into each child repo.
