# C′ Next Waves Plan — Tri-Review Fold

**Date:** 2026-07-25  
**Plan reviewed:** Cursor plan `next_waves_w2-w4` (do not treat that file as editable SSOT)  
**Reviewers:** 3× Grok 4.5 high (product / engineering / adversarial)  
**Initial verdict:** all three **APPROVE NO** → blockers folded below → SSOT + W2 design updated  

## Sequence lock (unchanged; product OK)

| Order | Wave | Role |
|-------|------|------|
| 1 | **W2** | Main line — missing-env ask / configure |
| 2 | **W3a** | Dimension fill — **implement only after W2 On-tree** (design may draft earlier) |
| ∥ | **W3b** | Thin — clarify B-path vs C′ vs Gate B; optional re-run; **no new cards** |
| last | **W4** | Tier-0 policy — draft YES thin = `graph_floor` + `ledger` only |

**W1 phrase lock:** say only `W1 freshness On-tree (HEAD+TTL subset) ≠ Sync contract DONE` — never bare “Sync On-tree”.

## Blockers folded → resolutions

| # | Source | Blocker | Resolution (locked) |
|---|--------|---------|---------------------|
| 1 | P+A | Roadmap W3b still said “deliver AP-C4+C5 dual-PHASE” vs already-proven B-path | Roadmap + plan-index updated: W3b = **thin clarify / optional re-verify**; B-path evidence stays at `docs/evidence/focus/SUMMARY.md` |
| 2 | P+E | W2 skip/classify vs `env_vacancy_waiver` owner-visible end-state unclear | W2 design §2–§4: binary waiver **kept** as whole-matrix hatch; per-gap answers in separate SSOT file; never grant full-sweep |
| 3 | P | Mermaid W1→W3a hard edge vs “wait for W2” | Soft: W3a **must not** claim depth/continuum-complete on vacancy-only / waiver-only piles; implement after W2 On-tree |
| 4 | E | Cell state interface (`proven\|failed` only) | Overlay — no new matrix `state`; skip/classify do not invent states |
| 5 | E | Write-path schema / ≠ freshness waiver | `docs/vibage/maps/env_vacancy_answers.json` + optional policy pointers; ≠ `freshness_skip_waiver` |
| 6 | E | Tokens / scripts unnamed | Frozen in W2 design §6 |
| 7 | E | W3a deepen “migrate or demote” ambiguous | Lock for later W3a design: **migrate into dimension-fill and retire `MAP_DEEPEN_OK` brand** (no dual “understood”) — noted in roadmap; not implemented now |
| 8 | A | ask ≠ full-sweep; C′↛B; W4 no sneak | Honesty locks restated in W2 design + roadmap W4 row |

## Tradeoffs (for owner gate)

| Wave | Product value | Eng cost | Greenwash risk | When |
|------|---------------|----------|----------------|------|
| W2 | High (live missing-env pain) | Medium | High if ask→full-sweep | **Next — design written** |
| W3a | High (depth) | High | High (understood) | After W2 On-tree |
| W3b | Medium (narrative clarity) | Low | Medium (mix B/C′) | Parallel OK; thin only |
| W4 | Medium (ship discipline) | Low–med | Medium (fat gate) | Last; draft YES thin floor+ledger |

## Owner one-liner (default)

> Next wave = **W2 env-vacancy ask** only for implementation planning; W3b thin docs may parallel; W3a/W4 design later; **no product code** until owner says execute on a W2 implementation plan.

## Re-review gate

| Round | Product | Engineering | Adversarial |
|-------|---------|-------------|-------------|
| 1 (plan) | NO | NO | NO |
| 2 (SSOT+W2) | **YES** | NO (§5 vs parent clause) | NO (point-pending / ANSWERED≠CLEAR) |
| 3 (§5 B all-special + token locks) | **YES** | **YES** | **YES** |

**Final (pre-execute confirmation round):** three-way **CONFIRM APPROVE YES**

| Lane | Confirm |
|------|---------|
| Product | YES — safe for writing-plans |
| Engineering | YES — interfaces locked |
| Adversarial | YES after locking non-vacuous `ANSWERED`, token mutex, exit-code matrix, §5 supersede one-liner |

**Gate:** writing-plans allowed; **product code still forbidden** until owner says execute on the W2 implementation plan.
