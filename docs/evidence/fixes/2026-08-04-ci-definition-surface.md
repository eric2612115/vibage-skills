# Fix report — CI definition surface (v0.9.3.4)

Closes the one residual v0.9.3.3 disclosed that cost nothing to use. Other residuals from
that release remain; see the list at the end.

## The hole

v0.9.3.3 gated hub-state writers, acceptance definers, and the suites CI runs, and it
disclosed a few shapes that still slip. Most of them cost something to use: adding
`tools/verify-x.sh` does nothing until a gated file calls it, and turning an exempt script
into an acceptance carrier needs the same kind of wiring commit.

One shape did not cost anything. Only `.github/workflows/tier0.yml` was a trigger, and the
CI-suite derivation read workflow files for literal `tests/test_*` references. So:

1. add `.github/actions/run-suite/action.yml` running `bash tests/test_sneaky.sh`
2. add `.github/workflows/nightly.yml` whose only step is `uses: ./.github/actions/run-suite`

Neither file was a trigger, and the suite name lived where the derivation never looked.
Measured on an isolated clone before the fix: `REVIEW_RECORD_SKIP reason=no_trigger_paths`
and `REVIEW_RECORD_TEST_OK` — no record demanded, no check red.

What that buys is narrower than it sounds. It cannot loosen an existing gate: `tier0.yml`
was already a trigger, so removing or weakening the `tier0` / `pack-health` /
`review-record` / `status-lints` jobs still needed a record. What it buys is an
**ungoverned new suite** — coverage that looks real and can then be weakened freely.

## Fix

**All of `.github/` is gate class, with metadata carved out.** The first draft named
`.github/workflows/**` and `.github/actions/**`; a reviewer immediately pointed at
`.github/scripts/**` as the next carrier, which is the predicate-chasing this design keeps
losing to. So the rule is inverted: everything under `.github/` is CI definition unless it
is listed repo metadata — the `ISSUE_TEMPLATE/`, `PULL_REQUEST_TEMPLATE/`, and
`DISCUSSION_TEMPLATE/` directories, plus `CODEOWNERS`, `dependabot.yml`/`.yaml`,
`FUNDING.yml`, `README.md`, `SECURITY.md`, `SUPPORT.md`, `CONTRIBUTING.md`,
`CODE_OF_CONDUCT.md`, and the single-file template spellings. A partition test over
`git ls-files .github` fails on anything that is neither.

The carve-out is deliberately short. Anything not on it — `labeler.yml`, `release.yml`,
`copilot-instructions.md` and similar furniture — will demand a record when it first
appears, which is over-gating rather than a false green, and the partition forces the
classification to be made consciously.

**The derivation reads composite actions too**, recursively over `.github/workflows/` and
`.github/actions/`, so a suite reachable only through an action is still discovered.

**Discovery is one function.** A reviewer noted the first simulation re-implemented the scan
on a private tree, so the shipped logic could regress while the assertion stayed green.
`discover_ci_suites(root)` is now called by both the live check and the simulation.

`.github/workflows/tier0.yml` left `TRIGGER_GATE_EXACT` — the prefix covers it.

## Verification

On an isolated clone with `main` fast-forwarded to the branch tip, so only the probe commit
differs:

| Probe | Before (v0.9.3.3) | After |
|-------|-------------------|-------|
| composite action + workflow running an ungated suite | `REVIEW_RECORD_SKIP`, derivation green | `REVIEW_RECORD_FAIL reason=missing_record`, derivation reports `tests/test_sneaky.sh` ungated |
| new workflow with no test reference at all | `REVIEW_RECORD_SKIP` | `REVIEW_RECORD_FAIL reason=missing_record` |
| editing `.github/scripts/run-ci.sh` after its wiring already landed | `REVIEW_RECORD_SKIP` | `REVIEW_RECORD_FAIL reason=missing_record` |
| editing a root `Makefile` after its wiring already landed | `REVIEW_RECORD_SKIP` | `REVIEW_RECORD_SKIP` — still open, see residuals |

Both layers fire independently: the record gate on the changed CI files, and the derivation
on the hidden suite name.

## Regression tests

`tests/test_review_record.sh`:

- `.github/workflows/other.yml`, `.github/actions/run-suite/action.yml`,
  `.github/scripts/run-ci.sh`, and a nested `workflows/nested/deep.yml` assert `is_trigger`
  and `classify_path == "gate"`; `CODEOWNERS`, `dependabot.yml`, `.github/README.md`, and
  the template forms assert not a trigger — the prefix does swallow `.github/`, and the
  carve-out list is what holds metadata out
- directory carve-outs are asserted to end in `/`. A reviewer found
  `.github/PULL_REQUEST_TEMPLATE` written without one, which also matched
  `.github/PULL_REQUEST_TEMPLATE_x/action.yml` and handed back the composite-action carrier
  this release closes; `_x/action.yml`, `TEMPLATEsneaky.yml`, and `ISSUE_TEMPLATE_x/run.sh`
  are now asserted to be triggers
- a temp-tree simulation builds a workflow that only calls a composite action and asserts
  the derivation still discovers `tests/test_sneaky.sh` — this does not depend on the repo
  owning a composite action today

The frozen `assert not is_trigger(".github/workflows/other.yml")` was deliberately flipped;
it recorded the decision this release reverses.

## Cost

One more record whenever anything under `.github/` other than metadata changes. Replaying
the last 150 commits: 8 touched `.github/workflows/**` (all `tier0.yml`) and every one of
them already required a record because `tier0.yml` was an exact trigger; 0 touched
`.github/actions/**`. So the added historical burden is zero — but this repo has exactly one
workflow file, so that is a small-sample observation, not a forecast for a repo that later
grows several workflows or a composite action.

## Residual risk

Carried forward from v0.9.3.3, unchanged unless noted:

| Residual | Needs a gated commit first? |
|----------|------------------------------|
| `scripts/lab/**` is excluded by rule; the harness is trusted to run on `/tmp` copies | **No** — a lab edit needs no record. The exclusion is convention, not enforcement |
| A new top-level `bin/` / `tools/` holding acceptance logic | Yes — wiring it in edits a gated file |
| An exempt script turned into an acceptance carrier | Yes — same |
| A root `Makefile` / task runner invoked by a workflow, edited after wiring | Yes for the wiring; **no** for later edits. Measured `SKIP` above. This repo has no such runner today |
| A third-party action's own body | Out of reach entirely |
| Suite paths assembled from variables inside a runner | Derivation misses the name, though the file holding it is now a trigger |
| The partition is enforced by the review-record CI job, not by the gate script | An unclassified-only commit `SKIP`s the gate and is caught by CI |

The structural claim is narrower than "nothing escapes": you cannot statically enumerate
every file a runner might reach. What is enforced is that the **wiring** — the moment
something becomes part of what CI runs — happens in a gated file.

## Honesty

- Exercised against fixtures and an isolated clone; no live parent was mutated.
- This closes the shape reviewers found and the `.github/scripts/**` variant they found
  next. It does not prove no other shape exists; the table above is what is known.
- An earlier draft of this report called this "the last residual escape" and lumped
  `scripts/lab/**` in with the shapes that need a gated commit first. A reviewer showed both
  were wrong: lab edits need no record at all.
- Gating CI definition forces a record; it does not guarantee a reviewer notices a job that
  quietly stops running something.
