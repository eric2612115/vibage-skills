#!/usr/bin/env bash
# Review-record gate smoke. ∉ Tier-0 / must not enter test-tier0.sh.
# --paths-file is TEST-ONLY (not a production acceptance path).
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

# assert_gate.sh must be a trigger
python3 - <<'PY' || fail "assert_gate.sh must be_trigger"
import sys
sys.path.insert(0, "scripts/lib")
from review_record import is_trigger
assert is_trigger("scripts/assert_gate.sh"), "assert_gate not trigger"
assert is_trigger("tests/test_assert_gate.sh"), "tests/ not trigger"
assert not is_trigger("docs/evidence/reviews/x.md")
print("TRIGGER_ASSERT_OK")
PY

PATHS_FILE="$FIX/paths.txt"
printf '%s\n' 'references/routing-scope.md' >"$PATHS_FILE"

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
if echo "$OUT" | grep -Fq 'REVIEW_RECORD_SKIP'; then
  fail "must not SKIP when OK"
fi

: >"$FIX/empty.txt"
SKIP_OUT="$(bash scripts/verify-review-record.sh --paths-file="$FIX/empty.txt" --base=fixture "$ROOT")"
echo "$SKIP_OUT" | grep -Fq 'REVIEW_RECORD_SKIP' || fail "empty paths must SKIP"
if echo "$SKIP_OUT" | grep -Fq 'REVIEW_RECORD_OK'; then
  fail "SKIP must not print REVIEW_RECORD_OK"
fi

# assert_gate path missing record → FAIL
printf '%s\n' 'scripts/assert_gate.sh' >"$FIX/ag_paths.txt"
set +e
AG_OUT="$(bash scripts/verify-review-record.sh --paths-file="$FIX/ag_paths.txt" --base=fixture "$ROOT" 2>&1)"
AG_EC=$?
set -e
[[ "$AG_EC" -ne 0 ]] || fail "assert_gate trigger without record must fail"
echo "$AG_OUT" | grep -Fq 'REVIEW_RECORD_FAIL' || fail "expected FAIL for assert_gate missing record"

# Missing record → FAIL
printf '%s\n' 'adapters/cursor/vibage.mdc' >"$FIX/bad_paths.txt"
set +e
BAD_OUT="$(bash scripts/verify-review-record.sh --paths-file="$FIX/bad_paths.txt" --base=fixture "$ROOT" 2>&1)"
BAD_EC=$?
set -e
[[ "$BAD_EC" -ne 0 ]] || fail "missing record must fail"

# Diversity ok with one model → fail schema
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
DIV_EC="$(bash scripts/verify-review-record.sh --paths-file="$FIX/one_paths.txt" --base=fixture "$ROOT" >/dev/null 2>&1; echo $?)"
set -e
[[ "$DIV_EC" -ne 0 ]] || fail "single-model diversity=ok must fail"

# resolve_base head1 when mb == HEAD
python3 - <<'PY' || fail "head1 mode check"
import sys
from pathlib import Path
sys.path.insert(0, "scripts/lib")
from review_record import resolve_base, git_stdout
pkg = Path(".").resolve()
base, mode = resolve_base(pkg)
head = git_stdout(pkg, ["rev-parse", "HEAD"]).strip()
# On a feature branch, mode is usually merge_base; on main tip, head1.
# Always: if mode==head1 must print path works via main()
assert mode in ("merge_base", "head1", "none"), mode
if mode == "none":
    raise SystemExit("unexpected none base in this repo")
print(f"RESOLVE_BASE_OK mode={mode} base={base[:8]}")
PY

# Live verify should emit head1 or merge_base (not no_git_base FAIL on this clone)
LIVE="$(bash scripts/verify-review-record.sh "$ROOT" 2>&1)" || true
if echo "$LIVE" | grep -Fq 'reason=no_git_base'; then
  fail "full clone must not no_git_base"
fi
# When triggers exist on branch vs main, expect OK or FAIL missing record — not silent skip-as-pass on no_git_base

echo "REVIEW_RECORD_TEST_OK"
