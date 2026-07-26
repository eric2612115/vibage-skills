# Review budget (blast radius)

SSOT for how many reviewers and what diversity `scripts/lib/review_record.py`
requires. Agents must **not** declare N — the script derives it from trigger paths.

## Classes (max severity wins)

| Class | Trigger membership (see `is_trigger` + `classify_path`) | Impl min N | Diversity rule |
|-------|----------------------------------------------------------|------------|----------------|
| `gate` | `scripts/verify-*.sh`; gate EXACT scripts (`assert_gate`, `write_confirm`, `coverage-box`, `test-tier0`, `pack-health`); entire `scripts/lib/` | ≥2 | ≥2 distinct non-empty reviewer **`context`** (all classes; A1) |
| `narrative` | entire `adapters/`; entire `skills/`; `references/hard-stops.md`; `references/looping-review.md`; `references/routing-scope.md`; `references/review-budget.md` | ≥2 | same: ≥2 distinct **`context`** |
| `tests` | entire `tests/` | ≥2 | same: ≥2 distinct **`context`** |

Severity: `gate` > `narrative` > `tests`. Mixed diffs use the highest class.

**Plan records (`loop: plan`):** mechanical floor is `max(3, blast_N)` so Plan-loop process ≥3 is not silently lowered by the Impl blast table.

**No `low` class.** Adapters / skill prose are never “docs/copy → low”.

**Model family is not a gate** (A2). Per-reviewer `model` is recorded for disclosure only.

**`diversity: ok`:** means A1 context axis is satisfied — **not** “model families were diversified”.

**`diversity: waived`:** correct and cheap for single-primary-model configs (A4). Requires non-empty `diversity_reason`. Does **not** lower N. Does **not** skip A1 context requirement. Rotating models purely to avoid waived is a forbidden heuristic.

## Forbidden heuristics

- Keying budget on implementer model tier / brand.
- Treating `adapters/` or skill prose as low-blast copy edits.
- Record fields `review_budget_n` / `min_reviewers` / `blast_class` that disagree with script-derived values (reject on mismatch). Agents may omit these fields; script stdout is authoritative.
- Rotating or switching reviewer models to satisfy `diversity` (A5).
- Selecting reviewer models without owner configuration when multi-review is first needed — ask once, record roster, reuse; do not infer (A5).

## Required / optional fields (honesty)

- Required per reviewer: `reviewer_selected_by: owner|implementer|host_default` (A3). Missing → schema FAIL. The value itself is **self-declared and unverifiable** (visible for review, not proof).
- `implementer`, per-reviewer `model`, and per-reviewer `context` are **self-declared and unverifiable** (A6). Prefer `context` as the gated axis because faking it requires inventing a session; satisfying model distinctness only required flipping a menu item.

## Tokens

- `blast_class=<gate|narrative|tests>`
- `review_budget_n=<int>` (Impl floor; Plan effective N may be higher — also print `review_budget_n_effective=` when `loop: plan`)
- `REVIEW_RECORD_OK` only after schema + budget pass.

`REVIEW_RECORD_OK` ≠ review quality. ∉ Tier-0.
