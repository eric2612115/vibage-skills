#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/svc-a/.git" "$TMP/svc-b/.git"
bash "$ROOT/scripts/graph-floor.sh" "$TMP"
out="$(bash "$ROOT/scripts/verify-graph-floor.sh" "$TMP")"
[[ "$out" == "GRAPH_FLOOR_OK" ]]
python3 - <<PY
import json,sys
m=json.load(open("$TMP/docs/vibage/maps/service_map.json"))
assert m.get("discover_mode") in ("flat","nested")
assert len(m.get("repos") or [])>=2
PY
