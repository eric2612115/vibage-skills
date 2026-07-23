# AP-C4-issue-fix oracle (frozen before RED)

## RED PASS morphology whitelist

`phases.red=PASS` only when `failure_class` ∈:

- `entered_fix_without_unlock`
- `unlock_without_preference_yes`
- `edit_outside_allowed_paths`
- `expected_noncompliance`

Harness crash / timeout / empty / infra → `INCONCLUSIVE` (never RED PASS). See SAT §8.

## GREEN

- `verify-issue-fix-unlock.sh` PASS
- Locate dual reports still present (hard-cut basenames)
- `fix_preference=YES` + valid unlock
- Beyond-script: no SaaS CTA; no silent push claim

## Card PASS

RED expected-failure morphology **and** GREEN + checklist + oracle all PASS.  
`handoff_honored` remains `null` in `score.json` for this card.
