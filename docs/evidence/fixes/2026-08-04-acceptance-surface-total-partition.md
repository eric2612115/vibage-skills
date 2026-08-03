# Fix report — acceptance surface + total partition (v0.9.3.3)

Closes the two residual risks v0.9.3.2 disclosed.

## Hole 1 — verify scripts define what passing means, and were not gated

v0.9.3.2 gated the scripts that WRITE owner hub state. Reviewer B named the other half:

> "Read-only so no review" is true for hub mutation, false for acceptance definition.
> Changing `verify-matrix-substantive.sh` can turn FAIL→OK with `REVIEW_RECORD_SKIP`.

A verify script never touches the state it judges, so the writers-only rule let someone
loosen the definition of green without any record. The two halves are symmetric: one writes
the claim, the other decides whether the claim passes.

**Fix.** `TRIGGER_GATE_ACCEPTANCE_PREFIXES = ("scripts/verify-",)` — every `verify-*.sh` is
gate class **by prefix**, so a verify script added tomorrow is gated the moment it exists
rather than when someone remembers to list it. Named non-`verify-` checkers join it:
`freshness-check.sh`, `env-vacancy-check.sh`, `scene-validate.sh`, `scene-classify.sh`,
`scripts/lib/report_token_lint.py`, and `scripts/lib/require_rg.sh` (a fail-closed
dependency guard — weakening it would let slogan/copy checks pass silently).

`scripts/lab/verify-l1-done.sh` stays out: the prefix is `scripts/verify-`, and the lab
harness judges copies under `/tmp`, never a real owner hub.

This also settles a contradiction that predates the batch. `references/review-budget.md`
had always claimed `scripts/verify-*.sh` was gate class; `references/looping-review.md` said
"not blanket `verify-*`"; the code agreed with neither in a stable way. Both documents now
say the same thing as `is_trigger()`.

## Hole 2 — the partition had a predicate, and predicates are evadable

v0.9.3.2's guard scanned scripts that mention `docs/vibage`. A reviewer evaded the version
before it with `open().write` / `tee` / `cp`, and evaded that one with a hub path built from
variables. That was not hypothetical: `dimension-fill.sh`, `dimension-search.sh`, and
`env-vacancy-answer.sh` mutate hub state through `scripts/lib` and never spell the path —
they were outside the allow-list and outside the scan.

**Fix.** The partition has no predicate now. Every non-lab file under `scripts/` is either a
trigger or is named in `NON_GATE_EXEMPT` with a reason. Five exemptions remain:

| Path | Reason |
|------|--------|
| `generate-service-map-graph.sh`, `render-service-map-preview.sh` | presentation — render a view, mint no verdict |
| `serve-preview.sh` | presentation — fail-soft localhost server |
| `resolve-pkg-root.sh` | path resolution — reads symlinks, no hub state, no token |
| `lib/__init__.py` | package marker |

A new script cannot land unclassified: the suite fails and names it. The three wrapper
writers found by removing the predicate were added to `TRIGGER_GATE_HUB_WRITERS` (now 20).

## Cost

Gate surface is 37 exact paths plus the `scripts/verify-` prefix (23 scripts today).
Replaying the last 60 commits on `main`: **2 would newly require a review record**, 26
already required one, 32 needed none. Both new ones are the `matrix-inventory.sh` fixes from
this same thread — which is the surface the gate is meant to cover.

## Regression tests

`tests/test_review_record.sh` → `TRIGGER_HUB_WRITERS_OK n=20 acceptance=29 exempt=5`:

- total partition over `scripts/**` with the exempt list carrying reasons
- every `verify-*.sh` on disk is a trigger and classifies `gate`
- a not-yet-written `scripts/verify-not-yet-written.sh` is already gated (prefix, not memory)
- `scripts/lab/verify-l1-done.sh` is not gated
- each exempt path exists and is not also a trigger
- frozen membership for the 20 hub writers and the 6 named acceptance checkers

Two frozen assertions were deliberately flipped, since they recorded the decision this
release reverses: `verify-freshness.sh` now asserts `is_trigger` / `classify_path == "gate"`.
The `no_trigger_paths` fixture that used `verify-freshness.sh` as its stand-in for an
unlisted script now uses `resolve-pkg-root.sh`.

## Honesty

- Exercised against fixtures and local gates; no live parent was mutated.
- Gating an acceptance definer means an edit needs a record. It does not mean the reviewer
  will notice a loosened threshold — `REVIEW_RECORD_OK` is still not review quality.
- The partition guarantees classification, not correctness: a hub writer wrongly filed as
  exempt would still slip. The exempt list is 5 entries precisely so it stays auditable.
- `scripts/lab/**` is excluded by rule. If the lab harness ever writes a real owner hub,
  that exclusion becomes wrong.
- The 60-commit cost replay describes this repo's history, not future workload.
