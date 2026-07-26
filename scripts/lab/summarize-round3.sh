#!/usr/bin/env bash
# Scan Round-3 results into a script-derived SUMMARY (not hand-assembled claims).
# Usage:
#   bash summarize-round3.sh <ROUND3_BASE> [--before=SNAP] [--after=SNAP] [--out=FILE]
# Does not delete. Dual-report counts = file presence only (≠ dig quality).
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_ROOT="$(cd "$LAB_DIR/../.." && pwd)"

BASE=""
BEFORE=""
AFTER=""
OUT=""

for arg in "$@"; do
  case "$arg" in
    --before=*) BEFORE="${arg#*=}" ;;
    --after=*) AFTER="${arg#*=}" ;;
    --out=*) OUT="${arg#*=}" ;;
    --*)
      echo "FAIL: unknown arg $arg" >&2
      exit 1
      ;;
    *)
      if [[ -z "$BASE" ]]; then BASE="$arg"; else
        echo "FAIL: unexpected arg $arg" >&2
        exit 1
      fi
      ;;
  esac
done

[[ -n "$BASE" && -d "$BASE" ]] || {
  echo "Usage: $0 <ROUND3_BASE> [--before=SNAP] [--after=SNAP] [--out=FILE]" >&2
  exit 2
}
BASE="$(cd "$BASE" && pwd -P)"
RUN_ID="$(basename "$BASE")"
RUN_ROOT="$(cd "$(dirname "$BASE")" && pwd -P)"
RESULTS_GLOB="$RUN_ROOT/results/${RUN_ID}-*"

set +e
SCAN_JSON="$(bash "$LAB_DIR/lab-no-delete-check.sh")"
set -e
[[ -n "$SCAN_JSON" ]] || SCAN_JSON='{"lab_no_delete_static_scan":false,"hits":[{"text":"scan_failed"}],"method":"static_script_scan"}'

if [[ -z "$OUT" ]]; then
  OUT="$RUN_ROOT/results/ROUND3-${RUN_ID}-SUMMARY.json"
fi
mkdir -p "$(dirname "$OUT")"

# Pass scan via env to avoid shell-quoting JSON
export LAB_NO_DELETE_SCAN_JSON="$SCAN_JSON"
python3 - "$BASE" "$RUN_ID" "$RUN_ROOT" "$OUT" "$BEFORE" "$AFTER" "$PKG_ROOT" <<'PY'
import json, os, sys
from pathlib import Path

base = Path(sys.argv[1])
run_id = sys.argv[2]
run_root = Path(sys.argv[3])
out_path = Path(sys.argv[4])
before_p = sys.argv[5]
after_p = sys.argv[6]
pkg_root = Path(sys.argv[7])
scan = json.loads(os.environ.get("LAB_NO_DELETE_SCAN_JSON") or "{}")

counts = {"DONE": 0, "SKIP_DIG": 0, "READY_DIG": 0, "other": 0}
trials = []
mismatches = []
dual_present = 0

result_dirs = sorted(
    p for p in (run_root / "results").glob(f"{run_id}-*") if p.is_dir()
)

for rd in result_dirs:
    name = rd.name[len(run_id) + 1 :] if rd.name.startswith(run_id + "-") else rd.name
    status_path = rd / "DIG_STATUS"
    status = status_path.read_text(encoding="utf-8").strip() if status_path.is_file() else "MISSING"
    if status in counts:
        counts[status] += 1
    else:
        counts["other"] += 1

    staging = ""
    sp = rd / "STAGING_PARENT"
    if sp.is_file():
        staging = sp.read_text(encoding="utf-8").strip()

    owner_r = (rd / "VIBAGE-ISSUE-OWNER.md").is_file()
    locate_r = (rd / "VIBAGE-ISSUE-LOCATE.md").is_file()
    # staging additive only
    if staging:
        st = Path(staging)
        if (st / "docs/vibage/VIBAGE-ISSUE-OWNER.md").is_file():
            owner_r = True
        if (st / "docs/vibage/VIBAGE-ISSUE-LOCATE.md").is_file():
            locate_r = True

    dual_ok = owner_r and locate_r
    if dual_ok:
        dual_present += 1

    # Cross-check DIG_STATUS vs files
    if status == "DONE" and not dual_ok:
        mismatches.append({"name": name, "kind": "DONE_without_dual_files"})
    if status == "SKIP_DIG" and dual_ok:
        mismatches.append({"name": name, "kind": "SKIP_with_dual_files"})
    if status == "READY_DIG" and dual_ok:
        mismatches.append({"name": name, "kind": "READY_with_dual_files"})

    parts = name.rsplit("-", 2)
    mother, model, slot = (parts + ["", "", ""])[:3] if len(parts) >= 3 else (name, "", "")
    if len(parts) >= 3:
        mother = "-".join(parts[:-2])
        model, slot = parts[-2], parts[-1]

    trials.append(
        {
            "name": name,
            "mother": mother,
            "model": model,
            "slot": slot,
            "dig_status": status,
            "owner_report": owner_r,
            "locate_report": locate_r,
            "dual_report_files_present": dual_ok,
            "staging": staging,
            "results": str(rd),
        }
    )

live_untouched = None
live_check = "missing_after"
if before_p and after_p and Path(before_p).is_file() and Path(after_p).is_file():
    before = json.load(open(before_p, encoding="utf-8"))
    after = json.load(open(after_p, encoding="utf-8"))
    if before == after:
        live_untouched = True
        live_check = "before_after_equal"
    else:
        live_untouched = False
        live_check = "before_after_differ"
elif before_p and Path(before_p).is_file() and not after_p:
    live_check = "prepare_only"
elif before_p and not Path(before_p).is_file():
    live_check = "missing_before"
else:
    live_check = "missing_after"

manifest_path = base / "MANIFEST.json"
prepare_ok = None
prepare_fail = None
if manifest_path.is_file():
    try:
        man = json.load(open(manifest_path, encoding="utf-8"))
        prepare_ok = man.get("prepare_ok")
        prepare_fail = man.get("prepare_fail")
    except Exception:
        pass

ready_n = counts["READY_DIG"]
partial = ready_n > 0

obj = {
    "run": str(base),
    "run_id": run_id,
    "generator": "scripts/lab/summarize-round3.sh",
    "prepare_ok": prepare_ok,
    "prepare_fail": prepare_fail,
    "dig_status_counts": counts,
    "dual_report_files_present": dual_present,
    "mismatches": mismatches,
    "partial": partial,
    "lab_no_delete_static_scan": scan.get("lab_no_delete_static_scan"),
    "lab_no_delete_hits": scan.get("hits"),
    "lab_no_delete_method": scan.get("method"),
    "live_untouched": live_untouched,
    "live_check": live_check,
    "before_snap": before_p or None,
    "after_snap": after_p or None,
    "trials_order": "lexicographic_by_results_dirname",
    "trials": trials,
    "honesty": (
        "LAB_OK ≠ live mutated ≠ TIER0_OK ≠ 掃透 ≠ letter B; "
        "dig_status_counts/dual_report_files_present = filesystem scan ≠ true dig proof; "
        "lab_no_delete_static_scan ≠ runtime zero-delete"
    ),
    "pkg_root": str(pkg_root),
}

out_path.write_text(json.dumps(obj, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print(f"LAB_ROUND3_SUMMARY_OK path={out_path}")
if partial:
    print(f"LAB_ROUND3_SUMMARY_PARTIAL ready_dig={ready_n}", file=sys.stderr)
    sys.exit(2)
sys.exit(0)
PY
EC=$?
exit "$EC"
