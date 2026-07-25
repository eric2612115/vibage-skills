#!/usr/bin/env bash
# Review-record gate smoke. ∉ Tier-0 / must not enter test-tier0.sh.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "FAIL: $*"; exit 1; }

if grep -qE 'test_review_record|verify-review-record' scripts/test-tier0.sh 2>/dev/null; then
  fail "review-record must not enter scripts/test-tier0.sh"
fi

[[ -f scripts/verify-review-record.sh ]] || fail "missing verify-review-record.sh"
[[ -f scripts/lib/review_record.py ]] || fail "missing review_record.py"
[[ -f references/looping-review.md ]] || fail "missing looping-review.md"

FIX="$ROOT/docs/evidence/reviews/_fixture_work"
mkdir -p "$FIX" "$ROOT/docs/evidence/reviews"
# No teardown rm of live trees; fixture files stay under docs/evidence/reviews/_fixture_work

# Build a tiny fake trigger file under adapters for digest stability inside FIX copy
# Use --paths-file pointing at a temp list; digests read from real package files.
PATHS_FILE="$FIX/paths.txt"
printf '%s\n' 'references/routing-scope.md' >"$PATHS_FILE"

# Compute expected id via library
DIFF_ID="$(python3 - <<PY
from pathlib import Path
import sys
sys.path.insert(0, "$ROOT/scripts/lib")
from review_record import compute_diff_id
print(compute_diff_id(Path("$ROOT"), ["references/routing-scope.md"]))
PY
)"
[[ -n "$DIFF_ID" ]] || fail "empty diff_id"

REC="$ROOT/docs/evidence/reviews/${DIFF_ID}.md"
cat >"$REC" <<EOF
---
diff_id: "$DIFF_ID"
diff_base: "fixture"
subject_paths:
  - references/routing-scope.md
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: ""
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-model-a
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS_WITH_GAPS
    model: fixture-model-b
    blocking: []
  - id: C
    lens: wrong_path
    verdict: PASS
    model: fixture-model-a
    blocking: []
conclusion: "fixture frozen; no blocking"
---

Fixture review record for test_review_record.sh. Not a product claim.
EOF

OUT="$(bash scripts/verify-review-record.sh --paths-file="$PATHS_FILE" --base=fixture "$ROOT")"
echo "$OUT" | grep -Fq 'REVIEW_RECORD_OK' || fail "expected REVIEW_RECORD_OK for fixture record"
echo "$OUT" | grep -Fq 'REVIEW_RECORD_SKIP' && fail "must not SKIP when OK"

# Clean tree / no triggers → SKIP (not OK)
: >"$FIX/empty.txt"
SKIP_OUT="$(bash scripts/verify-review-record.sh --paths-file="$FIX/empty.txt" --base=fixture "$ROOT")"
echo "$SKIP_OUT" | grep -Fq 'REVIEW_RECORD_SKIP' || fail "empty paths must SKIP"
if echo "$SKIP_OUT" | grep -Fq 'REVIEW_RECORD_OK'; then
  fail "SKIP must not print REVIEW_RECORD_OK"
fi

# Missing record → FAIL
BAD_PATHS="$FIX/bad_paths.txt"
printf '%s\n' 'adapters/cursor/vibage.mdc' >"$BAD_PATHS"
set +e
BAD_OUT="$(bash scripts/verify-review-record.sh --paths-file="$BAD_PATHS" --base=fixture "$ROOT" 2>&1)"
BAD_EC=$?
set -e
[[ "$BAD_EC" -ne 0 ]] || fail "missing record must fail"
echo "$BAD_OUT" | grep -Fq 'REVIEW_RECORD_FAIL' || fail "expected REVIEW_RECORD_FAIL"

# Diversity ok with one model → fail schema
ONE="$FIX/one_model.md"
ONE_ID="$(python3 - <<PY
from pathlib import Path
import sys
sys.path.insert(0, "$ROOT/scripts/lib")
from review_record import compute_diff_id
print(compute_diff_id(Path("$ROOT"), ["references/looping-review.md"]))
PY
)"
printf '%s\n' 'references/looping-review.md' >"$FIX/one_paths.txt"
cat >"$ROOT/docs/evidence/reviews/${ONE_ID}.md" <<EOF
---
diff_id: "$ONE_ID"
diff_base: "fixture"
subject_paths:
  - references/looping-review.md
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: ""
reviewers:
  - id: A
    lens: a
    verdict: PASS
    model: same
    blocking: []
  - id: B
    lens: b
    verdict: PASS
    model: same
    blocking: []
  - id: C
    lens: c
    verdict: PASS
    model: same
    blocking: []
conclusion: "should fail diversity"
---
EOF
set +e
DIV_OUT="$(bash scripts/verify-review-record.sh --paths-file="$FIX/one_paths.txt" --base=fixture "$ROOT" 2>&1)"
DIV_EC=$?
set -e
[[ "$DIV_EC" -ne 0 ]] || fail "single-model diversity=ok must fail"

echo "REVIEW_RECORD_TEST_OK"
