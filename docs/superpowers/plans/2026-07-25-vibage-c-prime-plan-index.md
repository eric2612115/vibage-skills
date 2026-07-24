# Vibage C′ Implementation Plan Index

> **Live SSOT for C′ construction.** Do **not** execute archived plans under `docs/archive/2026-07-24-pre-c-prime/plans/`.

**Spec:** `docs/superpowers/specs/2026-07-24-vibage-c-prime-graph-brief-ledger-design.md`  
**Detailed plan:** `docs/superpowers/plans/2026-07-25-vibage-c-prime-graph-brief-ledger.md`  
**Out of scope:** Vector DB / embedding / RAG; SaaS; replacing Gate B (CONFIRM / assert_gate)

## Ordered waves

| Wave | Chunk in detailed plan | Delivers | Exit tokens (script) |
|------|------------------------|----------|----------------------|
| P0 | Chunk 0 | Graph floor + ledger + rollup | `GRAPH_FLOOR_OK`, `LEDGER_SLICE_PROVEN`, `UNDERSTANDING_ROLLUP_OK` |
| P1 | Chunk 1 | Matrix inventory + evidence sweep + fill | `ENV_BRANCH_MATRIX_OK`, `MATRIX_SWEEP_SUBSTANTIVE_OK` |
| P2 | Chunk 2 | Scenes + briefs + cover verify | `SCENE_BRIEF_OK`, `BRIEF_USABLE_OK`, cover helper |
| P3 | Chunk 3 | Fixtures friend-chaos + local-scenes | F1/L1 fixture green (**sync deferred**) |
| P4 | Chunk 4–5 | Skills + freeze-lift + suite + STATUS On-tree | C′ On-tree=YES, Proven-green=NO (**done**) |

## Execution

Use `@superpowers:subagent-driven-development` (or executing-plans if no subagents).  
One wave at a time; do not claim C′ Proven-green from script green alone.
