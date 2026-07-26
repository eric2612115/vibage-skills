# Looping review (Plan loop + Impl loop)

Multi-host. **Qualified path = a formatted review record**, not “must open Cursor Task × 3”.

Records may come from another chat, another host, another person, or another model.

Budget SSOT: `references/review-budget.md` (blast class → N; diversity axis = reviewer `context`).

## When it applies

- Authoring or revising an implementation **plan** that will drive guarded work
- Changing guarded paths (see `scripts/verify-review-record.sh` trigger list +
  `references/review-budget.md`):
  `scripts/verify-*`, entire `scripts/lib/`, `adapters/**`, entire `skills/**`,
  entire `tests/` (incl. fixtures — churn requires a record),
  `references/hard-stops.md`, `references/looping-review.md`, `references/routing-scope.md`,
  `references/review-budget.md`,
  `scripts/assert_gate.sh`, `scripts/write_confirm.sh`, `scripts/coverage-box.sh`,
  `scripts/test-tier0.sh`, `scripts/pack-health.sh`

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

## Review record

Path: `docs/evidence/reviews/<diff_id>.md`

`diff_id` = SHA-256 of sorted trigger paths + content digests of those files **excluding** `docs/evidence/reviews/**` (so writing the record cannot invalidate its own id).

Required fields (YAML front matter):

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

Pass predicate (mechanical) — script-derived; see `references/review-budget.md`:

- **Impl records (`loop: impl`):** `reviewers` length ≥ blast-class N (from trigger paths); ≥2 distinct non-empty reviewer `context` values (all classes).
- **Plan records (`loop: plan`):** effective N = `max(3, blast_N)` so Plan-loop process ≥3 is not silently lowered; same context axis.
- each reviewer has `model` and `reviewer_selected_by: owner|implementer|host_default` (per-reviewer required)
- across reviewers: ≥2 distinct non-empty `context` values (`contexts_ok` is set-level — a reviewer may omit `context` if others already supply two distinct values)
- no `verdict: FAIL`; every `blocking` list empty; `frozen: true`
- trigger paths ⊆ `subject_paths`
- `diversity: ok` means the context axis is satisfied — **not** “model families were diversified”
- `diversity: waived` requires non-empty `diversity_reason`; does **not** lower N; does **not** skip the context requirement
- Model family / distinct model strings are **not** gated (disclosure only)
- Top-level `min_reviewers` must be omitted; optional `blast_class` / `review_budget_n` must match script if present

**Honesty:** `model`, `context`, and `reviewer_selected_by` are self-declared and unverifiable. Context is the gated axis for **incentive** (good-faith agents open separate sessions) — mechanically forging `context: a`/`b` is still zero-cost; see `references/review-budget.md` G2. Do not key budget on implementer model tier. Do not rotate reviewer models to satisfy diversity — ask owner for roster once when multi-review is first needed. `REVIEW_RECORD_OK` ≠ high-quality review.

## Tokens

- No trigger path changes → `REVIEW_RECORD_SKIP` (exit 0). **Never** print `REVIEW_RECORD_OK` on a clean/non-trigger tree. SKIP ≠ reviewed.
- Insufficient git history → `REVIEW_RECORD_FAIL reason=no_git_base` (exit ≠ 0) — must not pass pack-health.
- When triggers exist: stdout includes `blast_class=` and `review_budget_n=` (and `review_budget_n_effective=` for `loop: plan`).
- After record parse: `reviewer_selected_by: owner=N implementer=N host_default=N`; all-`implementer` adds a highest-risk honesty line (disclosure only — does not FAIL). Writing `owner` silences that line; nothing verifies it (reader prompt, not proof).
- Qualified record → `REVIEW_RECORD_OK`
- **Forbidden:** treat exit 0 as `REVIEW_RECORD_OK` (same class of bug as freshness).

∉ Tier-0. Review-record via pack-health + `tests/test_review_record.sh`.  
Plan-loop hygiene (todo-line phrase lint on `docs/superpowers/plans/**`) via **status-lints** + `tests/test_plan_loop_hygiene.sh` — not pack-health.

## Plan-loop hygiene (mechanical, word-level)

`scripts/verify-plan-loop-hygiene.sh` fails if **todo-ish lines** in `docs/superpowers/plans/**/*.md` contain Plan-loop-as-Implement phrases (`plan-loop-converge`, `run 3 plan reviews`, …). Todo-ish = checkbox rows, numbered steps (`1.` / `1)`), `*`/`+` bullets, and markdown table rows (`|…|`). Narrative “Plan loop already frozen…” is OK. Does **not** scan `~/.cursor/plans`. Rewrite still possible (word-level only). Token: `PLAN_LOOP_HYGIENE_OK`.
