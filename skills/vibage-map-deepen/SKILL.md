---
name: vibage-map-deepen
description: >-
  Optional nested deepen after GRAPH_FLOOR_OK / PILE_INDEX_OK when owner consents
  to cost and picks a model tier. Writes per-app dossiers and merges into the map.
  Requires verify-map-deepen.sh before claiming MAP_DEEPEN_OK. Not Plan-L
  Mermaid/Graphify. Not Architecture Pass. Not system-understood. Not Gate A 掃透.
  Not a dig/CONFIRM substitute. Dimension-fill path deferred in C′ plan. ∉ Tier-0.
---

# Vibage Map Deepen (optional / deferred dimension path)

**Status:** optional track after graph floor. Script-honest via `verify-map-deepen.sh`.  
**C′ note:** Dimension fill is **deferred** this plan — prefer matrix sweep + scene briefs on the continuum. If owner still asks for nested dossiers, this skill remains available but **never** narrates full-understanding or dig-ready-after-install.

**Name lock:** This skill ≠ Plan-L「local-maps deepen」(Mermaid/Graphify prettier). Graphify/Mermaid must **not** satisfy cost-consent deepen.

**Honest scope:** Nested L2 dossiers improve durable notes. That is still **≠** Architecture Pass, **≠** CONFIRM, **≠** dig-all, **≠** Gate A 掃透 (`MATRIX_SWEEP_SUBSTANTIVE_OK`), **≠** issue-fix unlock, **≠** full-understanding.

## When / Not

| When | Not |
|------|-----|
| Parent hub + `GRAPH_FLOOR_OK` / `PILE_INDEX_OK` thin map; owner said **yes** deepen after cost band | Default deepen on every install |
| Model tier asked and recorded (`source: human`) | Auto-upgrade to strongest model |
| Scope frozen **before** any L2 | Green-shrink after partial to mint OK |
| Child workspace asking “deepen whole system” | Deepen / init-hub / project-rule into child (S03 → open parent) |
| Owner wants optional dossiers | Claiming Gate A slogans (掃透 / scene cover / rollup) from deepen alone |

## PKG_ROOT

```bash
bash /path/to/vibage-skills/scripts/resolve-pkg-root.sh
```

## Consent order (MUST)

1. Anti-illusion already said after pile-index / graph-floor (nameplate ≠ understood; ≠ dig-ready-after-install).
2. Cost band for N already said; owner **yes** deepen (ticket paste alone = implicit no → do **not** enter this skill).
3. Ask model tier once (owner picks in IDE menu; you record):

> For the deeper pass, which model tier should we use?  
> 1) Fast/cheap — quicker, thinner dossiers  
> 2) Balanced — default  
> 3) Strong — slower/costlier, better reading  
> (You pick in the IDE model menu; I’ll match depth to your choice.)

4. Freeze scope + tier in `docs/vibage/DECISIONS.md` **and** open deepen RunEnvelope **before** any L2 spawn.
5. Then nested work. Do **not** rewrite hub `model-routing.json` as a private upgrade.

## Scope freeze (DECISIONS + envelope)

Append a human decision plus a fenced JSON block (verify reads the fence):

````markdown
## Map deepen freeze

```json
{
  "deepen_yes": true,
  "model_tier": "balanced",
  "deepen_scope_ids": ["svc-a", "svc-b"],
  "deepen_scope_hash": "<sha256 of sorted ids joined by comma>",
  "deepen_scope_frozen_at": "2026-07-24T00:00:00Z",
  "source": "human",
  "run_id": "map-deepen-1"
}
```
````

Default `deepen_scope_ids` = all service ids from thin map, **or** owner-explicit subset frozen **before** work starts.

Open `docs/vibage/RUNS/<run_id>.json` with at least:

- `pipeline_id`: exact `map_deepen`
- `run_id`, `phase` (`awaiting_deepen` → `started` → `done` | `partial` | `timeout` | `failed`)
- `mode`: `degraded` | `full nested`
- `scope_ids` + `original_scope_ids` (copy of freeze; **immutable** after `started`)
- `original_scope_hash` matching DECISIONS
- `nested_dispatch` when claiming `full nested` (investigators = L2 workers ≥1; reviewers ≥1 L1 critique)
- `claim_coverage`: `subset` | `full_pile` (must match reality vs map N)

Package shape: `$PKG_ROOT/references/hub/RunEnvelope.map_deepen.example.json`.

## Nested procedure

1. Child detect (S03): if child → stop; ask open parent.
2. Cap concurrency (e.g. 4 L2). One short dossier per scope id under `docs/vibage/dossiers/<id>.md`.
3. Dossier **minimum** (non-empty — stubs fail verify):

```markdown
# <id>
## Summary
<non-empty>
## Role
<non-empty>
## Notable paths
- <path>
```

4. If host cannot spawn subagents → `mode: degraded`; parent writes thinner dossiers sequentially. **Never** fake `full nested`.
5. Partial / timeout → phase `partial`|`timeout`; STOP + incompleteness + handoff. **Do not** claim `MAP_DEEPEN_OK`.
6. **Forbidden green-shrink:** after `started` / `partial` / `timeout` / `failed`, shrinking `scope_ids` to completed subset must **not** mint OK — even with a new human yes. New freeze may only **resume/extend** remaining work (same or larger unfinished set), or an honest new run that does not claim prior partial as full-pile done.
7. **Cross-run laundry:** new run with smaller scope that is only the completed subset of a prior partial must set `claim_coverage: subset` and chat “deepened subset S” — never “full pile done.”
8. Merge durable notes into map definitions when helpful; do not set Architecture Pass or “understood” claims.
9. **Before claiming complete:**

```bash
bash "$PKG_ROOT/scripts/verify-map-deepen.sh" "$WORKSPACE" docs/vibage/RUNS/<run_id>.json
```

   Expect stdout token **`MAP_DEEPEN_OK`**. On FAIL → do not claim complete.
10. Hand to `vibage-orient` (ticket × map). Deepen ≠ CONFIRM ≠ dig ≠ Gate A 掃透. Locate must **ignore deepen-as-auth**.

## Completion token

- Success = `MAP_DEEPEN_OK` from `verify-map-deepen.sh` for this run’s frozen scope.
- Partial / timeout / fake nested / stub dossiers / green-shrink → no OK token.
- `MAP_DEEPEN_OK` must **not** enter `assert_gate`, Tier-0, locate required path, or Gate A 掃透 / dig-ready-after-install narrative.

## Hard stops

Obey `$PKG_ROOT/references/hard-stops.md`.

- No dig / no dual reports / no issue-fix from deepen alone.
- No register / SaaS / Architecture Pass CTA.
- ≠ Plan-L local-maps deepen.
- Do not dig all N because deepen finished — dig ⊆ CONFIRM `planned_dig_ids` only.
