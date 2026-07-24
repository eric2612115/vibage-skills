# C′ Freeze Lift Notes

**Date:** 2026-07-25  
**Design:** `docs/superpowers/specs/2026-07-24-vibage-c-prime-graph-brief-ledger-design.md`  
**Plan:** `docs/superpowers/plans/2026-07-25-vibage-c-prime-graph-brief-ledger.md` (Chunks 4–5)

## What the freeze was

Until C′ scripts and skills landed, runtime gates stayed on legacy `service_map.json` / `PILE_INDEX_OK` / optional `MAP_DEEPEN_OK`. Design forbade **dual-running** two understanding substrates (or double nested cost) in one session.

## When the dual-substrate ban lifts

The ban lifts only when **all** of the following hold:

1. **`pile-index` is a wrapper** — `scripts/pile-index.sh` calls `graph-floor.sh` and still echoes `PILE_INDEX_OK` for freeze compat; floor truth is `GRAPH_FLOOR_OK` via `verify-graph-floor.sh`.
2. **Deepen is not “understood”** — `MAP_DEEPEN_OK` / dossiers never narrate full-understanding, dig-ready-after-install, or Gate A 掃透 (`MATRIX_SWEEP_SUBSTANTIVE_OK`). Locate **ignores deepen-as-auth**.
3. **Sessions do not run old+new nested substrates together** — one continuum: graph floor → matrix sweep → (optional deferred dimension fill) → ticket or scene → `SCENE_BRIEF_OK` when scene set → orient → CONFIRM → locate. Do not also run a parallel “thin map + deepen = understood” track in the same session.

## Still deferred (ban remains for these)

| Item | Status |
|------|--------|
| Slice/cell stale → reindex sync (§2.5) | **Deferred** — not required for On-tree this plan |
| Dimension fill / repo synthesizer wave | **Deferred** |
| C′ in Tier-0 / pack-health | **Not wired** |
| Proven-green / letter B for C′ | **NO** (script suite green ≠ agent Proven-green) |

## Gate reminder

- **Gate A** (narrative): rollup / matrix / 掃透 / scene cover tokens.  
- **Gate B** (dig): orient → CONFIRM → `assert_gate`.  
Gate A ≠ Gate B. Freeze lift does not replace Gate B.
