#!/usr/bin/env bash
# Lab harness smoke. ∉ Tier-0 / pack-health.
# LAB_NO_DELETE: does not rm lab roots; leaves artifacts under /tmp/vibage-lab/smoke-*
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "FAIL: $*"; exit 1; }

if grep -qE 'test_lab_harness|scripts/lab/' scripts/test-tier0.sh 2>/dev/null; then
  fail "lab harness must not enter scripts/test-tier0.sh"
fi
if grep -qE 'scripts/lab/' scripts/pack-health.sh 2>/dev/null; then
  fail "lab harness must not enter scripts/pack-health.sh"
fi

# Static no-delete across all lab shell scripts
bash scripts/lab/lab-no-delete-check.sh >/tmp/lab-nodelete-scan.json \
  || fail "lab-no-delete-check must pass (static)"
grep -Fq '"lab_no_delete_static_scan": true' /tmp/lab-nodelete-scan.json \
  || fail "expected lab_no_delete_static_scan true"

grep -Fq 'LAB_NO_DELETE' scripts/lab/run-trial.sh || fail "run-trial must declare LAB_NO_DELETE"
[[ -f scripts/lab/summarize-round3.sh ]] || fail "missing summarize-round3.sh"
[[ -f scripts/lab/finalize-round3.sh ]] || fail "missing finalize-round3.sh"

[[ -f scripts/lab/rsync-excludes.txt ]] || fail "missing rsync-excludes.txt"
grep -Fq '.venv' scripts/lab/rsync-excludes.txt || fail "excludes must name .venv"
grep -Fq 'node_modules' scripts/lab/rsync-excludes.txt || fail "excludes must name node_modules"
grep -Fq '__pycache__' scripts/lab/rsync-excludes.txt || fail "excludes must name __pycache__"
grep -Fq '_reference/' scripts/lab/rsync-excludes.txt || fail "excludes must name _reference/"

# shellcheck source=../scripts/lab/allowlist.sh
source scripts/lab/allowlist.sh

if lab_assert_source_allowed /Users/eric.fang 2>/tmp/lab-al.err; then
  fail "HOME root must be rejected"
fi
grep -Fq 'LAB_ALLOWLIST_FAIL' /tmp/lab-al.err || fail "expected LAB_ALLOWLIST_FAIL for HOME"

if [[ -d /Users/eric.fang/MindOwnBuz ]]; then
  lab_assert_source_allowed /Users/eric.fang/MindOwnBuz | grep -Fq 'LAB_ALLOWLIST_OK' \
    || fail "MindOwnBuz should be allowed"
fi

chmod +x scripts/lab/*.sh

export VIBAGE_LAB_ROOT="/tmp/vibage-lab/smoke-$(date -u +%Y%m%dT%H%M%SZ)-$$"
mkdir -p "$VIBAGE_LAB_ROOT"
# Intentionally NO trap rm — owner / later cleanup of /tmp only.

bash scripts/lab/run-trial.sh --fixture=synthetic-parent --model=script --slot=smoke \
  --run-root="$VIBAGE_LAB_ROOT" | tee /tmp/lab-smoke.out

grep -Fq 'LAB_CASE_OK' /tmp/lab-smoke.out || fail "expected LAB_CASE_OK"
grep -Fq 'LAB_KEEP' /tmp/lab-smoke.out || fail "expected LAB_KEEP"
if grep -Fq 'LAB_TEARDOWN_OK' /tmp/lab-smoke.out; then
  fail "teardown success token must not appear"
fi

sb="$(find "$VIBAGE_LAB_ROOT/results" -name SCOREBOARD.json 2>/dev/null | head -1)"
[[ -n "$sb" && -f "$sb" ]] || fail "expected persisted SCOREBOARD under results/"
staging="$(cat "$(dirname "$sb")/STAGING_PARENT")"
[[ -d "$staging" ]] || fail "staging parent must still exist (no delete): $staging"

# Docker mode must fail closed
if bash scripts/lab/run-trial.sh --fixture=synthetic-parent --mode=docker --run-root="$VIBAGE_LAB_ROOT" \
  >/tmp/lab-docker-reject.out 2>&1; then
  fail "docker mode must fail"
fi
grep -Eiq 'Docker mode removed|LAB_NO_DELETE' /tmp/lab-docker-reject.out \
  || fail "docker reject must mention LAB_NO_DELETE"

# --- summarize-round3 fixture (no real dig; no teardown rm) ---
FIX_BASE="$VIBAGE_LAB_ROOT/fixture-round3"
mkdir -p "$FIX_BASE/prompts" \
  "$VIBAGE_LAB_ROOT/results/fixture-round3-demo-composer-a" \
  "$VIBAGE_LAB_ROOT/results/fixture-round3-demo-composer-b"
printf 'DONE\n' >"$VIBAGE_LAB_ROOT/results/fixture-round3-demo-composer-a/DIG_STATUS"
printf '%s\n' "$FIX_BASE/parent-a" >"$VIBAGE_LAB_ROOT/results/fixture-round3-demo-composer-a/STAGING_PARENT"
printf 'x\n' >"$VIBAGE_LAB_ROOT/results/fixture-round3-demo-composer-a/VIBAGE-ISSUE-OWNER.md"
printf 'y\n' >"$VIBAGE_LAB_ROOT/results/fixture-round3-demo-composer-a/VIBAGE-ISSUE-LOCATE.md"
# mismatch: DONE claimed elsewhere without files — use READY with dual files
printf 'READY_DIG\n' >"$VIBAGE_LAB_ROOT/results/fixture-round3-demo-composer-b/DIG_STATUS"
printf '%s\n' "$FIX_BASE/parent-b" >"$VIBAGE_LAB_ROOT/results/fixture-round3-demo-composer-b/STAGING_PARENT"
printf 'o\n' >"$VIBAGE_LAB_ROOT/results/fixture-round3-demo-composer-b/VIBAGE-ISSUE-OWNER.md"
printf 'l\n' >"$VIBAGE_LAB_ROOT/results/fixture-round3-demo-composer-b/VIBAGE-ISSUE-LOCATE.md"

set +e
bash scripts/lab/summarize-round3.sh "$FIX_BASE" \
  --out="$VIBAGE_LAB_ROOT/results/ROUND3-fixture-round3-SUMMARY.json" \
  >"$VIBAGE_LAB_ROOT/summarize-no-after.out" 2>"$VIBAGE_LAB_ROOT/summarize-no-after.err"
SUM1=$?
set -e
grep -Fq 'LAB_ROUND3_SUMMARY_OK' "$VIBAGE_LAB_ROOT/summarize-no-after.out" \
  || fail "expected LAB_ROUND3_SUMMARY_OK"
python3 - "$VIBAGE_LAB_ROOT/results/ROUND3-fixture-round3-SUMMARY.json" <<'PY' || fail "summarize field checks"
import json, sys
o = json.load(open(sys.argv[1], encoding="utf-8"))
assert o.get("generator") == "scripts/lab/summarize-round3.sh"
assert o.get("live_untouched") is None, o.get("live_untouched")
assert o.get("live_check") in ("missing_after", "prepare_only", "missing_before")
assert o["dig_status_counts"]["DONE"] == 1
assert o["dig_status_counts"]["READY_DIG"] == 1
assert o["dual_report_files_present"] == 2
assert o.get("lab_no_delete_static_scan") is True
assert any(m.get("kind") == "READY_with_dual_files" for m in o.get("mismatches") or [])
assert "dig_done" not in o  # old hand field must not reappear as authority
assert "dual_reports" not in o
assert o.get("trials_order") == "lexicographic_by_results_dirname"
print("SUMMARIZE_FIELDS_OK")
PY
# PARTIAL because READY_DIG remains
[[ "$SUM1" -eq 2 ]] || fail "expected summarize exit 2 when READY_DIG present (got $SUM1)"

# before+after equal → live_untouched true (tiny fake snaps; not real mothers)
python3 - <<PY
import json
from pathlib import Path
root = Path("$VIBAGE_LAB_ROOT")
fake = {"probe": {"ok": True}}
(root / "before.json").write_text(json.dumps(fake), encoding="utf-8")
(root / "after.json").write_text(json.dumps(fake), encoding="utf-8")
(root / "after-differ.json").write_text(json.dumps({"probe": {"ok": False}}), encoding="utf-8")
PY
# Clear READY so summarize can exit 0 for live check demo
printf 'DONE\n' >"$VIBAGE_LAB_ROOT/results/fixture-round3-demo-composer-b/DIG_STATUS"
bash scripts/lab/summarize-round3.sh "$FIX_BASE" \
  --before="$VIBAGE_LAB_ROOT/before.json" --after="$VIBAGE_LAB_ROOT/after.json" \
  --out="$VIBAGE_LAB_ROOT/results/ROUND3-fixture-round3-SUMMARY-live.json" \
  | tee "$VIBAGE_LAB_ROOT/summarize-live.out"
grep -Fq 'LAB_ROUND3_SUMMARY_OK' "$VIBAGE_LAB_ROOT/summarize-live.out" || fail "live summarize ok"
python3 - "$VIBAGE_LAB_ROOT/results/ROUND3-fixture-round3-SUMMARY-live.json" <<'PY' || fail "live_untouched true expected"
import json, sys
o = json.load(open(sys.argv[1], encoding="utf-8"))
assert o.get("live_untouched") is True
assert o.get("live_check") == "before_after_equal"
print("LIVE_FIELDS_OK")
PY

# before≠after → live_untouched false (finalize check-fail path uses same field)
bash scripts/lab/summarize-round3.sh "$FIX_BASE" \
  --before="$VIBAGE_LAB_ROOT/before.json" --after="$VIBAGE_LAB_ROOT/after-differ.json" \
  --out="$VIBAGE_LAB_ROOT/results/ROUND3-fixture-round3-SUMMARY-differ.json" \
  >/dev/null
python3 - "$VIBAGE_LAB_ROOT/results/ROUND3-fixture-round3-SUMMARY-differ.json" <<'PY' || fail "differ snaps must be false"
import json, sys
o = json.load(open(sys.argv[1], encoding="utf-8"))
assert o.get("live_untouched") is False
assert o.get("live_check") == "before_after_differ"
print("LIVE_DIFFER_OK")
PY

# finalize MANIFEST.before_snap derivation + force-false patch (no real mothers check)
# Stub assert-live-untouched by using equal snaps then patching like finalize does on LIVE_EC≠0
python3 - "$VIBAGE_LAB_ROOT/results/ROUND3-fixture-round3-SUMMARY-live.json" <<'PY' || fail "force-false patch"
import json, sys
from pathlib import Path
p = Path(sys.argv[1])
o = json.load(open(p, encoding="utf-8"))
o["live_untouched"] = False
o["live_check"] = "assert_live_check_failed"
p.write_text(json.dumps(o, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
assert json.load(open(p, encoding="utf-8"))["live_untouched"] is False
print("FORCE_FALSE_OK")
PY

echo "LAB_HARNESS_SMOKE_OK root=$VIBAGE_LAB_ROOT (left in place; owner cleans /tmp)"
