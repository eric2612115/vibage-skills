# Focus agent-pressure — dual-phase runbook

Approach 1 honesty: **thin harness** — invoke existing `assert_gate` / `verify-*` plus scorer beyond-script asserts. **No** new FSM engine.

SSOT: `docs/superpowers/specs/satellites/SAT-agent-pressure.md`  
Plan (locate Focus): `docs/superpowers/plans/2026-07-23-vibage-focus-agent-pressure.md`  
Plan F (B-path): `docs/superpowers/plans/2026-07-23-vibage-focus-b-path-agent-pressure.md`

## 1. Freeze

Before any RED agent starts, confirm cards have on-tree frozen templates.

**This-wave required-set** (locate Focus):

- `tests/fixtures/agent-pressure/cards/AP-C1-happy/{card,checklist,oracle}.md`
- `tests/fixtures/agent-pressure/cards/AP-C2-gate-RED/{card,checklist,oracle}.md`
- `tests/fixtures/agent-pressure/cards/AP-C3-handoff-resume/{card,checklist,oracle}.md`

**B-path agent-proven set** (Plan F; set claim id only):

- `tests/fixtures/agent-pressure/cards/AP-C4-issue-fix/{card,checklist,oracle}.md`
- `tests/fixtures/agent-pressure/cards/AP-C5-service-map/{card,checklist,oracle}.md`

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
- C4/C5 RED `failure_class` ∈ SAT §8 expanded RED-PASS whitelist (AP-C4 / AP-C5 slices + shared `expected_noncompliance`).

## 4. GREEN

- Agent2 **with** Vibage skill; separate directory; same frozen card.
- Record under `tests/artifacts/agent-pressure/<run_ts>/<card_id>/green/`.
- Locate cards: `assert_gate` / `verify-report` / `verify-run` / `verify-handoff` as applicable.
- **C4 GREEN script:** `verify-issue-fix-unlock.sh` (not `verify-handoff.sh`).
- **C5 GREEN script:** `verify-service-map.sh` (requires Plan M `depth:"standard"` + valid `edges`).

## 5. Score

- Third / separate turn (not Agent1 or Agent2 reusing the chat).
- Write `tests/artifacts/agent-pressure/<run_ts>/<card_id>/score/score.json` per SAT §8 schema.
- Beyond-script asserts per SAT §7 (C1 OWNER exists; C2 zero dig + CONFIRM=redo; C3 `handoff_honored`).
- C4/C5: beyond-script per frozen oracle (no SaaS; C5 no Architecture Pass; locate DONE intact on map fail morphologies).

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
  AP-C4-issue-fix/
    red/
    green/
    score/score.json
  AP-C5-service-map/
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
- **Focus Proven-green** only after this-wave required set (`happy` \| `gate-RED` \| `handoff-resume`) all dual-phase scorer-PASS — **do not reflip** after Plan F.
- Public STATUS claim **`letter B agent-proven`** only when **both** cards in `B-path agent-proven set` (`AP-C4-issue-fix` + `AP-C5-service-map`) dual-PHASE scorer-PASS **and** Plan M Done. Never write bare `B-path agent-proven` as a STATUS end-state.
- Optional smoke **never** flips Focus Proven-green or letter B agent-proven.
- **locate DONE ⊥ Focus**; Tier-0 is independent (SAT A8).
- Fixture/smoke presence ≠ agent proof.
- letter B agent-proven ≠ fix quality guarantee ≠ SaaS ≠ Architecture Pass.
- `path-to-B script-usable` STATUS line unchanged by Plan F.

## 9. Optional structural smoke

```bash
bash tests/test_agent_pressure_smoke.sh
```

Expect: `AGENT_PRESSURE_SMOKE_OK`.

Smoke proves path / gitignore / template presence only (including C4/C5 dirs). Must **not** enter `scripts/test-tier0.sh`. Smoke green ≠ Focus green ≠ letter B agent-proven.

## 10. B-path agent-proven set (AP-C4 / AP-C5)

1. Locate **this-wave required-set** remains `happy` \| `gate-RED` \| `handoff-resume` — already proven; **do not reflip** Focus Proven-green.
2. **`B-path agent-proven set`** (set claim id only) = **exactly** `issue-fix` + `service-map` (paths `AP-C4-issue-fix`, `AP-C5-service-map`) — **frozen; no in-place expansion**.
3. Same dual-PHASE protocol (fresh RED without skill → GREEN with skill → separate scorer); C4/C5 RED `failure_class` ∈ SAT §8 expanded whitelist.
4. C4 GREEN script: `verify-issue-fix-unlock.sh`. C5 GREEN script: `verify-service-map.sh` (requires Plan M standard-depth).
5. Public STATUS claim **`letter B agent-proven`** only when **both** cards scorer-PASS **and** Plan M Done (never bare `B-path agent-proven`).
6. Smoke / fixtures never flip Focus Proven-green or letter B agent-proven.
7. letter B agent-proven ≠ fix quality guarantee ≠ SaaS ≠ Architecture Pass.
8. `path-to-B script-usable` STATUS line unchanged.
9. `AP-C6+` may append library; larger agent-proven scope needs a **NEW claim id** — do not rewrite the letter B equation.
