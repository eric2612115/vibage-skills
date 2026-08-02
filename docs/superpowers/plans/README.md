# Plans

**Agent rule:** Files under this directory are **not** current Build checklists unless the owner
explicitly says to implement a named open plan. Prefer package [`STATUS.md`](../../../STATUS.md)
and live skills / `references/` over re-executing shipped plan todos.

## SHIPPED / historical (do not re-execute)

| Wave | Plan | Notes |
|------|------|--------|
| C′ graph / brief / ledger | `2026-07-25-vibage-c-prime-plan-index.md` → `2026-07-25-vibage-c-prime-graph-brief-ledger.md` | On-tree + Proven-green in package `STATUS.md` |
| C′ follow-ons (freshness, vacancy, dimension, tier0-thin, …) | `2026-07-25-vibage-c-prime-*.md` | SHIPPED; see freeze-lift spec |
| Honesty | `2026-07-25-vibage-honesty-followup.md`, `2026-07-25-vibage-honesty-hardening.md` | SHIPPED |
| Review budget / blast radius | `2026-07-26-review-budget-blast-radius.md` | SHIPPED on `feat/review-budget-blast-radius` → merge to main |

## OPEN (feature branch only — do not treat as main Build checklist)

| Plan | Branch | Notes |
|------|--------|-------|
| `2026-08-02-work-continue-memory.md` | `feat/work-continue-memory` | Owner locks A/B/C/D1/E; implement only on that branch |

**Design refs (not executable todos):**  
`docs/superpowers/specs/2026-07-24-vibage-c-prime-graph-brief-ledger-design.md` ·  
`docs/superpowers/specs/2026-07-25-vibage-c-prime-freeze-lift.md` ·  
`docs/superpowers/specs/2026-08-02-work-continue-memory-design.md` (open on feat branch)

**STATUS (package):** C′ row Designed=YES · On-tree=YES · Proven-green=YES (`scope=script+live-pressure`).

**Pre-C′ plans:** deleted from the tree. Do not recover from git history into context unless the owner asks for archaeology.
