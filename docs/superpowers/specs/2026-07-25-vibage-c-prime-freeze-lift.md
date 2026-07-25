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
| Slice/cell stale → reindex sync (§2.5) | **W1 freshness On-tree (HEAD+TTL subset) ≠ Sync contract DONE** — scripts `freshness-*.sh` + `tests/test_freshness_w1.sh` (`FRESHNESS_W1_OK`). Remainder → optional W1b |
| Dimension fill / repo synthesizer wave | **W3a dimension-fill On-tree** (`DIMENSION_FILL_W3A_P0_OK` + `DIMENSION_FILL_W3A_P1_OK` + `DIMENSION_FILL_W3A_P2_OK`; P0 search+verify · P1 orchestrator · P2 deepen-migrate brand retire). Phrase: `W3a dimension-fill On-tree ≠ 掃透 ≠ understood ≠ letter B` (∉ Tier-0; script-only Proven ≠ live-panel) |
| Env vacancy ask / configure (W2) | **W2 env-vacancy On-tree ≠ 掃透 ≠ letter B** — `ENV_VACANCY_W2_OK`; design `…-env-vacancy-ask-design.md` |
| Letter B as C′ wave (W3b) | **Thin clarify** at `…-letter-b-thin-design.md` — B-path evidence already on-tree; ≠ rebuild cards |
| C′ in Tier-0 / pack-health | **Not wired** |
| C′ Proven-green | **YES** (`scope=script+live-pressure`; evidence `docs/evidence/c-prime/SUMMARY.md`) — suite alone ≠ enough; requires live PRESSURE_PASS |
| letter B for C′ | **NO** (Proven-green ≠ letter B) |

## Gate reminder

- **Gate A** (narrative): rollup / matrix / 掃透 / scene cover tokens.  
- **Gate B** (dig): orient → CONFIRM → `assert_gate`.  
Gate A ≠ Gate B. Freeze lift does not replace Gate B.
