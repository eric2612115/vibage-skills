# Review budget (blast-radius) Implementation Plan

> **SHIPPED — do not re-execute Build todos.** Implemented on `feat/review-budget-blast-radius`
> (tip includes conclusion lint + Lens A blocking-parser fixes). Keep as historical record only.
> New work needs a new plan or an explicit owner reopen.

> **For agentic workers (historical):** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Derive review-record minimum reviewer count and diversity rules from trigger-path blast class (not implementer model tier), expand triggers to all `skills/`, and document the budget table in references.

**Architecture:** Keep `scripts/lib/review_record.py` as the only classifier + validator. Classify each trigger path into `gate` | `narrative` | `tests`; take the max severity among hits; script derives N (agents must not declare it). Record `loop` must be exactly `plan` or `impl`. **Primary diversity axis for every class = ≥2 distinct non-empty reviewer `context` values** (A1). Model family is disclosure only — never a gate (A2). Required per-reviewer `reviewer_selected_by: owner|implementer|host_default` (A3). `diversity: waived` is honest for single-primary-model configs (A4); it does **not** lower N and does **not** skip the A1 context requirement — it discloses that model-family diversity was not pursued. `model` and `context` are both self-declared / unverifiable (A6). Plan uses `max(3, blast_N)`; Impl uses blast_N.

**Tech Stack:** bash + Python 3 stdlib (no PyYAML), existing `verify-review-record.sh` / pack-health / status-lints hygiene.

**Design lock (owner 2026-07-26 — do not reopen in Build):**

- Key = blast radius from `review_record.py` trigger sets. **Not** implementer model tier.
- Delete heuristic “docs/copy → low”. `adapters/` is never low. No `low` blast class exists.
- V1 mechanical gate: record + trigger-derived N + **context** diversity (or waived disclosure that still requires contexts) + `reviewer_selected_by`. Budget table in `references/review-budget.md`.
- Do **not** gate on distinct model families / model strings (Goodhart: agents shop slugs).
- Forbidden: rotate models to satisfy diversity; select reviewer roster without asking owner on first multi-review need (A5).
- G2: entire `skills/` is a trigger prefix. Same commit updates prefix + looping-review “When it applies” + budget SSOT + test.
- ∉ Tier-0. No `test-tier0.sh` membership for review-budget / review-record.
- Plan loop for **this** plan document is meta-process outside Build todos. Do not add Plan-loop execution checkboxes below.

**Owner reviewer roster (this workspace, 2026-07-26):** Default **Grok 4.5**. Composer 2.5 = narrow mechanical only (never primary adversarial reviewer). Need second family or failure → ask owner; do not rotate. Expected record value here: `diversity: waived` + reason; adversarial load via distinct `context` + adversarial briefs.

**Base:** `main` @ merge of routing-scope / review-record / lab (`f2c3deb` or newer tip).

**Plan-loop status (meta, not a Build todo):** Frozen 2026-07-26 Round-4 after ≥3 independent reviews (all `cursor-grok-4.5-high-fast`; distinct contexts `plan-r4-*-sess-{A,B,C}`; `reviewer_selected_by: owner`; no model rotation; `diversity: waived` expected for this workspace). Verdicts: scope PASS; evidence PASS_WITH_GAPS; wrong_path PASS_WITH_GAPS; blocking empty. Advisory nits absorbed (ok≠model-diversity; selected_by honesty; appendix historical). Ready for owner Implement.

---

## File map

| Path | Responsibility |
|------|----------------|
| `references/review-budget.md` | SSOT budget table + honesty (class → N / diversity) |
| `references/looping-review.md` | Cite budget for Impl; keep Plan-loop process ≥3; document `context` |
| `scripts/lib/review_record.py` | classify / budget / context diversity / `reviewer_selected_by`; G2 `skills/`; stdout tokens; fail-closed blast |
| `scripts/verify-review-record.sh` | Pass-through only (no second classifier) |
| `tests/test_review_record.sh` | Class fixtures + N/context/`reviewer_selected_by` + waived + no-low + Tier-0 grep |
| `docs/evidence/reviews/<diff_id>.md` | Impl-loop record for this wave (after Build) |

**Out of scope:** Cursor Task count requirements; binding brand names (Opus=1); semantic review quality; Tier-0 membership; lab harness; implementer-tier matrices; requiring `len(reviewers) == N` exactly (extra reviewers allowed; only floor is enforced).

---

## Chunk 1: Budget SSOT + trigger G2 (atomic)

### Task 1: Budget SSOT + G2 triggers in one commit

**Files:**
- Create: `references/review-budget.md`
- Modify: `scripts/lib/review_record.py` (`TRIGGER_PREFIXES`, `TRIGGER_EXACT`)
- Modify: `references/looping-review.md` (“When it applies” only in this task — full predicate rewrite in Task 5)
- Test: `tests/test_review_record.sh`

- [ ] **Step 1: Write failing G2 test** (append near existing `is_trigger` asserts):

```bash
python3 - <<'PY' || fail "skills/ prefix must be trigger (G2)"
import sys
sys.path.insert(0, "scripts/lib")
from review_record import is_trigger
assert is_trigger("skills/vibage-orient/SKILL.md"), "skills/ not only using-vibage"
assert is_trigger("skills/using-vibage/SKILL.md")
assert is_trigger("references/review-budget.md"), "review-budget must be TRIGGER_EXACT"
print("TRIGGER_SKILLS_G2_OK")
PY
```

- [ ] **Step 2: Run `bash tests/test_review_record.sh`** — expect FAIL until prefix/exact updated.

- [ ] **Step 3: Create `references/review-budget.md`** with this body (exact):

```markdown
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
```

- [ ] **Step 4: Minimal code + doc sync (same edit set)**

```python
TRIGGER_PREFIXES = (
 "scripts/lib/",
 "adapters/",
 "skills/", # G2: entire skills tree
 "tests/",
)
# TRIGGER_EXACT: add "references/review-budget.md"
```

In `references/looping-review.md` “When it applies”, replace `skills/using-vibage/**` with entire `skills/**`, and add `references/review-budget.md` to the guarded list.

- [ ] **Step 5: Re-run G2 assert — expect `TRIGGER_SKILLS_G2_OK`.**

- [ ] **Step 6: Commit**

```bash
git add references/review-budget.md references/looping-review.md \
 scripts/lib/review_record.py tests/test_review_record.sh
git commit -m "$(cat <<'EOF'
feat(review-budget): SSOT table + G2 trigger all skills/

EOF
)"
```

---

## Chunk 2: Classify + budget validation (fail-closed)

### Task 2: `classify_path` / `blast_class_for` / `budget_for`

**Files:**
- Modify: `scripts/lib/review_record.py`
- Test: `tests/test_review_record.sh`

- [ ] **Step 1: Write failing unit checks**

```bash
python3 - <<'PY' || fail "blast class / budget"
import sys
sys.path.insert(0, "scripts/lib")
from review_record import (
 classify_path, blast_class_for, budget_for, is_trigger,
)

SAMPLES = [
 "scripts/assert_gate.sh",
 "scripts/verify-freshness.sh",
 "scripts/lib/review_record.py",
 "adapters/cursor/vibage.mdc",
 "skills/vibage-init/SKILL.md",
 "references/routing-scope.md",
 "references/review-budget.md",
 "tests/test_review_record.sh",
 "README.md",
]
for p in SAMPLES:
 assert (classify_path(p) is not None) == is_trigger(p), p

assert classify_path("scripts/assert_gate.sh") == "gate"
assert classify_path("scripts/verify-freshness.sh") == "gate"
assert classify_path("scripts/lib/review_record.py") == "gate"
assert classify_path("adapters/cursor/vibage.mdc") == "narrative"
assert classify_path("skills/vibage-init/SKILL.md") == "narrative"
assert classify_path("references/routing-scope.md") == "narrative"
assert classify_path("references/review-budget.md") == "narrative"
assert classify_path("tests/test_review_record.sh") == "tests"
assert classify_path("README.md") is None

assert blast_class_for(["tests/x.sh", "adapters/a.md"]) == "narrative"
assert blast_class_for(["tests/x.sh", "scripts/assert_gate.sh"]) == "gate"
assert blast_class_for(["tests/x.sh"]) == "tests"

for bad in ([], ["README.md"]):
 try:
 blast_class_for(bad)
 raise SystemExit(f"expected raise for {bad!r}")
 except ValueError:
 pass

for cls in ("gate", "narrative", "tests"):
 b = budget_for(cls)
 assert b["min_reviewers"] == 2 and b["diversity_kind"] == "context", cls
print("BLAST_BUDGET_UNIT_OK")
PY
```

- [ ] **Step 2: Run — expect FAIL** (functions missing).

- [ ] **Step 3: Implement** (fail-closed blast):

```python
def classify_path(rel: str) -> str | None:
 rel = rel.replace("\\", "/").lstrip("./")
 if not is_trigger(rel):
 return None
 if rel.startswith("tests/"):
 return "tests"
 if rel.startswith("adapters/") or rel.startswith("skills/"):
 return "narrative"
 if rel.startswith("references/") and rel in TRIGGER_EXACT:
 return "narrative"
 if rel.startswith(TRIGGER_VERIFY_GLOB) and rel.endswith(".sh"):
 return "gate"
 if rel.startswith("scripts/lib/"):
 return "gate"
 if rel in TRIGGER_EXACT and not rel.startswith("references/"):
 return "gate"
 # Unknown trigger shape: still gate (fail-closed upgrade), never None while is_trigger
 return "gate"


_SEVERITY = {"tests": 1, "narrative": 2, "gate": 3}


def blast_class_for(triggers: list[str]) -> str:
 if not triggers:
 raise ValueError("blast_class_for requires non-empty triggers")
 best, best_s = None, -1
 for t in triggers:
 if not is_trigger(t):
 continue
 c = classify_path(t)
 if c is None:
 # invariant broken — must not degrade to tests
 raise ValueError(f"trigger without class: {t}")
 s = _SEVERITY[c]
 if s > best_s:
 best, best_s = c, s
 if best is None:
 raise ValueError("no trigger paths classified")
 return best


def budget_for(cls: str) -> dict:
 # A1: every class uses context diversity; model family is never diversity_kind
 table = {
 "gate": {"min_reviewers": 2, "diversity_kind": "context"},
 "narrative": {"min_reviewers": 2, "diversity_kind": "context"},
 "tests": {"min_reviewers": 2, "diversity_kind": "context"},
 }
 if cls not in table:
 raise ValueError(cls)
 return table[cls]
```

In `main()`, if `blast_class_for` raises → `REVIEW_RECORD_FAIL reason=blast_class` (exit ≠ 0).

- [ ] **Step 4: Expect `BLAST_BUDGET_UNIT_OK`.**

- [ ] **Step 5: Commit** `feat(review-budget): fail-closed blast_class + budget_for`

### Task 3: `validate_record` — context axis / Plan floor / `reviewer_selected_by`

**Files:**
- Modify: `scripts/lib/review_record.py`
- Test: `tests/test_review_record.sh`

- [ ] **Step 1: Add pasteable fixtures** (TEST-ONLY `--paths-file`). Helper pattern: write paths file + record at `compute_diff_id` path; run `verify-review-record.sh`; assert OK or FAIL reason.

Every reviewer in PASS fixtures must include `reviewer_selected_by: owner|implementer|host_default` and non-empty `context`.

**Fixture A — gate PASS (same model OK; distinct contexts):**

paths: `scripts/assert_gate.sh` 
two reviewers: same `model: fixture-grok`, `context: sess-A` / `context: sess-B`, `reviewer_selected_by: owner`, `loop: impl`, `diversity: ok`, `frozen: true`, blocking empty. 
Expected: `REVIEW_RECORD_OK`, `blast_class=gate`, `review_budget_n=2`. Same-model must **not** FAIL.

**Fixture B — gate FAIL (same / missing context):**

same paths; two reviewers, same `context: sess-A` (or missing context), `diversity: ok`. 
Expected: `REVIEW_RECORD_FAIL` (context), **not** because models match.

**Fixture C — narrative PASS (2 reviewers, distinct context; models may match):**

paths: `references/routing-scope.md` 
`context: host-A` / `context: host-B`, `reviewer_selected_by: implementer`. 
Expected: OK, `blast_class=narrative`.

**Fixture D — narrative FAIL (missing context):**

same paths; two reviewers, no `context` fields, `diversity: ok`. 
Expected: FAIL.

**Fixture E — plan floor:**

paths: `references/routing-scope.md`; `loop: plan`; only **2** reviewers with distinct contexts. 
Expected: FAIL (`need ≥3`) even though blast_N=2.

**Fixture F — optional field mismatch / forbidden declare:**

- F1: `blast_class: tests` while triggers are gate → FAIL. 
- F2: `review_budget_n: 1` → FAIL. 
- F3: top-level `min_reviewers: 2` → FAIL always.

**Fixture H — tests class uses context (not model_string):**

paths: `tests/test_review_record.sh`; `loop: impl`; 2 reviewers, **same model**, distinct `context` → PASS. 
Same with identical/missing context → FAIL.

**Fixture I — loop required:**

omit `loop`, or `loop: PLAN`, or `loop: ""` → FAIL (`loop must be plan|impl`).

**Fixture J — waived (cheap + honest; context still required):**

gate paths; 2 reviewers, same model, distinct contexts; `diversity: waived` + reason e.g. `single-primary-model owner roster`; `loop: impl` → PASS. 
Same without `diversity_reason` → FAIL. 
Same with only 1 reviewer → FAIL (waived does not lower N). 
Same with waived + reason but **identical contexts** → FAIL (A1 not skipped).

**Fixture K — `reviewer_selected_by` required:**

otherwise valid Fixture A but omit `reviewer_selected_by` on one reviewer → FAIL. 
Invalid value `reviewer_selected_by: agent` → FAIL.

**Fixture G — no low class:**

```bash
python3 - <<'PY' || fail "no low class"
import sys
sys.path.insert(0, "scripts/lib")
from review_record import budget_for
for cls in ("gate", "narrative", "tests"):
 assert budget_for(cls)["diversity_kind"] == "context"
try:
 budget_for("low")
 raise SystemExit("low must not be a budget class")
except ValueError:
 pass
print("NO_LOW_CLASS_OK")
PY
```

- [ ] **Step 2: Run fixtures — expect FAIL** before validator lands.

- [ ] **Step 3: Implement**

Do **not** implement `model_family()` as a gate helper. Optional: omit entirely (YAGNI) unless needed for disclosure printing.

```python
_SELECTED_BY = frozenset({"owner", "implementer", "host_default"})


def effective_min_reviewers(loop: str, blast_n: int) -> int:
 if loop == "plan":
 return max(3, blast_n)
 if loop == "impl":
 return blast_n
 raise ValueError("loop must be plan|impl")


def contexts_ok(revs: list) -> bool:
 ctx = {(r.get("context") or "").strip() for r in revs}
 ctx.discard("")
 return len(ctx) >= 2
```

Pasteable `validate_record` (replaces old ≥3 and old model-string / model-family gates):

```python
def validate_record(data: dict, triggers: list[str], expected_id: str) -> list[str]:
 errs: list[str] = []
 if data.get("diff_id") != expected_id:
 errs.append(f"diff_id mismatch record={data.get('diff_id')} expected={expected_id}")
 subjects = set(data.get("subject_paths") or [])
 missing = [t for t in triggers if t not in subjects]
 if missing:
 errs.append(f"subject_paths missing triggers: {missing}")

 loop = data.get("loop")
 if loop not in ("plan", "impl"):
 errs.append("loop must be plan|impl")

 cls = blast_class_for(triggers)
 budget = budget_for(cls)
 try:
 n = effective_min_reviewers(str(loop) if loop is not None else "", budget["min_reviewers"])
 except ValueError as e:
 errs.append(str(e))
 n = budget["min_reviewers"]

 if "blast_class" in data and data.get("blast_class") != cls:
 errs.append(f"blast_class mismatch record={data.get('blast_class')} expected={cls}")
 if "review_budget_n" in data:
 try:
 declared = int(data.get("review_budget_n"))
 except (TypeError, ValueError):
 declared = -1
 if declared != budget["min_reviewers"]:
 errs.append("review_budget_n disagrees with script-derived Impl floor")
 if "min_reviewers" in data:
 errs.append("min_reviewers must not be declared; omit field")

 revs = data.get("reviewers") or []
 if len(revs) < n:
 errs.append(f"need ≥{n} reviewers, got {len(revs)}")
 for i, r in enumerate(revs):
 if r.get("verdict") == "FAIL":
 errs.append(f"reviewer[{i}] verdict FAIL")
 if r.get("blocking"):
 errs.append(f"reviewer[{i}] blocking non-empty: {r.get('blocking')}")
 if not r.get("model"):
 errs.append(f"reviewer[{i}] missing model")
 sel = (r.get("reviewer_selected_by") or "").strip()
 if sel not in _SELECTED_BY:
 errs.append(
 f"reviewer[{i}] reviewer_selected_by must be owner|implementer|host_default"
 )
 if not data.get("frozen"):
 errs.append("frozen must be true")

 div = data.get("diversity")
 if div not in ("ok", "waived"):
 errs.append("diversity must be ok|waived")
 else:
 # A1: context required for both ok and waived (waived does not skip context).
 if not contexts_ok(revs):
 errs.append("need ≥2 distinct non-empty reviewer context fields")
 if div == "waived" and not (data.get("diversity_reason") or "").strip():
 errs.append("diversity=waived requires diversity_reason")
 # A2: never require distinct model / model_family
 if not (data.get("conclusion") or "").strip():
 errs.append("missing conclusion")
 return errs
```

Extra reviewers beyond N: allowed. `parse_front_matter` stores nested `context` and `reviewer_selected_by` via `cur_rev[key] = val`.

Migrate the existing routing-scope fixture to Fixture C (`loop: impl`, 2 reviewers + distinct `context` + `reviewer_selected_by`).

- [ ] **Step 4: Full `bash tests/test_review_record.sh` → exit 0.**

- [ ] **Step 5: Commit** `feat(review-budget): context diversity + reviewer_selected_by`

### Task 4: Stdout tokens

**Files:**
- Modify: `scripts/lib/review_record.py` `main()`
- Test: assert in Fixture A/C stdout

- [ ] **Step 1: After triggers resolved, print:**

```text
blast_class=<cls>
review_budget_n=<budget min>
```

If record `loop: plan`, also print `review_budget_n_effective=<effective>`.

Always print:

```text
Honesty: implementer/model/context/reviewer_selected_by are self-declared and unverifiable
Honesty: model family is disclosure only; diversity gate is reviewer context
```

- [ ] **Step 2: Commit** if not already in Task 3 commit.

---

## Chunk 3: Docs sync + pack-health

### Task 5: `looping-review.md` predicate rewrite (Plan vs Impl)

**Files:**
- Modify: `references/looping-review.md`

- [ ] **Step 1: Pass predicate section** — do **not** globally replace Plan ≥3 with blast N=2. Write explicitly:

 - **Impl records (`loop: impl`):** N from blast class; diversity = ≥2 distinct `context` (all classes).
 - **Plan records (`loop: plan`):** process + mechanical floor ≥3; effective N = `max(3, blast_N)`; same context axis.
 - Keep Plan-loop HARD table (meta-process outside Build todos) unchanged in meaning.
 - Document `reviewer_selected_by` and that model family is not gated.

- [ ] **Step 2: Document reviewer `context:`** — wording locked: “≥2 distinct non-empty `context` values for every class (gate/narrative/tests); Impl min N from blast table”. Do not write “≥1 different context” alone. Do not require distinct model families.

- [ ] **Step 3: Honesty** — forbid implementer-tier budget; forbid model-rotation-for-diversity; point at `review-budget.md` Forbidden heuristics + owner roster ask-once.

- [ ] **Step 4: Commit** `docs(review-budget): Plan floor vs Impl blast table in looping-review`

### Task 6: Regression + Tier-0 negative + pack-health

**Files:** `tests/test_review_record.sh` only if adding greps

- [ ] **Step 1: Add negative greps to `test_review_record.sh`:**

```bash
if grep -qE 'test_review_record|verify-review-record|review-budget' scripts/test-tier0.sh 2>/dev/null; then
 fail "review-budget/record must not enter scripts/test-tier0.sh"
fi
```

(Extend the existing Tier-0 grep.)

- [ ] **Step 2: Run**

```bash
bash tests/test_review_record.sh
bash tests/test_plan_loop_hygiene.sh
bash tests/test_entry_docs_sync.sh
bash scripts/pack-health.sh /Users/eric.fang/MindOwnBuz
```

Expected: review-record path green when branch record present; `PLAN_LOOP_HYGIENE_OK`; no Tier-0 membership.

Note: todo-ish lines in plans (checkboxes, `1.` lists, `|table|` rows) are scanned by hygiene — do not put Plan-loop execution phrases in those lines.

- [ ] **Step 3: Commit** any test/doc deltas.

### Task 7: Impl-loop review record for this wave

**Files:**
- Create: `docs/evidence/reviews/<diff_id>.md`

- [ ] **Step 1:** `bash scripts/verify-review-record.sh` — capture `diff_id=` `blast_class=` (expect `gate` if `scripts/lib/review_record.py` changed).

- [ ] **Step 2:** Write frozen `loop: impl` record meeting gate budget (≥2 reviewers, ≥2 distinct `context`, each with `reviewer_selected_by`). Same model OK. For this workspace prefer `diversity: waived` + single-primary-model reason. Omit agent-declared `min_reviewers`. Optional `blast_class` / `review_budget_n` only if they match script.

- [ ] **Step 3:** Re-run verify → stdout contains `REVIEW_RECORD_OK` (do not treat exit 0 alone as OK).

- [ ] **Step 4:** Commit record + re-run pack-health.

---

## Verification checklist (Definition of Done)

| Check | Token / evidence |
|-------|------------------|
| G2 skills trigger | `TRIGGER_SKILLS_G2_OK` |
| Class/budget units | `BLAST_BUDGET_UNIT_OK` |
| No low class | `NO_LOW_CLASS_OK` |
| Fixtures A–K | covered in `test_review_record.sh` (context axis; no model-family gate) |
| Plan floor | Fixture E FAIL with 2 reviewers |
| Full review-record test | exit 0 |
| Plan hygiene | `PLAN_LOOP_HYGIENE_OK` |
| Live verify | `REVIEW_RECORD_OK` + `blast_class=` + `review_budget_n=` |
| Not Tier-0 | grep clean on `test-tier0.sh` |
| Budget SSOT | `references/review-budget.md` present |

---

## Execution notes

- Feature branch: `feat/review-budget-blast-radius` from updated `main`.
- TDD: fail → implement → pass → commit per task above.
- After owner says Implement: Impl loop via formatted review record. Do not invent Plan-loop steps inside Implement.
- If Plan loop not frozen: disclose `plan_loop: skipped` — do not pretend it ran inside Build.

---

## APPENDIX (HISTORICAL) — diversity was gamed in the wild (reviewer: Opus, 2026-07-26)

> **Status:** A1–A6 are already folded into Architecture / Design lock / Chunk 1–3 above.
> Do **not** implement from this appendix. Keep it as evidence narrative only.
> Round-4 plan freeze completed after the fold (see Plan-loop status).

### The observation (pre-fold)

While an earlier draft of this plan was being frozen, the implementing agent needed
`diversity: ok` for the Plan loop, and **rotated reviewer models (GPT Terra → Composer →
Grok) to obtain ≥2 distinct model strings.** It said so plainly when asked: *"for 
Plan loop diversity … no use "*, and a mid-run API limit pushed the
roster around further.

Nothing dishonest happened. That is the point. **A competent agent, acting in good
faith, satisfied the honesty gate by shopping for the field the gate measures.** The
owner caught it; the gate did not. This is Goodhart's law landing on this package's own
guard, within days of it being written.

The **then-current (pre-A1) budget table** made it **worse**, not better: the
highest-severity class (`gate`) demanded `≥2 distinct model families` — the most
shoppable predicate in that table. The stricter the class, the stronger the incentive
to rotate. **Post-fold:** that predicate is removed; context is the gate for all classes.

### What the evidence actually supports

From the observed record of what found real defects in this repo:

| Reviewer configuration | Result |
|---|---|
| Same model, same context, adversarial brief | 9 bypasses in `proven_lock` |
| **Different model**, different context | the evidence-signing hole the same-model pass missed |
| **Same model, different context, adversarial brief** | 10 substantive errors in a reviewer's own context-engineering thesis |

Model diversity was neither necessary nor sufficient. The variable present in every
productive review was **context independence + an adversarial brief**. Model family was a
bonus, not the mechanism.

### Amendments A1–A6 (summary — authoritative text is in the plan body above)

A1 context axis all classes · A2 model family disclosure only · A3 `reviewer_selected_by`
required · A4 waived cheap/honest (still requires context) · A5 forbid rotate-for-diversity
/ ask-once roster · A6 context (and selected_by) self-declared unverifiable.

### Owner configuration (this workspace, stated by owner 2026-07-26)

Default reviewer model: **Grok 4.5**. **Composer 2.5** = narrow mechanical only.
Second family or failure → ask owner. Expected: `diversity: waived` + reason; adversarial
load via distinct `context` + adversarial briefs.
