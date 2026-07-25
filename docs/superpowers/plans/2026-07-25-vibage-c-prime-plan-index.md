# Vibage C′ Implementation Plan Index

> **Live SSOT for C′ construction.** Do **not** execute archived plans under `docs/archive/2026-07-24-pre-c-prime/plans/`.

**Spec:** `docs/superpowers/specs/2026-07-24-vibage-c-prime-graph-brief-ledger-design.md`  
**Detailed plan (P0–P4):** `docs/superpowers/plans/2026-07-25-vibage-c-prime-graph-brief-ledger.md`  
**Next-waves roadmap:** `docs/superpowers/specs/2026-07-25-vibage-c-prime-next-waves-roadmap.md`  
**Out of scope:** Vector DB / embedding / RAG; SaaS; replacing Gate B (CONFIRM / assert_gate)

## Ordered waves (substrate P0–P4 — done)

| Wave | Chunk in detailed plan | Delivers | Exit tokens (script) |
|------|------------------------|----------|----------------------|
| P0 | Chunk 0 | Graph floor + ledger + rollup | `GRAPH_FLOOR_OK`, `LEDGER_SLICE_PROVEN`, `UNDERSTANDING_ROLLUP_OK` |
| P1 | Chunk 1 | Matrix inventory + evidence sweep + fill | `ENV_BRANCH_MATRIX_OK`, `MATRIX_SWEEP_SUBSTANTIVE_OK` |
| P2 | Chunk 2 | Scenes + briefs + cover verify | `SCENE_BRIEF_OK`, `BRIEF_USABLE_OK`, cover helper |
| P3 | Chunk 3 | Fixtures friend-chaos + local-scenes | F1/L1 fixture green |
| P4 | Chunk 4–5 | Skills + freeze-lift + suite + STATUS | On-tree=YES; Proven-green via evidence pack (**done**) |

## Next waves (W1–W4)

| Wave | Spec / plan | Delivers |
|------|-------------|----------|
| **W1** | Spec: `…-sync-freshness-design.md` · Plan: `…-sync-freshness.md` (**On-tree**; `FRESHNESS_W1_OK`) | Freshness HEAD+TTL / HARD_MOTHER / SOFT_CHILD (**≠** Sync contract DONE) |
| **W1b** | (optional, not yet) | Remaining §2.5 triggers |
| **W2** | Spec: `…-env-vacancy-ask-design.md` · Plan: `…-env-vacancy-ask.md` (**On-tree**; `ENV_VACANCY_W2_OK`) | Missing-env ask / configure (skip/point/classify; ≠ 掃透) |
| **W3a** | Spec: `…-dimension-fill-design.md` · Plans: `…-p0.md` / `…-p1.md` (**P0+P1 On-tree**; `DIMENSION_FILL_W3A_P1_OK`) · P2 open | P0+P1 orchestrator/synth done; P2 deepen-migrate + STATUS scrub open |
| **W3b** | Spec: `…-letter-b-thin-design.md` (thin docs; B-path evidence already on-tree) | ≠ rebuild AP-C4/C5; ≠ C′ Proven-green ≠ Gate B; optional RUNBOOK re-verify only if owner asks |
| **W4** | (not yet; last) | Tier-0 thin-subset policy (draft: graph_floor + ledger; excludes freshness) |

## Execution

Use `@superpowers:subagent-driven-development` (or executing-plans if no subagents).  
One wave at a time.

- Proven-green loop (done): `2026-07-25-vibage-c-prime-proven-green-loop.md` + evidence `docs/evidence/c-prime/SUMMARY.md`  
- W1–W3 must not wire Tier-0 / whole `test_c_prime_suite`
