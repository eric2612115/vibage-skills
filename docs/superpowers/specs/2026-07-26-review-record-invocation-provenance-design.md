# Review-record invocation provenance (Lens A finding B)

**Date:** 2026-07-26
**Status:** PARKED mid-loop, **not frozen**, direction changed. Do not implement this document as
written. It is batch 2 of three; batch 1 (record-schema hardening) goes first.
**Plan loop:** round 1 = 3× BLOCK (six items); round 2 = BLOCK / APPROVE_WITH_GAPS / BLOCK (four
items); round 3 = APPROVE / BLOCK / APPROVE_WITH_GAPS. Round 3's BLOCK was a design-shape objection
rather than a detail, and the owner accepted it, so the document must be reshaped before it can
freeze. Every folded item was re-verified against source by the author; see §8.

**Reshape required before round 4.** The owner chose the option below over the design currently
written in §4:

- Remove `--paths-file` / `--base` forwarding from the production entry point
  `scripts/verify-review-record.sh`, so the documented command has no injection surface at all.
  The flags survive only on direct `scripts/lib/review_record.py` invocation, which is where the
  tests will call them from (a mechanical change to 22 call sites, no test logic rewritten).
- Keep the token namespace split from §4.1, because it is what actually makes a production success
  token unreachable on the library path too. Defence in depth, not a substitute.
- Add exactly one integration test that builds a real temporary git repository and drives the
  production path end to end. The suite has 22 flag-driven cases, one production-path call that
  asserts nothing (`tests/test_review_record.sh:903`), and **no `git init` anywhere**, so today it
  barely exercises what CI runs. One case recovers most of that without rewriting the other 22.
**Baseline commit:** `58c553a` (main = origin/main at design time)
**Trigger:** Lens A bypass hunt (Opus 5 reviewer) reproduced a false-green path where a
curated fixture invocation of `verify-review-record.sh` emits stdout that a reader cannot
distinguish from a real repository-derived run.
**Owner decision:** scope = invocation provenance in the token channel (includes `--base`).
`base == HEAD` semantics and shallow-repository detection are a separate root cause and are
**out of scope here**.

## 1. Problem (reproduced, not suspected)

`scripts/lib/review_record.py` accepts two flags that replace the repository-derived diff:

- `--paths-file=FILE` — replaces the changed-path set with an arbitrary list
- `--base=LABEL` — replaces the base label with an arbitrary string

Only `--paths-file` carries a TEST-ONLY declaration, and only as a source comment
(`scripts/lib/review_record.py:422`). `--base` carries no such declaration anywhere. Neither
reaches stdout. The pack's contract is "parse stdout tokens", so the one declaration that exists
lives outside the channel that consumers trust.

Reproduction on a scratch clone of `58c553a`, working tree carrying a real modification to
`scripts/lib/review_record.py` (blast class `gate`):

```
$ bash scripts/verify-review-record.sh \
    --paths-file=curated.txt --base=58c553a2eae67c6b20ac0af02b41d6cc943b5753 .
blast_class=tests
review_budget_n=2
diff_id=8135190d…
diff_base=58c553a2eae67c6b20ac0af02b41d6cc943b5753
trigger_count=1
trigger=tests/test_review_record.sh
reviewer_selected_by: owner=2 implementer=0 host_default=0
REVIEW_RECORD_OK path=…
```

Three things are wrong at once: the blast class was downgraded from `gate` to `tests`, the
base label reads as a genuine commit, and the production success token was emitted. The only
difference from a real run is the **absence** of a `review_record_mode=` line. Absence is not
detectable by a human reader and not matchable by grep.

The same absence covers `--base=HEAD` used alone, which turns
`REVIEW_RECORD_FAIL reason=missing_record` into `REVIEW_RECORD_SKIP` with no stdout trace at all.

## 2. Goals

| ID | Goal | Success signal |
|----|------|----------------|
| **B1** | A non-default invocation can never emit a production success token | `REVIEW_RECORD_OK` unreachable whenever a fixture flag is **present in argv** (§4.1.1) |
| **B2** | Every token-emitting path states how the run was invoked | exactly one `review_record_mode=` line and one `review_record_pkg=` line before the token on every path in `main()` |
| **B3** | Consumers cannot be fooled by substring overlap | `pack-health.sh` and `tests/` match tokens with anchored / word-boundary patterns |
| **B4** | Production token literals never appear in fixture-mode output | a test asserts disjointness over the entire captured **stdout and stderr**, not just the token line (§4.3) |

## 3. Non-goals / honesty locks

- ≠ fix `base == HEAD` producing a vacuous empty diff (separate root cause, separate change)
- ≠ add shallow-repository detection
- ≠ change `diff_id` computation, the record schema, or any existing record file
- ≠ change exit-code semantics for any input that is valid today. The one deliberate exception is
  an **empty** flag value, which is currently treated as "flag absent" and becomes a fail-closed
  error (§4.1.1). No existing test or caller passes an empty flag value, so the practical statement
  "exit codes are unchanged" still holds for `tests/test_review_record.sh` and for `pack-health.sh`.
- ≠ make the review-record gate part of Tier-0 (`TIER0_OK` semantics untouched)
- ≠ claim this makes `REVIEW_RECORD_OK` mean review quality. It still does not.
- ≠ claim the flags become unusable. They stay usable; they stop being able to say "production pass".

## 4. Design

### 4.1 Token namespace split

Follow the pack's existing idiom (`FRESHNESS_WAIVED` / `STALE_DISCLOSED`): a non-default state
gets **its own token string**, never a modifier on the OK token. A modifier line can be dropped
when quoting; a different token string cannot, because dropping it leaves no green at all.

| Invocation | Mode value | Success | No triggers | Failure |
|------------|-----------|---------|-------------|---------|
| default resolution, merge-base | `merge_base` | `REVIEW_RECORD_OK` | `REVIEW_RECORD_SKIP` | `REVIEW_RECORD_FAIL` |
| default resolution, tip of main | `head1` | `REVIEW_RECORD_OK` | `REVIEW_RECORD_SKIP` | `REVIEW_RECORD_FAIL` |
| `--paths-file` present | `fixture` | `REVIEW_RECORD_FIXTURE_PASS` | `REVIEW_RECORD_FIXTURE_SKIP` | `REVIEW_RECORD_FIXTURE_FAIL` |
| `--base` present, no `--paths-file` | `base_override` | `REVIEW_RECORD_FIXTURE_PASS` | `REVIEW_RECORD_FIXTURE_SKIP` | `REVIEW_RECORD_FIXTURE_FAIL` |

The suffix is `_PASS`, not `_OK`, so the fixture tokens do not join the pack's `*_OK` product-token
family in any lint or reader habit.

**Trade-off to accept explicitly:** `--base=<other-sha>` alone becomes non-production. Someone who
legitimately wants to diff against an older base loses the production token. This is intended —
default resolution becomes the only path that can say "production pass". Reviewers should push back
here if that cost is judged too high.

### 4.1.1 The mode predicate is argv presence, not value truthiness (HARD)

Today the branch is taken on the *value*: `if paths_file:` and `if base_override:`
(`scripts/lib/review_record.py:421` and `:431`). An empty value therefore behaves as if the flag
were absent — `bash scripts/verify-review-record.sh --base= .` currently resolves the base normally
and can reach `REVIEW_RECORD_OK`. Reusing that logic would leave the hole open through a one-character
change.

The implementation MUST set the mode from a **presence bit computed while scanning argv**: any
element matching `--paths-file=*` or `--base=*`, including an empty value, marks the run non-production.

Empty values are fail-closed, not silently ignored:

| Input | Result |
|-------|--------|
| `--paths-file=` (empty value) | `review_record_mode=fixture` + `REVIEW_RECORD_FIXTURE_FAIL reason=empty_flag_value`, exit ≠ 0 |
| `--base=` (empty value) | `review_record_mode=base_override` + `REVIEW_RECORD_FIXTURE_FAIL reason=empty_flag_value`, exit ≠ 0 |
| `--paths-file=<unreadable>` (missing file, directory, no permission) | `review_record_mode=fixture` + `REVIEW_RECORD_FIXTURE_FAIL reason=paths_file_unreadable`, exit ≠ 0 |
| flag repeated | last value wins, as today; presence bit stays set |

The unreadable case is a defect today, not merely an omission: `bash scripts/verify-review-record.sh
--paths-file=/tmp/does-not-exist.txt .` raises an unhandled `FileNotFoundError` and a directory
argument raises `IsADirectoryError`, so the run ends with a Python traceback and **no token at all**.
Any caller that greps for a token sees nothing, which is the failure shape B2 exists to remove.

A readable `--paths-file` may legitimately point anywhere — a symlink, a path outside the
repository, `/dev/stdin`. No repository-containment check is required, because under the presence
predicate every such run is already confined to the fixture namespace.

The wrapper already rejects the space-separated spelling (`--paths-file FILE`) as an unknown flag
(`scripts/verify-review-record.sh:23-25`), so only the `=` spelling needs handling. Calling
`scripts/lib/review_record.py` directly with a space-separated flag silently ignores it and therefore
cannot inject a curated path list; no change needed, but the implementation must not add support for
that spelling.

### 4.2 Mandatory mode line and package disclosure

Print exactly one of each line, before any token, on every path in `main()` that emits a token:

```
review_record_mode=merge_base|head1|none|fixture|base_override
review_record_pkg=<resolved absolute package root>
```

`none` is the value for the path where base resolution fails. `resolve_base` already returns the
internal string `"none"` (`scripts/lib/review_record.py:207`), and today that path prints the FAIL
token with no mode line at all (`:434-437`). The FAIL token keeps its existing `reason=no_git_base`
suffix; the mode line is not a substitute for it.

Today the mode line is printed only for `head1` and `merge_base`, and never on the `no_git_base`
FAIL path or after a fixture run. It becomes unconditional. The package line is new: the script
accepts an arbitrary directory argument, so "which tree was measured" is part of invocation
provenance, and today it is disclosed only inside the `REVIEW_RECORD_OK path=…` suffix and not on
the SKIP or FAIL paths at all.

Both lines are **secondary** disclosure. The token namespace in 4.1 is the primary signal, because
a line can be dropped when quoting and a token string cannot.

**Scope boundary:** B2 covers the token-emitting paths inside `main()`. The wrapper exits before
Python for `-h|--help` (`scripts/verify-review-record.sh:19-21`), an unknown flag (`:23-25`), a
non-directory argument (`:33`), and a missing library (`:34`). Those emit no token, so they emit no
mode line either. This is intentional and must be stated in the docs rather than left to inference.

### 4.3 Substring safety (the trap in this fix)

Current consumers match without anchors:

```70:70:scripts/pack-health.sh
if ! printf '%s\n' "$RR_OUT" | grep -Eq 'REVIEW_RECORD_(OK|SKIP)'; then
```

`tests/test_review_record.sh` uses `grep -Fq 'REVIEW_RECORD_OK'` in six places.

A naming such as `REVIEW_RECORD_OK_FIXTURE` would be matched by both patterns and would create a
false green **in the fix itself**. The chosen names insert the discriminator before the outcome
word, so no existing pattern can match them. B4 requires this to be asserted by a test rather than
argued in prose.

**The token line is not the only place a production literal can leak.** The success path today ends
with

```500:501:scripts/lib/review_record.py
    print(f"REVIEW_RECORD_OK path={rec_path}")
    print("Honesty: REVIEW_RECORD_OK ≠ review quality ≠ adversarial proof")
```

If the fixture path keeps that honesty line verbatim, `grep -Fq 'REVIEW_RECORD_OK'` matches the
fixture output and the entire fix is defeated by its own disclaimer. This is the pack's known
"do not move a `≠` sentence into verify stdout while consumers use unanchored grep" trap.

Therefore: **no production token literal (`REVIEW_RECORD_OK`, `REVIEW_RECORD_SKIP`,
`REVIEW_RECORD_FAIL`) may appear anywhere in fixture-mode stdout or stderr**, including honesty
lines, NOTE lines, and error messages. Fixture-mode honesty text must be written without naming the
production tokens, for example `Honesty: a fixture run is not a production acceptance path`. The
wrapper's own header line (`scripts/verify-review-record.sh:37`) must be checked against this rule
as well. B4's test asserts over the whole captured output, not the token line.

### 4.4 Consumer changes

- `scripts/pack-health.sh` — match tokens at word boundaries (lines 64 and 70) so a future rename
  cannot silently re-open the overlap. pack-health never passes the flags, so its behaviour is
  otherwise unchanged.
- `tests/test_review_record.sh` — the file drives every case through `--paths-file`, so **every**
  production-token assertion on those paths moves to the fixture namespace, not only the success
  ones. The full list to change: `:170`, `:206`, `:281`, `:487`, `:587`, `:812` (all `REVIEW_RECORD_OK`),
  `:247` (`REVIEW_RECORD_FAIL`), and `:877` (`REVIEW_RECORD_SKIP`). The negative check at `:878`
  ("SKIP must not print `REVIEW_RECORD_OK`") stays as written and gains force under B4.
- **Exit codes are unchanged**, so assertions capturing only an exit code need no edit:
  `D_EC`, `F1_EC`, `F2_EC`, `F3_EC`, `H2_EC`, `I_EC`, `J2_EC`, `J3_EC`, `J4_EC`, `K_EC`, `K2_EC`,
  `BAD_EC`.
- `scripts/verify-review-record.sh` — the header usage block (lines 5-7) documents the flags without
  a TEST-ONLY label and lists only the three production tokens. Update it to name the fixture
  namespace and the mode line.
- New test cases: (a) no production token literal appears anywhere in fixture-mode output;
  (b) fixture tokens are not matched by the legacy patterns in 4.3, with `REVIEW_RECORD_OK_FIXTURE`
  as a control that *is* matched; (c) `review_record_mode=` and `review_record_pkg=` appear exactly
  once on success, SKIP, and every FAIL path; (d) empty flag values fail closed per 4.1.1.

### 4.5 Documentation changes

Each obligation below names the file that must carry it. An obligation without a home is one an
implementer can legally skip.

- `references/looping-review.md` § Tokens (lines 93-100) — add the fixture namespace, the two new
  disclosure lines, and the `none` mode value; state that a fixture run is not a production
  acceptance path. Also carry the two obligations this design states elsewhere: that the wrapper's
  pre-Python exits emit no token and therefore no mode line (§4.2), and that the disjointness
  guarantee is enforced by a locally run suite rather than by CI (§6.1).
- `references/review-budget.md` § Tokens (line 61-66) — same token additions, plus a line that
  `blast_class` from a fixture run reflects the supplied path list, not the working tree.
- `README.md` line 66 token row — mention that only default resolution can emit `REVIEW_RECORD_OK`.
- Leave alone, verified still true after the change: `references/looping-review.md:91` and `:100`,
  `README.md:82`, `skills/using-vibage/SKILL.md:37`, and the four adapter lines
  (`adapters/cursor/vibage.mdc:32`, `adapters/claude/CLAUDE.vibage.md:28`,
  `adapters/codex/AGENTS.vibage.md:28`, `adapters/shared/AGENTS.vibage.md:28`).
- Adapters (`adapters/**`) state only "exit 0 ≠ `REVIEW_RECORD_OK`", which stays true. **Do not edit**
  unless a reviewer shows the wording became wrong; keeping them out holds the diff smaller.

### 4.6 Pinned implementation decisions

Round 2 review found these underspecified. They are decided here so two implementers cannot diverge.

| Question | Decision |
|----------|----------|
| stdout or stderr for the two new lines | **stdout**, matching today's `print("review_record_mode=head1")`. stderr keeps carrying only `FAIL: …` detail lines |
| line ordering | immediately after the mode is resolved and before any other diagnostic, so the order is `review_record_mode=`, `review_record_pkg=`, then `blast_class=` and the rest |
| suffixes on fixture tokens | mirror production exactly: `REVIEW_RECORD_FIXTURE_PASS path=…`, `REVIEW_RECORD_FIXTURE_SKIP reason=…`, `REVIEW_RECORD_FIXTURE_FAIL reason=…` |
| who owns what | `scripts/lib/review_record.py` owns the presence bit, the empty/unreadable-value failures, both new lines, the token namespace, and the honesty rewording. `scripts/verify-review-record.sh` changes only its header usage comment and, if its `NOTE:` line names a production token, that line. The wrapper keeps forwarding `--paths-file=*|--base=*` unchanged and does not itself validate values |
| exact fixture honesty text | `Honesty: a fixture run is not a production acceptance path` on the fixture PASS path. The existing SKIP honesty line contains no production token literal and may stay as written |
| `pack-health.sh` matching | `grep -Eq 'REVIEW_RECORD_(OK|SKIP)([^A-Za-z0-9_]|$)'` and the same boundary treatment for the `FAIL` check, so a `path=` or `reason=` suffix still matches while a `FIXTURE` infix never can |
| internal `"override"` string | renamed to `base_override` so the internal value and the printed value are the same string |

## 5. Why this fix is not more forgeable than what it replaces

Required by the pack's own rule that a proposed axis must be checked before it is adopted.

| Attack on the fix | Result |
|-------------------|--------|
| Quote stdout but drop the `review_record_mode=` line | Fails — the token itself is `REVIEW_RECORD_FIXTURE_PASS`, so there is no production green to quote |
| Claim in prose that "the gate passed" | Unchanged from today; narrative claims are handled by report lint and the honesty surfaces, not here |
| Name-collide the new token so old greps match | Blocked by B4's mechanical disjointness test |
| Edit `pack-health.sh` to accept fixture tokens | `pack-health.sh` is in `TRIGGER_EXACT`, so it needs a review record |
| Edit `review_record.py` to re-enable the old behaviour | It is under `scripts/lib/`, so it needs a review record |
| Stop running the gate at all | Unchanged from today. `.github/workflows/tier0.yml` is **not** a guarded path, so CI enforcement can be weakened without a record |

### 5.1 What this fix does NOT close (scope honesty)

The property being claimed is narrow and must be stated narrowly: **on the flag channel**, a
non-production run can no longer emit a production success token, and the result cannot be faked by
dropping a disclosure line. That is the whole claim. It is not "the forgery surface shrank" in
general, and the earlier draft of this section said so incorrectly.

Curated data can still reach a production `REVIEW_RECORD_OK` without touching either flag:

| Route | Status after this change |
|-------|--------------------------|
| Point the script at a different package root (`verify-review-record.sh /tmp/pristine-clone`) | **Still open.** Mitigated only by the new `review_record_pkg=` line, which is disclosure, not prevention |
| Work on a branch whose diff genuinely contains only `tests/` changes, then quote that green while the risky edit lives elsewhere | **Still open.** Indistinguishable from honest work by any mechanical means available here |
| Assert in prose that the gate passed, without running it | **Unchanged.** Handled by report lint and the honesty surfaces, not by this script |
| Print a forged token from an unguarded helper script and quote it | **Still open.** This is finding C (trigger set defined by naming, not capability) |

The fix adds **no new self-declared field**, and on the flag channel it removes a way to make
caller-supplied input look repository-derived. Outside that channel it changes nothing.

## 6. Verification plan

Every check parses stdout; exit 0 alone proves nothing.

1. `bash tests/test_review_record.sh` — full suite green.
2. Re-run the section 1 reproduction. Expect `review_record_mode=fixture` and
   `REVIEW_RECORD_FIXTURE_PASS`; assert `REVIEW_RECORD_OK` is absent from stdout.
3. `--base=HEAD` alone on a tree with real trigger changes. Expect `review_record_mode=base_override`
   and a fixture-namespace token; assert no production token.
4. Default invocation on a real branch with trigger changes. Expect the production tokens exactly as
   before, with `review_record_mode=` reporting whatever `resolve_base` actually chose — `merge_base`
   on a feature branch, `head1` at the tip of main. Both are passes; asserting `merge_base` alone
   would fail on main.
5. `bash scripts/test-tier0.sh` — `TIER0_OK` unchanged (this work is ∉ Tier-0; the check is that it
   was not disturbed).
6. `bash tests/test_pack_health.sh` — pack-health still green on a clean tree.
7. Grep the legacy patterns from 4.3 against fixture-mode stdout **and stderr** and assert zero
   matches, with `REVIEW_RECORD_OK_FIXTURE` as a control that does match.
8. `bash scripts/verify-review-record.sh --base= .` and `--paths-file= .` — expect the fixture
   namespace and a fail-closed `reason=empty_flag_value`, per 4.1.1.

### 6.1 Enforcement reality (disclosure, not a claim)

`tests/test_review_record.sh` is run by **nothing in CI**: not `scripts/test-tier0.sh`, not
`scripts/pack-health.sh`, not `tests/test_pack_health.sh`, not any job in
`.github/workflows/tier0.yml`. The suite is deliberately kept out of Tier-0 and the file even asserts
that Tier-0 does not reference it (`tests/test_review_record.sh:27`). CI exercises only the live
production path through `scripts/pack-health.sh:60`.

Consequence: B3 and B4 are enforced by a **locally run** suite. This design does not add a CI
mount point, because doing so touches Tier-0 adjacency and belongs in its own decision. The gap must
be written into the docs rather than left implicit, so that "the disjointness is tested" is never
read as "the disjointness is enforced on every push".

## 7. Known gaps left open after this change

Recorded so the change is not read as more than it is.

- `base == HEAD` still yields a vacuous empty diff and a `SKIP`, in default mode, on a
  depth-1 checkout of a branch whose tip carries the change. Not fixed here.
- The trigger set is still defined by path naming rather than by capability, so token-emitting
  scripts outside `scripts/verify-*` remain unguarded. Separate work (finding C).
- `verdict` is still compared against the literal string `FAIL`. Separate work (finding D).
- The hand-written front-matter parser still truncates on an embedded `---`. Separate work.
- `contexts_ok` remains zero-cost to forge, as already disclosed in `references/review-budget.md`.
- The `loop: plan` mechanical path has never been exercised by a production record; all eleven
  existing records are `loop: impl`.
- A legitimate `--base=<older-sha>` comparison loses the production token. Accepted cost, §4.1.
- Displacement routes stay open: alternate package root, and branches whose diff is honestly
  `tests`-only. See §5.1.
- B3 / B4 have no CI enforcement. See §6.1.
- `.github/workflows/tier0.yml` is not a guarded path, so the CI configuration protecting the gate
  can be changed without a review record.
- A time-of-check window remains between `changed_paths()`, `compute_diff_id()`, and the record
  read. A tree modified mid-run yields a `diff_id` that matches neither state. This change neither
  widens nor narrows that window; it is recorded so it is not mistaken for new.
- `review_record_pkg=` resolves symlinks and `..`, so it cannot be made to lie by aliasing a path.
  Whether a bind mount or mount namespace could make the printed path disagree with the tree that
  was actually digested was **not tested**. Treat the line as disclosure, never as proof of which
  tree was measured.

## 8. Plan loop log

**Round 1** — three reviews, distinct lenses and contexts, all `BLOCK`. Every item below was
re-verified against source by the author before folding in; none was accepted on report alone.

| # | Lens | Must-fix | Verification |
|---|------|----------|--------------|
| 1 | scope | §1 claimed both flags carry a TEST-ONLY comment | Only `--paths-file` does, at `scripts/lib/review_record.py:422` |
| 2 | engineering, adversarial | Mode predicate left as value truthiness lets `--base=` slip through | Confirmed at `:421` and `:431`; fixed by §4.1.1 |
| 3 | adversarial | Fixture output would still contain `REVIEW_RECORD_OK` via the honesty line | Confirmed at `:501`; fixed by §4.3 |
| 4 | engineering | Consumer list omitted the FAIL and SKIP assertions on fixture paths | Confirmed at `tests/test_review_record.sh:247` and `:877`; fixed by §4.4 |
| 5 | adversarial | §5 overclaimed a global reduction in forgery surface | Rewritten as §5 + §5.1 |
| 6 | adversarial | B4 presented as a mechanical guarantee without disclosing it is absent from CI | Confirmed: the suite is referenced by no CI job; disclosed in §6.1 |

Round 1 also confirmed, by direct grep, that `REVIEW_RECORD_FIXTURE_{PASS,SKIP,FAIL}` is not matched
by any existing consumer pattern while `REVIEW_RECORD_OK_FIXTURE` is matched by two — the naming
direction in §4.3 is correct.

**Round 2** — three reviews (fix-completeness / adversarial / implementability). Verdicts were
`BLOCK`, `APPROVE_WITH_GAPS`, `BLOCK`. All six round-1 repairs were independently confirmed complete.

| # | Lens | Must-fix | Verification |
|---|------|----------|--------------|
| 7 | fix-completeness **and** implementability, found independently | §4.2 required a mode line on the `no_git_base` path but the enum had no value for it | `resolve_base` returns `"none"` at `scripts/lib/review_record.py:207`; the FAIL path at `:434-437` prints no mode line. Enum extended in §4.2 |
| 8 | implementability | "must be stated in the docs" obligations named no file, so an implementer could skip them legally | Assigned to `references/looping-review.md` in §4.5 |
| 9 | implementability | Verification step 4 asserted `merge_base`, which is wrong at the tip of main | Confirmed `head1` locally; step 4 now accepts either |
| 10 | adversarial (non-blocking, promoted by the author) | An unreadable `--paths-file` raises a traceback and emits no token at all | Reproduced with a missing file and with a directory; fail-closed rule added to §4.1.1 |

Round 2 also recorded attacks that failed, so later rounds do not repeat them: symlinked, outside-repo
and `/dev/stdin` path lists stay confined to the fixture namespace; `review_record_pkg=` cannot be
made to lie by symlink or `..` because the path is resolved; weakening the disjointness test is
itself a guarded-path change; and the front-matter truncation defect does not interact with the mode
handling. The adversarial lens judged the new axis clearly harder to forge than the old one on the
flag channel, which is the bar this package sets for adopting a new axis.

The author additionally self-corrected one contradiction found while re-reading: §3 claimed no
exit-code change while §4.1.1 introduces a fail-closed error for empty flag values. §3 now carves
that out explicitly.

**Round 3** — three reviews (freeze-readiness / fresh-eyes / implementer dry run). Verdicts were
`APPROVE`, `BLOCK`, `APPROVE_WITH_GAPS`. The loop did **not** converge, so nothing here is frozen.

| # | Lens | Finding | Disposition |
|---|------|---------|-------------|
| 11 | freeze-readiness | All four round-2 repairs complete; no internal contradictions; §4.6 decidable | Confirmed, no action |
| 12 | fresh eyes | Wrong shape: labelling a test-only affordance that should not be on the production CLI at all. Verified that `pack-health.sh` never passes the flags, so the mechanical benefit to CI is zero and the real beneficiary is the pasted-output channel | **Accepted by owner.** Reshape recorded in the header |
| 13 | fresh eyes | Priority: `verdict` literal comparison and the `---` truncation fire on *normal* usage, this one needs a deliberate flag | **Accepted by owner.** Those become batch 1; this document becomes batch 2 |
| 14 | implementer dry run | §1's reproduction transcript shows `REVIEW_RECORD_OK`, but on a committed tree with no pre-planted record the same command yields `missing_record`. The original experiment wrote a matching record first and the write step was omitted from the transcript | **Must fix on reshape.** A reproduction that does not reproduce is exactly the defect class this package exists to catch |
| 15 | implementer dry run | `--paths-file=<readable>` combined with an empty `--base=` is undefined; "every FAIL path" needs an explicit enumeration; §6 steps 2, 4 and 6 are not executable as written | **Must fix on reshape** |

The dry run did confirm the document is implementable: working only from it, the reviewer produced a
change of roughly +161 / −42 across exactly the seven files the document names, with
`REVIEW_RECORD_TEST_OK` and `TIER0_OK` both green. The objection is to what was specified, not to how
clearly it was specified.
