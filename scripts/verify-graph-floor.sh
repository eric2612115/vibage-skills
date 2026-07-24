#!/usr/bin/env bash
# Usage: verify-graph-floor.sh <workspace_root>
# Exit 0 and print exactly GRAPH_FLOOR_OK when service_map graph-floor fields are valid.
set -euo pipefail

WS="${1:-}"
if [[ -z "$WS" || ! -d "$WS" ]]; then
  echo "FAIL: Usage: $0 <workspace_root>" >&2
  exit 2
fi

MAP="$WS/docs/vibage/maps/service_map.json"

fail() { echo "FAIL: $*" >&2; exit 1; }

[[ -f "$MAP" ]] || fail "missing $MAP"

python3 - "$MAP" <<'PY'
import json, sys

map_path = sys.argv[1]

def die(msg: str) -> None:
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)

try:
    with open(map_path, encoding="utf-8") as f:
        obj = json.load(f)
except Exception as e:
    die(f"service_map.json unreadable: {e}")

if not isinstance(obj, dict):
    die("service_map.json must be a JSON object")

mode = obj.get("discover_mode")
if mode not in ("flat", "nested"):
    die(f"discover_mode must be flat|nested, got {mode!r}")

if "discover_max_depth" not in obj:
    die("discover_max_depth required")

repos = obj.get("repos")
if not isinstance(repos, list) or len(repos) < 1:
    die("repos must be a non-empty list")

sys.exit(0)
PY

echo "GRAPH_FLOOR_OK"
