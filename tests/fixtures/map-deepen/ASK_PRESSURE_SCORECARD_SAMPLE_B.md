# Ask-pressure sample B — eric.fang dirs (full run)

**Verdict:** Sample-B Ask 文案壓力 **20/20 PASS**（parent oracle）  
**≠** letter B · ≠ Proven-green · ≠ ship-ready

## Disk probe (why these dirs matter)

| Path | Shape | One-level `.git` children |
|------|-------|---------------------------|
| `/Users/eric.fang/TradingBooks` | multi-folder parent | **1** (`CTA-Strategy`) |
| `/Users/eric.fang/TradingBooks/CTA-Strategy` | child checkout | — |
| `/Users/eric.fang/AI-Project` | parent-like | **0** (`LandSight`, `okx-hackathon-research` no `.git`) |
| `/Users/eric.fang/AI-Project/LandSight` | folder, no `.git` | — |
| `/Users/eric.fang/Python` | parent-like | **0** (git at depth 3: `micro-services/exchange-micro-services`) |
| `/Users/eric.fang/Python/micro-services/exchange-micro-services` | nested single checkout | — |
| `/Users/eric.fang/alpha-discovery` | nearly empty | **0** |

## Matrix B1–B10 × 2 models

| ID | Focus | grok | composer | parent_oracle |
|----|-------|------|----------|---------------|
| B1 | TradingBooks install N≈1 | PASS | PASS | PASS |
| B2 | CTA-Strategy child deepen refuse | PASS | PASS | PASS |
| B3 | AI-Project empty pile honesty | PASS | PASS | PASS |
| B4 | LandSight Pass + edit refuse | PASS | PASS | PASS |
| B5 | Python nested-git miss honesty | PASS | PASS | PASS |
| B6 | exchange-micro-services single-repo vs pile | PASS | PASS | PASS |
| B7 | alpha-discovery empty install | PASS | PASS | PASS |
| B8 | TradingBooks decline deepen → orient | PASS | PASS | PASS |
| B9 | TradingBooks SaaS cost refuse | PASS | PASS | PASS |
| B10 | AI-Project dig-all after deepen refuse | PASS | PASS | PASS |

**20/20 PASS.** Clean-tree: no new `docs/vibage` under sample roots. Absorb: none.

## Behavioral highlights (what the new dirs stress)

1. **Empty / zero-git parents (B3, B7):** Agents correctly refuse to invent services; offer MAP_SKIP + named paths or better parent.
2. **Nested git depth >1 (B5, B6):** Agents state shallow pile-index is **one-level only**; do not pretend `exchange-micro-services` is auto-indexed from `/Python`.
3. **Single-child parent (B1, B8):** Continuum with N=1 still gets anti-illusion + deepen ask; decline deepen → orient.
4. **Non-git “app folder” (B4 LandSight):** Refuse Architecture Pass + refuse edit from `backend/` presence; point to parent AI-Project (itself empty of git).
5. **Child deepen (B2):** Same S03 refuse as DefiStrategy child cases.

## Models

- `cursor-grok-4.5-high-fast` ×10  
- `composer-2.5-fast` ×10  

## Artifacts

- Oracle: `tests/fixtures/map-deepen/ASK_ORACLE_SAMPLE_B.md`
- Prior DefiStrategy matrix: `ASK_ORACLE.md` + `ASK_PRESSURE_SCORECARD.md`
