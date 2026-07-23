#!/usr/bin/env bash
# tests/test_assert_gate.sh — red/green for assert_gate + write_confirm
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/docs/vibage"
cp "$ROOT/tests/fixtures/sample_SCAN_PLAN.md" "$TMP/docs/vibage/SCAN_PLAN.md"

# Case A: missing CONFIRM → FAIL
set +e
"$ROOT/scripts/assert_gate.sh" "$TMP"
RC=$?
set -e
if [[ "$RC" -eq 0 ]]; then
  echo "FAIL: expected assert_gate to fail without CONFIRM"
  exit 1
fi
echo "OK: missing confirm rejected (rc=$RC)"

# Case B: write_confirm then assert_gate OK
"$ROOT/scripts/write_confirm.sh" "$TMP" "test-owner"
"$ROOT/scripts/assert_gate.sh" "$TMP"
echo "OK: matching confirm accepted"

# Case C: mutate plan → mismatch FAIL
python3 - <<'PY' "$TMP/docs/vibage/SCAN_PLAN.md"
import pathlib, sys
p = pathlib.Path(sys.argv[1])
text = p.read_text(encoding="utf-8")
text = text.replace(
    '"known_incompleteness": "no roots discovered yet"',
    '"known_incompleteness": "MUTATED"',
)
p.write_text(text, encoding="utf-8")
PY
set +e
"$ROOT/scripts/assert_gate.sh" "$TMP"
RC=$?
set -e
if [[ "$RC" -eq 0 ]]; then
  echo "FAIL: expected assert_gate to fail after plan mutate"
  exit 1
fi
echo "OK: stale confirm rejected after plan mutate (rc=$RC)"
echo "ALL assert_gate tests passed"
