# Looping review (Plan loop + Impl loop)

Multi-host. **Qualified path = a formatted review record**, not “must open Cursor Task × 3”.

Records may come from another chat, another host, another person, or another model.

Budget SSOT: `references/review-budget.md` (blast class → N; diversity axis = reviewer `context`).

## When it applies

- Authoring or revising an implementation **plan** that will drive guarded work
- Changing guarded paths (capability allow-list in `scripts/lib/review_record.py`
  + `references/review-budget.md` — not blanket `tests/` / `scripts/lib/`):
  gate entrypoints + helper closure (`review_record.py`, `pack-health.sh`,
  `test-tier0.sh`, `assert_gate.sh`, `write_confirm.sh`, `coverage-box.sh`, plus
  `scan_plan_hash.py` / `coverage_box.py` / `proven_lock.py`);   **CI definition**
  (all `.github/**` except listed metadata — what runs is what green covers);
  **hub-state writers** (write the owner's `docs/vibage/**` or mint
  cell / freshness / evidence values, including thin wrappers that do it through
  `scripts/lib`); **acceptance definers** (all `scripts/verify-*.sh` by prefix, plus named
  checkers — editing one changes what passing *means*); narrative (`adapters/**`,
  `skills/**`, four `references/*` files); frozen `tests/test_*.{sh,py}` enumeration only —
  membership stays a hand-kept list, but every suite a CI job runs must be on it, and
  `tests/test_review_record.sh` fails if one is missing. That suite also holds a total
  partition of tracked `scripts/**`, so an unclassified script fails.
  Details: `references/review-budget.md`

Not every commit message. Not a required git pre-commit hook in V1.

**Base selection:** prefer `merge-base(HEAD, main|master|origin/*)`. If that equals `HEAD` (tip of main / direct-push), use `HEAD~1` and print `review_record_mode=head1`. `REVIEW_RECORD_SKIP` ≠ reviewed. `head1` ≠ SKIP. Multi-commit direct pushes: head1 only covers the tip commit. `no_git_base` → **FAIL** (not SKIP) — CI pack-health needs `fetch-depth: 0`.

## Loops

1. **Plan loop** — **before** owner says Implement / Build: ≥3 independent reviews of the **plan document**. If the plan changes at all (even one sentence), run another round of ≥3. Stop when (a) zero edits vs prior round and (b) no blocking must-fix. Only then may Build start.
2. **Impl loop** — after implementation + smoke/tests: same until freeze (reviews the **code/docs produced**, not a fresh rewrite of the plan).

Lenses may split (e.g. no-delete / evidence / scope) or equivalent adversarial focus — not the same prompt three times.

### Plan loop is outside the plan body (HARD)

Plan loop is a **meta-process** that freezes the plan **before** Build. It must **not** be listed as an implementation todo inside the same plan that agents execute when the owner says “Implement the plan”.

| OK | Forbidden |
|----|-----------|
| Human/overview note: “Plan loop already frozen at <date>” | Todo: `plan-loop-converge` / “run 3 plan reviews” inside Build todos |
| Separate plan-only chat that only edits the plan | Treating Plan loop as step 0 of implementation in the same agent turn as coding |
| Impl todos = deliverables only (scripts, adapters, tests…) | “Absorb plan review must-fixes while implementing” as a substitute for freezing the plan first |

If Plan loop was skipped and Build already started: **stop inventing plan edits mid-flight**. Either (1) reopen a plan-only freeze round and pause Build, or (2) disclose `plan_loop: skipped` / `diversity: waived` with reason — do not pretend Plan loop happened inside Implement.

Always-on / skills point here; do **not** paste this table into Cursor plans as executable todos.

### Finding class — apply vs disclose (HARD)

Reviewers may keep asking. That is good. **What must not happen** is treating every ask as a
must-edit. Endless “what if” without a gate is what turns a 2-round freeze into 5–9 rounds.

**Unpromised surface (plain language):** something this plan/batch never said it would cover.
Example: the plan promised “test flags must not print production tokens.” A review that then
demands redacting directory names inside error text is on an *unpromised surface* — not proof the
door-lock promise failed. Asking about it is fine; **auto-applying it is not.**

Classify each finding before editing the plan or the tree:

| Class | Meaning | Action |
|-------|---------|--------|
| **1 — Plan broken** | The plan’s own promises conflict, or following it yields false-green / false-red | Edit the plan; new Plan round (≥3). Do not paper over in Build. |
| **2 — Impl missed the plan** | Plan is fine; code/docs do not match it | Fix the impl; may trigger Impl round |
| **3 — Fix broke a contract** | This change introduced FAIL→SKIP/OK, wrong exit, or a vacuous test for a claimed control | Fix that regression; may trigger Impl round on the **delta only** |
| **4 — Unpromised / proportional** | Extra ideation: nicer wording, future consumers, attacks outside the threat model, “could be tighter,” cost/shape debates with no false-green/false-red evidence | **Disclose** in freeze notes / residual risk. **Do not edit** the plan or tree for class 4 alone |

**Blocking must-fix** (the freeze predicate above) means class **1–3** only.
Class 4 is never blocking by itself.

**Coordinator rules (parent agent):**

1. **Ask freely; apply narrowly.** Do not skip adversarial review. After review, apply only 1–3.
2. **Two class-4-only rounds → freeze.** If two consecutive rounds produce zero class 1–3 findings,
   freeze and disclose leftovers — even if reviewers still have ideas. Ideas need not converge;
   **edits** must.
3. **No mid-flight edits.** Do not change the plan or tree while reviewers for the current round are
   still running. Apply after the round returns; the next round reviews that delta only.
4. **Impl budget.** Gate-class Impl is N=2 distinct `context` values (`references/review-budget.md`).
   Do not default to three reviewers or rotate models for “diversity theater.” Model family is
   disclosure only.
5. **Measure, don’t vibe.** Prefer “relative to stated baseline / plan claim, does outcome worsen?”
   over “can I invent another input?”

**Honesty:** Reviewers will still invent class-4 findings. That does not mean the plan keeps failing.
It means the search space is open. The freeze condition is empty blocking (1–3), not “no one can
think of anything else.”

## Review record

Path: `docs/evidence/reviews/<diff_id>.md`

`diff_id` = SHA-256 of sorted trigger paths + content digests of those files **excluding** `docs/evidence/reviews/**` (so writing the record cannot invalidate its own id).

Required fields (YAML front matter). The opening and closing delimiters must each be an
**unindented** line equal to `---` (trailing whitespace / CR allowed; leading whitespace is not).

```yaml
---
diff_id: "<hex>"
diff_base: "<git ref used>"
subject_paths:
  - adapters/claude/CLAUDE.vibage.md
loop: plan|impl
round: 1
frozen: true
diversity: ok|waived
diversity_reason: ""   # required if waived
reviewers:
  - id: A
    lens: scope
    verdict: PASS|PASS_WITH_GAPS|FAIL
    model: "<slug>|human|unknown"
    context: "<session-or-host id>"
    reviewer_selected_by: owner|implementer|host_default
    blocking: []
conclusion: "no blocking; frozen"
---
```

`verdict` is **required** on every reviewer and must be exactly one of
`PASS` | `PASS_WITH_GAPS` | `FAIL` (comparison is case-insensitive; other spellings such as
`FAILED` are schema errors). `frozen` must be the literal `true` or `false` (case-sensitive;
`True` / `yes` / `1` are schema errors); the pass predicate still requires `frozen: true`.

Pass predicate (mechanical) — script-derived; see `references/review-budget.md`:

- **Impl records (`loop: impl`):** `reviewers` length ≥ blast-class N (from trigger paths); ≥2 distinct non-empty reviewer `context` values (all classes).
- **Plan records (`loop: plan`):** effective N = `max(3, blast_N)` so Plan-loop process ≥3 is not silently lowered; same context axis.
- each reviewer has `model` and `reviewer_selected_by: owner|implementer|host_default` (per-reviewer required)
- across reviewers: ≥2 distinct non-empty `context` values (`contexts_ok` is set-level — a reviewer may omit `context` if others already supply two distinct values)
- each reviewer has a required `verdict` of `PASS` or `PASS_WITH_GAPS` (not merely “no `verdict: FAIL`”); every `blocking` list empty; `frozen: true`
- trigger paths ⊆ `subject_paths`
- `diversity: ok` means the context axis is satisfied — **not** “model families were diversified”
- `diversity: waived` requires non-empty `diversity_reason`; does **not** lower N; does **not** skip the context requirement
- Model family / distinct model strings are **not** gated (disclosure only)
- Top-level `min_reviewers` must be omitted; optional `blast_class` / `review_budget_n` must match script if present
- `conclusion` non-empty; must not claim `verified` / `proven` / `confirmed` (positive word match; `unverified` / `not verified` OK)

**Honesty:** `model`, `context`, and `reviewer_selected_by` are self-declared and unverifiable. Context is the gated axis for **incentive** (good-faith agents open separate sessions) — mechanically forging `context: a`/`b` is still zero-cost; see `references/review-budget.md` G2. Do not key budget on implementer model tier. Do not rotate reviewer models to satisfy diversity — ask owner for roster once when multi-review is first needed. `REVIEW_RECORD_OK` ≠ high-quality review.

## Tokens

- No trigger path changes → `REVIEW_RECORD_SKIP` (exit 0). **Never** print `REVIEW_RECORD_OK` on a clean/non-trigger tree. SKIP ≠ reviewed.
- Insufficient git history → `REVIEW_RECORD_FAIL reason=no_git_base` (exit ≠ 0) — must not pass pack-health.
- Package root is not the git toplevel → `REVIEW_RECORD_SKIP reason=git_scope_mismatch` (exit 0). Accurate reason for vendored installs; pack-health does not reject this reason.
- When triggers exist: stdout includes `blast_class=` and `review_budget_n=` (and `review_budget_n_effective=` for `loop: plan`).
- After record parse: `reviewer_selected_by: owner=N implementer=N host_default=N`; all-`implementer` adds a highest-risk honesty line (disclosure only — does not FAIL). Writing `owner` silences that line; nothing verifies it (reader prompt, not proof).
- When the file has more loose `-\s*id:` reviewer-entry lines than the front-matter region: `reviewers_outside_front_matter=N` (disclosure only — never FAILs; reader prompt, not a detector).
- Every token-emitting path prints exactly once: `review_record_mode=` (`merge_base`|`head1`|`none`|`fixture`|`base_override`), `review_record_pkg=`, `review_record_toplevel=`, `review_record_git_dir=` (literal `-` when git was not consulted). The last two are diagnostics, not a redirect control.
- Qualified record under default resolution → `REVIEW_RECORD_OK`.
- Direct library runs with `--paths-file=` or `--base=` → fixture namespace only: `REVIEW_RECORD_FIXTURE_PASS` / `_SKIP` / `_FAIL`. A fixture run is not a production acceptance path. The production wrapper rejects those flags (unknown flag, exit 2) and never forwards them.
- Wrapper pre-Python exits (`-h`/`--help`, unknown flag, non-directory, missing library) emit no token and therefore no provenance lines.
- **Forbidden:** treat exit 0 as `REVIEW_RECORD_OK` (same class of bug as freshness).

∉ Tier-0. Review-record via pack-health + `tests/test_review_record.sh`.  
Plan-loop hygiene (todo-line phrase lint on `docs/superpowers/plans/**`) via **status-lints** + `tests/test_plan_loop_hygiene.sh` — not pack-health.

## Plan-loop hygiene (mechanical, word-level)

`scripts/verify-plan-loop-hygiene.sh` fails if **todo-ish lines** in `docs/superpowers/plans/**/*.md` contain Plan-loop-as-Implement phrases (`plan-loop-converge`, `run 3 plan reviews`, …). Todo-ish = checkbox rows, numbered steps (`1.` / `1)`), `*`/`+` bullets, and markdown table rows (`|…|`). Narrative “Plan loop already frozen…” is OK. Does **not** scan `~/.cursor/plans`. Rewrite still possible (word-level only). Token: `PLAN_LOOP_HYGIENE_OK`.
