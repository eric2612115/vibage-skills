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

**V1 N is identical across classes (G3):** every class has Impl min N=2. Classification
is for stdout disclosure (`blast_class=`) and future budget tuning — **not** a stricter
constraint today. Plan records still use `max(3, blast_N)` (so the Plan floor is 3, not
class differentiation).

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
- `implementer`, per-reviewer `model`, and per-reviewer `context` are **self-declared and unverifiable** (A6).

### Why context (A1) despite weaker mechanical forge cost (G2)

| Axis | Mechanical forge cost | Incentive under a competent agent |
|------|----------------------|-----------------------------------|
| `model` (old gate) | Must call another model (API cost) — **or** lie in the string (also cheap if unverified) | Induced slug rotation to satisfy the gate (observed) |
| `context` (current gate) | Typing two different strings — **zero cost**; script cannot tell `a`/`b` from real sessions | Induces opening separate sessions when agents act in good faith (observed) |

A1 fixed **incentive direction** for good-faith agents; it did **not** raise the
mechanical floor against careless/malicious forgery. Do **not** add string-length or
regex cosmetics on `context`. Host-injected unforgeable session ids are out of V1 scope.
Stdout discloses `reviewer_selected_by` counts (G1) — same idiom as proven-lock: do not
block, make the risk configuration visible (all-`implementer` prints an explicit honesty line).

`reviewer_selected_by: owner` silences the highest-risk line. Nothing verifies it. The line
is a prompt for the reader, not a proof. (Same class of self-declaration as G2 context
forge cost.)

## Tokens

- `blast_class=<gate|narrative|tests>`
- `review_budget_n=<int>` (Impl floor; Plan effective N may be higher — also print `review_budget_n_effective=` when `loop: plan`)
- `reviewer_selected_by: owner=N implementer=N host_default=N` (after record parse; G1)
- `review_record_mode=` / `review_record_pkg=` / `review_record_toplevel=` / `review_record_git_dir=` on every token-emitting path (`none` when base resolution failed or scope mismatch on the default path; `fixture` / `base_override` for flagged library runs).
- `REVIEW_RECORD_OK` only after schema + budget pass under default resolution.
- Flagged library runs (`--paths-file=` / `--base=`) emit `REVIEW_RECORD_FIXTURE_PASS` / `_SKIP` / `_FAIL` only — not a production acceptance path. `blast_class` on a fixture run reflects the supplied path list, not the working tree.

**Conclusion lint:** `conclusion` must be non-empty and must **not** contain the
overclaim words `verified` / `proven` / `confirmed` as positive claims (word match;
`unverified` and `not verified` are allowed). Same class of bug as writing "verified"
into a record while SSOT says those fields are unverifiable.

**V1 known gap:** homoglyph / fullwidth spellings of those words are not normalized
(script is ASCII word-match only). Do not treat the lint as unicode-proof.

`REVIEW_RECORD_OK` ≠ review quality. ∉ Tier-0.
