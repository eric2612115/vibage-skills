#!/usr/bin/env bash
# Print Round-3 L1 dispatch index from a prepare MANIFEST / prompts dir.
# Does not delete. Does not launch agents (orchestrator / Cursor Task does).
# Usage: bash dispatch-round3-index.sh [/tmp/vibage-lab/<run>-round3]
set -euo pipefail
BASE="${1:-}"
if [[ -z "$BASE" ]]; then
  BASE="$(ls -dt /tmp/vibage-lab/*-round3 2>/dev/null | head -1 || true)"
fi
[[ -n "$BASE" && -d "$BASE/prompts" ]] || {
  echo "FAIL: no round3 prompts dir (pass prepare base)" >&2
  exit 1
}
BASE="$(cd "$BASE" && pwd)"
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "LAB_ROUND3_DISPATCH_INDEX base=$BASE"
set +e
SCAN_JSON="$(bash "$LAB_DIR/lab-no-delete-check.sh")"
set -e
export LAB_NO_DELETE_SCAN_JSON="$SCAN_JSON"
python3 - "$BASE" <<'PY'
import json, os, re, sys
from pathlib import Path
base = Path(sys.argv[1])
scan = json.loads(os.environ.get("LAB_NO_DELETE_SCAN_JSON") or "{}")
rows = []
for p in sorted((base / "prompts").glob("*.md")):
    t = p.read_text(encoding="utf-8", errors="replace")
    def g(k):
        m = re.search(rf"{k}=([^\s`]+)", t)
        return m.group(1) if m else ""
    dig = "UNKNOWN"
    res = Path(g("RESULTS_DIR"))
    if res.is_dir() and (res / "DIG_STATUS").is_file():
        dig = (res / "DIG_STATUS").read_text().strip()
    rows.append({
        "prompt": str(p),
        "name": p.stem,
        "model": g("MODEL"),
        "slot": g("SLOT"),
        "mother": g("MOTHER_NAME"),
        "staging": g("STAGING_PARENT"),
        "results": g("RESULTS_DIR"),
        "dig_status": dig,
        "cursor_model": "composer-2.5-fast" if g("MODEL") == "composer" else "cursor-grok-4.5-high-fast",
    })
out = base / "DISPATCH_INDEX.json"
json.dump(
    {
        "base": str(base),
        "trials": rows,
        "lab_no_delete_static_scan": scan.get("lab_no_delete_static_scan"),
        "lab_no_delete_hits": scan.get("hits"),
        "lab_no_delete_method": scan.get("method", "static_script_scan"),
    },
    open(out, "w", encoding="utf-8"),
    indent=2,
)
print(f"LAB_DISPATCH_INDEX {out} trials={len(rows)}")
ready = sum(1 for r in rows if r["dig_status"] == "READY_DIG")
done = sum(1 for r in rows if r["dig_status"] == "DONE")
skip = sum(1 for r in rows if r["dig_status"] == "SKIP_DIG")
print(f"LAB_DISPATCH_COUNTS ready={ready} done={done} skip={skip}")
PY
