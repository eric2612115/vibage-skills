#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# RED/GREEN for verify-run alone
set +e
"$ROOT/scripts/verify-run.sh" "$ROOT/tests/fixtures/run_degraded_ok.json"
RC=$?
set -e
[[ "$RC" -eq 0 ]] || { echo "FAIL: degraded_ok should pass"; exit 1; }
echo "OK: degraded_ok"

set +e
"$ROOT/scripts/verify-run.sh" "$ROOT/tests/fixtures/run_full_ok.json"
RC=$?
set -e
[[ "$RC" -eq 0 ]] || { echo "FAIL: full_ok should pass"; exit 1; }
echo "OK: full_ok"

set +e
"$ROOT/scripts/verify-run.sh" "$ROOT/tests/fixtures/run_full_fake.json"
RC=$?
set -e
[[ "$RC" -ne 0 ]] || { echo "FAIL: full_fake should fail"; exit 1; }
echo "OK: full_fake rejected"

# verify-report: second arg is RUNS json path
set +e
"$ROOT/scripts/verify-report.sh" \
  "$ROOT/tests/fixtures/sample_LOCATE_degraded.md" \
  "$ROOT/tests/fixtures/run_degraded_ok.json"
RC=$?
set -e
[[ "$RC" -eq 0 ]] || { echo "FAIL: verify-report degraded should pass"; exit 1; }
echo "OK: verify-report + degraded RUNS"

set +e
"$ROOT/scripts/verify-report.sh" \
  "$ROOT/tests/fixtures/sample_LOCATE_full.md" \
  "$ROOT/tests/fixtures/run_full_fake.json"
RC=$?
set -e
[[ "$RC" -ne 0 ]] || { echo "FAIL: verify-report with fake full RUNS should fail"; exit 1; }
echo "OK: verify-report rejects fake full nested RUNS"

echo "ALL verify-run tests passed"
