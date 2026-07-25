# Looping review (Plan loop + Impl loop)

Multi-host. **Qualified path = a formatted review record**, not “must open Cursor Task × 3”.

Records may come from another chat, another host, another person, or another model.

## When it applies

- Authoring or revising an implementation **plan** that will drive guarded work
- Changing guarded paths (see `scripts/verify-review-record.sh` trigger list):
  `scripts/verify-*`, entire `scripts/lib/`, `adapters/**`, `skills/using-vibage/**`,
  `references/hard-stops.md`, `references/looping-review.md`, `references/routing-scope.md`

Not every commit message. Not a required git pre-commit hook in V1. Branch relative to merge-base: if any trigger path changed, a record is required for pack-health.

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
    blocking: []
conclusion: "no blocking; frozen"
---
```

Pass predicate (mechanical):

- `reviewers` length ≥ 3
- each has `model` (or human/unknown)
- no `verdict: FAIL`
- every `blocking` list empty
- `frozen: true`
- trigger paths ⊆ `subject_paths`
- if `diversity: ok` → ≥2 distinct `model` strings; if `waived` → non-empty `diversity_reason`

**Honesty:** model strings can be forged; diversity is disclosure + weak check, not proof of adversarial quality. `REVIEW_RECORD_OK` ≠ high-quality review. Implementer-only self-review without waiver is a process violation (disclose `diversity: waived` if unavoidable).

## Tokens

- No trigger path changes → `REVIEW_RECORD_SKIP` (exit 0). **Never** print `REVIEW_RECORD_OK` on a clean/non-trigger tree.
- Qualified record → `REVIEW_RECORD_OK`
- **Forbidden:** treat exit 0 as `REVIEW_RECORD_OK` (same class of bug as freshness).

∉ Tier-0. Wired via pack-health + `tests/test_review_record.sh` only.
