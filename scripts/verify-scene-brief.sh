#!/usr/bin/env bash
# Usage: verify-scene-brief.sh <workspace_root>
# Exit 0 and print SCENE_BRIEF_OK when §2.10.7 checklist holds.
# Matrix files are ignored (absent still OK). Invokes scene-validate.
set -euo pipefail

PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

fail() { echo "FAIL: $*" >&2; exit 1; }

WS="${1:-}"
if [[ -z "$WS" || ! -d "$WS" ]]; then
  echo "FAIL: Usage: $0 <workspace_root>" >&2
  exit 2
fi
WS="$(cd "$WS" && pwd)"

bash "$PKG_ROOT/scripts/scene-validate.sh" "$WS" >/dev/null \
  || fail "scene-validate failed"

python3 - "$WS" "$PKG_ROOT" <<'PY'
import json, re, subprocess, sys
from collections import defaultdict
from pathlib import Path

ws = Path(sys.argv[1]).resolve()
pkg_root = Path(sys.argv[2]).resolve()

def die(msg: str) -> None:
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)

scenes_path = ws / "docs/vibage/scenes/SCENES.json"
map_path = ws / "docs/vibage/maps/service_map.json"
status_path = ws / "docs/vibage/STATUS.md"
claims_path = ws / "docs/vibage/ledger/claims.jsonl"
briefs_dir = ws / "docs/vibage/briefs"

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

if not status_path.is_file():
    die("missing hub STATUS.md")
status_text = status_path.read_text(encoding="utf-8")
active_scene = parse_status_key(status_text, "active_scene") or ""
if not active_scene:
    die("STATUS.active_scene required")

draft = (parse_status_key(status_text, "scenes_draft") or "false").lower()
if draft in ("true", "yes", "1"):
    die("scenes_draft=true — SCENE_BRIEF_OK false until owner accepts scenes")

scenes = load_scenes(scenes_path)
by_id = {sc["scene_id"].strip(): sc for sc in scenes if isinstance(sc, dict) and sc.get("scene_id")}
if active_scene not in by_id:
    die(f"active_scene {active_scene!r} not in SCENES.json")

brief_path = briefs_dir / f"{active_scene}.md"
if not brief_path.is_file():
    die(f"missing brief {brief_path}")

# Budget + usable via verify-brief
r = subprocess.run(
    ["bash", str(pkg_root / "scripts/verify-brief.sh"), str(ws), active_scene],
    capture_output=True,
    text=True,
)
if r.returncode != 0 or "BRIEF_USABLE_OK" not in (r.stdout or ""):
    die(f"BRIEF_USABLE_OK required: {r.stderr or r.stdout}")

brief_text = brief_path.read_text(encoding="utf-8")
# Reject stale-marked brief as active
if re.search(r"(?im)^(stale|invalidated)\s*:\s*true\s*$", brief_text):
    die("active brief is marked stale/invalidated")

# brief.scene_id == STATUS.active_scene
m = re.search(r"(?im)^scene_id:\s*(\S+)\s*$", brief_text)
if not m:
    die("brief missing scene_id header")
if m.group(1).strip() != active_scene:
    die(f"brief.scene_id={m.group(1)!r} != STATUS.active_scene={active_scene!r}")

try:
    smap = json.loads(map_path.read_text(encoding="utf-8"))
except Exception as e:
    die(f"service_map.json unreadable: {e}")

graph_repos = set()
for r0 in (smap.get("repos") or []) + (smap.get("services") or []):
    if isinstance(r0, dict):
        rid = r0.get("id") or r0.get("repo_id")
        if isinstance(rid, str) and rid.strip():
            graph_repos.add(rid.strip())

active = by_id[active_scene]
scene_repos = []
for rid in active.get("repo_ids") or []:
    if isinstance(rid, str) and rid.strip():
        scene_repos.append(rid.strip())

# repos ⊆ graph
missing_repos = [r for r in scene_repos if r not in graph_repos]
if missing_repos:
    die(f"scene repos not in graph: {missing_repos}")

edges = smap.get("edges") or []
if not isinstance(edges, list):
    edges = []
edge_by_id = {}
for e in edges:
    if isinstance(e, dict) and e.get("from") and e.get("to"):
        edge_by_id[edge_id(e)] = e

# hot edges terminal = each hot_edge_id resolves to an existing graph edge
for hid in active.get("hot_edge_ids") or []:
    if not isinstance(hid, str) or not hid.strip():
        continue
    hid = hid.strip()
    if hid not in edge_by_id:
        die(f"hot edge not terminal/present in graph: {hid}")

# Membership sets
n_scenes = len(by_id)
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

# Bridges listed in brief == required
listed = set(re.findall(r"([A-Za-z0-9._-]+->[A-Za-z0-9._-]+)", brief_text))
# Restrict comparison to bridges section when possible
br_sec = re.search(
    r"(?ims)^## Bridges.*?(?=^## |\Z)",
    brief_text,
)
if br_sec:
    listed = set(re.findall(r"([A-Za-z0-9._-]+->[A-Za-z0-9._-]+)", br_sec.group(0)))

req_set = set(required_ids)
if req_set and not listed:
    die("non-empty required_bridges but brief bridge list empty")
if listed != req_set:
    die(
        f"bridges listed != required_bridges; "
        f"listed={sorted(listed)} required={sorted(req_set)}"
    )

# scene_bridge claims terminal (proven|failed) for each required
latest = {}
if claims_path.is_file():
    for lineno, line in enumerate(claims_path.read_text(encoding="utf-8").splitlines(), 1):
        line = line.strip()
        if not line:
            continue
        try:
            claim = json.loads(line)
        except json.JSONDecodeError as e:
            die(f"claims.jsonl line {lineno}: {e}")
        if not isinstance(claim, dict):
            continue
        if claim.get("claim_class") != "scene_bridge":
            continue
        if claim.get("scene_id") and claim.get("scene_id") != active_scene:
            continue
        sid = claim.get("subject_id")
        if sid:
            latest[str(sid)] = claim

for eid in required_ids:
    c = latest.get(eid)
    if not c:
        die(f"missing scene_bridge claim for required bridge {eid}")
    if c.get("state") not in ("proven", "failed"):
        die(f"scene_bridge {eid} not terminal (state={c.get('state')!r})")

# Matrix absence is OK — deliberately ignore matrix files
sys.exit(0)
PY

echo "SCENE_BRIEF_OK"
