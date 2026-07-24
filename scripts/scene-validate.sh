#!/usr/bin/env bash
# Usage: scene-validate.sh <workspace_root>
# Exit 0 when SCENES.json membership is legal (exclusive|shared; no illegal partial).
set -euo pipefail

fail() { echo "FAIL: $*" >&2; exit 1; }

WS="${1:-}"
if [[ -z "$WS" || ! -d "$WS" ]]; then
  echo "FAIL: Usage: $0 <workspace_root>" >&2
  exit 2
fi
WS="$(cd "$WS" && pwd)"

SCENES="$WS/docs/vibage/scenes/SCENES.json"
[[ -f "$SCENES" ]] || fail "missing $SCENES"

python3 - "$SCENES" <<'PY'
import json, sys
from collections import defaultdict

path = sys.argv[1]

def die(msg: str) -> None:
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)

try:
    raw = json.loads(open(path, encoding="utf-8").read())
except Exception as e:
    die(f"SCENES.json unreadable: {e}")

if isinstance(raw, list):
    scenes = raw
elif isinstance(raw, dict):
    scenes = raw.get("scenes")
    if scenes is None:
        die("SCENES.json must be a list or {scenes:[...]}")
else:
    die("SCENES.json must be a list or object")

if not isinstance(scenes, list) or len(scenes) < 1:
    die("scenes must be a non-empty list")

n = len(scenes)
repo_scenes = defaultdict(set)

for i, sc in enumerate(scenes):
    if not isinstance(sc, dict):
        die(f"scenes[{i}] must be an object")
    sid = sc.get("scene_id")
    if not isinstance(sid, str) or not sid.strip():
        die(f"scenes[{i}].scene_id required")
    if "keywords" not in sc:
        die(f"scenes[{i}].keywords[] required (may be empty)")
    kws = sc.get("keywords")
    if not isinstance(kws, list):
        die(f"scenes[{i}].keywords must be a list")
    repos = sc.get("repo_ids")
    if not isinstance(repos, list):
        die(f"scenes[{i}].repo_ids must be a list")
    for rid in repos:
        if not isinstance(rid, str) or not rid.strip():
            die(f"scenes[{i}].repo_ids entries must be non-empty strings")
        repo_scenes[rid.strip()].add(sid.strip())

illegal = []
for rid, homes in sorted(repo_scenes.items()):
    count = len(homes)
    if count == 1:
        continue  # exclusive
    if count == n:
        continue  # shared
    # listed in some but not all when ≥2 scenes
    if n >= 2:
        illegal.append(f"{rid} in {sorted(homes)} (not exclusive and not shared)")

if illegal:
    die("illegal membership: " + "; ".join(illegal))

print("OK: scene membership legal")
sys.exit(0)
PY
