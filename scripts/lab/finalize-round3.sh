#!/usr/bin/env bash
# After all L1 digs: after live snapshot, check vs before, summarize → artifacts.
# Usage:
#   bash finalize-round3.sh --base=/tmp/vibage-lab/<run>-round3 [--before=SNAP]
# Does not delete. Never claims dig quality — only filesystem + live fingerprint.
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_ROOT="$(cd "$LAB_DIR/../.." && pwd)"

BASE=""
BEFORE=""

for arg in "$@"; do
  case "$arg" in
    --base=*) BASE="${arg#*=}" ;;
    --before=*) BEFORE="${arg#*=}" ;;
    *)
      echo "FAIL: unknown arg $arg" >&2
      exit 1
      ;;
  esac
done

[[ -n "$BASE" && -d "$BASE" ]] || {
  echo "Usage: $0 --base=ROUND3_BASE [--before=SNAP]" >&2
  exit 2
}
BASE="$(cd "$BASE" && pwd -P)"
RUN_ID="$(basename "$BASE")"
RUN_ROOT="$(cd "$(dirname "$BASE")" && pwd -P)"
ART="$PKG_ROOT/docs/evidence/lab/artifacts"
mkdir -p "$RUN_ROOT/live-snapshots" "$RUN_ROOT/results" "$ART"

# Prefer --before, then MANIFEST.before_snap, then conventional path
if [[ -z "$BEFORE" && -f "$BASE/MANIFEST.json" ]]; then
  BEFORE="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1],encoding="utf-8")).get("before_snap") or "")' "$BASE/MANIFEST.json" 2>/dev/null || true)"
fi
if [[ -z "$BEFORE" || ! -f "$BEFORE" ]]; then
  CAND="$RUN_ROOT/live-snapshots/before-${RUN_ID}.json"
  [[ -f "$CAND" ]] && BEFORE="$CAND"
fi
if [[ -z "$BEFORE" || ! -f "$BEFORE" ]]; then
  # fallback: newest before-*round3*.json under live-snapshots
  BEFORE="$(ls -t "$RUN_ROOT"/live-snapshots/before-*round3*.json 2>/dev/null | head -1 || true)"
fi
[[ -n "$BEFORE" && -f "$BEFORE" ]] || {
  echo "FAIL: --before= snapshot required (prepare before snap missing)" >&2
  exit 1
}
BEFORE="$(cd "$(dirname "$BEFORE")" && pwd -P)/$(basename "$BEFORE")"

AFTER="$RUN_ROOT/live-snapshots/after-${RUN_ID}.json"
echo "LAB_ROUND3_FINALIZE_START base=$BASE before=$BEFORE after=$AFTER"

bash "$LAB_DIR/assert-live-untouched.sh" --snapshot="$AFTER"
# Keep a copy in package artifacts (no delete of older files)
cp -f "$AFTER" "$ART/after-${RUN_ID}.json"
cp -f "$BEFORE" "$ART/before-${RUN_ID}.json" 2>/dev/null || true

set +e
bash "$LAB_DIR/assert-live-untouched.sh" --check="$BEFORE"
LIVE_EC=$?
set -e

SUM_OUT="$RUN_ROOT/results/ROUND3-${RUN_ID}-SUMMARY.json"
set +e
bash "$LAB_DIR/summarize-round3.sh" "$BASE" \
  --before="$BEFORE" --after="$AFTER" --out="$SUM_OUT"
SUM_EC=$?
set -e

# Must-fix: check fail still writes SUMMARY with live_untouched:false
if [[ "$LIVE_EC" -ne 0 ]]; then
  python3 - "$SUM_OUT" <<'PY'
import json, sys
from pathlib import Path
p = Path(sys.argv[1])
o = json.load(open(p, encoding="utf-8"))
o["live_untouched"] = False
o["live_check"] = "assert_live_check_failed"
p.write_text(json.dumps(o, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print("LAB_ROUND3_SUMMARY_LIVE_FORCED_FALSE", p)
PY
fi

cp -f "$SUM_OUT" "$ART/ROUND3-${RUN_ID}-SUMMARY.json"

# DIG table from SUMMARY
python3 - "$SUM_OUT" "$ART/ROUND3-${RUN_ID}-DIG-TABLE.md" <<'PY'
import json, sys
from pathlib import Path
obj = json.load(open(sys.argv[1], encoding="utf-8"))
out = Path(sys.argv[2])
lines = [
    "# Round3 dig table (script-derived)",
    "",
    f"run: `{obj.get('run')}`",
    f"generator: `{obj.get('generator')}`",
    f"live_check: `{obj.get('live_check')}` live_untouched: `{obj.get('live_untouched')}`",
    f"partial: `{obj.get('partial')}`",
    "",
    "| name | dig_status | dual_files |",
    "|------|------------|------------|",
]
for t in obj.get("trials") or []:
    lines.append(
        f"| {t.get('name')} | {t.get('dig_status')} | {t.get('dual_report_files_present')} |"
    )
lines.append("")
lines.append(
    "Note: dual_report_files_present = OWNER+LOCATE files exist; ≠ dig quality / true dig proof."
)
lines.append("trials_order = lexicographic_by_results_dirname (not execution order).")
out.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(f"LAB_ROUND3_DIG_TABLE path={out}")
PY

EC=0
if [[ "$LIVE_EC" -ne 0 ]]; then
  echo "LAB_ROUND3_FINALIZE_LIVE_FAIL (SUMMARY still written; live_untouched should be false)" >&2
  EC=1
fi
if [[ "$SUM_EC" -eq 2 ]]; then
  echo "LAB_ROUND3_FINALIZE_PARTIAL ready_dig remains" >&2
  EC=1
elif [[ "$SUM_EC" -ne 0 ]]; then
  echo "LAB_ROUND3_FINALIZE_SUMMARY_FAIL ec=$SUM_EC" >&2
  EC=1
fi

if [[ "$EC" -eq 0 ]]; then
  echo "LAB_ROUND3_FINALIZE_OK summary=$SUM_OUT"
else
  echo "LAB_ROUND3_FINALIZE_DONE_WITH_ERRORS summary=$SUM_OUT" >&2
fi
exit "$EC"
