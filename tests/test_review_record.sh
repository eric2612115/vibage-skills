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

echo "REVIEW_RECORD_TEST_OK"
