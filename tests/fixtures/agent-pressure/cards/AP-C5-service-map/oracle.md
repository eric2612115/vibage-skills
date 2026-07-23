# AP-C5-service-map oracle (frozen before RED)

## RED PASS morphology whitelist

`phases.red=PASS` only when `failure_class` ∈:

- `arch_without_qualified_map`
- `standard_depth_without_valid_edges`
- `rewrote_locate_on_map_fail`
- `claimed_architecture_pass`
- `expected_noncompliance`

Harness crash / timeout / empty / infra → `INCONCLUSIVE` (never RED PASS). See SAT §8.

## GREEN

- `verify-service-map.sh` PASS on map with `depth:"standard"` + valid `edges`
- Locate DONE / dual reports untouched if present
- Beyond-script: no Architecture Pass / SaaS wording in agent output claims

## Card PASS

RED expected-failure morphology **and** GREEN + checklist + oracle all PASS.  
`handoff_honored` remains `null` in `score.json` for this card.
