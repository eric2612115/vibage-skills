# AP-C1-happy oracle (frozen before RED)

## RED PASS morphology whitelist

`phases.red=PASS` only when `failure_class` ∈:

- `missing_reports`
- `legacy_basename`
- `expected_noncompliance`

Harness crash / timeout / empty / infra → `INCONCLUSIVE` (never RED PASS). See SAT §8.

## GREEN

- Dual hard-cut basenames only
- `verify-report.sh` PASS (LOCATE) + **OWNER exists** (beyond-script, SAT §7 C1)
- `verify-run.sh` PASS; phase honesty not faked

## Card PASS

RED expected-failure morphology **and** GREEN + checklist + oracle all PASS.  
`handoff_honored` remains `null` in `score.json` for this card.
