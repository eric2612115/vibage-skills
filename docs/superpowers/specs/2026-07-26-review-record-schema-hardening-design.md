# Review-record schema hardening

**Date:** 2026-07-26
**Status:** Frozen after eight plan-loop rounds. Ready to implement.
**Plan loop:** eight rounds, three independent reviews each. The full record of what each round found
and what changed is §9. Rounds 1 and 2 patched defective shapes one at a time and were defeated
repeatedly, so round 3 replaced that approach with the single structural rule in §4.3. No round
after round 4 found a new way to hide a failure in the parser.
**Baseline commit:** `58c553a` (main = origin/main at design time)
**Batch:** 1 of 3. Batch 2 is invocation provenance (parked, reshaping). Batch 3 is the trigger-set
capability problem (finding C).

**One sentence:** the record validator lets a reviewer's failure be visible to a human and invisible
to the gate, in every way listed in §1 and §4.3.1, all reproduced. **No total is stated here on
purpose.** Four earlier drafts of this document stated a count and three of them were wrong, always
by double-counting or by reporting a filtered measurement as a total. The defects are enumerated;
readers who need a number should count the enumeration.

**The one cause.** `parse_front_matter` ignores every line it does not recognise. Each defect below
is a different way to write a failure onto a line the parser will not look at. Two rounds of review
closed three shapes and the adversarial lens immediately produced three more, which is the signature
of patching symptoms. Round 3 therefore inverts the parser's default: **inside the front-matter
region, a line that is not affirmatively recognised is a schema error.** The record vocabulary is
small and closed — ten top-level keys and seven reviewer keys across all eleven real records — so a
whitelist is practical, and the parser stops having anywhere to hide a failure.

## 1. The defects (all reproduced, none suspected)

Every reproduction below was run against `58c553a` in a scratch clone. In each case the record file
plainly contains a failure a person would see, and `scripts/verify-review-record.sh` printed
`REVIEW_RECORD_OK`.

### 1.1 `verdict` is compared against one literal string

```372:373:scripts/lib/review_record.py
        if (r.get("verdict") or "").strip().upper() == "FAIL":
            errs.append(f"reviewer[{i}] verdict FAIL")
```

Records whose reviewers all carry `verdict: FAILED`, or `BLOCKED`, or `REJECT`, or **no `verdict`
key at all**, each produced `REVIEW_RECORD_OK`. `FAILED` is the spelling a person is most likely to
write. Nothing requires the key to exist.

### 1.2 The front-matter delimiter is matched anywhere, not only on its own line

```243:247:scripts/lib/review_record.py
    if not text.startswith("---"):
        raise ValueError("missing YAML front matter")
    parts = text.split("---", 2)
    if len(parts) < 3:
        raise ValueError("unterminated front matter")
```

A reviewer carrying `note: "cross-ref --- thread"` truncates the front matter mid-value, so every
reviewer below it disappears, including one with `verdict: FAIL` and a non-empty `blocking` list.

**Correction to the round-1 draft, which overclaimed.** This is *not* mainly an accident waiting to
happen. With the canonical field order shown in `references/looping-review.md:54-74`, where
`conclusion` comes after `reviewers`, truncation also removes `conclusion` and the record fails with
`missing conclusion`. Verified. The false green requires `conclusion` to appear *before* `reviewers`
— legal YAML, invisible to a casual reader, but a deliberate arrangement rather than a slip. The
defect is real and it is an attack; calling it an everyday accident was wrong.

### 1.3 Duplicate keys silently keep the last value

A reviewer carrying `verdict: FAIL` immediately followed by `verdict: PASS` produced
`REVIEW_RECORD_OK`. So did a reviewer carrying `blocking: ["gate is broken"]` followed by
`blocking: []`. The failing text stays in the file; the parser keeps only the second value.

### 1.4 A reviewer field at the wrong indentation is silently dropped

Reviewer fields are recognised only by `re.match(r"^    \w", line)` — exactly four spaces. A
`blocking:` key at three spaces, listing a real finding, produced `REVIEW_RECORD_OK`, because the
line matched nothing and fell through to be ignored. `blocking` then defaulted to empty.

### 1.3b A key that differs only in case is stored separately and ignored

Reviewer B carrying `Verdict: FAIL` on one line and `verdict: PASS` on the next produced
`REVIEW_RECORD_OK`. The parser stores `Verdict` and `verdict` as two different keys and the
validator reads only the lower-case one. A duplicate-key rule that compares exact strings does not
see this, which is why round 2's rule was not enough.

### 1.4b A list item that carries a colon is dropped without complaint

A line `      - id: dropped-finding` written inside a reviewer entry but before its `blocking:` key
is a list item, so it is exempt from the indentation rule, and it is not inside a `blocking` context,
so nothing collects it. It vanishes. `REVIEW_RECORD_OK`.

### 1.4c `splitlines()` manufactures a delimiter that is not in the file

`'\x0c---'.splitlines()` returns `['', '---']`, because Python's `splitlines` breaks on form feed,
vertical tab, and `U+2028`. `'\x0c---'.split('\n')` returns the single element `['\x0c---']`. So a
delimiter rule expressed as "a line equal to `---`" terminates the front matter early if the
implementation splits with `splitlines()`, even though no such line exists in the file. Reviewers
below the fabricated delimiter disappear.

### 1.4d `frozen: False` reads as not-frozen and passes as frozen

The parser converts a value to a boolean only for the exact lowercase literals `true` and `false`
(`scripts/lib/review_record.py:311-312`). Anything else stays a string, and a non-empty string is
truthy, so `validate_record`'s `if not data.get("frozen")` check passes. A digit string takes a
second route: it is coerced with `int()`, and any non-zero integer is truthy. So a record can be
marked as not frozen in a way a reader understands and the gate accepts as frozen.

No summarising sentence is offered here, because every previous attempt to summarise this matrix in
prose was wrong. The measured result, over the values tested:

| Satisfies the frozen requirement today | Does not |
|---|---|
| `true`, `True`, `TRUE`, `False`, `FALSE`, `no`, `No`, `yes`, `YES`, `on`, `off`, `t`, `f`, `null`, `1`, `01`, `2`, `-1` | `false`, `0`, `00`, empty |

Only `true` and `false` are what the schema means. Everything else in the left column is a value a
reader could read as "not frozen" or as meaningless, which the gate accepts as frozen. This list is
the set of values that were tested, not a claim about every possible value.

All eleven existing records write `frozen: true`, so constraining this is migration-free; verified.

### 1.5 An indented delimiter would still truncate under the round-1 fix

The round-1 draft proposed terminating at any line whose *stripped* content equals `---`. A line of
four spaces followed by `---`, placed between two reviewers, satisfies that rule: the file shows
three reviewers and the rule sees two. The draft also claimed this matched YAML's own reading, which
is false — PyYAML raises a scanner error on an indented document marker rather than truncating
silently. The rule must forbid leading whitespace.

## 2. Goals

| ID | Goal | Success signal |
|----|------|----------------|
| **S1** | A verdict outside the documented vocabulary can never pass | `verdict` required; value must be `PASS`, `PASS_WITH_GAPS`, or `FAIL`; anything else is a schema error quoting the offending value |
| **S2** | Front matter ends only at an unindented delimiter line | open and close both require a line equal to `---` after stripping trailing whitespace and `\r`, with **no leading whitespace** |
| **S3** | The parser has nowhere to hide a failure | every line in the front-matter region must match one of seven recognised shapes; keys must come from a closed whitelist; container keys must carry no inline value; the reviewer `id` must be a simple token. Anything else is a schema error quoting the line and its number |
| **S4** | A repeated key cannot overwrite a failure | a whitelisted key appearing twice at top level, or twice within one reviewer entry, is a schema error naming the key |
| **S5** | Reviewers outside the parsed region are visible | stdout discloses `reviewers_outside_front_matter=N` when the file contains more reviewer-entry lines than the parsed region does. **Disclosure only — never fails the gate** |
| **S6** | A boolean field cannot be truthy while reading as false | `frozen` must be the literal `true` or `false`; any other value is a schema error quoting it |

S5 follows the idiom `references/review-budget.md:54-55` sets for `reviewer_selected_by`: where a
mechanical rule would be arbitrary, do not block, make the configuration visible.

**The round-1 reviewer-count cross-check was cut.** Two lenses independently showed it earns
nothing: computed over the same delimited region with the same predicate, the raw and parsed counts
are equal by construction, so it cannot detect any defect above. It also carried a false-failure
risk if implemented with `strip()`, because `blocking` list items are written `      - id: …` in
some records. S5 replaces it with something that *can* see past the region, and that cannot fail a
good record because it never fails anything.

## 3. Non-goals / honesty locks

- ≠ replace the hand-written parser with a YAML library. PyYAML imports on this machine but is
  absent from `requirements-tier0.txt`, and the CI `pack-health` job installs no Python requirements,
  so adopting it is a separate decision with its own CI work.
- ≠ change review policy. `PASS_WITH_GAPS` still passes when `blocking` is empty, exactly as
  `references/looping-review.md:68` and `:83` describe. This closes parsing holes; it does not raise
  the bar for what counts as an acceptable review.
- ≠ touch the flags, token names, or invocation modes. That is batch 2.
- ≠ change `diff_id`, the budget table, `contexts_ok`, or `reviewer_selected_by` handling.
- ≠ claim the parser becomes correct in general. It stays hand-written. S5 exists because we do not
  trust it.
- ≠ claim `REVIEW_RECORD_OK` means review quality. Unchanged.

## 4. Design

### 4.1 Verdict vocabulary (S1)

`references/looping-review.md:68` already documents `verdict: PASS|PASS_WITH_GAPS|FAIL`. Make the
code agree with the document. Evaluate in this order, on the trimmed value, comparing case-insensitively:

| Condition | Error text |
|-----------|-----------|
| key absent or value empty | `reviewer[i] missing verdict` |
| value is `FAIL` | `reviewer[i] verdict FAIL` — **unchanged wording**, because `tests/test_review_record.sh:870` asserts on this exact substring |
| value is `PASS` or `PASS_WITH_GAPS` | accepted |
| anything else | `reviewer[i] verdict must be PASS\|PASS_WITH_GAPS\|FAIL, got '<trimmed original>'` |

The final message quotes the value as written, not upper-cased, because the entire point is that
`FAILED` and `FAIL` look alike when skimming.

### 4.2 Delimiter (S2)

Replace `text.split("---", 2)` with a line scan:

1. Line 0 must satisfy `line.rstrip() == "---"`. Otherwise `missing YAML front matter`.
2. Scan forward; the region ends at the first later line satisfying the same predicate.
3. No such line → `unterminated front matter`.
4. Everything after it is body and is not parsed.

`rstrip()` removes trailing whitespace and `\r`, so CRLF files behave like LF files, while leading
whitespace is significant and therefore an indented `---` does **not** terminate anything.

Two behaviour changes beyond the intended fix, stated so they are not discovered later. Today
`text.startswith("---")` accepts `---x` as an opener; under the new rule it does not, and the file
is reported as having no front matter. Today an indented opener is rejected, and it still is. The
eleven existing records all open with an exact `---` and are unaffected; verified.

### 4.3 Recognised shapes and key whitelist (S3)

This replaces round 2's separate indentation rule and subsumes it. Inside the front-matter region,
each line must match exactly one of the shapes below. Anything else is the error
`front matter line <n> not recognised: <line as written>`.

| # | Shape | Condition |
|---|-------|-----------|
| 1 | blank | `line.strip() == ""` |
| 2 | comment | `line.lstrip()` starts with `#` |
| 3 | top-level key | `^[A-Za-z_][A-Za-z0-9_]*:` at column 0, key in the top-level whitelist |
| 4 | `subject_paths` item | `^  - ` and the most recent top-level key was `subject_paths` |
| 5 | reviewer entry start | `^  - id:` or `^  -id:` |
| 6 | reviewer field | `^    [A-Za-z_][A-Za-z0-9_]*:` inside a reviewer entry, key in the reviewer whitelist |
| 7 | `blocking` item | `^      - ` inside a reviewer entry whose most recent field was `blocking` |

Top-level whitelist: `diff_id`, `diff_base`, `subject_paths`, `loop`, `round`, `frozen`,
`diversity`, `diversity_reason`, `reviewers`, `conclusion`, `blast_class`, `review_budget_n`,
`min_reviewers`.

Reviewer whitelist: `id`, `lens`, `verdict`, `model`, `context`, `reviewer_selected_by`, `blocking`.

`min_reviewers` is deliberately *recognised* even though `validate_record` rejects any record that
declares it. If the parser refused it as unrecognised, the specific existing message
`min_reviewers must not be declared; omit field` would be replaced by a generic one and the reader
would lose the explanation. Recognise, then reject with the message that already exists.

Matching is **case-sensitive**, which is what closes §1.3b: `Verdict` is not in the whitelist, so it
is an unrecognised line rather than a silently separate key. Shape 7 is scoped to a `blocking`
context, which is what closes §1.4b: a list item anywhere else is unrecognised rather than dropped.

#### 4.3.1 Container keys must have an empty value (S3c)

Recognising a line is not enough if its value is then discarded. `reviewers:` and `subject_paths:`
are containers whose value the parser throws away, so a whole failing reviewer can be written on the
same line in YAML flow style and vanish:

```yaml
reviewers: [{id: Z, verdict: FAIL, model: x, context: cz, reviewer_selected_by: owner, blocking: [gate broken]}]
```

Reproduced: a reader sees reviewer Z failing with a finding; the gate reports only the block-style
reviewers below. For `reviewers:` and `subject_paths:`, anything after the colon other than
whitespace is the error `key '<key>' must have no inline value`.

**The same failure exists on the reviewer entry line itself.** Shape 5 takes everything after the
first colon as the `id` value, so an entry can be written

```yaml
  - id: Z, verdict: FAIL, model: x, context: cz, reviewer_selected_by: owner, blocking: [gate broken]
    verdict: PASS
    model: m
```

and the whole failing reviewer becomes an opaque `id` string while the gate reads the `PASS` below.
Reproduced against the current parser. Therefore `id` must match `^[A-Za-z0-9._-]+$`; anything else
is the error `reviewer[i] id must be a simple token, got '<value>'`. Every id in the existing corpus
is `A`, `B` or `C`, so the constraint is migration-free; verified.

This constraint is deliberately **not** extended to `model`, `context` or `lens`. The reason is cost,
not severity: `id` is a machine identifier with no legitimate need for punctuation, while those
fields are documented as free-form self-declared prose. §8 states the residual and why an earlier,
different justification for the same decision was wrong.

#### 4.3.2 Scanning rules (pinned)

Three points the round-3 dry run had to guess. They are decided here because two compliant
implementations would otherwise diverge.

- **Precedence.** Shapes are tested in this order: control-character check, 1, 2, 3, **5, then 4**,
  6, 7. Shape 5 precedes shape 4 because `  - id: foo` under a `subject_paths` context matches both,
  and a reviewer entry is the meaning that matters.
- **Context maintenance.** The most-recent top-level key is set only by a successful shape 3 match
  and is never cleared by blank lines, comments, or list items. The most-recent reviewer field is set
  by a successful shape 6 match, is cleared when shape 5 starts a new entry or a top-level key ends
  the entry, and is not changed by blank lines, comments, or list items. So a blank line between
  `blocking:` and its items does not break the context.
- **Unrecognised lines do not stop the scan.** Record the error and keep going. Aborting would hide
  the reviewers below the offending line, which is the exact failure mode this whole design exists to
  remove; test case 6 depends on the later reviewer still being seen.
- **`blocking` inline and scalar values are retained, not discarded.** A `blocking:` line may carry
  an inline list, a scalar, or nothing, and the existing parser's handling of all three is unchanged.
  This is stated because §4.3.1 forbids inline values on the *container* keys, and an implementer
  reading that rule alone could reasonably extend it to `blocking`, which would silently drop a
  finding written as `blocking: [gate is broken]`. Existing assertions at
  `tests/test_review_record.sh:857-865` would catch that, but the design must not rely on a test to
  carry a rule.
- **List-item payload.** A shape 4 item's value is the text after `  - `, and a shape 7 item's value
  is the text after `      - `. State the offsets rather than "the rest of the line": the round-5 dry
  run initially sliced six characters instead of eight and was caught only by an existing test.
- **Duplicate keys keep the first value**, and the duplicate is reported. The record fails either
  way, so the choice only affects which value appears in an error message, but it is pinned so the
  tests are deterministic.

**Two behaviour changes to accept deliberately.** A reviewer entry may no longer carry free-text keys
such as `note:`; the record's free-text field is `conclusion`. And a `subject_paths` item may no
longer appear after some other top-level key has intervened. Neither affects any existing record;
verified in §4.6.

### 4.3.3 Boolean literals (S6)

`frozen` must be exactly `true` or `false` after trimming, compared case-sensitively. This is
**stricter** than YAML 1.1, which also accepts `True`, `yes` and `no` as booleans; an earlier draft
said it matched YAML, which it does not.
Any other value is `frozen must be true or false, got '<value>'`. The existing requirement that the
value be `true` is unchanged; what changes is that every value in the left column of §1.4d's table
stops being silently truthy.

**Quote handling, pinned.** The existing parser strips surrounding quotes from every scalar before
use. That behaviour is retained, so `frozen: "true"` is accepted. Without this sentence two compliant
implementations would disagree, because §4.3.3 read literally says only "after trimming".

This rule is scoped to `frozen` because it is the only field whose *truthiness* the validator tests.
An earlier draft justified the scope by claiming `round` and `review_budget_n` are integers already
validated where they are used. That is false for `round`: **`review_record.py` never reads `round`
at all**, so any value passes, which is a disclosure gap rather than a false-green one and is
recorded in §8. `review_budget_n` is genuinely checked against the script-derived floor when present.

### 4.4 Duplicate keys (S4)

Track keys seen at top level and, separately, within the current reviewer entry. A repeat is
`duplicate key '<key>'` or `reviewer[i] duplicate key '<key>'`. Starting a new reviewer entry resets
the per-entry set. Because §4.3 already rejects unwhitelisted keys, this rule only needs to handle
exact repeats of legitimate keys.

### 4.4b Line splitting and control characters

Split the document with `text.split("\n")` and strip a trailing `\r` from each line. **Do not use
`str.splitlines()`**, which also breaks on form feed, vertical tab, `U+2028` and others, and would
fabricate a delimiter line that does not exist in the file (§1.4c).

Additionally, any line in the front-matter region containing a control character other than tab —
that is, any codepoint below `U+0020` except `\t`, plus `U+2028` and `U+2029` — is the error
`front matter line <n> contains a control character`. This makes the split choice enforceable rather
than merely documented, so a later refactor to `splitlines()` cannot silently reopen §1.4c.

### 4.5 Where errors surface (pinned)

Round-1 review showed two implementers would split this differently, so it is decided here.

`parse_front_matter` continues to raise only for the two structural failures it raises today,
`missing YAML front matter` and `unterminated front matter`, which reach stdout as
`REVIEW_RECORD_FAIL reason=parse`. Everything added by S1, S3, S4 and S6 is collected and surfaced
through `validate_record`, reaching stdout as `REVIEW_RECORD_FAIL reason=schema`.

To carry findings across, `parse_front_matter` accumulates them in its returned dictionary under the
reserved key **`_parser_errors`** (a list of strings), and `validate_record` extends its own error
list from that key as its first action, before any other check. The name is pinned here because two
implementers would otherwise choose differently. `_parser_errors` is not a whitelisted key, so a
record cannot inject or clear it: a literal `_parser_errors:` line in the file is rejected by §4.3.

S5's disclosure line is printed next to the other disclosure output, after the record parses and
before the token, using the same placement as the existing `reviewer_selected_by:` line.

**S5's predicate, pinned.** Count lines matching `^\s*-\s*id:` in the whole file, and subtract those
inside the front-matter region. Print `reviewers_outside_front_matter=N` only when `N > 0`. The
predicate is deliberately looser than the parser's own entry shape, so that an entry written
`- id: D` at column zero after the terminator is still counted. The cost is that prose in the body
resembling a reviewer entry inflates the number. That is acceptable because the line never fails the
gate; it exists to make a reader look. It is **not** a detector and §8 says so.

### 4.6 Migration risk, measured rather than assumed

All eleven records under `docs/evidence/reviews/` were re-parsed with the pack's own parser and
checked against every new rule. Zero records change status.

| Record prefix | Reviewers | Verdicts |
|---|---|---|
| `0d7ee47a7f0f` | 3 | PASS ×3 |
| `23c0a123b126` | 3 | PASS ×3 |
| `2c30ce8206a6` | 3 | PASS ×3 |
| `5467651f296d` | 3 | PASS ×3 |
| `5b9d88ea7ddc` | 3 | PASS ×3 |
| `61245efb49fa` | 3 | PASS ×3 |
| `6d40d5163dbe` | 3 | PASS ×3 |
| `7a5552241fd8` | 3 | PASS ×3 |
| `bfa627086481` | 3 | PASS, PASS_WITH_GAPS, PASS |
| `c17c3281d4d4` | 3 | PASS ×3 |
| `d630854434f8` | 2 | PASS ×2 |

Also measured across the same corpus:

- top-level keys used, in total: `conclusion`, `diff_base`, `diff_id`, `diversity`,
  `diversity_reason`, `frozen`, `loop`, `reviewers`, `round`, `subject_paths` — all ten are
  whitelisted. An earlier draft said nine because the author's own measurement script excluded
  `reviewers` and then reported the filtered set as the total
- reviewer keys used, in total: `blocking`, `context`, `id`, `lens`, `model`,
  `reviewer_selected_by`, `verdict` — all seven are whitelisted, and no record uses `note`
- no duplicate key at top level or inside any reviewer entry
- no reviewer field at an unexpected indentation
- no indented `---`; all eleven open with an exact `---`
- no control characters in any front-matter region

Step 3 of the verification plan re-runs this against the table above, so a regression is caught
rather than assumed.

### 4.7 Files

| File | Change | Guard class |
|------|--------|-------------|
| `scripts/lib/review_record.py` | §4.1 through §4.5 | gate |
| `tests/test_review_record.sh` | new cases per §5 | tests |
| `references/looping-review.md` | `verdict` is required; the pass predicate at `:83` currently says only "no `verdict: FAIL`" and becomes incomplete; delimiter must be an unindented line of its own | narrative |

`references/review-budget.md` is **not** the SSOT for record field semantics and needs no edit; that
was an unnecessary entry in the round-1 list. `scripts/verify-review-record.sh` is an exec wrapper
and is untouched. `pack-health.sh`, `README.md`, `skills/**`, `adapters/**` and
`references/hard-stops.md` state nothing that becomes false; each was read to confirm this.

Blast class is `gate`, so the Impl floor is two reviewers with at least two distinct contexts. This
document is a plan, so its own loop floor is three.

## 5. Test cases to add

Every negative case asserts the token, the `reason=`, **and** the specific error text. A bare
`REVIEW_RECORD_FAIL` would also be printed by an over-strict wrong implementation, and a case that
checks only the message would not catch an implementation that routes it through `reason=parse` in
violation of §4.5.

| # | Record shape | Assert |
|---|--------------|--------|
| 1 | every reviewer `verdict: FAILED` | `REVIEW_RECORD_FAIL`, `reason=schema`, message contains `got 'FAILED'` |
| 2 | `verdict` key omitted | `REVIEW_RECORD_FAIL`, `reason=schema`, message contains `missing verdict` |
| 3 | `verdict: fail` lower case | `REVIEW_RECORD_FAIL`, `reason=schema`, message contains `verdict FAIL` — proves the existing case-insensitive path is untouched |
| 4 | `verdict: PASS_WITH_GAPS`, empty `blocking` | `REVIEW_RECORD_OK` — proves policy did not change |
| 5 | reviewer B carries a value containing `---` mid-line **after** all of B's required fields, reviewer C has `verdict: FAIL` and a finding, and `conclusion` is placed **before** `reviewers` | `REVIEW_RECORD_FAIL`, `reason=schema`, message contains `verdict FAIL`. The layout matters: if the `---` precedes any of B's required fields, the record already fails today for a different reason, so the case would not pin the truncation |
| 6 | an indented `    ---` between reviewers B and C | `REVIEW_RECORD_FAIL`, `reason=schema`, and the C reviewer is seen — the round-1 rule let this through |
| 7 | duplicate `verdict` key, `FAIL` then `PASS` | `REVIEW_RECORD_FAIL`, `reason=schema`, contains `duplicate key 'verdict'` |
| 8 | duplicate `blocking` key, finding then `[]` | `REVIEW_RECORD_FAIL`, `reason=schema`, contains `duplicate key 'blocking'` |
| 9 | `blocking:` at three-space indent listing a finding | `REVIEW_RECORD_FAIL`, `reason=schema`, contains `not recognised` |
| 10 | `Verdict: FAIL` then `verdict: PASS` on one reviewer | `REVIEW_RECORD_FAIL`, `reason=schema`, contains `not recognised` — §1.3b, which the round-2 duplicate rule missed |
| 11 | `      - id: dropped-finding` inside a reviewer entry, before its `blocking:` key | `REVIEW_RECORD_FAIL`, `reason=schema`, contains `not recognised` — §1.4b |
| 12 | a form feed immediately before `---` inside the front matter, with a `verdict: FAIL` reviewer after it | `REVIEW_RECORD_FAIL`, `reason=schema`, contains `control character` — §1.4c. Must fail whether or not the implementation happens to use `splitlines()` |
| 13 | a reviewer field named `note:` | `REVIEW_RECORD_FAIL`, `reason=schema`, contains `not recognised` — pins the deliberate behaviour change in §4.3 |
| 14 | a record declaring `min_reviewers:` | `REVIEW_RECORD_FAIL`, `reason=schema`, contains `min_reviewers must not be declared` — proves the whitelist did not swallow the specific existing message |
| 15 | valid record whose **body** contains `---` after the front matter | `REVIEW_RECORD_OK` — proves legal documents still parse |
| 16 | valid record with CRLF line endings | parses to the same reviewers and verdicts as the LF version |
| 17 | front matter never terminated | `reason=parse`, `unterminated front matter`, unchanged |
| 18 | a reviewer entry written `- id: D` at column zero **after** the terminator | `REVIEW_RECORD_OK` plus `reviewers_outside_front_matter=1` — proves S5's loose predicate catches the shape the parser's own predicate would miss, and that it discloses without blocking |
| 19 | `reviewers:` carrying an inline flow value containing a `verdict: FAIL` entry, with valid block-style reviewers below | `REVIEW_RECORD_FAIL`, `reason=schema`, contains `must have no inline value` — §4.3.1 |
| 20 | a duplicate **top-level** key, `conclusion` twice | `REVIEW_RECORD_FAIL`, `reason=schema`, contains `duplicate key 'conclusion'` — the round-3 review noted only per-reviewer duplicates were covered |
| 21 | an unrecognised line placed **above** a `verdict: FAIL` reviewer | `REVIEW_RECORD_FAIL` reporting **both** `not recognised` and `verdict FAIL` — pins the rule in §4.3.2 that scanning continues past an unrecognised line |
| 22 | `subject_paths:` carrying an inline value | `REVIEW_RECORD_FAIL`, `reason=schema`, contains `must have no inline value` |
| 23 | a reviewer entry line written `  - id: Z, verdict: FAIL, …, blocking: [gate broken]` with valid `PASS` fields beneath it | `REVIEW_RECORD_FAIL`, `reason=schema`, contains `id must be a simple token` — §4.3.1 |
| 24 | a `U+2028` immediately before `---` **on the same line**, inside the front matter, with a `verdict: FAIL` reviewer after it — the same byte layout as case 12 | `REVIEW_RECORD_FAIL`, `reason=schema`, contains `control character` — the same family as case 12 and the case a YAML library would **not** catch |
| 25 | `frozen: False` | `REVIEW_RECORD_FAIL`, `reason=schema`, contains `frozen must be true or false` — §4.3.3 |
| 26 | `frozen: no` | same as 25 — proves the rule is a literal check, not a truthiness check |
| 27 | `frozen: yes` | same as 25 — the third spelling named in §1.4d, so the case list covers every one |
| 28 | `frozen: 1` | same as 25 — closes the digit-coercion route, which a rule written only against word-like values would miss |
| 29 | `frozen: True` | same as 25. This case targets an implementation that lowercases before comparing, which §4.3.3 forbids. A round-8 reviewer showed the naive form of that mistake is already caught by case 25's message assertion, so the earlier claim that only case 29 could catch it was wrong; a narrower wrong implementation that special-cases `true` and routes everything else correctly is caught by 29 alone. It earns its place, but not for the reason first given |

## 6. Verification plan

Every step parses stdout; exit 0 alone proves nothing.

1. `bash tests/test_review_record.sh` — suite green, including every case listed in §5. Do not
   restate the case count here; it has drifted three times.
2. Confirm no existing assertion changed. The diff for that file must be additions only. In
   particular the `verdict FAIL` assertion at `tests/test_review_record.sh:870` still passes
   unmodified, which is what pins the wording in §4.1.
3. Re-parse all eleven existing records and confirm the reviewer counts and verdict lists match the
   table in §4.6 exactly, and that none produces a `_parser_errors` entry. A difference means the
   fix broke real history.
4. `bash scripts/test-tier0.sh` — `TIER0_OK` unchanged. This work is ∉ Tier-0; the check is that it
   was not disturbed.
5. `bash tests/test_pack_health.sh` — green **on a clean checkout**. On the implementation tree
   itself this step fails with `REVIEW_RECORD_FAIL reason=missing_record` until the Impl review
   record for this change exists, because the change touches guarded paths. That is the gate working,
   not a defect. Run it on a clean clone during implementation, and again on the real tree only after
   the Impl record is written.

## 7. Why these fixes are not more forgeable than what they replace

| Attack on the fix | Result |
|-------------------|--------|
| Write `PASS` instead of `FAILED` | Still possible, and unchanged by this work. The difference is that it becomes an active lie rather than a sloppy word the gate happened to ignore. `references/review-budget.md` already states these fields are self-declared and unverifiable |
| Put the failure somewhere the parser ignores | §4.3 removes the *unrecognised-line* channel entirely. Two channels remain by choice and are named in §8: comment lines, and free-text scalar values. So the accurate claim is narrower than 'the parser ignores nothing' — it is that a line the parser does not understand can no longer be silently skipped. Two rounds of adversarial review found five such shapes against enumerated rules and none has been offered against the whitelist, but that is absence of a finding, not proof |
| Add a shape the whitelist happens to accept | The whitelist is closed and small. Widening it is a change to `scripts/lib/review_record.py`, a guarded path, so it needs a review record |
| Reorder fields so truncation drops `conclusion` last | S2 removes the truncation itself |
| Weaken the new tests | `tests/` is a guarded path, so it needs a review record |

No new self-declared field is introduced. Every rule added is checkable from the file itself.

## 8. Known gaps left open

- The parser remains hand-written, and it is still not a YAML parser. What §4.3 changes is its
  failure direction: it now refuses what it does not understand instead of ignoring it. A document
  that real YAML would read differently from this parser is still possible; such a document now
  produces a schema error rather than a silent misreading, which is the property we actually need.
- Free-text scalar values — `model`, `context`, `lens`, `diff_base`, `diversity_reason`,
  `conclusion` — can be written to look like structured fields, for example
  `model: x, verdict: FAIL, blocking: [gate broken]`, and the gate reads them as opaque strings.

  **This residual is structurally identical to the `id` defect that §4.3.1 closes, and the honest
  reason for treating them differently is not the one an earlier draft gave.** That draft argued the
  free-text case is weaker because the reviewer's real `verdict:` line sits directly beneath it —
  but that was equally true of the `id` case, which was closed anyway, so the argument does not
  distinguish them. The real reason is narrower: `id` is a machine identifier with no legitimate need
  for punctuation, so constraining it costs nothing, whereas `model`, `context` and `conclusion` are
  documented as free-form self-declared prose and constraining them would break their purpose.
  That is a cost judgement, not a claim that the residual is smaller. Accepted with eyes open.
- A comment line is recognised and then ignored, so `# verdict: FAIL` is still a place to write
  something a skimming reader may register and the gate will not. Comments are visibly comments, so
  this is weaker than the defects being fixed, and banning them would be worse than the disease.
  Recorded rather than closed.
- `reviewers_outside_front_matter` is a prompt for a reader, not a detector. Its predicate is loose
  on purpose, so body prose can inflate it, and a sufficiently creative arrangement could still put
  something a reader treats as a reviewer where the count does not see it. It never fails the gate,
  so it can never be the thing that stops an attack — only the thing that makes someone look.
- A byte-order mark before the opening delimiter still defeats front-matter detection.
- Found during rounds 5 and 6 in code this design does not touch, recorded so they are triaged rather
  than lost. None is caused by this change and none is fixed by it.
  - A `blocking` item written as a non-breaking space strips to `-`, fails the `- ` test and is
    dropped, so a reader sees a finding the gate does not.
  - The `conclusion` overclaim regex is defeated by a zero-width space or a Cyrillic homoglyph inside
    `verified`, extending the unicode gap already disclosed at `references/review-budget.md:73-74`.
  - `diversity_reason` set to a zero-width space survives `.strip()`, so a reason that renders as
    blank satisfies the `diversity: waived` requirement.
  - `round` is never read by `review_record.py`, so any value passes. This hides nothing a reviewer
    said, but the field reads as meaningful and is not.
  - Five of the eleven historical records omit `context` or `reviewer_selected_by` on some reviewer
    and would fail `validate_record` in isolation; they pass today only because they are not the
    current diff.
- Found in round 7 on the certification surface rather than the record file. All were reproduced and
  all belong to a later batch, because they concern `diff_id`, `changed_paths` and `is_trigger`
  rather than parsing. Listed so batch 3 starts from evidence rather than from scratch.
  - `file_digest` reads the working tree, so a staged change can differ from what is digested: the
    index can hold one content while the record certifies another. This is the most serious of the
    group, because a commit writes the index.
  - `git diff --name-only` is called without `-z`, so a path containing a newline is emitted quoted,
    fails `is_trigger`, and the change is reported as having no trigger paths at all.
  - A second record under a subdirectory of `docs/evidence/reviews/` is never read, so a `verdict:
    FAIL` recorded there is invisible while the canonical path passes.
  - `scripts/lib/__pycache__/*.pyc` satisfies the `scripts/lib/` trigger prefix.
  - `subject_paths` may name paths that do not exist and are not triggers, so the certified set can
    be a strict superset of what was measured.
- A `---` line at column zero inside the front matter still terminates it. That case is genuinely
  ambiguous in YAML too, and S5 discloses when reviewers fall outside the region as a result.
- Everything in batches 2 and 3 stays open: the invocation flags, `base == HEAD` producing a vacuous
  diff, the trigger set defined by filename convention, and `contexts_ok` being free to forge.
- `tests/test_review_record.sh` runs in no CI job. Verified: `scripts/test-tier0.sh`,
  `scripts/pack-health.sh`, `tests/test_pack_health.sh` and `.github/workflows/tier0.yml` reference
  it exactly zero times. These new cases are enforced locally only. Wiring the suite into CI is
  deliberately not bundled here.

## 9. Plan loop log

Eight rounds, three independent reviews each, distinct lenses and contexts, every round using a
different reviewer. Verdicts and process narrative have been removed; what remains is the record of
what was found and what changed, which is the part that has to survive.

Every finding was reproduced by the author against source before being folded in. Findings whose
subject is this document rather than the code are the author's own errors, kept deliberately: they
are the same class of defect the design exists to prevent, and deleting them would be the tidying
this package forbids.

| Round | # | Finding | Verification | Response |
|---|---|---|---|---|
| 1 | 1 | adversarial | The proposed `strip()` delimiter still truncates on an indented `---`, and the claim that this matches YAML was false | Reproduced: file shows three reviewers, the rule sees two. Fixed in §4.2 by forbidding leading whitespace |
| 1 | 2 | adversarial, scope | The reviewer-count cross-check cannot detect any demonstrated defect and risks false failures | Confirmed structurally equal by construction. Cut; replaced by S5 disclosure |
| 1 | 3 | adversarial | Duplicate keys overwrite a failure | Reproduced for both `verdict` and `blocking`. Now §4.4 after the round-3 restructure |
| 1 | 4 | adversarial | A `blocking` key at three-space indent is silently ignored | Reproduced. Subsumed by the whitelist in §4.3 after the round-3 restructure |
| 1 | 5 | correctness | §2 and §4.1 disagreed on the `FAIL` message, which would break the assertion at `tests/test_review_record.sh:870` and falsify "no existing test changes" | Confirmed the assertion at `tests/test_review_record.sh:870`. §4.1 now pins the wording |
| 1 | 6 | correctness | §1.2 overclaimed: with the canonical field order the truncation fails closed on `missing conclusion` | Reproduced both orders. §1.2 rewritten as a correction |
| 1 | 7 | correctness, scope | The delimiter change also alters opener behaviour for `---x` | Confirmed against `scripts/lib/review_record.py:243`. Disclosed in §4.2 |
| 1 | 8 | scope | S3's error string and token path were undefined, so implementers would split parse versus schema differently | New §4.5 pins both |
| 1 | 9 | scope | Test 4 of the round-1 list could be satisfied by an over-strict wrong implementation | §5 now requires the specific error text in every case |
| 1 | 10 | scope | `references/review-budget.md` is not the SSOT for these fields and did not belong in the file list | Confirmed against both references. Removed in §4.7 |
| 2 | 11 | `Verdict: FAIL` beside `verdict: PASS` — a case-variant key is stored separately and the exact-string duplicate rule misses it | Reproduced: reviewer keys become `['Verdict', …, 'verdict']` and the gate reads `PASS` | §1.3b; closed by the case-sensitive whitelist in §4.3 |
| 2 | 12 | A list item carrying a colon, written before a reviewer's `blocking:` key, is exempt from the indentation rule and collected by nothing | Reproduced | §1.4b; closed by scoping list items to a `blocking` context in §4.3 |
| 2 | 13 | `splitlines()` fabricates a `---` line from a form feed, truncating the region even though no such line exists | Reproduced: `'\x0c---'.splitlines()` is `['', '---']` while `.split('\n')` is `['\x0c---']` | §1.4c; closed by pinning the split and rejecting control characters in §4.4b |
| 2 | 14 | `reviewers_outside_front_matter` can read zero while a reader sees a reviewer outside, and can be inflated by body prose | Reproduced | Predicate loosened and pinned in §4.5; limits stated in §8 rather than papered over |
| 3 | 15 | Recognising a line is not enough when its value is discarded: `reviewers:` with an inline flow value hides a whole `verdict: FAIL` reviewer | Reproduced — a reader sees reviewer Z failing, the gate reports only the block-style reviewers | §4.3.1 |
| 3 | 16 | Shape precedence undefined when a line matches both shape 4 and shape 5 | Confirmed by inspection of the shape table | §4.3.2 |
| 3 | 17 | The "most recent key / field" contexts had no stated maintenance or reset rules | Confirmed | §4.3.2 |
| 3 | 18 | Whether scanning continues past an unrecognised line was unstated, and case 6 silently depends on it | Confirmed | §4.3.2, plus new test case 21 |
| 3 | 19 | Cases 3 and 5 omitted the `reason=` assertion the section preamble requires | Confirmed | Both corrected |
| 3 | 20 | S3's goal wording claimed every shape has a key, which shapes 1, 2, 4 and 7 do not | Confirmed | Reworded |
| 3 | 21 | The round-1 log referenced section numbers the round-3 restructure moved | Confirmed | Corrected |
| 4 | 22 | §4.3.1 closed container keys but not the reviewer entry line: shape 5 swallows everything after the first colon into `id`, hiding a whole failing reviewer | Reproduced — `id` parses as the entire `Z, verdict: FAIL, …` string and the gate reads `PASS, PASS` | `id` must be a simple token, §4.3.1; new case 23 |
| 4 | 23 | §10's measurement was wrong for one row: `U+2028` does not merely get rejected, it starts a **new YAML document**, so a validator reading the first document loses everything after it | Reproduced — one file parsed into three documents, the `verdict: FAIL` reviewer landing in the second | §10 row corrected; the claim that a YAML library removes the line-splitting family withdrawn; new case 24 |
| 4 | 24 | §6 restated a case count that had drifted out of step with §5 | Confirmed | Corrected at the time by writing a new number, which drifted again by round 6; every count was finally deleted in round 6 (finding 36) |
| 4 | 25 | Status line still said round 3 | Confirmed | Corrected |
| 5 | 26 | `frozen: False`, `frozen: no` and `frozen: yes` are stored as truthy strings and satisfy the frozen requirement | Reproduced; corpus is uniformly `frozen: true` so the fix is migration-free | New §4.3.3 and cases 25, 26 |
| 5 | 27 | §7 claimed the parser ignores nothing inside the region, contradicting §8's own admission about comment lines | Confirmed by reading both sections | §7 narrowed to the accurate claim |
| 5 | 28 | §8's justification for leaving free-text scalars unconstrained was the same fact that was true of the `id` case, which was closed anyway | Confirmed | §8 rewritten with the real reason, which is cost, not severity |
| 5 | 29 | The corpus uses **ten** top-level keys, not nine — the author's measurement script excluded `reviewers` and the filtered set was reported as the total | Reproduced | Corrected in two places, with the cause recorded |
| 5 | 30 | `review-budget.md` disclosure idiom is at `:54-55`, not `:53-56` | Confirmed | Corrected |
| 5 | 31 | List-item payload offsets were unpinned; the dry run sliced six characters instead of eight and was caught only by an existing test | Confirmed | Pinned in §4.3.2 |
| 5 | 32 | Case 24's byte layout was ambiguous where case 12's was explicit | Confirmed | Pinned |
| 5 | 33 | §2's S3 goal had not been updated with the `id` token rule | Confirmed | Corrected |
| 6 | 34 | §4.3.3 claimed `round` is "already validated where it is used". `review_record.py` never reads `round` at all | Reproduced by search | Claim withdrawn; the real scope reason stated; `round` recorded in §8 |
| 6 | 35 | `frozen: 1` also passes, via digit coercion rather than string truthiness — §1.4d listed only word-like values | Reproduced, including `frozen: 01` | §1.4d extended and case 28 added. The round-6 text also claimed case 27 covered this; case 27 is `frozen: yes`, which belongs to finding 26. Corrected in round 7, which also found `True` and `TRUE` pass and added case 29 |
| 6 | 36 | The stated defect total double-counted §1.4d | Recount confirmed | Totals deleted. The round-6 log said *all* counts were removed, which finding 44 disproved |
| 6 | 37 | §6 still stated a case count, which had drifted again after cases 25 and 26 were added | Confirmed | Replaced with a pointer to §5 |
| 6 | 38 | §4.5's error-surfacing list omitted S6 | Confirmed | Added |
| 6 | 39 | Case 5's layout would not reproduce today's false green under the canonical field order | Confirmed | Layout pinned in the case |
| 6 | 40 | §4.3.3 said the boolean rule "matches YAML"; YAML 1.1 also accepts `True`, `yes`, `no` | Confirmed against PyYAML | Reworded as deliberately stricter |
| 6 | 41 | The round-2 log presented a citation correction that round 5 later showed was itself wrong | Confirmed | Log now records both, rather than tidying the error away |
| 6 | 42 | `diversity_reason` set to a zero-width space satisfies the waived requirement | Reproduced | Recorded in §8, out of scope |
| 7 | 43 | The round-6 pattern paragraph claimed zero false-greens in rounds 5 and 6. The `frozen` findings in those rounds *are* false-greens; the true statement is about the parser only | Confirmed by re-reading the log against its own findings | Paragraph rewritten above with the qualifier written down |
| 7 | 44 | The round-6 log claimed all hardcoded counts were removed; many remain | Reproduced by search | Corrected above |
| 7 | 45 | `frozen: True` and `frozen: TRUE` also pass, and `frozen: 01` was named only in the log | Reproduced across the full matrix | §1.4d completed; case 29 added |
| 7 | 46 | No case distinguishes §4.3.3's case-sensitive rule from a `.lower()` implementation, so a wrong implementation passes every `frozen` case | Confirmed by inspection of cases 25-28 | Case 29 exists for exactly this |
| 7 | 47 | Finding 35's response misattributed case 27 | Confirmed | Corrected in the row above |
| 8 | 48 | §1.4d claimed the full measured matrix was in cases 25-29. Test cases are not a measurement, and they omit `TRUE` and `01` | Confirmed | §1.4d now carries the measured table itself and states it is the set tested, not a universal claim |
| 8 | 49 | §1.4d claimed only `frozen: 0` fails. Also failing: `false`, `00`, empty. Also passing, unlisted: `on`, `off`, `t`, `f`, `null`, `2`, `-1` | Reproduced across the full value set | Same table; **no summarising sentence is offered any more**, because every attempt to write one has been wrong |
| 8 | 50 | The finding-47 row had an orphaned fragment of a deleted paragraph pasted into it | Confirmed | Row repaired |
| 8 | 51 | Quote stripping was unpinned, so `frozen: "true"` would divide two compliant implementations | Reproduced | Pinned in §4.3.3 |
| 8 | 52 | `blocking`'s inline and scalar values were unpinned, and an implementer extending §4.3.1 to it would silently drop findings | Reproduced against a cold implementation | Pinned in §4.3.2 |
| 8 | 53 | Case 29's stated reason was wrong: the naive `.lower()` mistake is already caught by case 25 | Confirmed | Reason corrected; the case is kept for the narrower mistake it does catch |
| 8 | 54 | Status line lagged again | Confirmed | Corrected |

Two patterns are worth stating, and only these two:

- New ways to hide a failure **in the parser** were found in rounds 1 through 4 and in none of
  rounds 5 through 8. The later defects (`frozen`) were in validation code no earlier round probed.
- Most findings after round 4 were unsupported claims in this document, all the author's, and
  several were introduced by corrections to earlier unsupported claims. The response was to stop
  writing summarising sentences about measurements and present measured tables instead.

## 10. Open question the author cannot decide

§3 rules out adopting a YAML library, on the grounds that PyYAML is absent from
`requirements-tier0.txt` and the CI `pack-health` job installs no Python requirements. After three
adversarial rounds that judgement deserves to be put to the owner rather than assumed.

Every defect in §1 exists because a hand-written parser reads the file differently from how a person
reads it, so the obvious question is whether a real YAML parser removes the category. **It does not.
This was measured, not assumed**, against PyYAML 6.0.3:

| Defect family | PyYAML behaviour | Still needs our rule? |
|---|---|---|
| §1.2 `---` inside a quoted value | Parsed as part of the value; no truncation | No — the format handles it |
| §1.4c line splitting and control characters | **Partly.** A form feed raises `ReaderError`, but `U+2028` is treated as a line break and starts a **new YAML document**, so a validator reading only the first document loses every reviewer after it — measured, three documents parsed from one file | **Yes** |
| §4.3.1 inline flow value on `reviewers:` | Parsed properly; the hidden reviewer becomes visible to the validator | No |
| §1.3 duplicate keys | **Silently keeps the last value and raises nothing** | **Yes, unchanged** |
| §1.3b case-variant keys | `Verdict` and `verdict` are two distinct keys; the validator still reads `PASS` | **Yes, unchanged** |
| §1.1 verdict vocabulary | Not a parsing question at all | Yes, unchanged |

So the whitelist in §4.3 is not a substitute for a YAML library that we skipped for dependency
reasons. The key whitelist and the duplicate-key rule are required **either way**; a YAML library
would only replace the delimiter and flow-value halves, which §4.2 and §4.3.1 already cover. It would
**not** remove the need for §4.4b, because `U+2028` moves content into a second YAML document rather
than rejecting it.

That changes the recommendation and the reason for it. Ship the whitelist because it is necessary in
every future, not merely because it is cheaper. Adopting PyYAML later would simplify the parsing
half and remove some hand-written code, which is a reasonable cleanup with a much smaller payoff
than "this class of finding stops recurring" — a claim an earlier draft of this section made and
which the measurement above refutes.
