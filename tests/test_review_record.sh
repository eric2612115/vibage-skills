#!/usr/bin/env bash
# Review-record gate smoke. ∉ Tier-0 / must not enter test-tier0.sh.
# --paths-file is TEST-ONLY (not a production acceptance path).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "FAIL: $*"; exit 1; }

CLEANUP_RECS=()
cleanup() {
  local p
  for p in "${CLEANUP_RECS[@]:-}"; do
    rm -f "$p"
  done
}
trap cleanup EXIT

write_rec() {
  local id="$1"
  local body="$2"
  local path="$ROOT/docs/evidence/reviews/${id}.md"
  printf '%s\n' "$body" >"$path"
  CLEANUP_RECS+=("$path")
}

if grep -qE 'test_review_record|verify-review-record|review-budget' scripts/test-tier0.sh 2>/dev/null; then
  fail "review-budget/record must not enter scripts/test-tier0.sh"
fi

[[ -f scripts/verify-review-record.sh ]] || fail "missing verify-review-record.sh"
[[ -f scripts/lib/review_record.py ]] || fail "missing review_record.py"
[[ -f references/looping-review.md ]] || fail "missing looping-review.md"
[[ -f references/review-budget.md ]] || fail "missing review-budget.md"

FIX="$ROOT/docs/evidence/reviews/_fixture_work"
mkdir -p "$FIX" "$ROOT/docs/evidence/reviews"

python3 - <<'PY' || fail "assert_gate.sh must be_trigger"
import sys
sys.path.insert(0, "scripts/lib")
from review_record import is_trigger
assert is_trigger("scripts/assert_gate.sh"), "assert_gate not trigger"
assert is_trigger("tests/test_assert_gate.sh"), "tests/ not trigger"
assert not is_trigger("docs/evidence/reviews/x.md")
print("TRIGGER_ASSERT_OK")
PY

python3 - <<'PY' || fail "skills/ prefix must be trigger (G2)"
import sys
sys.path.insert(0, "scripts/lib")
from review_record import is_trigger
assert is_trigger("skills/vibage-orient/SKILL.md"), "skills/ not only using-vibage"
assert is_trigger("skills/using-vibage/SKILL.md")
assert is_trigger("references/review-budget.md"), "review-budget must be TRIGGER_EXACT"
print("TRIGGER_SKILLS_G2_OK")
PY

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

diff_id_for() {
  local paths_csv=""
  local p
  for p in "$@"; do
    paths_csv+="$p"$'\n'
  done
  PATHS_CSV="$paths_csv" python3 - <<'PY'
from pathlib import Path
import os, sys
sys.path.insert(0, "scripts/lib")
from review_record import compute_diff_id
paths = [ln for ln in os.environ["PATHS_CSV"].splitlines() if ln.strip()]
print(compute_diff_id(Path(".").resolve(), paths))
PY
}

# --- Fixture A: gate PASS same model, distinct contexts ---
printf '%s\n' 'scripts/assert_gate.sh' >"$FIX/a_paths.txt"
A_ID="$(diff_id_for scripts/assert_gate.sh)"
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fixture A gate same-model distinct contexts\"
---
Fixture A.
"
A_OUT="$(bash scripts/verify-review-record.sh --paths-file="$FIX/a_paths.txt" --base=fixture "$ROOT")"
echo "$A_OUT" | grep -Fq 'REVIEW_RECORD_OK' || fail "Fixture A expected OK"
echo "$A_OUT" | grep -Fq 'blast_class=gate' || fail "Fixture A blast_class"
echo "$A_OUT" | grep -Fq 'review_budget_n=2' || fail "Fixture A review_budget_n"
echo "$A_OUT" | grep -Fq 'reviewer_selected_by: owner=2 implementer=0 host_default=0' \
  || fail "Fixture A must disclose selected_by counts (G1)"

# G1: all-implementer → highest-risk honesty line
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: implementer
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: implementer
    blocking: []
conclusion: \"fixture G1 all implementer\"
---
"
G1_OUT="$(bash scripts/verify-review-record.sh --paths-file="$FIX/a_paths.txt" --base=fixture "$ROOT")"
echo "$G1_OUT" | grep -Fq 'REVIEW_RECORD_OK' || fail "G1 all-implementer still OK"
echo "$G1_OUT" | grep -Fq 'reviewer_selected_by: owner=0 implementer=2 host_default=0' \
  || fail "G1 counts"
echo "$G1_OUT" | grep -Fq 'all reviewers selected by the implementing agent' \
  || fail "G1 highest-risk honesty line"

# --- Fixture B: gate FAIL same context ---
B_ID="$(diff_id_for scripts/assert_gate.sh)"
write_rec "$B_ID" "---
diff_id: \"$B_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fixture B same context\"
---
"
set +e
B_OUT="$(bash scripts/verify-review-record.sh --paths-file="$FIX/a_paths.txt" --base=fixture "$ROOT" 2>&1)"
B_EC=$?
set -e
[[ "$B_EC" -ne 0 ]] || fail "Fixture B must FAIL"
echo "$B_OUT" | grep -Fq 'REVIEW_RECORD_FAIL' || fail "Fixture B FAIL token"

# --- Fixture C: narrative PASS (routing-scope) ---
printf '%s\n' 'references/routing-scope.md' >"$FIX/c_paths.txt"
C_ID="$(diff_id_for references/routing-scope.md)"
write_rec "$C_ID" "---
diff_id: \"$C_ID\"
diff_base: \"fixture\"
subject_paths:
  - references/routing-scope.md
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: host-A
    reviewer_selected_by: implementer
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS_WITH_GAPS
    model: fixture-grok
    context: host-B
    reviewer_selected_by: implementer
    blocking: []
conclusion: \"fixture C narrative\"
---
"
C_OUT="$(bash scripts/verify-review-record.sh --paths-file="$FIX/c_paths.txt" --base=fixture "$ROOT")"
echo "$C_OUT" | grep -Fq 'REVIEW_RECORD_OK' || fail "Fixture C expected OK"
echo "$C_OUT" | grep -Fq 'blast_class=narrative' || fail "Fixture C blast_class"

# --- Fixture D: narrative FAIL missing context ---
write_rec "$C_ID" "---
diff_id: \"$C_ID\"
diff_base: \"fixture\"
subject_paths:
  - references/routing-scope.md
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fixture D no context\"
---
"
set +e
D_EC="$(bash scripts/verify-review-record.sh --paths-file="$FIX/c_paths.txt" --base=fixture "$ROOT" >/dev/null 2>&1; echo $?)"
set -e
[[ "$D_EC" -ne 0 ]] || fail "Fixture D must FAIL"

# --- Fixture E: plan floor ---
write_rec "$C_ID" "---
diff_id: \"$C_ID\"
diff_base: \"fixture\"
subject_paths:
  - references/routing-scope.md
loop: plan
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: host-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: host-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fixture E plan floor\"
---
"
set +e
E_OUT="$(bash scripts/verify-review-record.sh --paths-file="$FIX/c_paths.txt" --base=fixture "$ROOT" 2>&1)"
E_EC=$?
set -e
[[ "$E_EC" -ne 0 ]] || fail "Fixture E must FAIL plan floor"
echo "$E_OUT" | grep -Eiq 'need ≥3|need >=3' || fail "Fixture E must mention ≥3 reviewers"

# --- Fixture F: field mismatch ---
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
blast_class: tests
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fixture F1\"
---
"
set +e
F1_EC="$(bash scripts/verify-review-record.sh --paths-file="$FIX/a_paths.txt" --base=fixture "$ROOT" >/dev/null 2>&1; echo $?)"
set -e
[[ "$F1_EC" -ne 0 ]] || fail "Fixture F1 blast_class mismatch must FAIL"

write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
review_budget_n: 1
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fixture F2\"
---
"
set +e
F2_EC="$(bash scripts/verify-review-record.sh --paths-file="$FIX/a_paths.txt" --base=fixture "$ROOT" >/dev/null 2>&1; echo $?)"
set -e
[[ "$F2_EC" -ne 0 ]] || fail "Fixture F2 review_budget_n mismatch must FAIL"

write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
min_reviewers: 2
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fixture F3\"
---
"
set +e
F3_EC="$(bash scripts/verify-review-record.sh --paths-file="$FIX/a_paths.txt" --base=fixture "$ROOT" >/dev/null 2>&1; echo $?)"
set -e
[[ "$F3_EC" -ne 0 ]] || fail "Fixture F3 min_reviewers declare must FAIL"

# --- Fixture H: tests class context ---
printf '%s\n' 'tests/test_review_record.sh' >"$FIX/h_paths.txt"
H_ID="$(diff_id_for tests/test_review_record.sh)"
write_rec "$H_ID" "---
diff_id: \"$H_ID\"
diff_base: \"fixture\"
subject_paths:
  - tests/test_review_record.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: t-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: t-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fixture H tests same model\"
---
"
H_OUT="$(bash scripts/verify-review-record.sh --paths-file="$FIX/h_paths.txt" --base=fixture "$ROOT")"
echo "$H_OUT" | grep -Fq 'REVIEW_RECORD_OK' || fail "Fixture H expected OK"
echo "$H_OUT" | grep -Fq 'blast_class=tests' || fail "Fixture H blast_class"

write_rec "$H_ID" "---
diff_id: \"$H_ID\"
diff_base: \"fixture\"
subject_paths:
  - tests/test_review_record.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-a
    context: t-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-b
    context: t-A
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fixture H fail same context\"
---
"
set +e
H2_EC="$(bash scripts/verify-review-record.sh --paths-file="$FIX/h_paths.txt" --base=fixture "$ROOT" >/dev/null 2>&1; echo $?)"
set -e
[[ "$H2_EC" -ne 0 ]] || fail "Fixture H same context must FAIL"

# --- Fixture I: loop required ---
write_rec "$C_ID" "---
diff_id: \"$C_ID\"
diff_base: \"fixture\"
subject_paths:
  - references/routing-scope.md
loop: PLAN
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: host-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: host-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fixture I bad loop\"
---
"
set +e
I_EC="$(bash scripts/verify-review-record.sh --paths-file="$FIX/c_paths.txt" --base=fixture "$ROOT" >/dev/null 2>&1; echo $?)"
set -e
[[ "$I_EC" -ne 0 ]] || fail "Fixture I bad loop must FAIL"

# --- Fixture J: waived ---
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: waived
diversity_reason: \"single-primary-model owner roster\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fixture J waived\"
---
"
J_OUT="$(bash scripts/verify-review-record.sh --paths-file="$FIX/a_paths.txt" --base=fixture "$ROOT")"
echo "$J_OUT" | grep -Fq 'REVIEW_RECORD_OK' || fail "Fixture J expected OK"

write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: waived
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fixture J no reason\"
---
"
set +e
J2_EC="$(bash scripts/verify-review-record.sh --paths-file="$FIX/a_paths.txt" --base=fixture "$ROOT" >/dev/null 2>&1; echo $?)"
set -e
[[ "$J2_EC" -ne 0 ]] || fail "Fixture J missing reason must FAIL"

write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: waived
diversity_reason: \"single-primary-model owner roster\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fixture J one reviewer\"
---
"
set +e
J3_EC="$(bash scripts/verify-review-record.sh --paths-file="$FIX/a_paths.txt" --base=fixture "$ROOT" >/dev/null 2>&1; echo $?)"
set -e
[[ "$J3_EC" -ne 0 ]] || fail "Fixture J one reviewer must FAIL"

write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: waived
diversity_reason: \"single-primary-model owner roster\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fixture J waived same context\"
---
"
set +e
J4_EC="$(bash scripts/verify-review-record.sh --paths-file="$FIX/a_paths.txt" --base=fixture "$ROOT" >/dev/null 2>&1; echo $?)"
set -e
[[ "$J4_EC" -ne 0 ]] || fail "Fixture J waived identical context must FAIL"

# --- Fixture K: reviewer_selected_by ---
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fixture K missing selected_by\"
---
"
set +e
K_EC="$(bash scripts/verify-review-record.sh --paths-file="$FIX/a_paths.txt" --base=fixture "$ROOT" >/dev/null 2>&1; echo $?)"
set -e
[[ "$K_EC" -ne 0 ]] || fail "Fixture K missing reviewer_selected_by must FAIL"

write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: agent
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fixture K bad selected_by\"
---
"
set +e
K2_EC="$(bash scripts/verify-review-record.sh --paths-file="$FIX/a_paths.txt" --base=fixture "$ROOT" >/dev/null 2>&1; echo $?)"
set -e
[[ "$K2_EC" -ne 0 ]] || fail "Fixture K invalid reviewer_selected_by must FAIL"

# --- Conclusion overclaim lint ---
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"context axis verified\"
---
"
set +e
CL_OUT="$(bash scripts/verify-review-record.sh --paths-file="$FIX/a_paths.txt" --base=fixture "$ROOT" 2>&1)"
CL_EC=$?
set -e
[[ "$CL_EC" -ne 0 ]] || fail "conclusion with 'verified' must FAIL"
echo "$CL_OUT" | grep -Fq 'verified|proven|confirmed' || fail "conclusion lint message"

write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fields disclosed; unverifiable; not verified\"
---
"
CL_OK="$(bash scripts/verify-review-record.sh --paths-file="$FIX/a_paths.txt" --base=fixture "$ROOT")"
echo "$CL_OK" | grep -Fq 'REVIEW_RECORD_OK' || fail "unverified / not verified must PASS conclusion lint"
echo "CONCLUSION_LINT_OK"

# --- Lens A: blocking list / scalar / verdict case must not fake-green ---
python3 - <<'PY' || fail "blocking/verdict parser bypass still open"
import sys
sys.path.insert(0, "scripts/lib")
from review_record import parse_front_matter, validate_record

def fm(blocking_block: str, verdict: str = "PASS") -> dict:
    return parse_front_matter(f"""---
diff_id: "x"
diff_base: "fixture"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: ""
reviewers:
  - id: A
    lens: scope
    verdict: {verdict}
    model: m
    context: a
    reviewer_selected_by: owner
{blocking_block}
  - id: B
    lens: e
    verdict: PASS
    model: m
    context: b
    reviewer_selected_by: owner
    blocking: []
conclusion: "parser bypass check"
---
""")

# six-space YAML list under blocking
d = fm("    blocking:\n      - should-block")
assert d["reviewers"][0]["blocking"] == ["should-block"], d["reviewers"][0]
errs = validate_record(d, ["scripts/assert_gate.sh"], "x")
assert any("blocking" in e for e in errs), errs

# scalar blocking must not wipe to []
d = fm("    blocking: critical-finding")
assert d["reviewers"][0]["blocking"] == ["critical-finding"], d["reviewers"][0]
errs = validate_record(d, ["scripts/assert_gate.sh"], "x")
assert any("blocking" in e for e in errs), errs

# inline list
d = fm('    blocking: ["a", "b"]')
assert d["reviewers"][0]["blocking"] == ["a", "b"], d["reviewers"][0]

# verdict case
d = fm("    blocking: []", verdict="fail")
errs = validate_record(d, ["scripts/assert_gate.sh"], "x")
assert any("verdict FAIL" in e for e in errs), errs
print("BLOCKING_VERDICT_PARSE_OK")
PY

# empty paths → SKIP
: >"$FIX/empty.txt"
SKIP_OUT="$(bash scripts/verify-review-record.sh --paths-file="$FIX/empty.txt" --base=fixture "$ROOT")"
echo "$SKIP_OUT" | grep -Fq 'REVIEW_RECORD_SKIP' || fail "empty paths must SKIP"
if echo "$SKIP_OUT" | grep -Fq 'REVIEW_RECORD_OK'; then
  fail "SKIP must not print REVIEW_RECORD_OK"
fi

# missing record → FAIL
printf '%s\n' 'adapters/cursor/vibage.mdc' >"$FIX/bad_paths.txt"
set +e
BAD_OUT="$(bash scripts/verify-review-record.sh --paths-file="$FIX/bad_paths.txt" --base=fixture "$ROOT" 2>&1)"
BAD_EC=$?
set -e
[[ "$BAD_EC" -ne 0 ]] || fail "missing record must fail"

python3 - <<'PY' || fail "head1 mode check"
import sys
from pathlib import Path
sys.path.insert(0, "scripts/lib")
from review_record import resolve_base, git_stdout
pkg = Path(".").resolve()
base, mode = resolve_base(pkg)
assert mode in ("merge_base", "head1", "none"), mode
if mode == "none":
    raise SystemExit("unexpected none base in this repo")
print(f"RESOLVE_BASE_OK mode={mode} base={base[:8]}")
PY

LIVE="$(bash scripts/verify-review-record.sh "$ROOT" 2>&1)" || true
if echo "$LIVE" | grep -Fq 'reason=no_git_base'; then
  fail "full clone must not no_git_base"
fi

# --- Schema hardening (§5 cases 1–29); append-only — do not edit assertions above ---

assert_schema_fail() {
  local label="$1"
  local needle="$2"
  local out ec
  set +e
  out="$(bash scripts/verify-review-record.sh --paths-file="$FIX/a_paths.txt" --base=fixture "$ROOT" 2>&1)"
  ec=$?
  set -e
  [[ "$ec" -ne 0 ]] || fail "$label: expected non-zero exit"
  echo "$out" | grep -Fq 'REVIEW_RECORD_FAIL' || fail "$label: missing REVIEW_RECORD_FAIL"
  echo "$out" | grep -Fq 'reason=schema' || fail "$label: expected reason=schema, got: $out"
  echo "$out" | grep -Fq "$needle" || fail "$label: missing '$needle' in: $out"
}

# Case 1: every reviewer verdict: FAILED
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: FAILED
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: FAILED
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 1 FAILED spelling\"
---
"
assert_schema_fail "case1" "got 'FAILED'"

# Case 2: verdict key omitted
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 2 missing verdict\"
---
"
assert_schema_fail "case2" "missing verdict"

# Case 3: verdict: fail lower case → existing case-insensitive FAIL path
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: fail
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 3 lower-case fail\"
---
"
assert_schema_fail "case3" "verdict FAIL"

# Case 4: PASS_WITH_GAPS + empty blocking still OK
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS_WITH_GAPS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 4 PASS_WITH_GAPS policy unchanged\"
---
"
C4_OUT="$(bash scripts/verify-review-record.sh --paths-file="$FIX/a_paths.txt" --base=fixture "$ROOT")"
echo "$C4_OUT" | grep -Fq 'REVIEW_RECORD_OK' || fail "case4: PASS_WITH_GAPS must OK"

# Case 5: --- mid-value after B's required fields; conclusion before reviewers; C FAIL
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
conclusion: \"case 5 conclusion before reviewers\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    reviewer_selected_by: owner
    blocking: []
    context: \"cross-ref --- thread\"
  - id: C
    lens: adversarial
    verdict: FAIL
    model: fixture-grok
    context: sess-C
    reviewer_selected_by: owner
    blocking:
      - gate truncation hide
---
"
assert_schema_fail "case5" "verdict FAIL"

# Case 6: indented --- between B and C; C must still be seen
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
    ---
  - id: C
    lens: adversarial
    verdict: FAIL
    model: fixture-grok
    context: sess-C
    reviewer_selected_by: owner
    blocking:
      - indented delimiter must not hide
conclusion: \"case 6 indented delimiter\"
---
"
assert_schema_fail "case6" "verdict FAIL"
set +e
C6_OUT="$(bash scripts/verify-review-record.sh --paths-file="$FIX/a_paths.txt" --base=fixture "$ROOT" 2>&1)"
set -e
echo "$C6_OUT" | grep -Fq 'not recognised' || fail "case6: indented --- must be not recognised"

# Case 7: duplicate verdict FAIL then PASS
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: FAIL
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 7 duplicate verdict\"
---
"
assert_schema_fail "case7" "duplicate key 'verdict'"

# Case 8: duplicate blocking finding then []
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking:
      - gate is broken
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 8 duplicate blocking\"
---
"
assert_schema_fail "case8" "duplicate key 'blocking'"

# Case 9: blocking at three-space indent
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
   blocking:
      - three-space finding
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 9 three-space blocking\"
---
"
assert_schema_fail "case9" "not recognised"

# Case 10: Verdict: FAIL then verdict: PASS
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    Verdict: FAIL
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 10 case-variant key\"
---
"
assert_schema_fail "case10" "not recognised"

# Case 11: list item with colon before blocking key
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
      - id: dropped-finding
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 11 orphan list item\"
---
"
assert_schema_fail "case11" "not recognised"

# Case 12: form feed before --- inside front matter; FAIL reviewer after
python3 - <<PY || fail "case12 write"
from pathlib import Path
aid = "$A_ID"
path = Path("docs/evidence/reviews") / f"{aid}.md"
body = f"""---
diff_id: "{aid}"
diff_base: "fixture"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: ""
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
\x0c---
  - id: C
    lens: adversarial
    verdict: FAIL
    model: fixture-grok
    context: sess-C
    reviewer_selected_by: owner
    blocking:
      - form-feed truncation
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: "case 12 form feed"
---
"""
path.write_text(body, encoding="utf-8")
print(path)
PY
CLEANUP_RECS+=("$ROOT/docs/evidence/reviews/${A_ID}.md")
assert_schema_fail "case12" "control character"

# Case 13: reviewer field note:
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    note: free text not allowed
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 13 note field\"
---
"
assert_schema_fail "case13" "not recognised"

# Case 14: min_reviewers declared — specific message retained
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
min_reviewers: 2
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 14 min_reviewers\"
---
"
assert_schema_fail "case14" "min_reviewers must not be declared"

# Case 15: body contains --- after front matter — still OK
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 15 body delimiter\"
---
Body may contain --- without truncating.
"
C15_OUT="$(bash scripts/verify-review-record.sh --paths-file="$FIX/a_paths.txt" --base=fixture "$ROOT")"
echo "$C15_OUT" | grep -Fq 'REVIEW_RECORD_OK' || fail "case15: body --- must OK"

# Case 16: CRLF line endings parse same as LF
python3 - <<'PY' || fail "case16 CRLF parity"
import sys
sys.path.insert(0, "scripts/lib")
from review_record import parse_front_matter

lf = """---
diff_id: "x"
diff_base: "fixture"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: ""
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: m
    context: a
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: e
    verdict: PASS_WITH_GAPS
    model: m
    context: b
    reviewer_selected_by: owner
    blocking: []
conclusion: "crlf parity"
---
"""
crlf = lf.replace("\n", "\r\n")
d_lf = parse_front_matter(lf)
d_crlf = parse_front_matter(crlf)
assert [(r.get("id"), r.get("verdict")) for r in d_lf["reviewers"]] == [
    ("A", "PASS"),
    ("B", "PASS_WITH_GAPS"),
]
assert [(r.get("id"), r.get("verdict")) for r in d_crlf["reviewers"]] == [
    ("A", "PASS"),
    ("B", "PASS_WITH_GAPS"),
]
assert d_lf.get("_parser_errors") == []
assert d_crlf.get("_parser_errors") == []
print("CASE16_CRLF_OK")
PY

# Case 17: unterminated front matter — reason=parse unchanged
python3 - <<PY || fail "case17 write"
from pathlib import Path
aid = "$A_ID"
path = Path("docs/evidence/reviews") / f"{aid}.md"
path.write_text(f"""---
diff_id: "{aid}"
diff_base: "fixture"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
frozen: true
diversity: ok
reviewers:
  - id: A
    verdict: PASS
    model: m
    context: a
    reviewer_selected_by: owner
    blocking: []
conclusion: "unterminated"
""", encoding="utf-8")
PY
CLEANUP_RECS+=("$ROOT/docs/evidence/reviews/${A_ID}.md")
set +e
C17_OUT="$(bash scripts/verify-review-record.sh --paths-file="$FIX/a_paths.txt" --base=fixture "$ROOT" 2>&1)"
C17_EC=$?
set -e
[[ "$C17_EC" -ne 0 ]] || fail "case17: expected fail"
echo "$C17_OUT" | grep -Fq 'REVIEW_RECORD_FAIL' || fail "case17: FAIL token"
echo "$C17_OUT" | grep -Fq 'reason=parse' || fail "case17: expected reason=parse"
echo "$C17_OUT" | grep -Fq 'unterminated front matter' || fail "case17: unterminated message"

# Case 18: - id: D at column zero after terminator → OK + S5 disclosure
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 18 outside reviewer\"
---
- id: D
"
C18_OUT="$(bash scripts/verify-review-record.sh --paths-file="$FIX/a_paths.txt" --base=fixture "$ROOT")"
echo "$C18_OUT" | grep -Fq 'REVIEW_RECORD_OK' || fail "case18: must OK"
echo "$C18_OUT" | grep -Fq 'reviewers_outside_front_matter=1' \
  || fail "case18: expected reviewers_outside_front_matter=1 in: $C18_OUT"

# Case 19: reviewers: inline flow with FAIL entry
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers: [{id: Z, verdict: FAIL, model: x, context: cz, reviewer_selected_by: owner, blocking: [gate broken]}]
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 19 inline reviewers\"
---
"
assert_schema_fail "case19" "must have no inline value"

# Case 20: duplicate top-level conclusion
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"first\"
conclusion: \"second\"
---
"
assert_schema_fail "case20" "duplicate key 'conclusion'"

# Case 21: unrecognised line above FAIL reviewer — both errors
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  bogus_unrecognised: true
  - id: C
    lens: adversarial
    verdict: FAIL
    model: fixture-grok
    context: sess-C
    reviewer_selected_by: owner
    blocking:
      - must still be seen
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 21 continue past unrecognised\"
---
"
set +e
C21_OUT="$(bash scripts/verify-review-record.sh --paths-file="$FIX/a_paths.txt" --base=fixture "$ROOT" 2>&1)"
C21_EC=$?
set -e
[[ "$C21_EC" -ne 0 ]] || fail "case21: expected fail"
echo "$C21_OUT" | grep -Fq 'REVIEW_RECORD_FAIL' || fail "case21: FAIL token"
echo "$C21_OUT" | grep -Fq 'reason=schema' || fail "case21: reason=schema"
echo "$C21_OUT" | grep -Fq 'not recognised' || fail "case21: missing not recognised"
echo "$C21_OUT" | grep -Fq 'verdict FAIL' || fail "case21: missing verdict FAIL (scan must continue)"

# Case 22: subject_paths inline value
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths: [scripts/assert_gate.sh]
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 22 inline subject_paths\"
---
"
assert_schema_fail "case22" "must have no inline value"

# Case 23: id line swallows FAIL fields
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: Z, verdict: FAIL, model: x, context: cz, reviewer_selected_by: owner, blocking: [gate broken]
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 23 id token\"
---
"
assert_schema_fail "case23" "id must be a simple token"

# Case 24: U+2028 before --- on same line
python3 - <<PY || fail "case24 write"
from pathlib import Path
aid = "$A_ID"
path = Path("docs/evidence/reviews") / f"{aid}.md"
body = f"""---
diff_id: "{aid}"
diff_base: "fixture"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: ""
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
\u2028---
  - id: C
    lens: adversarial
    verdict: FAIL
    model: fixture-grok
    context: sess-C
    reviewer_selected_by: owner
    blocking:
      - u2028 truncation
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: "case 24 u2028"
---
"""
path.write_text(body, encoding="utf-8")
PY
CLEANUP_RECS+=("$ROOT/docs/evidence/reviews/${A_ID}.md")
assert_schema_fail "case24" "control character"

# Cases 25–29: frozen literal rule (case-sensitive; no .lower())
for frozen_val in False no yes 1 True; do
  write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: ${frozen_val}
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case frozen=${frozen_val}\"
---
"
  assert_schema_fail "frozen=${frozen_val}" "frozen must be true or false"
done

echo "SCHEMA_HARDENING_CASES_OK"

echo "REVIEW_RECORD_TEST_OK"
