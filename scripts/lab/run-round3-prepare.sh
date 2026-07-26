#!/usr/bin/env bash
# Round 3 prepare: for each named mother × (composer|grok) × (a|b),
# create independent staging, continuum, seed SCAN_PLAN, mint lab CONFIRM.
# Does NOT launch Cursor agents and does NOT delete anything.
# Usage:
#   bash run-round3-prepare.sh
#   bash run-round3-prepare.sh --mothers=MindOwnBuz,LangSight   # smoke subset
#   bash run-round3-prepare.sh --parallel=2
set -euo pipefail
# Job control needed so `jobs -rp` throttles under nohup/non-interactive.
set -m
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_ROOT="$(cd "$LAB_DIR/../.." && pwd)"
# shellcheck source=allowlist.sh
source "$LAB_DIR/allowlist.sh"

export LAB_NO_DELETE=1
RUN_ROOT="${VIBAGE_LAB_ROOT:-/tmp/vibage-lab}"
PARALLEL=2
MOTHER_FILTER=""

for arg in "$@"; do
  case "$arg" in
    --parallel=*) PARALLEL="${arg#*=}" ;;
    --run-root=*) RUN_ROOT="${arg#*=}" ;;
    --mothers=*) MOTHER_FILTER="${arg#*=}" ;;
    *) echo "FAIL: unknown arg $arg" >&2; exit 1 ;;
  esac
done

RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)-round3"
BASE="$RUN_ROOT/$RUN_ID"
mkdir -p "$BASE/prompts" "$BASE/prepare-logs" "$RUN_ROOT/results" "$RUN_ROOT/live-snapshots"
SNAP="$RUN_ROOT/live-snapshots/before-$RUN_ID.json"
bash "$LAB_DIR/assert-live-untouched.sh" --snapshot="$SNAP"

MODELS=(composer grok)
SLOTS=(a b)

mothers=()
while IFS= read -r m; do
  [[ -n "$m" ]] || continue
  base="$(basename "$m")"
  if [[ -n "$MOTHER_FILTER" ]]; then
    IFS=',' read -r -a want <<<"$MOTHER_FILTER"
    hit=0
    for w in "${want[@]}"; do
      [[ "$base" == "$w" || "$m" == "$w" ]] && hit=1 && break
    done
    [[ "$hit" -eq 1 ]] || continue
  fi
  mothers+=("$m")
done < <(lab_list_named_mothers)

# Termmax last
sorted=()
for m in "${mothers[@]}"; do
  [[ "$(basename "$m")" == "Termmax" ]] && continue
  sorted+=("$m")
done
for m in "${mothers[@]}"; do
  [[ "$(basename "$m")" == "Termmax" ]] && sorted+=("$m")
done
mothers=("${sorted[@]}")

echo "LAB_ROUND3_PREPARE_START mothers=${#mothers[@]} run=$BASE"
echo "LAB_NO_DELETE=1"

JOBS=()
enqueue() { JOBS+=("$*"); }

for m in "${mothers[@]}"; do
  name="$(basename "$m")"
  max_dig=3
  [[ "$name" == "Termmax" ]] && max_dig=2
  for model in "${MODELS[@]}"; do
    for slot in "${SLOTS[@]}"; do
      enqueue "$m" "$name" "$model" "$slot" "$max_dig"
    done
  done
done

prepare_one() {
  local live="$1" name="$2" model="$3" slot="$4" max_dig="$5"
  local trial="$BASE/${name}-${model}-${slot}"
  local parent="$trial/parent"
  local out="$trial/out"
  local results="$RUN_ROOT/results/$RUN_ID-${name}-${model}-${slot}"
  local log="$BASE/prepare-logs/${name}-${model}-${slot}.log"
  mkdir -p "$parent" "$out" "$results"
  {
    echo "PREPARE $name $model $slot"
    bash "$LAB_DIR/copy-parent.sh" --source="$live" --dest="$parent"
    # Write gate: staging must be under lab root
    bash "$LAB_DIR/assert-write-gate.sh" "$parent"
    export HOME="$out/fake-home"
    mkdir -p "$HOME"
    bash "$LAB_DIR/continuum.sh" "$parent" "$PKG_ROOT" "$out" || true
    seed_out="$(bash "$LAB_DIR/seed-lab-scan-plan.sh" "$parent" "$max_dig")"
    echo "$seed_out"
    if echo "$seed_out" | grep -Fq 'LAB_SCAN_PLAN_SEEDED_EMPTY' \
      || grep -Eq '"planned_dig_ids"[[:space:]]*:[[:space:]]*\[\s*\]' "$parent/docs/vibage/SCAN_PLAN.md" 2>/dev/null; then
      echo "LAB_PREPARE_SKIP_DIG empty_or_no_ids mother=$name"
      printf 'SKIP_DIG\n' >"$results/DIG_STATUS"
    else
      bash "$LAB_DIR/mint-lab-confirm.sh" "$parent" "lab-${model}-${slot}" || {
        echo "NOTE: confirm mint deferred — SCAN_PLAN/assert may need agent orient"
      }
      printf 'READY_DIG\n' >"$results/DIG_STATUS"
    fi
    bash "$LAB_DIR/assert-write-gate.sh" "$parent/docs/vibage" --staging="$parent"
    printf '%s\n' "$parent" >"$results/STAGING_PARENT"
    printf '%s\n' "$trial" >"$results/TRIAL_ROOT"
    [[ -f "$out/SCOREBOARD.json" ]] && cp -f "$out/SCOREBOARD.json" "$results/SCOREBOARD.json"
    # Filled L1 prompt
    local prompt="$BASE/prompts/${name}-${model}-${slot}.md"
    sed \
      -e "s|{{STAGING_PARENT}}|$parent|g" \
      -e "s|{{MODEL}}|$model|g" \
      -e "s|{{SLOT}}|$slot|g" \
      -e "s|{{MOTHER_NAME}}|$name|g" \
      -e "s|{{PKG_ROOT}}|$PKG_ROOT|g" \
      -e "s|{{RESULTS_DIR}}|$results|g" \
      -e "s|{{MAX_DIG_IDS}}|$max_dig|g" \
      -e "s|{{FAKE_HOME}}|$out/fake-home|g" \
      -e "s|{{OUT_DIR}}|$out|g" \
      "$LAB_DIR/L1_PROMPT_TEMPLATE.md" >"$prompt"
    echo "LAB_PROMPT $prompt"
    echo "STAGING_PARENT=$parent"
  } >"$log" 2>&1
}

fail_n=0
ok_n=0
batch=()
flush_batch() {
  local pid
  for pid in "${batch[@]+"${batch[@]}"}"; do
    if wait "$pid"; then ok_n=$((ok_n + 1)); else fail_n=$((fail_n + 1)); fi
  done
  batch=()
}
for spec in "${JOBS[@]}"; do
  # shellcheck disable=SC2086
  set -- $spec
  prepare_one "$@" &
  batch+=("$!")
  if [[ "${#batch[@]}" -ge "$PARALLEL" ]]; then
    flush_batch
  fi
done
flush_batch

MANIFEST="$BASE/MANIFEST.json"
set +e
SCAN_JSON="$(bash "$LAB_DIR/lab-no-delete-check.sh")"
set -e
export LAB_NO_DELETE_SCAN_JSON="$SCAN_JSON"
python3 - "$MANIFEST" "$BASE" "$RUN_ID" "$ok_n" "$fail_n" "$SNAP" <<'PY'
import json, sys, os, glob
path, base, run_id, ok, fail, snap = sys.argv[1:7]
prompts = sorted(glob.glob(os.path.join(base, "prompts", "*.md")))
run_root = os.path.dirname(base)
results = sorted(glob.glob(os.path.join(run_root, "results", f"{run_id}-*", "STAGING_PARENT")))
rows = []
for sp in results:
    staging = open(sp, encoding="utf-8").read().strip()
    trial = open(os.path.join(os.path.dirname(sp), "TRIAL_ROOT"), encoding="utf-8").read().strip()
    rows.append({"staging": staging, "trial": trial, "results_dir": os.path.dirname(sp)})
scan = json.loads(os.environ.get("LAB_NO_DELETE_SCAN_JSON") or "{}")
obj = {
    "run_id": run_id,
    "base": base,
    "prepare_ok": int(ok),
    "prepare_fail": int(fail),
    "prompts": prompts,
    "trials": rows,
    "before_snap": snap,
    "next": (
        "Dispatch one L1 Cursor agent per prompts/*.md; workspace=STAGING_PARENT; "
        "then bash scripts/lab/finalize-round3.sh --base=<this_base> --before=<before_snap>. "
        "Prepare live check ≠ dig-after live proof."
    ),
    "lab_no_delete_static_scan": scan.get("lab_no_delete_static_scan"),
    "lab_no_delete_hits": scan.get("hits"),
    "lab_no_delete_method": scan.get("method", "static_script_scan"),
    "live_check_note": "prepare_only — run finalize-round3.sh after digs for after snap",
}
json.dump(obj, open(path, "w", encoding="utf-8"), indent=2)
print("LAB_ROUND3_MANIFEST", path)
PY

bash "$LAB_DIR/assert-live-untouched.sh" --check="$SNAP"
echo "LAB_ROUND3_PREPARE_DONE ok=$ok_n fail=$fail_n base=$BASE"
echo "LAB_ROUND3_PREPARE_LIVE_CHECK=prepare_only (dig-after requires finalize-round3.sh)"
echo "Dispatch L1 agents using $BASE/prompts/*.md — do not delete staging"
echo "After digs: bash $LAB_DIR/finalize-round3.sh --base=$BASE --before=$SNAP"
[[ "$fail_n" -eq 0 ]]
