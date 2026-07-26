# C′ Next Waves Roadmap

**Date:** 2026-07-25  
**Status:** Roadmap SSOT for post–Proven-green C′ work  
**Parent design:** `docs/superpowers/specs/2026-07-24-vibage-c-prime-graph-brief-ledger-design.md`  
**Proven-green evidence:** `docs/evidence/c-prime/SUMMARY.md`  
**Wave-1 design:** `docs/superpowers/specs/2026-07-25-vibage-c-prime-sync-freshness-design.md`  
**Wave-1 implementation plan:** `docs/superpowers/plans/2026-07-25-vibage-c-prime-sync-freshness.md`

## Why split

Four owner themes are **four subsystems**. One mega-spec mixes ship gates, UX, and agent-pressure and invites greenwash. Each wave gets its own design → plan → implement cycle.

## Wave table

| Wave | Theme | Delivers | Explicitly out |
|------|-------|----------|----------------|
| **W1** | Sync / freshness (HEAD+TTL subset) | Mark stale; **HARD_MOTHER**; **SOFT_CHILD** + ask + non-silent refuse; tokens below | Env-vacancy dialogue; full-sweep; letter B; dimension; Tier-0; edge invalidate; brief refresh; other §2.5 triggers |
| **W1b** | Sync remainder (optional later) | Remaining §2.5: edge invalidate, brief refresh, branch/env path rebuild, compose/deploy, scene registry, ledger pointer mismatch, session auto-continue incomplete | Not scheduled until after W1 On-tree; **out of this roadmap’s committed sequence** until owner opens W1b |
| **W2** | Missing-env → ask / configure | Answerable gaps; per-gap skip / point / classify + ask tokens; binary `env_vacancy_waiver` kept as hatch | Asking / skip / classify / waiver **never** grant full-sweep; ≠ freshness waiver |
| **W3a** | Dimension fill (may split N plans) | Repo synthesizer + dimension searchers → ledger `dimension_*`; **migrate deepen → retire `MAP_DEEPEN_OK` brand** | ≠ full-sweep; ≠ “understood”; **implement after W2 On-tree** |
| **W3b** | Letter B (**thin**) | Clarify: B-path agent-proven (AP-C4/C5 evidence already on-tree) ≠ C′ Proven-green ≠ Gate B; optional RUNBOOK re-verify for new `run_ts` | **No new cards**; **no** rebuild Focus C1–C3; C′/W1 **never** auto-flip letter B |
| **W4** | Tier-0 policy | Thin C′ subset ship-gate **On-tree** (YES = `graph_floor` + `ledger` only; `TIER0_C_PRIME_THIN_OK`) | Rejects whole `test_c_prime_suite`; **excludes** freshness / matrix / fixtures / defi_pile / dimension |

### Dependencies

```text
W1 freshness On-tree (≠ Sync DONE) → W2
W2 On-tree → W3a implement          (W3a design may draft earlier; soft edge from W1)
W3b thin                            (independent; parallel with W2 OK)
W4                                  (after W2+W3a settle; never during W1–W3 sneak-wire)
W1b                                 (optional; owner-scheduled; not blocking W2)
```

**Tri-review fold:** `docs/superpowers/specs/2026-07-25-vibage-c-prime-next-waves-tri-review.md`

**W1–W3 MUST NOT:** modify `scripts/test-tier0.sh` or pack-health; add freshness tests to the **required** path of `tests/test_c_prime_suite.sh` (optional local script `tests/test_freshness_w1.sh` — named to avoid `test_c_prime_*.sh` suite glob — and must stay out of Tier-0 / suite ship-gate candidates).

## Tier-0 in plain language

**Tier-0** = the package’s **minimum must-pass exam before publish** (today: scan_plan hash, assert_gate, handoff, install safety, etc. → `TIER0_OK`).

Wiring C′ into Tier-0 means: **if those C′ tests fail, the package must not ship.** Decide only in W4. If a thin subset is ever added, default candidates are `graph_floor` + `ledger` only — **not** freshness, fixtures, defi_pile, or whole suite.

## Honesty locks (all waves)

- C′ Proven-green ≠ letter B ≠ Gate B (CONFIRM/dig) ≠ full-pile full-sweep  
- `freshness_skip_waiver` **never** grants `FRESHNESS_OK` or `MATRIX_SWEEP_SUBSTANTIVE_OK`  
- `env_vacancy_waiver` never grants full-sweep  
- W1 On-tree phrase must be: `W1 freshness On-tree (HEAD+TTL subset) ≠ Sync contract DONE` — never “Sync On-tree” alone  
- Never read real `.env`; no vector / RAG / SaaS  

## Document map

| Doc | Role |
|-----|------|
| This file | Roadmap index |
| `…-next-waves-tri-review.md` | W2–W4 planning tri-review fold |
| `…-sync-freshness-design.md` | W1 design (On-tree) |
| `…-sync-freshness.md` (plans/) | W1 implementation plan (**executed**) |
| `…-env-vacancy-ask-design.md` | W2 design (**On-tree**; `ENV_VACANCY_W2_OK`) |
| `…-letter-b-thin-design.md` | W3b thin clarify |
| `…-dimension-fill-design.md` | W3a design (**On-tree**; `MAP_DEEPEN_OK` retired) |
| `…-tier0-thin-policy.md` | W4 policy (**On-tree**) |
| `…-c-prime-plan-index.md` | Live construction index |
