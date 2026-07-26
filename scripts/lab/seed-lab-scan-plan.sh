#!/usr/bin/env bash
# Ensure staging SCAN_PLAN has planned_dig_ids capped for lab dig.
# Usage: bash seed-lab-scan-plan.sh <STAGING_PARENT> <max_ids>
set -euo pipefail
WS="${1:-}"
MAX="${2:-3}"
[[ -n "$WS" && -d "$WS" ]] || { echo "Usage: $0 <STAGING_PARENT> [max_ids]" >&2; exit 2; }
WS="$(cd "$WS" && pwd -P)"
LAB_ROOT_RAW="${VIBAGE_LAB_ROOT:-/tmp/vibage-lab}"
mkdir -p "$LAB_ROOT_RAW"
LAB_ROOT="$(cd "$LAB_ROOT_RAW" && pwd -P)"
case "$WS" in
  "$LAB_ROOT"|"$LAB_ROOT"/*) ;;
  *) echo "FAIL: staging must be under lab root $LAB_ROOT" >&2; exit 1 ;;
esac

MAP="$WS/docs/vibage/maps/service_map.json"
PLAN="$WS/docs/vibage/SCAN_PLAN.md"
mkdir -p "$(dirname "$PLAN")"
if [[ ! -f "$MAP" ]]; then
  # Empty mothers (0 git children) — honest skip dig, still leave a plan fence.
  python3 - "$PLAN" "$MAX" <<'PY'
import json, sys, pathlib
plan_path, max_ids = sys.argv[1], int(sys.argv[2])
obj = {
    "schema_version": "1",
    "root_refs": [],
    "budgets": {"max_wall_min": 5, "max_files": 5, "max_depth": 1},
    "hot_path_ids": [],
    "known_incompleteness": "lab empty mother — no service_map; SKIP dig",
    "planned_dig_ids": [],
}
body = (
    "# SCAN_PLAN (lab-seeded empty)\n\n"
    "```json scan_plan_v1\n"
    + json.dumps(obj, indent=2, ensure_ascii=False)
    + "\n```\n"
)
pathlib.Path(plan_path).write_text(body, encoding="utf-8")
print("LAB_SCAN_PLAN_SEEDED_EMPTY", plan_path)
PY
  exit 0
fi

python3 - "$MAP" "$PLAN" "$MAX" "$WS" <<'PY'
import json, sys, pathlib
map_path, plan_path, max_ids, ws = sys.argv[1], sys.argv[2], int(sys.argv[3]), sys.argv[4]
data = json.load(open(map_path, encoding="utf-8"))
services = data.get("services") or data.get("nodes") or []
ids = []
for s in services:
    if isinstance(s, dict):
        sid = s.get("id") or s.get("service_id") or s.get("name")
        if sid:
            ids.append(str(sid))
    if len(ids) >= max_ids:
        break
if not ids:
    # fallback: one-level child dir names with .git
    root = pathlib.Path(ws)
    for p in sorted(root.iterdir()):
        if p.is_dir() and (p / ".git").exists():
            ids.append(p.name)
        if len(ids) >= max_ids:
            break
if not ids:
    ids = ["lab-placeholder"]
ids = ids[:max_ids]
root_refs = [{"id": i, "path": i} for i in ids]
obj = {
    "schema_version": "1",
    "root_refs": root_refs,
    "budgets": {"max_wall_min": 25, "max_files": 40, "max_depth": 3},
    "hot_path_ids": list(ids),
    "known_incompleteness": "lab seed — dig ⊆ planned_dig_ids only; ≠ full-sweep",
    "planned_dig_ids": ids,
}
fence = json.dumps(obj, indent=2, ensure_ascii=False)
body = f"# SCAN_PLAN (lab-seeded)\n\n```json scan_plan_v1\n{fence}\n```\n"
pathlib.Path(plan_path).write_text(body, encoding="utf-8")
print("LAB_SCAN_PLAN_SEEDED", plan_path, "ids=", ids)
PY
