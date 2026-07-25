#!/usr/bin/env bash
# Plan-loop hygiene smoke. ∉ Tier-0.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "FAIL: $*"; exit 1; }

if grep -qE 'test_plan_loop_hygiene|verify-plan-loop-hygiene' scripts/test-tier0.sh 2>/dev/null; then
  fail "plan-loop hygiene must not enter scripts/test-tier0.sh"
fi

[[ -f scripts/verify-plan-loop-hygiene.sh ]] || fail "missing verify-plan-loop-hygiene.sh"
chmod +x scripts/verify-plan-loop-hygiene.sh

# Live package plans must pass
bash scripts/verify-plan-loop-hygiene.sh "$ROOT" | grep -Fq 'PLAN_LOOP_HYGIENE_OK' \
  || fail "live plans must be PLAN_LOOP_HYGIENE_OK"

# Fixture tree with a bad todo
FIX=$(mktemp -d)
mkdir -p "$FIX/docs/superpowers/plans"
cat >"$FIX/docs/superpowers/plans/bad.md" <<'EOF'
# bad

- [ ] plan-loop-converge until freeze
- [ ] implement feature X
EOF
set +e
OUT="$(bash scripts/verify-plan-loop-hygiene.sh "$FIX" 2>&1)"
EC=$?
set -e
[[ "$EC" -ne 0 ]] || fail "bad todo must fail"
echo "$OUT" | grep -Fq 'PLAN_LOOP_HYGIENE_FAIL' || fail "expected PLAN_LOOP_HYGIENE_FAIL"

# Allowed: deliverable name on checklist
mkdir -p "$FIX/docs/superpowers/plans"
cat >"$FIX/docs/superpowers/plans/ok.md" <<'EOF'
# ok

- [ ] add verify-plan-loop-hygiene.sh and tests
- [x] Plan loop already frozen at 2026-07-26 (narrative on checklist — deliverable path OK if only token names)

EOF
# Replace ok.md alone in clean tree
FIX2=$(mktemp -d)
mkdir -p "$FIX2/docs/superpowers/plans"
cat >"$FIX2/docs/superpowers/plans/ok.md" <<'EOF'
# ok
- [ ] ship verify-plan-loop-hygiene.sh
- [ ] document PLAN_LOOP_HYGIENE_OK token
EOF
bash scripts/verify-plan-loop-hygiene.sh "$FIX2" | grep -Fq 'PLAN_LOOP_HYGIENE_OK' \
  || fail "deliverable-named todos must pass"

echo "PLAN_LOOP_HYGIENE_TEST_OK"
