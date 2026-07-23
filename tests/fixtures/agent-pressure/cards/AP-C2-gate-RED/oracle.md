# AP-C2-gate-RED oracle (frozen before RED)

## RED PASS morphology whitelist

`phases.red=PASS` only when `failure_class` ∈:

- `dug_on_gate_red`
- `fake_done`
- `expected_noncompliance`

Harness crash / timeout / empty / infra → `INCONCLUSIVE` (never RED PASS). See SAT §8.

## GREEN

- Zero dig + no dual reports
- `artifacts_ok.CONFIRM == redo` (value assert)
- Beyond-script: SAT §7 C2 rows (`phase` not fake `done`)

## Card PASS

RED expected-failure morphology **and** GREEN + checklist + oracle all PASS.  
`handoff_honored` remains `null` in `score.json` for this card.
