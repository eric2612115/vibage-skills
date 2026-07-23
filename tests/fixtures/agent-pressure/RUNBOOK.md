# Focus agent-pressure — dual-phase runbook

Approach 1 honesty: **thin harness** — invoke existing `assert_gate` / `verify-*` plus scorer beyond-script asserts. **No** new FSM engine.

SSOT: `docs/superpowers/specs/satellites/SAT-agent-pressure.md`  
Plan: `docs/superpowers/plans/2026-07-23-vibage-focus-agent-pressure.md`

## 1. Freeze

Before any RED agent starts, confirm all three cards have on-tree frozen templates:

- `tests/fixtures/agent-pressure/cards/AP-C1-happy/{card,checklist,oracle}.md`
- `tests/fixtures/agent-pressure/cards/AP-C2-gate-RED/{card,checklist,oracle}.md`
- `tests/fixtures/agent-pressure/cards/AP-C3-handoff-resume/{card,checklist,oracle}.md`

Post-hoc checklist edits do **not** count as a match (SAT A3).

## 2. Isolate

- Two **fresh** agents per card; **no** shared transcript; separate directories.
- Visible inputs: frozen card templates, synthetic-parent **copy**, skills/scripts allowed for that phase.
- Do **not** use product `docs/vibage/` as Focus scratch.
- GREEN must not inherit RED disk pollution (scorer may read both read-only).

## 3. RED

- Agent1 **without** Vibage skill.
- Record under `tests/artifacts/agent-pressure/<run_ts>/<card_id>/red/`.
- Scorer needs a **positive** expected-failure morphology (SAT §6.3); crash/timeout/empty → INCONCLUSIVE, never RED PASS.

## 4. GREEN

- Agent2 **with** Vibage skill; separate directory; same frozen card.
- Record under `tests/artifacts/agent-pressure/<run_ts>/<card_id>/green/`.

## 5. Score

- Third / separate turn (not Agent1 or Agent2 reusing the chat).
- Write `tests/artifacts/agent-pressure/<run_ts>/<card_id>/score/score.json` per SAT §8 schema.
- Beyond-script asserts per SAT §7 (C1 OWNER exists; C2 zero dig + CONFIRM=redo; C3 `handoff_honored`).

## 6. Pack

- Evidence packs only under gitignored `tests/artifacts/agent-pressure/`.
- Never dump RUNS / chat / evidence into product `docs/vibage/`.

### Pack layout

```text
tests/artifacts/agent-pressure/<run_ts>/
  AP-C1-happy/
    red/
    green/
    score/score.json
  AP-C2-gate-RED/
    red/
    green/
    score/score.json
  AP-C3-handoff-resume/
    red/
    green/
    score/score.json
```

## 7. Roles table

| Role | Phase | Skill |
|------|-------|-------|
| Agent1 | RED | **without** Vibage skill |
| Agent2 | GREEN | **with** Vibage skill |
| Scorer | Score (separate) | frozen checklist + oracles → `score.json` |

Per card = exactly two agent-runs + scorer.  
**Forbidden:** Runner A/B each doing full RED→GREEN (would be four runs per card).

## 8. STATUS rules

- **On-tree** may be YES from fixture / card template presence.
- **Proven-green** only after this-wave required set (`happy` \| `gate-RED` \| `handoff-resume`) all dual-phase scorer-PASS.
- Optional smoke **never** flips Proven-green.
- **locate DONE ⊥ Focus**; Tier-0 is independent (SAT A8).
- Fixture/smoke presence ≠ agent proof.

## 9. Optional structural smoke

```bash
bash tests/test_agent_pressure_smoke.sh
```

Expect: `AGENT_PRESSURE_SMOKE_OK`.

Smoke proves path / gitignore / template presence only. Must **not** enter `scripts/test-tier0.sh`. Smoke green ≠ Focus green.
