#!/usr/bin/env bash
# Usage: verify-scene-cover.sh <workspace_root>
# Exit 0 iff stereoscopic cover claim holds (§2.10).
# Not a STATUS capability token — exit code only (optional OK line on stdout).
set -euo pipefail

PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

fail() { echo "FAIL: $*" >&2; exit 1; }

WS="${1:-}"
if [[ -z "$WS" || ! -d "$WS" ]]; then
  echo "FAIL: Usage: $0 <workspace_root>" >&2
  exit 2
fi
WS="$(cd "$WS" && pwd)"

# SCENE_BRIEF_OK required
sout="$(bash "$PKG_ROOT/scripts/verify-scene-brief.sh" "$WS")" || fail "SCENE_BRIEF_OK required for cover"
[[ "$sout" == "SCENE_BRIEF_OK" ]] || fail "expected SCENE_BRIEF_OK, got: $sout"

python3 - "$WS" <<'PY'
import json, re, sys
from collections import defaultdict
from pathlib import Path

ws = Path(sys.argv[1]).resolve()

def die(msg: str) -> None:
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)

def load_scenes(path: Path):
    raw = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(raw, list):
        return raw
    if isinstance(raw, dict):
        return raw.get("scenes") or []
    die("SCENES.json invalid")

def parse_status_key(text: str, key: str):
    m = re.search(rf"^{re.escape(key)}:\s*(.*)$", text, flags=re.M)
    if not m:
        return None
    return m.group(1).strip()

def edge_id(e: dict) -> str:
    if isinstance(e.get("id"), str) and e["id"].strip():
        return e["id"].strip()
    return f"{e['from']}->{e['to']}"

def truthy(v) -> bool:
    if v is True:
        return True
    if isinstance(v, str) and v.strip().lower() in ("true", "yes", "1"):
        return True
    return False

scenes_path = ws / "docs/vibage/scenes/SCENES.json"
waivers_path = ws / "docs/vibage/scenes/WAIVERS.json"
map_path = ws / "docs/vibage/maps/service_map.json"
status_path = ws / "docs/vibage/STATUS.md"
claims_path = ws / "docs/vibage/ledger/claims.jsonl"

scenes = load_scenes(scenes_path)
n_scenes = len(scenes)
waivers = {}
if waivers_path.is_file():
    try:
        waivers = json.loads(waivers_path.read_text(encoding="utf-8"))
        if not isinstance(waivers, dict):
            waivers = {}
    except Exception:
        waivers = {}

single_waiver = truthy(waivers.get("single_scene_waiver"))
isolation_waiver = truthy(waivers.get("isolation_waiver"))

if n_scenes < 2 and not single_waiver:
    die("cover requires ≥2 scenes or valid single_scene_waiver")

status_text = status_path.read_text(encoding="utf-8")
active_scene = parse_status_key(status_text, "active_scene") or ""
if not active_scene:
    die("STATUS.active_scene required")

# If only one scene with waiver, cover holds after SCENE_BRIEF_OK
if n_scenes < 2:
    sys.exit(0)

if isolation_waiver:
    # ≥2 scenes + isolation_waiver: cover OK without cross exclusive edges
    sys.exit(0)

by_id = {sc["scene_id"].strip(): sc for sc in scenes if isinstance(sc, dict) and sc.get("scene_id")}
repo_scenes = defaultdict(set)
for sc in scenes:
    sid = sc["scene_id"].strip()
    for rid in sc.get("repo_ids") or []:
        if isinstance(rid, str) and rid.strip():
            repo_scenes[rid.strip()].add(sid)

exclusive = defaultdict(set)
shared = set()
for rid, homes in repo_scenes.items():
    if len(homes) == 1:
        exclusive[next(iter(homes))].add(rid)
    elif len(homes) == n_scenes:
        shared.add(rid)

home_of = {}
for sid, repos in exclusive.items():
    for rid in repos:
        home_of[rid] = sid

try:
    smap = json.loads(map_path.read_text(encoding="utf-8"))
except Exception as e:
    die(f"service_map.json unreadable: {e}")

edges = smap.get("edges") or []
if not isinstance(edges, list):
    edges = []

# ≥1 cross_scene_edge: both ends exclusive, different home scenes
cross = []
for e in edges:
    if not isinstance(e, dict):
        continue
    a, b = e.get("from"), e.get("to")
    if not isinstance(a, str) or not isinstance(b, str):
        continue
    a, b = a.strip(), b.strip()
    if a in shared or b in shared:
        continue  # shared hubs never satisfy cover cross requirement alone
    ha, hb = home_of.get(a), home_of.get(b)
    if ha and hb and ha != hb:
        cross.append(edge_id(e))

if not cross:
    die(
        "cover requires ≥1 exclusive↔exclusive cross_scene_edge "
        "(shared-only edges insufficient; no isolation_waiver)"
    )

# ≥1 terminal scene_bridge on a required_bridges entry for active scene
e_active = set(exclusive.get(active_scene, set()))
other_excl = set()
for sid, repos in exclusive.items():
    if sid != active_scene:
        other_excl |= repos
bridge_targets = other_excl | shared

required_ids = []
for e in edges:
    if not isinstance(e, dict):
        continue
    a, b = e.get("from"), e.get("to")
    if not isinstance(a, str) or not isinstance(b, str):
        continue
    a, b = a.strip(), b.strip()
    if (a in e_active and b in bridge_targets) or (b in e_active and a in bridge_targets):
        eid = edge_id(e)
        if eid not in required_ids:
            required_ids.append(eid)

if not required_ids:
    die("cover requires ≥1 required_bridges entry for active scene")

latest = {}
if claims_path.is_file():
    for line in claims_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            claim = json.loads(line)
        except json.JSONDecodeError:
            continue
        if not isinstance(claim, dict):
            continue
        if claim.get("claim_class") != "scene_bridge":
            continue
        if claim.get("scene_id") and claim.get("scene_id") != active_scene:
            continue
        sid = claim.get("subject_id")
        if sid:
            latest[str(sid)] = claim

terminal_ok = False
for eid in required_ids:
    c = latest.get(eid)
    if c and c.get("state") in ("proven", "failed"):
        terminal_ok = True
        break

if not terminal_ok:
    die("cover requires ≥1 terminal scene_bridge on required_bridges")

sys.exit(0)
PY
