#!/usr/bin/env bash
# P1 smoke: init-hub → confirm → assert_gate OK → mutate FAIL → fake full nested FAIL
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Synthetic parent with two fake git roots
mkdir -p "$TMP/app-a/.git" "$TMP/app-b/.git"
cp "$ROOT/tests/fixtures/synthetic-parent/app-a/README.md" "$TMP/app-a/README.md"
cp "$ROOT/tests/fixtures/synthetic-parent/app-b/README.md" "$TMP/app-b/README.md"

# init hub
bash "$ROOT/scripts/install.sh" --init-hub="$TMP"
[[ -f "$TMP/docs/war-room/STATUS.md" ]]

# Write a real SCAN_PLAN with two roots
cat > "$TMP/docs/war-room/SCAN_PLAN.md" <<'MD'
# SCAN_PLAN

Visible subset: app-a, app-b.

```json scan_plan_v1
{
  "schema_version": "1",
  "root_refs": [
    {"id": "app-a", "path": "app-a", "presence": "checked_out", "kind": "app", "evidence": ["app-a/.git"], "hot_path": true},
    {"id": "app-b", "path": "app-b", "presence": "checked_out", "kind": "app", "evidence": ["app-b/.git"], "hot_path": false}
  ],
  "budgets": {"max_wall_min": 25, "max_files": 40, "max_depth": 3},
  "hot_path_ids": ["app-a"],
  "known_incompleteness": "no deploy root in synthetic fixture",
  "planned_dig_ids": ["app-a"]
}
```
MD

# confirm + gate OK
bash "$ROOT/scripts/write_confirm.sh" "$TMP" "smoke"
bash "$ROOT/scripts/assert_gate.sh" "$TMP"
echo "OK: assert_gate after confirm"

# verify-run degraded OK
bash "$ROOT/scripts/verify-run.sh" "$ROOT/tests/fixtures/run_degraded_ok.json"
echo "OK: degraded verify-run"

# fake full nested must FAIL
set +e
bash "$ROOT/scripts/verify-run.sh" "$ROOT/tests/fixtures/run_full_fake.json"
RC=$?
set -e
[[ "$RC" -ne 0 ]] || { echo "FAIL: fake full nested should fail verify-run"; exit 1; }
echo "OK: fake full nested rejected"

# verify-report with fake full RUNS must FAIL
set +e
bash "$ROOT/scripts/verify-report.sh" \
  "$ROOT/tests/fixtures/sample_LOCATE_full.md" \
  "$ROOT/tests/fixtures/run_full_fake.json"
RC=$?
set -e
[[ "$RC" -ne 0 ]] || { echo "FAIL: verify-report should reject fake full RUNS"; exit 1; }
echo "OK: verify-report fake full nested FAIL"

# mutate plan → stale confirm
python3 - <<'PY' "$TMP/docs/war-room/SCAN_PLAN.md"
import pathlib, sys
p = pathlib.Path(sys.argv[1])
t = p.read_text(encoding="utf-8")
t = t.replace(
    '"known_incompleteness": "no deploy root in synthetic fixture"',
    '"known_incompleteness": "MUTATED_SMOKE"',
)
p.write_text(t, encoding="utf-8")
PY
set +e
bash "$ROOT/scripts/assert_gate.sh" "$TMP"
RC=$?
set -e
[[ "$RC" -ne 0 ]] || { echo "FAIL: expected stale confirm"; exit 1; }
echo "OK: stale confirm after mutate"

# preview copy fail-soft path exists
mkdir -p "$TMP/war-room-preview"
cp "$ROOT/assets/war-room-preview/index.html" "$TMP/war-room-preview/index.html"
[[ -f "$TMP/war-room-preview/index.html" ]]
echo "OK: preview copy"

echo "ALL p1 smoke tests passed"
