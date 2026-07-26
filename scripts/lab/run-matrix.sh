#!/usr/bin/env bash
# Round-1/2 script matrix over named allowlisted mothers + fixtures.
# Host only. LAB_NO_DELETE — never deletes staging.
# Usage:
#   bash run-matrix.sh
#   bash run-matrix.sh --fixtures-only
#   bash run-matrix.sh --parallel=2
#   bash run-matrix.sh --round=2
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=allowlist.sh
source "$LAB_DIR/allowlist.sh"

export LAB_NO_DELETE=1

FIXTURES_ONLY=0
PARALLEL=2
ROUND="1"
RUN_ROOT="${VIBAGE_LAB_ROOT:-/tmp/vibage-lab}"

for arg in "$@"; do
  case "$arg" in
    --fixtures-only) FIXTURES_ONLY=1 ;;
    --parallel=*) PARALLEL="${arg#*=}" ;;
    --run-root=*) RUN_ROOT="${arg#*=}" ;;
    --round=*) ROUND="${arg#*=}" ;;
    --mode=*)
      echo "FAIL: Docker mode removed (LAB_NO_DELETE). Host staging only." >&2
      exit 1
      ;;
    *) echo "FAIL: unknown arg: $arg" >&2; exit 1 ;;
  esac
done

RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)-round${ROUND}"
MATRIX_ROOT="$RUN_ROOT/$RUN_ID"
mkdir -p "$MATRIX_ROOT/matrix-logs" "$RUN_ROOT/results"

JOBS=()
enqueue() { JOBS+=("$*"); }

enqueue bash "$LAB_DIR/run-trial.sh" --fixture=synthetic-parent --model=script --slot=r"${ROUND}" --run-root="$MATRIX_ROOT"
enqueue bash "$LAB_DIR/run-trial.sh" --fixture=defi_strategy_like --model=script --slot=r"${ROUND}" --run-root="$MATRIX_ROOT"
enqueue bash "$LAB_DIR/run-trial.sh" --fixture=friend-chaos --model=script --slot=r"${ROUND}" --run-root="$MATRIX_ROOT"

if [[ "$FIXTURES_ONLY" -eq 0 ]]; then
  while IFS= read -r m; do
    [[ -n "$m" ]] || continue
    enqueue bash "$LAB_DIR/run-trial.sh" --source="$m" --model=script --slot=r"${ROUND}" --run-root="$MATRIX_ROOT"
  done < <(lab_list_named_mothers)
fi

echo "LAB_MATRIX_START round=$ROUND jobs=${#JOBS[@]} parallel=$PARALLEL root=$MATRIX_ROOT"
echo "LAB_NO_DELETE=1 owner cleans /tmp later"
echo "Honesty: no HOME scan; named mothers only"

fail_n=0
ok_n=0
i=0
pids=()

run_one() {
  local cmd="$1" log="$2"
  # shellcheck disable=SC2086
  if eval "$cmd" >"$log" 2>&1; then
    echo "OK  $cmd"
    return 0
  fi
  echo "FAIL $cmd (log=$log)" >&2
  return 1
}

for cmd in "${JOBS[@]}"; do
  i=$((i + 1))
  log="$MATRIX_ROOT/matrix-logs/job-$i.log"
  run_one "$cmd" "$log" &
  pids+=("$!")
  while [[ "$(jobs -rp | wc -l | tr -d ' ')" -ge "$PARALLEL" ]]; do
    sleep 1
  done
done

for pid in "${pids[@]}"; do
  if wait "$pid"; then
    ok_n=$((ok_n + 1))
  else
    fail_n=$((fail_n + 1))
  fi
done

# Aggregate index (no deletes)
INDEX="$RUN_ROOT/results/MATRIX-$RUN_ID.json"
set +e
SCAN_JSON="$(bash "$LAB_DIR/lab-no-delete-check.sh")"
set -e
export LAB_NO_DELETE_SCAN_JSON="$SCAN_JSON"
python3 - "$INDEX" "$MATRIX_ROOT" "$ok_n" "$fail_n" "$ROUND" <<'PY'
import json, sys, os, glob
path, root, ok, fail, round_ = sys.argv[1:6]
boards = sorted(glob.glob(os.path.join(root, "results", "*", "SCOREBOARD.json")))
rows = []
for b in boards:
    try:
        rows.append(json.load(open(b, encoding="utf-8")))
    except Exception as e:
        rows.append({"error": str(e), "path": b})
scan = json.loads(os.environ.get("LAB_NO_DELETE_SCAN_JSON") or "{}")
obj = {
    "round": round_,
    "matrix_root": root,
    "ok": int(ok),
    "fail": int(fail),
    "scoreboards": rows,
    "honesty": "LAB_OK ≠ live mutated ≠ TIER0_OK ≠ full-sweep ≠ letter B",
    "lab_no_delete_static_scan": scan.get("lab_no_delete_static_scan"),
    "lab_no_delete_hits": scan.get("hits"),
    "lab_no_delete_method": scan.get("method", "static_script_scan"),
}
os.makedirs(os.path.dirname(path), exist_ok=True)
json.dump(obj, open(path, "w", encoding="utf-8"), indent=2)
print("LAB_MATRIX_INDEX", path)
PY

echo "LAB_MATRIX_DONE ok=$ok_n fail=$fail_n index=$INDEX"
echo "LAB_KEEP matrix_root=$MATRIX_ROOT"
[[ "$fail_n" -eq 0 ]]
