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

**Fix.** The partition enumerates `git ls-files scripts` — every tracked file, any
extension — and each is either a trigger or is named in `NON_GATE_EXEMPT` with a reason.
Six exemptions remain:

| Path | Reason |
|------|--------|
| `generate-service-map-graph.sh` | presentation — writes `graph.mmd` / notes, mints no gate token |
| `render-service-map-preview.sh` | presentation — writes preview assets, mints no gate token |
| `serve-preview.sh` | presentation — copies preview assets and serves localhost; no verdict |
| `resolve-pkg-root.sh` | path resolution — reads symlinks, no hub state, no token |
| `lib/__init__.py` | package marker |
| `hooks/vibage-child-post-commit.sample` | sample hook — not installed or executed by the pack |

A first draft kept a `.sh`/`.py` suffix filter, and a reviewer walked straight through it
with `scripts/check-matrix.mjs` and an extensionless script. Enumerating tracked files
removes that last predicate. The three wrapper writers found by dropping the earlier
`docs/vibage` predicate joined `TRIGGER_GATE_HUB_WRITERS` (now 20).

## Cost

Trigger surface is 37 exact gate paths plus the `scripts/verify-` prefix (23 scripts today),
plus 4 CI-run suites added to the `tests` class.

Replaying commits reachable from `0dd2d3d` (v0.9.3.2) with that release's allow-list versus
this one (`--no-renames`, merge commits with empty trees counted under "none"):

| Window | Newly require a record | Already required one | None | Touched a newly gated path |
|--------|------------------------|----------------------|------|-----------------------------|
| last 60 | **0** | 28 | 32 (7 merge/empty) | 6 |
| last 150 | **3** | 89 | 58 (10 merge/empty) | 37 |

Method, so this is reproducible: commits from `git log -N --format=%H 0dd2d3d`; files from
`git show --pretty= --name-only --no-renames <sha>`; a commit with an empty file list (the
PR merge commits) counts under "none"; "touched a newly gated path" counts any commit with a
path that is a trigger now and was not at `0dd2d3d`, whichever column it lands in.

A reviewer's independent replay returned 88 / 59 / 11 for the 150 window. Enumerating the
empty-diff commits in that window shows exactly 10, all of them PR merges #1–#10, so the
table above is the one that reconciles.

Sixty commits is a short and favourable window; the 150-commit figure is the honest one to
quote. Even there the added burden is 3 records across 150 commits, because most edits to a
newly gated path already carried another trigger.

That is history, not a forecast. Forward cost is one record per edit to a verify script, a
named checker, or a CI-run suite — the surfaces where a change alters what "passing" means.

Two earlier drafts got this wrong and reviewers caught both: the first quoted "2 of the last
60", which was the **v0.9.3.2 hub-writer** delta measured against a pre-`26b082a` baseline;
the second quoted a "none" count that had silently dropped merge commits.

## Hole 3 — renaming a path out of the allow-list escaped the gate

Found during review, same class as the other two. `changed_paths()` used
`git diff --name-only`, which is rename-aware and reports only the destination. So
`git mv scripts/verify-matrix-substantive.sh scripts/check-matrix-substantive.sh` produced
`REVIEW_RECORD_SKIP reason=no_trigger_paths` — the guarded source path vanished from the
diff. Moving a file out of the gate is precisely the edit that must not escape review.

**Fix.** `changed_paths()` passes `--no-renames`, so both the old and new paths appear and
the guarded source still counts. Reproduced on an isolated clone — the same rename now
yields `REVIEW_RECORD_FAIL reason=missing_record` — and locked by a fixture in
`tests/test_review_record.sh` that renames a guarded path and fails if the result is
`no_trigger_paths` or if the renamed-away path is missing from the trigger list.

A record for such a rename is still producible: the deleted source hashes as `missing` in
`compute_diff_id`, so a record written for that `diff_id` validates normally.

## Hole 4 — the regression suites CI runs were not all gated

`TRIGGER_TESTS_EXACT` is a frozen enumeration, and it omitted `test_proven_lock.sh`,
`test_status_capability_table.sh`, `test_c_prime_matrix_durability.sh`, and
`test_install_pins_report.sh` — the last two being the regressions added for the v0.9.3
matrix bug and the pin-ordering bug. Weakening or deleting one needed no record: editing
what "still locked" means was a no-ceremony change.

**Fix.** Those four joined the enumeration, and the suite now DERIVES the required set by
reading `scripts/test-tier0.sh`, `scripts/pack-health.sh`, and **every**
`.github/workflows/*.yml`, failing if any CI-run suite is not a trigger. (A reviewer showed
a hard-coded `tier0.yml` source list would miss a new `nightly.yml`, so the workflow
directory is globbed.)

The derivation reads literal `tests/test_*` references. A path assembled from shell
variables would slip it — but the commit that wires it into a runner edits a gated file, so
the wiring itself needs a record.

## Regression tests

`tests/test_review_record.sh` → `TRIGGER_HUB_WRITERS_OK n=20 acceptance=29 exempt=6`:

- total partition over every tracked file under `scripts/` with the exempt list carrying reasons
- every suite referenced by a CI runner is a trigger (derived, not hard-coded)
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
  exempt would still slip. The exempt list is six entries precisely so it stays auditable.
- `scripts/lab/**` is excluded by rule. A reviewer noted `lab/continuum.sh`,
  `lab/seed-lab-scan-plan.sh`, and `lab/mint-lab-confirm.sh` accept a parent path and write
  `docs/vibage` inside it; callers copy under `/tmp` first, so the exclusion rests on that
  convention rather than on an enforced write gate. Disclosed, not closed.
- The partition covers `scripts/`. A new top-level `bin/` or `tools/` holding acceptance
  logic is outside it. Wiring such a script into the pack requires editing a gated caller,
  so the wiring commit needs a record — but later edits to the out-of-tree helper would not.
- Same shape as above: an exempt script could be turned into an acceptance carrier by a
  gated wiring commit, after which edits to it are unreviewed. The exempt list is six
  entries precisely so that stays auditable.
- The cost replay describes this repo's history, not future workload.
- The CI derivation reads `scripts/test-tier0.sh`, `scripts/pack-health.sh`, and
  `.github/workflows/*.y*ml`. A reviewer showed two shapes still slip it: a suite run from a
  composite action under `.github/actions/**`, and a workflow in a nested directory (which
  GitHub itself ignores). Neither exists in this pack today.
- Globbing workflows is fail-closed in the other direction too: a `tests/test_*` path
  mentioned in a workflow comment or a `paths:` filter is read as CI-run and must be gated.
