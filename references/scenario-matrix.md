# Scenario matrix (P1 acceptance)

| ID | Scenario | Expected |
|----|----------|----------|
| S1 | Empty parent | init+orient; no dig without roots |
| S1b | Repos added later | re-orient; stale CONFIRM |
| S2 | Many `.git` roots | orient→CONFIRM→locate with budget |
| S3 | Vibing single repo | still light SCAN_PLAN+CONFIRM |
| S4 | Path iron evidence | locate; survey SKIP |
| S5 | Missing deploy/infra | GapQuestion; MUST survey if hot path |
| S6 | Missing Grafana/DB/… | ask after analysis |
| S7 | One-line install+analyze | stop at awaiting_confirm |
| S8 | Pin fail | block analyzing |
| S9 | Design section gate | section-gate; `go_next` ≠ Mode |
| S10 | User skips web | survey SKIP |
| S11 | Post-CONFIRM delivery | dual MD + RUNS + preview fail-soft + soft CTA |
| S12 | Resume | read STATUS/RUNS; do not wipe CONFIRM via re-init |
| S13 | Reject/change plan | clear/re-CONFIRM; hash mismatch blocks analyzing |
| S14 | Stale CONFIRM | phase stale_confirm; re-orient/confirm |

Do not mix columns: `phase` ≠ `Mode` ≠ section-gate `go_next`.
