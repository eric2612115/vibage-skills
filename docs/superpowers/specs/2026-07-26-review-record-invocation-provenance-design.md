# Review-record invocation provenance

**Date:** 2026-07-27
**Status:** **Frozen** after seven plan-loop rounds. Ready to implement.
**Freeze disclosure:** the round-7 corrections — `--no-replace-objects` in §4.2.2, the split
criterion rows and the replace case in §5 and §4.5.2, and the withdrawn stub claim — were written
after the last reviewer reported and have been read by nobody else. They are recorded as findings 74
and 75. The residual risk is that a sixth stub passes §4.5.2, which §4.5.2 now says outright it
cannot exclude. These carry into the Impl loop, where reviewers read this document against the diff.
**Baseline:** `feat/review-record-schema-hardening` at `0458493`, **not** `58c553a`. Batch 1 rewrote
`scripts/lib/review_record.py`, so every line number here was re-derived against that branch.
**Batch:** 2 of 3. Batch 1 (record-schema hardening) has landed on the branch. Batch 3 is
enforcement: wiring the suite into CI, guarding `.github/workflows/tier0.yml`, `pack-health`'s
treatment of `SKIP`, and the trigger set by capability — see the ranking in §5.
**Reading order:** §4 through §7 are the constraints an implementer or reviewer needs. §5 and §6 are
the honest account of what this does not cover. §8 is the loop history — provenance for how the
constraints were reached, not something to read first. An impl-loop reviewer asked for it to be moved
out; it stays because the review record points at one path, and the disclosure above is only auditable
next to the findings it names.
**Prior loop:** three rounds against the earlier shape of this design, fifteen findings, all folded.
The third round's adversarial lens rejected the *shape* — labelling a test-only affordance rather
than removing it from the production entry point — and the owner accepted that. §8 records the
history; the design below is the accepted shape, not the reviewed one, so it starts a fresh loop.

## 1. The defect

`scripts/verify-review-record.sh` is the documented production entry point. It forwards two flags to
the library that replace the repository-derived diff with caller-supplied data:

| Flag | Effect |
|---|---|
| `--paths-file=FILE` | replaces the changed-path set with an arbitrary list |
| `--base=LABEL` | replaces the base label with an arbitrary string |

A run using them emits stdout that a reader cannot distinguish from a genuine run, including the
production success token. Measured on `58c553a` during the Lens A hunt, with a working tree carrying
a real modification to a `gate`-class file and a matching record planted first:

```
$ bash scripts/verify-review-record.sh \
    --paths-file=curated.txt --base=58c553a2eae67c6b20ac0af02b41d6cc943b5753 .
blast_class=tests
diff_id=8135190d…
diff_base=58c553a2eae67c6b20ac0af02b41d6cc943b5753
trigger_count=1
trigger=tests/test_review_record.sh
REVIEW_RECORD_OK path=…
```

The blast class reads `tests` while the tree carries a `gate` change, the base reads as a genuine
commit, and the production token is emitted. The only difference from a real run is the **absence**
of a `review_record_mode=` line, and absence is not something a reader or a grep detects.

Planting the matching record first is part of the reproduction. An earlier draft omitted that step,
so the transcript did not reproduce.

Measured facts on the current branch:

| Fact | Value |
|---|---|
| Wrapper forwards both flags | `scripts/verify-review-record.sh:18` |
| Wrapper documents them as ordinary usage | `:5` |
| Library reads them from argv | `scripts/lib/review_record.py:586` |
| Library branches on value truthiness, not flag presence | `:593` and `:602` |
| TEST-ONLY declaration, source comment only, `--paths-file` only | `:594` |
| Production token literal printed on the success path | `:677` and `:678` |
| Consumers match tokens without anchors | `scripts/pack-health.sh:64` and `:70` |
| Test call sites driving the flags through the wrapper | 29 |
| Test call sites using the production path | 1, at `tests/test_review_record.sh:903`; it asserts only that the output does not contain `reason=no_git_base` |
| `git init` in `tests/test_review_record.sh` | 0. Other test files do use it, for example `tests/test_c_prime_matrix.sh` and `tests/test_coverage_box.sh` |

So the review-record suite drives the production path once, and that one call checks for a single
failure reason rather than for a result.

## 2. Goals

| ID | Goal | Success signal |
|----|------|----------------|
| **P1** | The production entry point has no **argv** injection surface | `scripts/verify-review-record.sh` rejects `--paths-file` and `--base` as unknown flags. Scoped to argv deliberately: the environment spelling is closed by clearing, but the redirect class reached through repository files is not closable from inside the package — §4.2.2 — and §5 shows why it is not worth chasing |
| **P2** | A production success token is unreachable from a flagged run, including direct library invocation | flagged runs emit `REVIEW_RECORD_FIXTURE_PASS` / `_SKIP` / `_FAIL` |
| **P3** | Every token-emitting path states how the run was invoked | one each of `review_record_mode=`, `review_record_pkg=`, `review_record_toplevel=` and `review_record_git_dir=` before the token, including on the `OK` path. The last two are diagnostics, not a control: §4.2.2 measures a one-file redirect that leaves both of them naming the package |
| **P4** | No production token literal appears anywhere in flagged-run output | asserted over the whole of stdout and stderr, not the token line |
| **P5** | Consumers cannot be fooled by substring overlap | `pack-health.sh` and the suite match at word boundaries |
| **P6** | The suite exercises the production path | one integration test builds a real temporary git repository and drives it end to end |

## 3. Non-goals

- ≠ fix `base == HEAD` producing a vacuous empty diff, or add shallow-repository detection. Separate
  root cause, recorded in §6.
- ≠ change `diff_id`, the record schema, the budget table, or anything batch 1 touched.
- ≠ rewrite the 29 existing flag-driven cases. They change their call target, not their logic.
- ≠ claim the forgery surface shrinks in general. §5 states exactly what stays open.
- ≠ claim `REVIEW_RECORD_OK` means review quality.

## 4. Design

### 4.1 Remove the flags from the production entry point (P1)

`scripts/verify-review-record.sh:18` currently forwards `--paths-file=*|--base=*`. Delete that case
arm. Both flags then fall through to the existing unknown-flag arm, which prints
`FAIL: unknown flag <arg>` and exits 2. Update the usage block at `:5` to document only
`bash verify-review-record.sh [<pkg_root>]`.

The wrapper stops passing any flag through, so it no longer needs `ARGS`; it execs the library with
the package root alone.

### 4.2 Token namespace for flagged runs (P2)

The flags survive on direct library invocation, which is where the tests call them from. That path
must still be unable to claim production acceptance. Follow the pack's existing idiom — `freshness`
emits `FRESHNESS_WAIVED` plus `STALE_DISCLOSED` rather than a modifier on `FRESHNESS_OK` — and give
the non-production state its own token string. A modifier line can be dropped when quoting; a
different token string cannot.

| Invocation | `review_record_mode=` | Success | No triggers | Failure |
|---|---|---|---|---|
| default resolution, merge-base | `merge_base` | `REVIEW_RECORD_OK` | `REVIEW_RECORD_SKIP` | `REVIEW_RECORD_FAIL` |
| default resolution, tip of main | `head1` | `REVIEW_RECORD_OK` | `REVIEW_RECORD_SKIP` | `REVIEW_RECORD_FAIL` |
| base resolution failed | `none` | — | — | `REVIEW_RECORD_FAIL reason=no_git_base` |
| `--paths-file` present | `fixture` | `REVIEW_RECORD_FIXTURE_PASS` | `REVIEW_RECORD_FIXTURE_SKIP` | `REVIEW_RECORD_FIXTURE_FAIL` |
| `--base` present, no `--paths-file` | `base_override` | `REVIEW_RECORD_FIXTURE_PASS` | `REVIEW_RECORD_FIXTURE_SKIP` | `REVIEW_RECORD_FIXTURE_FAIL` |

The suffix is `_PASS`, not `_OK`, so the fixture tokens do not join the pack's `*_OK` product-token
family. Existing suffixes are kept: `…_PASS path=…`, `…_SKIP reason=…`, `…_FAIL reason=…`.

§4.2.2's scope check adds one outcome that crosses this table, and a reviewer found the table did not
cover it. It resolves before the base does, so it has its own row:

| Invocation | `review_record_mode=` | Scope mismatch |
|---|---|---|
| default resolution | `none` | `REVIEW_RECORD_SKIP reason=git_scope_mismatch` |
| `--base` present, no `--paths-file` | `base_override` | `REVIEW_RECORD_FIXTURE_SKIP reason=git_scope_mismatch` |
| `--paths-file` present, with or without `--base` | `fixture` | check not run; git provenance lines are `-` |

Two combinations remain, both of which a reviewer flagged as undefined. When git does not resolve at
all, the scope check cannot run and is not reached: the existing `no_git_base` outcome stands, in the
production namespace by default and in the fixture namespace when `--base` was given. `--paths-file`
present is decided by that flag alone, whether or not `--base` accompanies it, because the path set
is what the check protects and that run derives it from the file.

The internal string `"override"` is renamed `base_override` so the internal and printed values match.

### 4.2.1 The predicate is argv presence, not value truthiness (HARD)

`:593` and `:602` branch on the value. An empty value therefore behaves as if the flag were absent:
`--base=` currently resolves the base normally and can reach a production token. Reusing that logic
leaves the hole open through a one-character change.

**The argv contract, pinned, because the current one has a hole the reshape would otherwise widen.**
Today `pkg = argv[1]` and flags are read from `argv[2:]`. The 29 existing call sites pass the flags
*before* the package root, which works through the wrapper because the wrapper reorders them, execing
the library as `<pkg>` followed by the flags. Pointing
those same call sites at the library without reordering makes the flag string itself become the
package root. Measured on this branch:

```
$ printf 'tests/test_review_record.sh\n' > /tmp/av.txt   # must exist and name a trigger path

$ python3 scripts/lib/review_record.py --paths-file=/tmp/av.txt --base=fixture .
REVIEW_RECORD_SKIP reason=no_trigger_paths

$ python3 scripts/lib/review_record.py . --paths-file=/tmp/av.txt --base=fixture
REVIEW_RECORD_FAIL reason=missing_record
```

The first line of that transcript is part of the reproduction. With the file absent the second
command raises `FileNotFoundError`, and with the file empty it prints
`REVIEW_RECORD_SKIP reason=no_trigger_paths`. An earlier draft omitted the setup line, which is the
same defect as finding 11.

The first form carries a flag on the command line and emits a **production** token, against a
package root that does not exist. Therefore:

- The package root is the **first argv element that does not match `--*`**, defaulting to `.`.
- The presence scan covers **every** argv element after the program name, including the one that
  would otherwise be taken as the package root. A run whose command line contains `--paths-file=` or
  `--base=` anywhere is non-production, regardless of position.
- Only the `=` spelling is recognised. A space-separated `--paths-file FILE` is not a flag, so it
  neither injects a path list nor sets the presence bit; it is a stray positional argument. Do not
  add support for that spelling.
- `--` is not treated as an end-of-options terminator; an argument after it that matches `--paths-file=*`
  still sets the presence bit.

Empty and unreadable values fail closed:

| Input | Result |
|---|---|
| `--paths-file=` or `--base=` with an empty value | `REVIEW_RECORD_FIXTURE_FAIL reason=empty_flag_value`, exit ≠ 0 |
| `--base=` empty, no `--paths-file` | as above, and `review_record_mode=base_override` — the mode follows flag *presence*, so an empty value does not fall back to `none` or to `fixture` |
| `--paths-file=<missing file, directory, or unreadable>` | `REVIEW_RECORD_FIXTURE_FAIL reason=paths_file_unreadable`, exit ≠ 0 |
| both flags present, either value empty | mode is `fixture`; `reason=empty_flag_value` |
| flag repeated | last value wins; the presence bit stays set |

The unreadable case is a defect today, not an omission: a missing file raises `FileNotFoundError` and
a directory raises `IsADirectoryError`, so the run ends in a traceback with **no token at all**,
which is the failure shape P3 exists to remove.

A readable `--paths-file` may point anywhere — a symlink, outside the repository, `/dev/stdin`. No
containment check is required, because the presence predicate already confines every such run to the
fixture namespace.

### 4.2.2 The environment must not redirect the history (P1)

Removing the flags is not sufficient. `git_stdout` runs `git -C <pkg> …`, and `-C` only sets the
working directory; the `GIT_DIR` and `GIT_WORK_TREE` environment variables still override which
repository git actually reads. So the tree named by the package root and the history the run
measures can be different trees, with **no flag on the command line**. Measured on this branch:

```
$ bash scripts/verify-review-record.sh .              # innocent checkout, on its own
review_record_mode=head1
REVIEW_RECORD_OK path=…/innocent/docs/evidence/reviews/d630854434….md

$ GIT_DIR=/tmp/gd/curated/.git bash scripts/verify-review-record.sh .
review_record_mode=merge_base
blast_class=gate
diff_base=58c553a2eae67c6b20ac0af02b41d6cc943b5753
trigger_count=3
REVIEW_RECORD_FAIL reason=missing_record
```

Same command, same package root, different history: the mode, the base, the blast class and the
trigger count all come from the other repository. The second run ends in `missing_record` only
because that particular innocent tree has no matching record; a reviewer planted one and obtained a
production `REVIEW_RECORD_OK`.

This defeats P1 as stated, and `review_record_pkg=` cannot disclose it, because the package root
really is the innocent tree.

**The redirect class cannot be adjudicated from inside the package. This is a result, not a gap.**

Three rounds tried to build an outcome check that accepts every honest layout and rejects every
redirect. Each version traded one error for another:

| version | rejected the attacks | but |
|---|---|---|
| clear seven `GIT_*` variables | environment only | a repository-local `core.worktree`, and a `.git` file, are not environment variables |
| git directory must lie inside the package | yes | false-fails a linked `git worktree`, whose git directory is at `<main>/.git/worktrees/<name>` |
| package must appear in `git worktree list` | yes | false-fails a submodule |
| add "the repository's own working tree is the package" | `GIT_DIR` only | false-fails `--separate-git-dir`, and **admits the `.git`-file redirect** |

The last row is the end of the line, and the reason is structural. A submodule *is* a `.git` file
pointing at an external git directory with `core.worktree` pointing back at the working tree.
Measured, side by side:

```
submodule   .git file: gitdir: ../.git/modules/sub    core.worktree: ../../../sub
redirect    .git file: gitdir: /tmp/f3/curated/.git   core.worktree: /tmp/f3/innocent
```

The redirect is the same construct with different paths, and it makes `git -C <pkg> rev-parse HEAD`
report the other repository's HEAD while every probe reports a healthy submodule. No probe separates
them because there is nothing to separate: only the superproject's index and `.gitmodules` know that
one of them is a real submodule, and the package cannot see its superproject. Reviewers reproduced
this from opposite directions — as a false failure on `--separate-git-dir` and as a false pass on the
`.git` redirect — which is the signature of a rule that is chasing a distinction that does not exist.

**So this section stops adjudicating and does two smaller things it can actually back.**

*One scope check, chosen because it has no false positives.* Require that the working tree git
resolved is the package root: `os.path.samefile(git rev-parse --show-toplevel, pkg)`. `samefile`
compares inodes, so it is immune to symlinked paths and to macOS case folding, where `realpath`
preserves the caller's spelling and string comparison false-fails. Measured:

| layout | same file | outcome |
|---|---|---|
| plain clone, linked worktree, submodule, `--separate-git-dir`, case-folded path | yes | proceeds normally |
| vendored subdirectory | no | `SKIP reason=git_scope_mismatch` |
| `core.worktree` pointing at another tree | no | `SKIP reason=git_scope_mismatch` |
| `GIT_DIR` redirect, `.git`-file redirect, `.git/commondir` redirect | yes | **not covered** — see §5 |

The vendored row is the honest payoff. That installation today reports
`SKIP reason=no_trigger_paths` — measured — because the monorepo names paths
`vendor/vibage-skills/scripts/…` and no trigger prefix matches. That reason reads as "nothing needed
review" when the truth is "the wrong tree was measured". The new reason is accurate and the outcome
is unchanged, so that installation does not break.

**One case in this row does change outcome, and it is a downgrade.** Passing a *subdirectory of the
package's own repository* as `pkg_root` — `verify-review-record.sh ./scripts` — measured
`FAIL reason=missing_record` before and `SKIP reason=git_scope_mismatch` after, because the trigger
prefixes still matched when the subdirectory sat inside the package's own history. A vendored package
root and a mistyped subdirectory have the same probe signature (`pkg` strictly inside the toplevel),
and the vendored installation must not break, so this design accepts the downgrade rather than
splitting them. It is accident-reachable: a CI line that gains a stray path argument goes from red to
a `SKIP` that `pack-health.sh` accepts. The structural close is on the accepting side — a consumer
that stops treating `SKIP` as a pass — which is the next batch's scope, not this one's. Both classes
are asserted in the suite so the delta stays visible rather than becoming folklore.

Three details the implementer must not have to guess, each raised by a dry run that guessed
differently:

- **The token obeys §4.2's namespace.** A flagged run that hits a scope mismatch emits
  `REVIEW_RECORD_FIXTURE_SKIP reason=git_scope_mismatch`, not the production `SKIP`. Writing the
  production token here would put a production literal in flagged output and break P4.
- **The mode line is still required**, and the check runs before any other git call, so print
  `review_record_mode=none` on the default path and `base_override` when `--base=` was given.
- **Attach the check to "the run is about to consult git", not to `resolve_base`.** A reviewer traced
  a path that would slip through a literal reading: `--base=` without `--paths-file=` skips
  `resolve_base` entirely and goes straight to `changed_paths`, so a check placed at the top of
  `resolve_base` would let a scope-mismatched run produce git-derived output. A pure `--paths-file=`
  run consults git for nothing and skips the check, printing `-` for both git provenance lines per
  §4.3.
- **`os.path.samefile` raises rather than returning false** when a path has gone away — a reviewer hit
  `FileNotFoundError` on a toplevel deleted between git's answer and the comparison. Catch `OSError`
  and treat it as a mismatch.
- **The check applies only when git returned a toplevel.** If `git rev-parse --show-toplevel` fails
  at all — not a repository, or a bare one — there is nothing to compare and the existing
  `REVIEW_RECORD_FAIL reason=no_git_base` outcome stands, exactly as §4.2 says. An earlier version of
  this bullet said a bare repository should be treated as a mismatch, which contradicted §4.2; the
  implementer followed this bullet and produced a measured `FAIL` → `SKIP` downgrade on a non-git
  directory, which `pack-health.sh:87` explicitly requires to fail. That is the false-green class this
  batch exists to remove, introduced by this batch.

*Two diagnostic lines, which are **not** a control.* On every path that emits a token, including
`REVIEW_RECORD_OK`, print the resolved working tree and git directory as the
`review_record_toplevel=` and `review_record_git_dir=` lines specified in §4.3 — those exact key
names, since a dry run invented `git_toplevel=` and `git_dir=` when this section named no keys.

An earlier version of this round called those lines "disclosure" and treated them as what the section
delivers once adjudication was abandoned. A reviewer broke that too, and the author reproduced it. A
single on-disk file, `.git/commondir`, redirects where git reads objects and refs while both printed
lines keep naming the package:

```
$ git -C pkg rev-parse --show-toplevel        /private/tmp/cd1/pkg
$ git -C pkg rev-parse --absolute-git-dir     /private/tmp/cd1/pkg/.git      <- printed
$ git -C pkg rev-parse --git-common-dir       /private/tmp/cd1/common-clean/.git  <- not printed
$ git -C pkg log --oneline -1                 a29e50b curated c2 gate
                                              samefile(toplevel, pkg) = True
```

`refs/replace`, `info/grafts`, `objects/info/alternates` with a rewritten ref, and a symlinked
`.git/objects` reach the same place. Printing `--git-common-dir` as well would move the problem, not
solve it. So the lines are kept as diagnostics — they are cheap, and they do name the foreign
directory in the `GIT_DIR` and `.git`-file cases — but this design does not claim they detect a
redirect, and §5 records the class as open rather than disclosed.

**Why this section stops here rather than continuing to chase it** is in §5: every remaining route
requires write access inside the package, and an attacker with that access has a strictly cheaper
path that no git-level check can see.

**`scripts/pack-health.sh` is deliberately *not* changed to reject `git_scope_mismatch`.** An earlier
draft of this round required it. It contradicts itself: pack-health computes `PKG_ROOT` from its own
location (`scripts/pack-health.sh:7`), so the vendored installation this section just protected would
run pack-health, hit its own mismatch, and fail — the exact breakage the SKIP was chosen to avoid.
The rule would also have closed one of three redirect doors while the other two stay open, so it buys
little and costs a contradiction.

Clear `GIT_DIR`, `GIT_WORK_TREE`, `GIT_INDEX_FILE`, `GIT_OBJECT_DIRECTORY`,
`GIT_ALTERNATE_OBJECT_DIRECTORIES`, `GIT_COMMON_DIR` and `GIT_NAMESPACE` before every git call, and
pass `--no-replace-objects` on every git call.

The second one closes a route a reviewer found in this document's own criterion, which had filed
`refs/replace` with the undecidable cases. It is neither undecidable nor exotic: a replace ref left
behind after legitimate history rewriting makes the gate's diff vacuous, and the run reports a clean
`SKIP` over a real change. Measured:

```
$ git replace <tip> <init>
$ git diff --name-only HEAD~1..HEAD                     (empty)
$ git --no-replace-objects diff --name-only HEAD~1..HEAD  scripts/assert_gate.sh
```

One flag, and the route is closed rather than disclosed. `.git/info/grafts` reaches the same effect
and is **not** covered by the flag — measured — so it stays open; it is deprecated, and git prints a
loud deprecation hint on every invocation, which makes an accidental graft the one member of this
family that announces itself.

**Say what this closes with the scope attached, because three sections of this document previously
said it three different ways and a reviewer caught all three.** Clearing closes the
*environment-variable spelling* of the redirect: measured, with `GIT_DIR` cleared git resolves the
package's own git directory again. It does **not** close the redirect *class*, because the same
effect is reachable through `.git`, `.git/commondir` and `refs/replace`, which are files. Both
sentences are true; neither may be written without its qualifier. This is the accidental case worth
removing — a stray variable in a wrapper or CI harness — not a defence against anyone.

A reviewer confirmed clearing does not break a legitimate `git worktree` checkout or a submodule,
because those rely on the `.git` file.

**Every git invocation must be covered, and there are three call sites, not one.** `git_stdout` uses
`git -C`, but `resolve_base` also calls `subprocess.run(["git", …])` directly, twice, for
`rev-parse --verify`. A reviewer demonstrated that clearing the environment only inside `git_stdout`
leaves the redirect working through those two. Route every git call through one helper.

Still open, and recorded in §5: a `git` binary earlier on `PATH` than the real one can fabricate the
scope check and both provenance lines. Nothing inside the script can detect that, because the
script's only view of git is git itself.

### 4.3 Mandatory provenance lines (P3)

Print exactly one of each, on stdout, immediately after the mode is resolved and before any other
diagnostic, on every path in `main()` that emits a token:

```
review_record_mode=merge_base|head1|none|fixture|base_override
review_record_pkg=<resolved absolute package root>
review_record_toplevel=<git rev-parse --show-toplevel, or - when git did not resolve>
review_record_git_dir=<git rev-parse --absolute-git-dir, or - when git did not resolve>
```

Order is `mode`, `pkg`, `toplevel`, `git_dir`, then `blast_class=` and the rest. Today the mode line
is printed only for `head1` and `merge_base`, and never on the `no_git_base` path. The package line
is new: the script accepts an arbitrary directory argument, so which tree was measured is part of
provenance, and today it appears only inside the `REVIEW_RECORD_OK path=…` suffix.

The last two lines are diagnostics, printed on the `OK` path as well as on failures. §4.2.2 measures
a redirect that leaves both of them naming the package, so they must not be described anywhere as
detecting one. Print a literal `-` rather than omitting the line when git did not resolve, so a
consumer can tell "no git" from "line missing".

These lines are secondary. §4.2's token namespace is the primary signal.

The wrapper exits before Python for `-h|--help`, an unknown flag, a non-directory argument, and a
missing library. Those emit no token and therefore no provenance lines. That is intentional and §4.6
assigns it to the documentation.

### 4.4 No production token literal in flagged output (P4)

The success path ends with a disclaimer that names the production token:

```677:678:scripts/lib/review_record.py
    print(f"REVIEW_RECORD_OK path={rec_path}")
    print("Honesty: REVIEW_RECORD_OK ≠ review quality ≠ adversarial proof")
```

If the fixture path keeps that line verbatim, `grep -Fq 'REVIEW_RECORD_OK'` matches fixture output
and the fix is defeated by its own disclaimer. This is the pack's known trap: do not move a `≠`
sentence into verify stdout while consumers use unanchored grep.

Rule: **no production token literal — `REVIEW_RECORD_OK`, `REVIEW_RECORD_SKIP`,
`REVIEW_RECORD_FAIL` — may appear anywhere in flagged-run stdout or stderr**, including honesty
lines, NOTE lines, and error messages. Fixture honesty text must be written without naming them, for
example `Honesty: a fixture run is not a production acceptance path`. The wrapper's `NOTE:` line at
`:37` names no token and may stay. P4's test asserts over the whole captured output.

The rule cannot be met by choosing careful wording alone, because diagnostics echo untrusted input:
the package path, the `--base=` value, trigger paths, and the offending front-matter line. A reviewer
measured `FAIL: front matter line 2 not recognised: REVIEW_RECORD_OK` in flagged output from a record
whose front matter contained that literal, and a package directory named `REVIEW_RECORD_OK` producing
`review_record_pkg=…/REVIEW_RECORD_OK`, which `pack-health.sh:70`'s word-boundary pattern matches
because `/` is not a word character. Neither turns that consumer green today — it tests for the `FAIL`
literal and for a non-zero exit before it looks for `OK|SKIP` — but the namespace is only worth
splitting if a token in the stream means an outcome. So every diagnostic that embeds input passes
through one substitution that rewrites token literals to `REVIEW_RECORD_<redacted>`, a string matched
by neither the bare nor the word-boundary patterns. Enumerating the sites instead of routing them
through one function is what let this through the first time: the reviewer-content route existed
before this batch and the path route was created by §4.3's provenance lines.

Four details, each from a measurement:

- **The bare `REVIEW_RECORD_FIXTURE` prefix is redacted too**, because that is what a consumer
  separating the two namespaces greps for. A first implementation covered only the suffixed forms, and
  a package directory named `REVIEW_RECORD_FIXTURE` defeated this batch's own reverse assertion.
- **Substrings count.** `REVIEW_RECORD_OKAY` is matched by `grep -F REVIEW_RECORD_OK`, so it is
  redacted even though it is not a token. Over-redaction costs a diagnostic some fidelity;
  under-redaction costs the invariant.
- **The wrapper redacts its own three diagnostics**, which echo argv and paths before python runs.
  They all exit non-zero, so `pack-health.sh` catches them on the exit check regardless, but the
  invariant is what makes the namespace worth splitting. The rule now exists twice, in Python and in
  `sed`; a test runs both over one table so neither drifts.
- **`--help` deliberately names the tokens** and is left alone: it is a human request that prints no
  outcome, and redacting it would leave the usage text unable to say what it documents.

The substitution also runs inside `emit_outcome`, so the one line that prints a token sanitises its
own payload. That changes no output today — every caller passes a constant `reason=` or an
already-redacted path — and exists because the reviewer who found this defect predicted its return
through exactly that door.

Naming check. The measured result, not a characterisation of it:

| String | `-Fq 'REVIEW_RECORD_OK'` | `-Fq 'REVIEW_RECORD_FAIL'` | `-Fq 'REVIEW_RECORD_SKIP'` | `-Eq 'REVIEW_RECORD_(OK\|SKIP)'` |
|---|---|---|---|---|
| `REVIEW_RECORD_FIXTURE_PASS` | miss | miss | miss | miss |
| `REVIEW_RECORD_FIXTURE_SKIP` | miss | miss | miss | miss |
| `REVIEW_RECORD_FIXTURE_FAIL` | miss | miss | miss | miss |
| `REVIEW_RECORD_OK_FIXTURE` (control) | **hit** | miss | miss | **hit** |

The chosen names are matched by nothing. The control is matched by two of the four patterns, which
is enough to show the discriminator must go before the outcome word, never after. An earlier draft
of this paragraph said all four patterns match the control; the table above was on screen when that
sentence was written.

### 4.5 Consumers and tests

- `scripts/pack-health.sh:64` and `:70` — match at word boundaries, so a future rename cannot
  silently re-open the overlap. Suggested form: `grep -Eq 'REVIEW_RECORD_(OK|SKIP)([^A-Za-z0-9_]|$)'`
  and the same treatment for the `FAIL` check, so a `path=` or `reason=` suffix still matches while a
  `FIXTURE` infix never can. pack-health passes no flags, so its behaviour is otherwise unchanged.
  pack-health is **not** otherwise changed; see §4.2.2 for why it must not reject
  `reason=git_scope_mismatch`.
- `tests/test_review_record.sh` — the 29 call sites that today run
  `bash scripts/verify-review-record.sh --paths-file=… --base=… "$ROOT"` must instead run
  `python3 scripts/lib/review_record.py "$ROOT" --paths-file=… --base=…`, because §4.1 makes the
  wrapper reject the flags.

  **This is not a call-target substitution.** The package root moves to the front. A swap that keeps
  the wrapper's flags-first order produces the failure measured in §4.2.1: the flag becomes the
  package root and the run emits a production token. §4.2.1's first-non-flag rule makes both orders safe **for the `=`
  spelling only** — a space-separated `--paths-file FILE` is not recognised as a flag in either
  order, so it neither injects nor marks the run. Write the call sites pkg-first so the intent is
  visible.

  Assertions on production tokens in those cases move to the fixture namespace, including the shared
  schema-failure helper. Assertions that capture only an exit code do not change, since §4.2 keeps
  exit-code semantics.
- New cases: no production token literal anywhere in flagged output; fixture tokens unmatched by the
  legacy patterns with `REVIEW_RECORD_OK_FIXTURE` as a control that *is* matched; `review_record_mode=`
  and `review_record_pkg=` present exactly once on success, on SKIP, and on every FAIL path; empty and
  unreadable flag values failing closed; and the wrapper rejecting each flag with exit 2.

### 4.5.1 The integration test (P6)

One new case, not a rewrite of the others. Append it **after** the existing cases and re-plant the
shared fixture record first: earlier cases in the file leave that record in a schema-invalid state,
so a success case appended after them fails for an unrelated reason. A dry run hit this.

1. Create a temporary directory and `git init` it, with `user.email` and `user.name` set locally so
   the test does not depend on the machine's git config.
2. Populate it with the package contents so that `is_trigger` paths exist. Exclude `.git` and
   exclude `docs/evidence/reviews/*.md`, so no pre-existing record interferes.
3. Commit everything. Then make a **second commit that changes exactly one `gate`-class file** and
   nothing else. Leave the tree **clean** afterwards — no untracked or modified files.
4. Run `bash scripts/verify-review-record.sh <tmp>` with **no flags**.
5. Assert all of the following, not just the token:
   - `review_record_mode=` is `head1`. The recipe above builds exactly two commits on one branch, so
     `resolve_base` takes the `mb == HEAD` path and uses `HEAD~1`. Asserting the looser
     `merge_base or head1` here would contradict the `diff_base` assertion below: on a layout where
     `resolve_base` returns a merge-base, `diff_base` is not `HEAD~1`. A reviewer showed that
     conjunction is false in general, so the recipe is pinned instead of the assertion loosened.
   - `review_record_pkg=` equals the **resolved** temporary path. On macOS `/tmp` resolves to
     `/private/tmp`, so compare against `Path(tmp).resolve()` rather than the shell variable.
   - `trigger_count=1`, and the single `trigger=` line names exactly the file changed in step 3,
     which must be `scripts/assert_gate.sh` so the test and the assertion cannot drift apart.
   - `diff_base=` equals `git -C <tmp> rev-parse HEAD~1`.
   - `blast_class=gate`.
   - `REVIEW_RECORD_FAIL reason=missing_record`.
6. Plant a qualified record at the printed `diff_id` and re-run, asserting `REVIEW_RECORD_OK`.

Also assert that `diff_base=` equals the SHA that `git -C <tmp> rev-parse HEAD~1` prints, and that
this SHA exists in the temporary repository's object store.

What that assertion does and does not do, stated precisely because an earlier draft overstated it.
It defeats an implementation that hardcodes a trigger list, which two reviewers built independently,
because the SHA differs on every run. It does **not** force the run to have called git: a reviewer
showed that reading `.git/HEAD`, following the ref and zlib-decoding the commit object satisfies it
with zero git subprocesses. Closing that would need a spy on the git binary, or a regression case
asserting that a redirected repository changes the output. Neither is bundled here; the assertion is
kept for the hardcode it does catch.

### 4.5.2 Layout cases for the scope check (§4.2.2)

§4.2.2's scope check is one `samefile` comparison, but the four layouts it must *not* reject were
each discovered by a reviewer breaking a previous version of the rule. Without cases they will be
broken again. Build each on top of the §4.5.1 repository, and assert stdout, never the exit code.

| Case | Construction | Assertion |
|---|---|---|
| linked worktree | `git worktree add` from the §4.5.1 repository | `reason=git_scope_mismatch` absent **and** `review_record_toplevel=` names that worktree |
| submodule | a second `git init` repository added with `git -c protocol.file.allow=always submodule add` | absent **and** `review_record_git_dir=` names `<super>/.git/modules/<name>` |
| `--separate-git-dir` | `git clone --separate-git-dir` of the §4.5.1 repository | absent **and** `review_record_git_dir=` names the separate directory |
| **package root spelled in a different case** | run against the §4.5.1 repository through a path whose case differs, on a case-insensitive filesystem | absent **and** `review_record_toplevel=` names the package. Skip where the filesystem is case-sensitive |
| **package root spelled in a different unicode normalisation** | a directory created NFC, addressed NFD, on a filesystem that normalises | same. Skip where `os.path.exists` on the other spelling is false |
| **leftover replace ref** | `git replace <tip> <init>` on the §4.5.1 repository, whose second commit changes one gate file | the run still reports `trigger_count=1` and the gate file, i.e. `--no-replace-objects` is in effect. Without it the diff is empty and the run reports `SKIP reason=no_trigger_paths` |
| package root below the toplevel | run against a subdirectory of the §4.5.1 repository | `SKIP reason=git_scope_mismatch`, no `REVIEW_RECORD_OK`, and specifically **not** `reason=no_trigger_paths` |
| `core.worktree` pointing elsewhere | `git config core.worktree` set to another tree | same |

**"Names" means compared with `os.path.samefile`, not as strings, and not by resolving both sides
first.** A reviewer measured all three expected values failing string equality on macOS, where the
construction yields `/tmp/…` and git returns `/private/tmp/…` — the same defect §4.5.1 already
handles for `review_record_pkg=`. Resolving first fixes that one and not the next: measured,
`Path.resolve()` preserves the caller's case and unicode spelling, so the two rows below still fail.
`samefile` is the only one of the three that is right in every row.

The last two rows exist because each was found by a stub that passed everything before it. A plain
`realpath` string comparison, never calling `samefile`, passed the first three cases; that is finding
46's hole and the case-spelling row closes it. A `realpath().lower()` comparison then passed all four;
the normalisation row closes that one, measured:

```
samefile(NFC, NFD)          True
realpath equal as string    False
realpath().lower() equal    False
```

Both rows must skip rather than fail where the filesystem does not fold — on a case-sensitive or
non-normalising filesystem the two spellings are genuinely different directories.

**What this does and does not establish, stated because the previous version of this paragraph
overstated it and was caught within one round.** It claimed no stub passed every case. A reviewer
then wrote one that does — `os.path.realpath(unicodedata.normalize("NFC", abspath(p))).lower()`,
which passes all of them without calling `samefile`. So: the cases reject four wrong implementations
that were actually written, and a fifth passes. No test can force the primitive, since any
implementation that agrees with `samefile` on every axis the suite measures is by definition
acceptable to it. Chasing a sixth discriminator would be the enumerate-the-shapes failure this
document warns about twice, and the fifth stub is itself an enumeration — case and normalisation —
that breaks on the first axis nobody thought of. The reason to write `samefile` is that it agrees on
the axes that were *not* tested; that reason is in the specification, not in the suite.

The three legitimate cases are the point of this section, and the positive half of each assertion is
load-bearing. A dry run showed that "the mismatch reason is absent" is satisfied by an implementation
that never prints that reason at all. The suite as a whole is not fooled — such a stub fails the two
reject cases — but a per-case assertion that a stub passes is not a regression guard for that case,
which is what these cases exist to be. Asserting the provenance values instead makes each legitimate
case prove that the layout was resolved, and the expected value differs per layout so it cannot be
satisfied by one constant. Do not assert the token on these three: what they produce otherwise
depends on their diff, which is not under test.

The submodule case needs `protocol.file.allow=always` on the `submodule add`, since recent git
refuses local-path submodules by default. It must be passed as `git -c protocol.file.allow=always
submodule add`; a reviewer measured that setting it with `git config` first still fails with
`fatal: transport 'file' not allowed`.

Do **not** add cases asserting that a `GIT_DIR` or `.git`-file redirect is rejected. §4.2.2 does not
reject them, and a test asserting otherwise would be encoding a claim the design withdrew. If a case
is wanted there, it should assert the *provenance line* names the foreign git directory.

Step 6 needs a record that passes the schema, which batch 1 made stricter. Copy the shape from an
existing passing fixture in the same file rather than writing one from scratch: two reviewers, two
distinct non-empty `context` values, `verdict: PASS`, `frozen: true`, `reviewer_selected_by`, a
`conclusion` free of the overclaim words, `diff_id` set to the printed value, and `subject_paths`
containing the trigger from step 3. A record that fails the schema would make the case green for the
wrong reason.

After this case exists, it is the only place in the suite where a production `REVIEW_RECORD_OK` is
produced from real git history.

### 4.6 Documentation

Each obligation names its file. An obligation without a home is one an implementer can skip.

- `references/looping-review.md` § Tokens — the fixture namespace, the two provenance lines, the
  `none` mode value, and that a fixture run is not a production acceptance path. Also record that the
  wrapper's pre-Python exits emit no token and therefore no provenance lines (§4.3).
- `references/review-budget.md` § Tokens — the same token additions, plus that `blast_class` from a
  fixture run reflects the supplied path list rather than the working tree.
- `README.md:66` token row — only default resolution can emit `REVIEW_RECORD_OK`.
- `scripts/verify-review-record.sh` header — usage block at `:5` and the token list.
- Leave alone, each read on the current branch to confirm it stays true after the change:
  `references/looping-review.md:107` ("Forbidden: treat exit 0 as `REVIEW_RECORD_OK`"),
  `README.md:82` (`REVIEW_RECORD_OK` ≠ review quality; `REVIEW_RECORD_SKIP` ≠ reviewed),
  `skills/using-vibage/SKILL.md:37`, `adapters/cursor/vibage.mdc:32`,
  `adapters/claude/CLAUDE.vibage.md:28`, `adapters/codex/AGENTS.vibage.md:28` and
  `adapters/shared/AGENTS.vibage.md:28`. An earlier draft cited `looping-review.md:91` and `:100`
  for this; batch 1 edited that file and shifted the lines, and the draft used the pre-batch-1
  numbers from memory. `:91` is the diversity bullet and `:100` is blank.

## 5. What this does not close

**The threat model, stated first, because four rounds of this loop searched without one.**

Rounds 2 through 5 each found a wider redirect surface than the last — `GIT_DIR`, then
`core.worktree`, then a `.git` file, then `.git/commondir` and `refs/replace` — and each new one
required the same thing: write access inside the package. That access already buys something far
cheaper. Measured on a scratch copy of this repository, on a real gate-class change with no review of
any kind:

```
$ bash scripts/verify-review-record.sh .
REVIEW_RECORD_FAIL reason=missing_record        # the gate working

# copy any existing record; edit two fields, diff_id and subject_paths
$ bash scripts/verify-review-record.sh .
REVIEW_RECORD_OK path=…/27692fe2…md             # genuine production token
```

A reviewer reproduced this independently and added one correction: the donor record must itself be
schema-complete, since batch 1's rules reject older records missing `context` or
`reviewer_selected_by`. Several complete donors are in the tree, so the cost stands. Making records
unforgeable needs an attestation the package cannot produce about itself — the same structural gap
`docs/HONESTY-SURFACES.md` already records for the chat surface.

**Two questions decide whether a route deserves a control, and neither is "who can write".** An
earlier version of this section argued that every redirect needs write access inside the package,
that such access already buys the two-field forgery above, and that the redirect class is therefore
not worth chasing. A reviewer destroyed the first premise and was right to. Measured, with **zero
writes into the package**:

```
$ GIT_DIR=…/curated/.git GIT_WORK_TREE=…/curated bash scripts/verify-review-record.sh .
REVIEW_RECORD_SKIP reason=no_trigger_paths      # the unreviewed gate change is invisible
```

and `pack-health.sh:70` accepts any `SKIP`. The environment spelling needs no package write at all,
so the argument built on that premise is withdrawn. Four routes that genuinely need no package write
were also tried and did **not** move the history — `core.worktree` in a global `~/.gitconfig`, an
`include.path` pulling in the other repository's config, `GIT_CONFIG_COUNT`, and `GIT_CONFIG_GLOBAL`
— which is a negative result on four candidates, not a proof that no other exists.

The criterion that survives is the pair the design was already using without naming:

| Route | reachable by accident? | decidable from inside the package? | treatment |
|---|---|---|---|
| `GIT_DIR`, `GIT_WORK_TREE` and the other variables | **yes** — a stray variable in a wrapper, a CI harness, or porcelain that exports them to hooks | yes, trivially | **closed**, by clearing before every git call |
| package root is not the repository root | yes — a vendored install | yes, one `samefile` | **caught**, §4.2.2 |
| `refs/replace` | **yes** — a replace ref left behind after legitimate history rewriting makes the gate's diff vacuous | yes, `git replace -l` | **closed**, by `--no-replace-objects` on every git call |
| `.git/info/grafts` | yes, same shape | yes, the file either exists or does not | **recorded**, not closed: deprecated, and git announces it on every invocation |
| `.git` file, `.git/commondir`, alternates with a rewritten ref | no realistic accident: each needs git metadata deliberately written | **no** — each is a legitimate git feature, and a submodule is byte-for-byte the `.git`-file case | **recorded**, in the table below |

The forgery measurement is calibration, not justification: it bounds what a control in the third row
could ever be worth. The reason that row is not chased is the middle column, undecidability, which is
§4.2.2's result — and it should never have been restated as an argument about write access.

**A criterion that only excuses work is not a criterion, so this one is applied in the other
direction.** Ranking the open items by the same two columns puts the redirect class last and promotes
three things this batch does not do:

1. `tests/test_review_record.sh` runs in no CI job, per §6. Everything this batch adds is therefore
   unenforced on push — the plainest honest failure of all, and it outranks the whole of §4.2.2.
2. `update-index --skip-worktree` on a gate-class file yields `SKIP reason=no_trigger_paths` with the
   change sitting on disk, and `base == HEAD` on a shallow CI checkout yields a vacuous empty diff.
   Both are accident-reachable, both are decidable, and both produce a green that reads as clean.
3. `pack-health.sh` treats every `SKIP` as a pass, which is what keeps items 1 and 2 quiet.

These are the next batch, ahead of anything left in the redirect class. A reviewer's charge that the
redirect prose was crowding out the real honest-failure holes is accepted; this ranking is the
response, and it is why §4.2.2 shrank to a `samefile` call rather than growing a sixth rule.

**Against that standard, the claim is two claims of different strength.** On the argv channel, a
non-production run can no longer emit a production success token, and the result cannot be faked by
dropping a disclosure line. On the environment and repository-configuration channels, the claim is
weaker: one spelling is closed by clearing, one scope error is caught, and the rest is open. Nothing
wider. A reviewer found the earlier version of this paragraph still describing the argv claim alone
after the design had grown past it.

| Route to a production token with curated data | Status |
|---|---|
| Point the script at a different package root | **Open.** Mitigated only by the new `review_record_pkg=` line, which is disclosure, not prevention |
| Work on a branch whose diff genuinely contains only `tests/` changes and quote that green | **Open.** Mechanically indistinguishable from honest work |
| Assert in prose that the gate passed without running it | **Unchanged.** Handled by report lint, not here |
| Print a forged token from an unguarded helper script | **Open.** Batch 3 |
| Put a fake `git` earlier on `PATH` | **Open and not closable from inside the script.** The scope check and both provenance lines go through the same binary. Reproduced by a reviewer, who obtained a production `REVIEW_RECORD_OK` with a fabricated `diff_base` |
| Redirect the history with `GIT_DIR` or `GIT_WORK_TREE` | **This spelling closed; the class is not.** Measured: with the variable cleared, git resolves the package's own git directory again. Two conditions — every git call must route through the clearing helper, since §4.2.2 names three call sites, and the same redirect remains available through the file-based rows below |
| Redirect the history with a `.git` file plus `core.worktree` | **Open and shown to be unadjudicable from inside the package.** Structurally identical to a submodule — see §4.2.2. Survives a fully cleared environment: measured under `env -i`. The `review_record_git_dir=` line does name the foreign directory here, but see the row below |
| Redirect the history with `.git/commondir`, `refs/replace`, grafts, or alternates plus a rewritten ref | **Open, and invisible in the output.** Measured: `--show-toplevel` and `--absolute-git-dir` both keep naming the package while `git log` returns the other repository's history. This is why §4.2.2 does not claim the provenance lines detect redirects |
| Forge the review record itself | **Open, and cheaper than every row above.** Two edited fields, measured at the top of this section. No git-level check can see it |
| Edit `pack-health.sh` or `review_record.py` to accept fixture tokens | Both are guarded paths; needs a review record |
| Edit `.github/workflows/tier0.yml`, which is **not** guarded, to weaken CI | **Open.** Batch 3 |

`review_record_pkg=` resolves symlinks and `..`, so it cannot be made to lie by aliasing. Whether a
bind mount could make the printed path disagree with the digested tree was **not tested**.

No new self-declared field is introduced.

## 6. Known gaps left open

- `base == HEAD` still yields a vacuous empty diff and a `SKIP` in default mode, on a depth-1
  checkout of a branch whose tip carries the change. Not fixed here.
- A legitimate `--base=<older-sha>` comparison loses the production token. Accepted cost of §4.2.
- P4 and P5 are enforced by a suite that runs in **no CI job**: `scripts/test-tier0.sh`,
  `scripts/pack-health.sh`, `tests/test_pack_health.sh` and `.github/workflows/tier0.yml` reference
  `tests/test_review_record.sh` exactly zero times. Wiring it into CI is deliberately not bundled
  here. "Tested" must not be read as "enforced on every push".
- §4.2.2 neither stops nor reliably reveals a run whose history comes from another repository. See
  the §5 threat model for why it stops trying.
- `git update-index --skip-worktree` or `--assume-unchanged` on a gate-class file hides an on-disk
  change from the trigger scan: measured, `SKIP reason=no_trigger_paths` with the modified content
  sitting in the working tree. This is a measurement-integrity hole rather than a redirect, it needs
  no foreign repository, and it belongs with batch 3's working-tree-versus-index item. Recorded here
  because a reviewer found it during this batch.
- A time-of-check window remains between `changed_paths()`, `compute_diff_id()` and the record read.
  Unchanged by this work; recorded so it is not mistaken for new.
- Everything in batch 3: the trigger set defined by filename rather than capability, the
  working-tree-versus-index digest, newline filenames skipping the trigger scan, nested records being
  ignored, `__pycache__` matching the trigger prefix, and phantom `subject_paths` entries.

## 7. Verification plan

Every step parses stdout; exit 0 proves nothing.

1. `bash tests/test_review_record.sh` — suite green, including every case in §4.5, §4.5.1 and §4.5.2.
2. `bash scripts/verify-review-record.sh --paths-file=x .` and `--base=x .` — both print
   `FAIL: unknown flag` and exit 2. This is P1.
3. Re-run §1's reproduction against the library directly, with the record planted first. Expect
   `review_record_mode=fixture` and `REVIEW_RECORD_FIXTURE_PASS`; assert no production token literal
   appears in stdout or stderr.
4. `python3 scripts/lib/review_record.py . --base=HEAD` on a tree with real trigger changes — expect
   `review_record_mode=base_override` and a fixture token, no production token.
5. Default invocation on a branch with trigger changes — production tokens exactly as before, with
   `review_record_mode=` reporting whatever `resolve_base` chose.
6. Grep the legacy patterns from §4.4 against flagged stdout and stderr; expect zero matches, and one
   match for the `REVIEW_RECORD_OK_FIXTURE` control.
7. Empty and unreadable flag values — fixture namespace, fail closed, per §4.2.1.
8. `bash scripts/test-tier0.sh` — `TIER0_OK` unchanged. This work is ∉ Tier-0.
9. `bash tests/test_pack_health.sh` — green on a **clean checkout**. On the implementation tree it
   fails with `missing_record` until this batch's Impl record exists, which is the gate working.
10. A run against a subdirectory of a repository — `SKIP reason=git_scope_mismatch`, not
    `no_trigger_paths`.
11. `GIT_DIR` pointing at another repository — `review_record_git_dir=` names the **package's own**
    git directory, because §4.2.2 clears the variable. This is the check that the clearing reaches
    all three call sites.
12. A `.git`-file redirect, which clearing does not affect — assert only that the run completes and
    that `review_record_git_dir=` names the foreign directory. Do **not** assert a rejection, and do
    **not** generalise the case: a `.git/commondir` redirect passes the same run with both lines
    naming the package, per §4.2.2. The case documents one diagnostic that happens to work, not a
    control.

## 8. Prior loop history

Three rounds ran against the earlier shape of this design and produced fifteen findings, all folded
before the reshape. They are kept because several were the author's own false claims, which is the
defect class this package exists to prevent.

| # | Finding | Response |
|---|---------|----------|
| 1 | §1 claimed both flags carry a TEST-ONLY comment; only `--paths-file` does | Corrected |
| 2 | The mode predicate keyed on value truthiness, so `--base=` slipped through | §4.2.1 |
| 3 | Fixture output would still contain `REVIEW_RECORD_OK` via the honesty line | §4.4 |
| 4 | The consumer list omitted the FAIL and SKIP assertions on fixture paths | §4.5 |
| 5 | §5 overclaimed a global reduction in forgery surface | Rewritten |
| 6 | The disjointness guarantee was presented without disclosing it is absent from CI | §6 |
| 7 | The `no_git_base` path had no mode value in the enum | §4.2 adds `none` |
| 8 | Documentation obligations named no file | §4.6 |
| 9 | A verification step asserted `merge_base`, wrong at the tip of main | §7 step 5 |
| 10 | An unreadable `--paths-file` raised a traceback and emitted no token | §4.2.1 |
| 11 | §1's transcript omitted the record-planting step, so it did not reproduce | §1 |
| 12 | `--paths-file` with an empty `--base` was undefined | §4.2.1 |
| 13 | "Every FAIL path" was not enumerated | §4.3 |
| 14 | Verification steps were not executable as written | §7 |
| 15 | **Shape objection:** labelling a test-only affordance instead of removing it from the production entry point. The real beneficiary was the pasted-output channel, since `pack-health.sh` never passes the flags | Accepted by the owner. §4.1 removes them; the namespace stays as defence in depth |

### Reshaped round 1

Three reviews of the reshaped design. Verdicts `BLOCK`, `BLOCK`, `APPROVE_WITH_GAPS`. All findings
were reproduced by the author against the branch before folding in.

| # | Finding | Response |
|---|---------|----------|
| 16 | The library takes `pkg` from `argv[1]` and scans flags from `argv[2:]`, so pointing the 29 flags-first call sites at it makes the flag become the package root and emits a **production** token. Measured | §4.2.1 pins the argv contract: first non-flag argument is the root, presence scans everything |
| 17 | §4.5 called the migration "mechanical", which is what would produce finding 16 | Reworded, with the failure named |
| 18 | §4.4 claimed all four legacy patterns match the control string. Only two do. The correct measurement had been run minutes earlier and was misread when written up | Replaced with the measurement table |
| 19 | §4.6 cited `looping-review.md:91` and `:100` for "exit 0 ≠ OK". Batch 1 shifted that file; `:91` is the diversity bullet, `:100` is blank, and the real line is `:107`. `README.md:82` was also mischaracterised | Citations re-derived against the branch |
| 20 | §1 said the one production-path call site asserts nothing; it asserts the absence of `reason=no_git_base` | Corrected |
| 21 | "Zero `git init` in the suite" was true of the file, not of `tests/` | Scoped |
| 22 | The integration test's seven steps would pass against an implementation that never consults git. Two reviewers built one | §4.5.1 now pins the trigger set, count, resolved package path, and the record schema |
| 23 | Neither the qualified record's shape nor the macOS `/tmp` resolve behaviour was specified, and a dry run hit both | §4.5.1 |

### Reshaped round 2

Verdicts `BLOCK`, `BLOCK`, `APPROVE_WITH_GAPS`. Seven of the eight round-1 repairs were confirmed
complete; the integration test was PARTIAL. All findings were reproduced by the author.

| # | Finding | Response |
|---|---------|----------|
| 24 | **New false-green class.** `GIT_DIR` redirects which repository git reads, so the package root and the measured history can be different trees, with no flag on the command line. Reproduced: the same command flips the mode, the trigger set and `diff_base` to the other repository's. The exact counts depend on the fixture pair; an earlier version of this row gave numbers that contradicted the transcript in §4.2.2. `review_record_pkg=` cannot disclose it because the root really is the innocent tree | New §4.2.2 clears the redirecting environment variables. **Still current for this variable**, though round 4 showed clearing does not close the class |
| 25 | The strengthened integration test still passed an implementation that hardcodes the one file the test changes and never calls git. Two reviewers built it independently | §4.5.1 adds a `diff_base` assertion against real `rev-parse` output, which is the only output that cannot be guessed from the file system |
| 26 | §4.2.1's measured transcript omitted that `/tmp/av.txt` must exist and name a trigger path. Missing gives a traceback, empty gives SKIP | Setup line added. This is finding 11's shape again |
| 27 | The header cross-referenced §7 for the history, which is §8 | Corrected |
| 28 | "The wrapper sorts them" — it reorders them | Corrected |
| 29 | "Both orders safe" is true only for the `=` spelling | Scoped |
| 30 | Appending a success case after the existing cases hits a fixture record left schema-invalid by earlier cases | §4.5.1 requires re-planting first |

Round 2 broke a stated two-round bound. It is recorded rather than quietly extended: the bound was
set on the expectation that only prose would remain, and finding 24 is a new attack class, which is
what the loop exists to surface.

### Reshaped round 3

Verdicts `BLOCK`, `BLOCK`, `BLOCK`. All findings reproduced by the author.

| # | Finding | Response |
|---|---------|----------|
| 31 | Clearing seven `GIT_*` variables does not close the class. A repository-local `core.worktree`, and a `.git` file pointing elsewhere, still divorce the package root from the measured tree and reach a production `REVIEW_RECORD_OK`. Neither is an environment variable | §4.2.2 rewritten around an outcome check: require `--show-toplevel` to equal the package root and `--absolute-git-dir` to lie inside it. **Superseded by round 4** — that rule false-fails a linked worktree; see findings 38 and 43 |
| 32 | §4.2.2 named `git_stdout` but `resolve_base` has two bare `subprocess.run` git calls. Clearing the environment in one place leaves the redirect working | §4.2.2 now says three call sites and requires one helper |
| 33 | §4.5.1 claimed `diff_base` cannot be guessed from the file system and forces a git call. A reviewer satisfied it by reading `.git/HEAD` and zlib-decoding the commit, with zero git subprocesses | Claim withdrawn; what the assertion actually catches is stated |
| 34 | §4.5.1 allowed `merge_base or head1` while requiring `diff_base == HEAD~1`. On a branch ahead by two commits the mode is `merge_base` and the conjunction is false | Recipe pinned to `head1` |
| 35 | P1's success signal still said "rejects two flags", which §4.2.2 had already shown insufficient. The document contradicted itself | P1 restated with both conditions |
| 36 | §8 finding 24 gave a trigger count that contradicted the transcript in §4.2.2 | Numbers removed; the class is what the row records |
| 37 | §4.4's table header read as bare `-Fq OK` / `FAIL` / `SKIP`, under which two fixture rows would be hits. Only the full production tokens make the table true | Header now quotes the full patterns |

**Where this leaves the batch.** Rounds 1, 2 and 3 each found a *wider* surface than the last: the
argv contract, then the environment, then repository configuration and `PATH`. That is divergence,
not convergence, and it happened because the original scope — "stop the flags faking a run" — grew
into "guarantee the run measured the tree it names". §4.2.2's outcome check is the structural answer
to the second question and should stop the widening; the remaining known hole, a fake `git` on
`PATH`, is not closable from inside the script and is disclosed rather than patched.

**Superseded.** The outcome check was abandoned in round 4 and the widening did not stop until round
5 replaced the question — see findings 43 and 55, and the threat model that now opens §5. The
paragraph is kept because its diagnosis of the scope growth was right even though its remedy was not.

An implementer dry run against the pre-reshape document produced a working change across the seven
files it named, with the suite and `TIER0_OK` green. An earlier version of this sentence gave a
line count that no longer corresponded to any measurable artefact; a later dry run against the round-4
document measured +605 / −114 across the same seven files.

### Reshaped round 4

Opened by the author before dispatching reviewers, by testing round 3's own fix against legitimate
layouts rather than against more attacks. Round 3 had checked only that the new rule caught the two
known attacks.

| # | Finding | Response |
|---|---------|----------|
| 38 | Round 3's rule — git directory must lie inside the package root — **false-fails a legitimate `git worktree` checkout**, whose git directory is at `<main>/.git/worktrees/<name>`. Measured. A rule that rejects a legitimate layout gets routed around | Rule replaced |
| 39 | The replacement probe, "the package root is listed in `git worktree list`", **false-fails a submodule**, which produces the same signature as the `GIT_DIR` attack. Measured | Third probe added, then also withdrawn — see 43 |
| 40 | Reject-as-`FAIL` would newly break a vendored subdirectory install, which today reports `SKIP reason=no_trigger_paths` — measured, because the monorepo reports `vendor/…/scripts/…` and no trigger prefix matches | Reject is `SKIP reason=git_scope_mismatch`: an accurate reason in place of a misleading one, same outcome |
| 41 | With reject as `SKIP`, `pack-health.sh` would accept the redirected run, since it already treats `SKIP` as a pass | Proposed making pack-health reject that reason. Withdrawn by 45 |
| 42 | No case covered a legitimate layout, so nothing would have caught findings 38 and 39 after implementation | §4.5.2 added |

Findings 38 to 42 were opened by the author before dispatching reviewers, by testing round 3's fix
against legitimate layouts rather than against more attacks. Reviewers then found that the
replacement was wrong in both directions.

| # | Finding | Response |
|---|---------|----------|
| 43 | The three-probe rule **admits a `.git` file pointing at a foreign git directory with `core.worktree` pointing back**, because that is byte-for-byte the construct git uses for a submodule. Reproduced independently by the author: `git -C <pkg> rev-parse HEAD` returns the foreign HEAD while all three probes report a healthy submodule | The adjudication is abandoned. §4.2.2 now states the impossibility, keeps one `samefile` scope check with no false positives, and moves the redirect class to disclosure in §4.3 and §5. **Superseded in part by finding 55**: disclosure does not work either, and the class is recorded as open |
| 44 | The same rule **false-fails a stock `git clone --separate-git-dir`**, which sets no `core.worktree` | Same response. `samefile` accepts it; measured |
| 45 | Findings 40 and 41 contradict each other. `pack-health.sh:7` derives `PKG_ROOT` from its own location, so the vendored install that 40 protects would fail the check 41 adds | 41 withdrawn. §4.2.2 records why pack-health must not reject the reason |
| 46 | String comparison of `realpath` output false-fails a case-folded path on macOS, where `Path.resolve()` keeps the caller's spelling and git returns the canonical one | `os.path.samefile`, which compares inodes and is immune to both case folding and symlinks. Measured |

**Where this leaves §4.2.2.** Four rounds of building an outcome check ended in a proof that no such
check exists: the honest and hostile constructs are the same construct, distinguishable only from the
superproject, which the package cannot see. The section now claims detection, and §5 says so in those
words. **Superseded by finding 55**: `.git/commondir` defeats detection as well, so §4.2.2 claims
neither and §5 records the class as open. This is the outcome the package's own rules are for — the alternative was shipping a rule that
two reviewers had already broken in both directions.

Two further reviewers reported against the pre-rewrite text. Their §4.2.2 findings are superseded by
43 to 46; the rest survived and are recorded here.

| # | Finding | Response |
|---|---------|----------|
| 47 | Clearing the `GIT_*` variables contradicts a test case requiring a `GIT_DIR` redirect to be detected: once cleared, there is nothing to detect. An implementer resolved it by inventing a `clear_redirects=False` branch for the probes | Measured both directions: clearing genuinely restores the package's own git directory, and the `.git`-file redirect survives `env -i`. So the `GIT_DIR` **spelling** is closed — not the class, per finding 59 — and the disclosure case must use the `.git`-file redirect. §5 and §7 corrected; no branch needed |
| 48 | A flagged run that hits a scope mismatch would emit the production `REVIEW_RECORD_SKIP`, putting a production literal in flagged output and breaking P4 | §4.2.2 now requires `REVIEW_RECORD_FIXTURE_SKIP reason=git_scope_mismatch` on the flag channel |
| 49 | §4.5.2's legitimate-layout cases assert only that a string is absent, which an implementation that never prints it satisfies. Demonstrated with a stub | Each legitimate case now also asserts a provenance value that differs per layout. The claim that the *suite* is fooled is not accepted — the stub fails the two reject cases — and the section says so |
| 50 | §4.2.2 named no keys for the provenance lines, so a dry run invented `git_toplevel=` and `git_dir=` | Cross-referenced to §4.3's exact key names |
| 51 | The document did not say what `review_record_mode=` should be when the scope check fires before `resolve_base`, nor whether a pure `--paths-file=` run runs the check | Both stated |
| 52 | §5's opening still described an argv-only claim after the design had grown past it; §8's findings 24 and 31 still presented superseded rules as current | Opening rewritten as two claims of different strength; both history rows marked |
| 53 | The `own-wt` probe was described as "the repository's own working tree", but the command returns the current directory for a plain clone; the description was an overreading of what was measured | The probe is gone with the adjudication. Recorded because the same overreading produced two of the four failed rules |
| 54 | The dry-run line count in this section was unverifiable | Replaced with a measured figure and the provenance of the old one |

### Reshaped round 5

Two reviewers on the rewritten §4.2.2 only. One returned `BLOCK`; findings reproduced by the author.

| # | Finding | Response |
|---|---------|----------|
| 55 | The provenance lines, which were all §4.2.2 had left, **can be made to lie by a single on-disk file**. `.git/commondir` redirects objects and refs while `--show-toplevel` and `--absolute-git-dir` keep naming the package and `samefile` returns true. `refs/replace`, grafts and alternates-plus-rewritten-ref reach the same place | Reproduced. The lines are demoted to diagnostics; §4.2.2 and §5 no longer claim they detect a redirect |
| 56 | A `--base=` run without `--paths-file=` skips `resolve_base` but still calls `changed_paths`, so a check placed at the top of `resolve_base` — a literal reading of the previous wording — would emit git-derived output without ever running | Wording changed to attach the check to the first git call |
| 57 | `os.path.samefile` raises `FileNotFoundError` rather than returning false when the toplevel disappears; a bare repository has no toplevel at all. Neither was specified | Both specified: catch `OSError`, treat as mismatch |
| 58 | `update-index --skip-worktree` on a gate-class file yields `SKIP reason=no_trigger_paths` with the modified content on disk. No foreign repository needed | Recorded in §6 and routed to batch 3; out of scope here |
| 59 | P1, §4.2.2 and §5 stated the strength of the `GIT_DIR` closure three incompatible ways: "disclosed instead", "not claimed to close the class", and "closed, conditionally" | All three rewritten to the same scoped claim: the environment *spelling* is closed, the *class* is not, and neither half may appear without the other |
| 60 | §4.2's token table did not cover the scope-mismatch outcome, and three combinations of flag, scope and git availability were undefined | Row added and all three defined |
| 61 | §4.5.2's three "equals" assertions are string-false on macOS, where the construction yields `/tmp/…` and git returns `/private/tmp/…`. §4.5.1 already handles this for `review_record_pkg=` | Comparison specified as `samefile` |
| 62 | **The five §4.5.2 cases do not require `samefile`.** A wrong implementation using plain `realpath` string comparison passed all of them, leaving finding 46's case-folding hole untested | A case-spelling row added, with a skip on case-sensitive filesystems |
| 63 | `git config protocol.file.allow always` then `submodule add` still fails; only `git -c … submodule add` works | Exact form specified |
| 64 | Round 3's closing paragraph still presented the abandoned outcome check as the current answer | Marked superseded |

**What round 5 actually settled.** Finding 55 would have forced a sixth rewrite under the assumption
the loop had been running on. Instead the author asked what every one of these attacks costs, and
measured that an attacker with write access to the package forges a review record by editing two
fields of a copied one — cheaper than any redirect, and invisible to every check inside the package.
Rounds 2 to 5 had been searching a space the gate never claimed to cover, which is why each round
found more of it. §5 now opens with the threat model, and the batch's claim is scoped to the honest
failure the gate exists for. The loop converges because the question changed, not because the answers
finally ran out.

### Reshaped round 6

A reviewer was pointed at §5's threat model alone and asked whether it was sound scoping or a claim
narrowed to fit the work already done. It returned `BLOCK` and said the second. Reproduced by the
author, and largely accepted.

| # | Finding | Response |
|---|---------|----------|
| 65 | §5's first premise — every redirect needs write access inside the package — is **false**. `GIT_DIR` with `GIT_WORK_TREE` needs zero package writes and yields `SKIP reason=no_trigger_paths` over an unreviewed gate change, which `pack-health.sh:70` accepts. Reproduced by the author | Premise withdrawn. §5 rewritten around two criteria, accident-reachability and decidability, with the measurement included |
| 66 | The right reason to stop chasing file-based redirects is §4.2.2's undecidability, not §5's write-access argument. Restating it as a property of the attacker made a sound result look like an excuse | Accepted verbatim. The forgery measurement is now labelled calibration, and the reason is the decidability column |
| 67 | An honest reframing should cut work, not only excuse it. §5 wrote a threat model to justify not chasing redirects while three accident-reachable, decidable honest-failure holes — the suite being in no CI job, `skip-worktree` and vacuous `base == HEAD`, and `pack-health` treating every `SKIP` as a pass — sat deferred | Accepted. §5 now ranks them above the redirect class and names them as the next batch |
| 68 | The forgery needs a **schema-complete** donor record; batch 1's rules reject older ones. Marginally harder than "any existing record" | Corrected in §5. Complete donors exist in the tree, so the two-field cost stands |

A second reviewer did the pre-freeze pass. It confirmed the `GIT_DIR` strength is now consistent
across §2, §4.2.2, §5 and §7, reproduced all three measured claims independently — the `commondir`
redirect, the two-field forgery, and `samefile` across five layouts — and found no remaining
implementer decision in §4.1, §4.2, §4.2.2, §4.3, §4.5.1 or §4.6. It returned `BLOCK` on the tests.

| # | Finding | Response |
|---|---------|----------|
| 69 | The case-spelling row added by finding 62 asserts only that a string is absent — **exactly the shape finding 49 rejected**, reintroduced in the fix for finding 46 | Positive provenance assertion added, as on the other legitimate rows |
| 70 | A `realpath().lower()` comparison, which never calls `samefile`, passes all six cases. The suite still does not reject the enumerating implementation | A unicode-normalisation row added. Measured: `samefile` true, both plain and lowercased `realpath` false. §4.5.2 also now states what the suite can and cannot establish, since no test can prove the primitive |
| 71 | §4.5.2 allowed "`samefile`, or resolve both sides first". Those are not equivalent: `Path.resolve()` preserves the caller's case and unicode spelling | Alternative removed |
| 72 | Three history rows still stated superseded strengths without saying so: round 4's "the section now claims detection", finding 43's "moves the redirect class to disclosure", and finding 47's flat "`GIT_DIR` is closed" | All three marked |
| 73 | §4.2.1's empty-value table did not give `review_record_mode=` for an empty `--base=` with no `--paths-file` | Row added |

Round 6 did not change the design. It changed why the design stops where it does, which had been
wrong in a way that flattered the work — the failure mode this package exists to catch, reached by
the author of the document about it. Findings 69 and 70 are the third and fourth time a test case in
this document was satisfiable by a stub; that pattern, not any individual attack, is what the loop
kept catching.

### Reshaped round 7

One reviewer, reading only the parts rewritten during round 6, so the round would close rather than
re-litigate. `BLOCK`, two findings, both reproduced by the author.

| # | Finding | Response |
|---|---------|----------|
| 74 | §5's new criterion filed `refs/replace` with the undecidable cases, and both of its columns are wrong there: a leftover replace ref is accident-reachable after ordinary history rewriting, and `git replace -l` decides it in one command. The criterion was laundering a decidable, accidental route through a row about undecidable ones | Accepted, and it turned into a fix rather than a disclosure. Measured that `--no-replace-objects` restores the correct diff, so §4.2.2 now passes it on every git call and §5 lists the route as **closed**. `.git/info/grafts` is not covered by the flag, also measured, and moves to its own recorded row |
| 75 | §4.5.2 claimed no stub passed every case. One does: `realpath(NFC(abspath(p))).lower()`, which never calls `samefile` | Claim withdrawn and the stub recorded. The paragraph now states that no test can force the primitive and why chasing a sixth discriminator would repeat the failure this document warns about |

Finding 74 is the criterion doing what it was added for. It was introduced in round 6 after a
reviewer said an honest reframing must cut work as well as excuse it; one round later it identified
work that had been wrongly excused, and that work was a single flag. Finding 75 is the fifth stub in
four rounds, and the response is to stop rather than to add a sixth case.

**Scope.** A reviewer recommended splitting the git-scope work into its own batch, reviewing the
version where it was an adjudicating gate with its own failure modes and its own risk of breaking
legitimate installations. After findings 43 to 46 that work is one `samefile` comparison, two print
lines and five test cases, and the risk axis the recommendation rested on is gone, since `samefile`
has no false positive across five measured layouts. Kept in one batch. The recommendation is recorded
rather than dropped, because the reasoning was sound against the design as it then stood.
