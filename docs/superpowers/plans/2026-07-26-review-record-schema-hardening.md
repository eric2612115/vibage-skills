# Review-record schema hardening — implementation plan

**Spec:** `docs/superpowers/specs/2026-07-26-review-record-schema-hardening-design.md` — frozen after
eight plan-loop rounds. The spec is authoritative; this plan only sequences the work.
**Baseline:** `58c553a`
**Blast class:** `gate` (touches `scripts/lib/`), so the Impl review record needs at least two
reviewers with at least two distinct contexts.

Plan loop already frozen. Do not add plan-review steps to the todos below.

## What this changes

`scripts/lib/review_record.py` currently ignores any front-matter line it does not recognise, which
lets a reviewer's failure be visible in the record file and invisible to the gate. The spec inverts
that default and adds five rules around it. All the reproduced defects, the exact rules, the pinned
scanning decisions, and the error strings are in the spec; do not re-derive them.

## Files

| File | Work |
|------|------|
| `scripts/lib/review_record.py` | spec §4.1 through §4.5 |
| `tests/test_review_record.sh` | every case in spec §5, appended — the existing file must not lose or change a single assertion |
| `references/looping-review.md` | spec §4.7: `verdict` is required, the delimiter must be an unindented line of its own, and the two disclosures §4.5 and §6.1 assign here |

Nothing else. `scripts/verify-review-record.sh`, `scripts/pack-health.sh`, `README.md`,
`references/review-budget.md`, `adapters/**` and `skills/**` were each checked during the plan loop
and say nothing that becomes false.

## Steps

1. **Rewrite `parse_front_matter`** per spec §4.2, §4.3, §4.3.1, §4.3.2, §4.4 and §4.4b: line-oriented
   delimiter with no leading whitespace, seven recognised shapes with the two whitelists, container
   keys with no inline value, `id` as a simple token, duplicate-key detection, `text.split("\n")`
   with control-character rejection. Collect findings under `_parser_errors` as §4.5 pins.
2. **Add the validator rules** per spec §4.1 and §4.3.3: the verdict vocabulary with its exact error
   strings, and the `frozen` literal rule with the quote handling §4.3.3 pins. Extend `validate_record`
   from `_parser_errors` as its first action.
3. **Add the S5 disclosure line** per spec §4.5, using the predicate pinned there. It must never fail
   the gate.
4. **Append the test cases** from spec §5. Every negative case asserts the token, the `reason=`, and
   the specific error text — a bare `REVIEW_RECORD_FAIL` would also be printed by an over-strict
   wrong implementation.
5. **Update `references/looping-review.md`** per spec §4.7.
6. **Run the verification plan** in spec §6, every step, including its step-5 clean-checkout
   precondition.

## Acceptance

Parse stdout tokens; `exit 0` proves nothing.

- `bash tests/test_review_record.sh` prints `REVIEW_RECORD_TEST_OK`
- `git diff --stat tests/test_review_record.sh` shows insertions only, zero deletions
- all eleven records under `docs/evidence/reviews/` still parse with an empty `_parser_errors` and
  match the reviewer counts and verdicts in spec §4.6
- `bash scripts/test-tier0.sh` prints `TIER0_OK`
- `bash tests/test_pack_health.sh` is green **on a clean checkout**; on the working tree it will
  print `REVIEW_RECORD_FAIL reason=missing_record` until the Impl record exists, which is the gate
  working

## Notes for whoever implements this

Four independent dry runs implemented this spec from the document alone and reached green, so the
contract is executable. The things they got wrong on the first attempt, all now pinned in the spec
but worth reading twice: the shape 7 payload offset is eight characters, not six; shape 5 is tested
before shape 4; an unrecognised line must not stop the scan; and `frozen` is compared
case-sensitively, so `.lower()` is wrong.
