#!/usr/bin/env bash
# Usage: write_confirm.sh <workspace_root> [confirmed_by]
set -euo pipefail
WS="${1:-}"
BY="${2:-owner}"
[[ -n "$WS" && -d "$WS" ]] || { echo "Usage: $0 <workspace_root> [confirmed_by]" >&2; exit 2; }
HUB="$WS/docs/vibage"
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLAN="$HUB/SCAN_PLAN.md"
[[ -f "$PLAN" ]] || { echo "missing $PLAN" >&2; exit 1; }
mkdir -p "$HUB"
HASH="$("$PKG_ROOT/scripts/lib/scan_plan_hash.py" "$PLAN")"
python3 - "$HUB/CONFIRM.json" "$HASH" "$BY" <<'PY'
import json, sys, datetime
path, h, by = sys.argv[1], sys.argv[2], sys.argv[3]
obj = {
    "schema_version": "1",
    "confirm_kind": "scan_plan",
    "subject_ref": "docs/vibage/SCAN_PLAN.md",
    "payload_hash": h,
    "hash_alg": "sha256",
    "timestamp": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "confirmed_by": by,
}
with open(path, "w", encoding="utf-8") as f:
    json.dump(obj, f, indent=2)
    f.write("\n")
print("WROTE", path)
PY
