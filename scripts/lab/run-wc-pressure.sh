#!/usr/bin/env bash
# Prepare / summarize work-continue pressure run (100 trials, batches of 10).
# LAB_NO_DELETE: never deletes staging or mother. Owner cleans /tmp later.
#
# Usage:
#   bash run-wc-pressure.sh prepare [--source=...] [--run-root=...] [--count=100]
#   bash run-wc-pressure.sh eval-batch --run-id=... --batch=0   # batch 0 = trials 1-10
#   bash run-wc-pressure.sh summarize --run-id=...
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_DEFAULT="$(cd "$LAB_DIR/../.." && pwd)"
export LAB_NO_DELETE=1

CMD="${1:-}"
shift || true

SOURCE="$PKG_DEFAULT"
RUN_ROOT="${VIBAGE_WC_PRESSURE_ROOT:-/tmp/vibage-wc-pressure}"
COUNT=100
BATCH_SIZE=10
RUN_ID=""
BATCH=0

for arg in "$@"; do
  case "$arg" in
    --source=*) SOURCE="${arg#*=}" ;;
    --run-root=*) RUN_ROOT="${arg#*=}" ;;
    --count=*) COUNT="${arg#*=}" ;;
    --run-id=*) RUN_ID="${arg#*=}" ;;
    --batch=*) BATCH="${arg#*=}" ;;
    --batch-size=*) BATCH_SIZE="${arg#*=}" ;;
    *) echo "FAIL: unknown arg: $arg" >&2; exit 1 ;;
  esac
done

CARDS=(
  01_script_green
  02_seed_red
  03_live_green
  04_hollow_red
  05_skill_d1
  06_exception_honesty
  07_adapter_routing
  08_firewall
  09_adversarial_dual_done
  10_resume_carveout
)

card_for() {
  local i="$1" # 1-based
  local idx=$(( (i - 1) % ${#CARDS[@]} ))
  echo "${CARDS[$idx]}"
}

echo "LAB_NO_DELETE=1 owner cleans /tmp later"

case "$CMD" in
  prepare)
    RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)-wc"
    BASE="$RUN_ROOT/$RUN_ID"
    mkdir -p "$BASE/trials" "$BASE/prompts" "$BASE/results"
    SOURCE="$(cd "$SOURCE" && pwd -P)"
    printf '%s\n' "$SOURCE" >"$BASE/MOTHER_SOURCE"
    printf '%s\n' "$(git -C "$SOURCE" rev-parse HEAD 2>/dev/null || echo unknown)" >"$BASE/MOTHER_HEAD"
    echo "WC_PREPARE_START base=$BASE count=$COUNT source=$SOURCE"

    for i in $(seq 1 "$COUNT"); do
      id="$(printf 't%03d' "$i")"
      trial="$BASE/trials/$id"
      pkg="$trial/pkg"
      card="$(card_for "$i")"
      mkdir -p "$pkg" "$trial/out"
      bash "$LAB_DIR/copy-pkg-sandbox.sh" --source="$SOURCE" --dest="$pkg"
      # ensure new lab helpers exist even if copy raced; re-sync scripts/lab thin
      rsync -a --safe-links --max-size=5m \
        "$SOURCE/scripts/lab/copy-pkg-sandbox.sh" \
        "$SOURCE/scripts/lab/eval-wc-card.sh" \
        "$pkg/scripts/lab/" 2>/dev/null || true
      chmod +x "$pkg/scripts/lab/copy-pkg-sandbox.sh" "$pkg/scripts/lab/eval-wc-card.sh" \
        "$pkg/scripts/verify-work-continue.sh" 2>/dev/null || true
      cat >"$BASE/prompts/$id.md" <<EOF
# Work-continue pressure trial $id

LAB_NO_DELETE=1. NEVER delete any files. NEVER write outside this trial directory.

- PKG_SANDBOX: \`$pkg\`
- TRIAL_DIR: \`$trial\`
- CARD: \`$card\`
- OUT: \`$trial/out/agent_result.json\`

## Required steps

1. cd only under TRIAL_DIR / PKG_SANDBOX.
2. Run:
   \`\`\`bash
   export WC_TRIAL_DIR="$trial"
   bash "$pkg/scripts/lab/eval-wc-card.sh" --pkg="$pkg" --card="$card" --out="$trial/out/eval_result.json"
   \`\`\`
3. Read \`eval_result.json\`. Independently sanity-check the card claim (false-green / D1).
4. Write \`agent_result.json\` with fields:
   \`verdict\` (PASS|FAIL|INCONCLUSIVE), \`card\`, \`agree_with_eval\` (bool), \`notes\` (array), \`sandbox_path\`.
5. Do not modify mother source. Do not delete staging.

Model: cursor-grok-4.5-high. Keep answer short.
EOF
      printf '%s\t%s\t%s\n' "$id" "$card" "$pkg" >>"$BASE/MANIFEST.tsv"
      echo "WC_TRIAL_READY $id card=$card"
    done

    echo "$RUN_ID" >"$RUN_ROOT/LATEST_RUN_ID"
    echo "WC_PREPARE_OK run_id=$RUN_ID base=$BASE"
    echo "LAB_KEEP base=$BASE"
    ;;

  eval-batch)
    [[ -n "$RUN_ID" ]] || { echo "FAIL: --run-id= required" >&2; exit 1; }
    BASE="$RUN_ROOT/$RUN_ID"
    [[ -d "$BASE/trials" ]] || { echo "FAIL: missing $BASE" >&2; exit 1; }
    start=$(( BATCH * BATCH_SIZE + 1 ))
    end=$(( start + BATCH_SIZE - 1 ))
    [[ "$end" -gt "$COUNT" ]] && end="$COUNT"
    echo "WC_EVAL_BATCH start=$start end=$end"
    pids=()
    for i in $(seq "$start" "$end"); do
      id="$(printf 't%03d' "$i")"
      trial="$BASE/trials/$id"
      pkg="$trial/pkg"
      card="$(card_for "$i")"
      (
        export WC_TRIAL_DIR="$trial"
        set +e
        bash "$pkg/scripts/lab/eval-wc-card.sh" --pkg="$pkg" --card="$card" --out="$trial/out/eval_result.json"
        ec=$?
        set -e
        cp -f "$trial/out/eval_result.json" "$BASE/results/$id.eval.json" 2>/dev/null || true
        echo "WC_EVAL_DONE $id ec=$ec"
      ) &
      pids+=("$!")
    done
    for pid in "${pids[@]}"; do
      wait "$pid" || true
    done
    echo "WC_EVAL_BATCH_OK batch=$BATCH"
    ;;

  summarize)
    [[ -n "$RUN_ID" ]] || RUN_ID="$(cat "$RUN_ROOT/LATEST_RUN_ID" 2>/dev/null || true)"
    [[ -n "$RUN_ID" ]] || { echo "FAIL: --run-id= or LATEST_RUN_ID required" >&2; exit 1; }
    BASE="$RUN_ROOT/$RUN_ID"
    python3 - "$BASE" <<'PY'
import json, sys
from pathlib import Path
from collections import Counter
base = Path(sys.argv[1])
pass_n = fail_n = inc_n = missing = 0
by_card = Counter()
rows = []
for p in sorted((base / "results").glob("*.eval.json")):
    try:
        o = json.loads(p.read_text(encoding="utf-8"))
    except Exception as e:
        missing += 1
        rows.append({"id": p.stem, "verdict": "INCONCLUSIVE", "error": str(e)})
        continue
    v = o.get("verdict", "INCONCLUSIVE")
    by_card[o.get("card", "?") + ":" + v] += 1
    if v == "PASS":
        pass_n += 1
    elif v == "FAIL":
        fail_n += 1
    else:
        inc_n += 1
    rows.append({"id": p.name.replace(".eval.json", ""), "verdict": v, "card": o.get("card"), "notes": o.get("notes", [])})

# also count agent_result if present
agent_pass = agent_fail = agent_inc = agent_missing = 0
for trial in sorted((base / "trials").glob("t*")):
    ar = trial / "out" / "agent_result.json"
    if not ar.is_file():
        agent_missing += 1
        continue
    try:
        o = json.loads(ar.read_text(encoding="utf-8"))
        v = o.get("verdict", "INCONCLUSIVE")
    except Exception:
        agent_inc += 1
        continue
    if v == "PASS":
        agent_pass += 1
    elif v == "FAIL":
        agent_fail += 1
    else:
        agent_inc += 1

summary = {
    "run_base": str(base),
    "eval": {"PASS": pass_n, "FAIL": fail_n, "INCONCLUSIVE": inc_n, "by_card": dict(by_card)},
    "agent": {"PASS": agent_pass, "FAIL": agent_fail, "INCONCLUSIVE": agent_inc, "missing": agent_missing},
    "lab_no_delete": True,
    "honesty": "PASS ≠ Proven-green; staging kept for owner cleanup",
    "rows": rows,
}
(base / "summary.json").write_text(json.dumps(summary, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
lines = [
    f"# Work-continue pressure REPORT",
    "",
    f"- base: `{base}`",
    f"- LAB_NO_DELETE: **true** (nothing deleted by harness)",
    f"- eval PASS/FAIL/INCONCLUSIVE: {pass_n}/{fail_n}/{inc_n}",
    f"- agent PASS/FAIL/INCONCLUSIVE/missing: {agent_pass}/{agent_fail}/{agent_inc}/{agent_missing}",
    "",
    "## By card (eval)",
]
for k, n in sorted(by_card.items()):
    lines.append(f"- {k}: {n}")
lines += ["", "## Failures / inconclusive (eval)", ""]
for r in rows:
    if r["verdict"] != "PASS":
        lines.append(f"- **{r['id']}** `{r.get('card')}` → {r['verdict']}: {r.get('notes')}")
lines += ["", "## Staging paths (kept)", "", f"- `{base}`", f"- trials under `{base / 'trials'}`", ""]
(base / "REPORT.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
print(json.dumps({"summary": str(base / "summary.json"), "report": str(base / "REPORT.md"), "eval": summary["eval"]}, ensure_ascii=False))
PY
    echo "LAB_KEEP base=$BASE"
    ;;

  *)
    echo "Usage: $0 prepare|eval-batch|summarize ..." >&2
    exit 2
    ;;
esac
