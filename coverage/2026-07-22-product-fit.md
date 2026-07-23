# Product fit eval — 2026-07-22

Plan: SelfAutoBuz `docs/superpowers/plans/2026-07-22-vibage-skills-product-fit-eval.md`  
Matrix: `docs/research/vibage/product-fit-gap-matrix-2026-07-22.md`  
Model lock: `cursor-grok-4.5-high`

## Chunk B

- Package patch: **none** (`must-fix: none`)
- Smoke: `SMOKE_OK` + `verify-pins` OK @ `363923f74aa9cd7b470c0aaa73dee629a8bfdc90`

## Gate B (impl review)

| Agent | Lens | Verdict |
|-------|------|---------|
| B1 | SSOT | APPROVE |
| B2 | exec/smoke | APPROVE |
| B3 | continuity | APPROVE |

## Gate C (blind — no hub/plan lore in prompts)

| Agent | ROLE | Score | Use on fat repo? |
|-------|------|-------|------------------|
| C1 | owner-user | **6/10** | YES (as entry discipline) |
| C2 | skill-author-reviewer | **6/10** | YES (guardrails + shell) |
| C3 | vibing-garbage-complexity | **5/10** | YES conditional (not a complexity weapon) |

### Consensus themes (from judges only)

**What it is:** Locate-for-non-coder-owners of fat/AI/outsourced repos; dual reports; nested investigate→review; pins; hard stops — not full fix / pentest / strategy.

**Strengths:** Narrow scope; path+quote kill; dual audience; PKG_ROOT + pin + install; fat identity / deny list; nested protocol text.

**Gaps for vibing garbage (top recurring):**
1. Nested MUST not mechanically enforceable / easy to fake
2. Orient assumes docs (`README`/`STATUS`/`AGENTS`) — need no-docs cold start
3. Thin seam heuristics / vibe-debt smell library
4. Nested failure degradation path
5. Golden example reports + auditability of nested pass
6. Owner capability branching (can’t run docker → different actions)
7. Multi-root / service-map template; pin UX friction for non-coders

**Not implemented here:** Gate C suggestions stay ideas until Eric asks (per plan).
