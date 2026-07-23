#!/usr/bin/env bash
# Usage: verify-service-map.sh <workspace_root>
# Exit 0 only if docs/vibage/maps/service_map.json passes the B2 floor schema.
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

# Floor schema only — unknown/extra keys must NOT fail.
sv = obj.get("schema_version")
if not isinstance(sv, str) or not sv.strip():
    die("schema_version must be a non-empty string")

pid = obj.get("pipeline_id")
if pid != "service_map":
    die(f'pipeline_id must be exactly "service_map", got {pid!r}')

scale = obj.get("scale")
if scale not in ("Tiny", "Subset", "Large"):
    die(f"scale must be Tiny|Subset|Large, got {scale!r}")

qb = obj.get("quality_bar")
if qb != "MEDIUM":
    die(f'quality_bar must be exactly "MEDIUM", got {qb!r}')

services = obj.get("services")
if not isinstance(services, list) or len(services) < 1:
    die("services must be a non-empty list")

for i, item in enumerate(services):
    if not isinstance(item, dict):
        die(f"services[{i}] must be an object")
    sid = item.get("id")
    if not isinstance(sid, str) or not sid.strip():
        die(f"services[{i}].id must be a non-empty string")

depth = obj.get("depth", None)
if depth is not None and not isinstance(depth, str):
    die("depth must be a string when present")

service_ids = {
    item["id"].strip()
    for item in services
    if isinstance(item, dict)
    and isinstance(item.get("id"), str)
    and item["id"].strip()
}

if depth == "standard":
    edges = obj.get("edges")
    if not isinstance(edges, list) or len(edges) < 1:
        die('depth="standard" requires non-empty edges array')
    for i, edge in enumerate(edges):
        if not isinstance(edge, dict):
            die(f"edges[{i}] must be an object")
        frm = edge.get("from")
        to = edge.get("to")
        if not isinstance(frm, str) or not frm.strip():
            die(f"edges[{i}].from must be a non-empty string")
        if not isinstance(to, str) or not to.strip():
            die(f"edges[{i}].to must be a non-empty string")
        if frm not in service_ids:
            die(f"edges[{i}].from {frm!r} not in services[].id")
        if to not in service_ids:
            die(f"edges[{i}].to {to!r} not in services[].id")
    print("OK: depth=standard edges valid")
# else: non-standard / absent depth → do NOT validate edges (even if present)

print("OK: service_map.json present")
print("OK: pipeline_id=service_map")
print("OK: quality_bar=MEDIUM")
print(f"OK: scale={scale}")
print(f"OK: services count={len(services)}")
print("OK: map qualification gates pass")
sys.exit(0)
PY
