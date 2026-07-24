#!/usr/bin/env bash
# Usage: scene-brief.sh <workspace_root> <scene_id>
# Compile docs/vibage/briefs/<scene_id>.md (max_tokens + scene_id header).
# On switch: invalidate prior scene brief; set STATUS.active_scene.
# Append scene_bridge ledger claims for required_bridges.
set -euo pipefail

PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

fail() { echo "FAIL: $*" >&2; exit 1; }

WS="${1:-}"
SCENE_ID="${2:-}"
if [[ -z "$WS" || ! -d "$WS" || -z "$SCENE_ID" ]]; then
  echo "FAIL: Usage: $0 <workspace_root> <scene_id>" >&2
  exit 2
fi
WS="$(cd "$WS" && pwd)"

SCENES="$WS/docs/vibage/scenes/SCENES.json"
MAP="$WS/docs/vibage/maps/service_map.json"
STATUS="$WS/docs/vibage/STATUS.md"
BRIEFS="$WS/docs/vibage/briefs"
LEDGER_DIR="$WS/docs/vibage/ledger"

[[ -f "$SCENES" ]] || fail "missing $SCENES"
[[ -f "$MAP" ]] || fail "missing $MAP"
mkdir -p "$BRIEFS" "$LEDGER_DIR"
[[ -f "$STATUS" ]] || cat >"$STATUS" <<'EOF'
# Vibage Hub STATUS

schema_version: 1
hub_ready: true
active_scene:
scenes_draft: false
phase: installed
notes: "auto-created by scene-brief"
EOF

bash "$PKG_ROOT/scripts/scene-validate.sh" "$WS" >/dev/null \
  || fail "scene-validate failed"

python3 - "$WS" "$SCENE_ID" "$PKG_ROOT" <<'PY'
import hashlib, json, re, subprocess, sys
from datetime import datetime, timezone
from pathlib import Path
from collections import defaultdict

ws = Path(sys.argv[1]).resolve()
scene_id = sys.argv[2].strip()
pkg_root = Path(sys.argv[3]).resolve()
scenes_path = ws / "docs/vibage/scenes/SCENES.json"
map_path = ws / "docs/vibage/maps/service_map.json"
status_path = ws / "docs/vibage/STATUS.md"
briefs_dir = ws / "docs/vibage/briefs"
append_sh = pkg_root / "scripts/ledger-append.sh"

def die(msg: str) -> None:
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)

def load_scenes(path: Path):
    raw = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(raw, list):
        return raw
    if isinstance(raw, dict):
        return raw.get("scenes") or []
    die("SCENES.json invalid shape")

def edge_id(e: dict) -> str:
    if isinstance(e.get("id"), str) and e["id"].strip():
        return e["id"].strip()
    return f"{e['from']}->{e['to']}"

def parse_status_key(text: str, key: str):
    m = re.search(rf"^{re.escape(key)}:\s*(.*)$", text, flags=re.M)
    if not m:
        return None
    return m.group(1).strip()

def set_status_key(text: str, key: str, value: str) -> str:
    lines = text.splitlines()
    out = []
    found = False
    prefix = f"{key}:"
    for ln in lines:
        if ln.strip().startswith(prefix) or ln.startswith(prefix):
            out.append(f"{key}: {value}")
            found = True
        else:
            out.append(ln)
    if not found:
        inserted = False
        out2 = []
        for ln in out:
            out2.append(ln)
            if (not inserted) and ln.strip().startswith("schema_version:"):
                out2.append(f"{key}: {value}")
                inserted = True
        out = out2 if inserted else (out + [f"{key}: {value}"])
    return "\n".join(out) + "\n"

scenes = load_scenes(scenes_path)
by_id = {}
for sc in scenes:
    if isinstance(sc, dict) and isinstance(sc.get("scene_id"), str):
        by_id[sc["scene_id"].strip()] = sc
if scene_id not in by_id:
    die(f"unknown scene_id: {scene_id}")

active = by_id[scene_id]
n_scenes = len(by_id)

# Membership classification
repo_scenes = defaultdict(set)
for sc in scenes:
    sid = sc["scene_id"].strip()
    for rid in sc.get("repo_ids") or []:
        if isinstance(rid, str) and rid.strip():
            repo_scenes[rid.strip()].add(sid)

exclusive = defaultdict(set)  # scene_id -> repos
shared = set()
for rid, homes in repo_scenes.items():
    if len(homes) == 1:
        exclusive[next(iter(homes))].add(rid)
    elif len(homes) == n_scenes:
        shared.add(rid)

e_active = set(exclusive.get(scene_id, set()))
other_excl = set()
for sid, repos in exclusive.items():
    if sid != scene_id:
        other_excl |= repos
bridge_targets = other_excl | shared

try:
    smap = json.loads(map_path.read_text(encoding="utf-8"))
except Exception as e:
    die(f"service_map.json unreadable: {e}")

graph_repos = set()
for r in (smap.get("repos") or []) + (smap.get("services") or []):
    if not isinstance(r, dict):
        continue
    rid = r.get("id") or r.get("repo_id")
    if isinstance(rid, str) and rid.strip():
        graph_repos.add(rid.strip())

edges = smap.get("edges") or []
if not isinstance(edges, list):
    edges = []

# required_bridges = graph edges with one end in E_active and other in bridge_targets
required = []
required_ids = []
for e in edges:
    if not isinstance(e, dict):
        continue
    a, b = e.get("from"), e.get("to")
    if not isinstance(a, str) or not isinstance(b, str):
        continue
    a, b = a.strip(), b.strip()
    ends = {a, b}
    if not (ends & e_active):
        continue
    if not (ends & bridge_targets):
        continue
    # one end exclusive(active), other in exclusive(other)∪shared
    if (a in e_active and b in bridge_targets) or (b in e_active and a in bridge_targets):
        eid = edge_id(e)
        if eid not in required_ids:
            required.append({"id": eid, "from": a, "to": b})
            required_ids.append(eid)

# Invalidate prior active scene brief on switch
status_text = status_path.read_text(encoding="utf-8") if status_path.is_file() else ""
prior = parse_status_key(status_text, "active_scene") or ""
if prior and prior != scene_id:
    prior_path = briefs_dir / f"{prior}.md"
    if prior_path.is_file():
        old = prior_path.read_text(encoding="utf-8")
        if not re.search(r"(?i)^(stale|invalidated)\s*:", old, flags=re.M) and "stale: true" not in old.lower():
            # mark stale in header / prepend
            if old.lstrip().startswith("---"):
                # insert stale into frontmatter
                parts = old.split("---", 2)
                if len(parts) >= 3:
                    fm = parts[1]
                    if "stale:" not in fm.lower():
                        fm = fm.rstrip() + "\nstale: true\ninvalidated: true\n"
                    old = "---" + fm + "---" + parts[2]
                    # keep file but marked stale, then rename aside? plan: deletes/marks stale
                    prior_path.write_text(old, encoding="utf-8")
                else:
                    prior_path.write_text(
                        "---\nstale: true\ninvalidated: true\n---\n" + old, encoding="utf-8"
                    )
            else:
                prior_path.write_text(
                    "---\nstale: true\ninvalidated: true\n---\n\n" + old, encoding="utf-8"
                )
        # Prefer delete after marking so switch leaves no active prior brief
        prior_path.unlink(missing_ok=True)

# Update STATUS
status_text = status_path.read_text(encoding="utf-8") if status_path.is_file() else (
    "# Vibage Hub STATUS\n\nschema_version: 1\nhub_ready: true\n"
)
status_text = set_status_key(status_text, "active_scene", scene_id)
if parse_status_key(status_text, "scenes_draft") is None:
    status_text = set_status_key(status_text, "scenes_draft", "false")
status_path.write_text(status_text if status_text.endswith("\n") else status_text + "\n", encoding="utf-8")

# Hot edges for active scene
hot_ids = []
for hid in active.get("hot_edge_ids") or []:
    if isinstance(hid, str) and hid.strip():
        hot_ids.append(hid.strip())

edge_by_id = {edge_id(e): e for e in edges if isinstance(e, dict) and e.get("from") and e.get("to")}

# Non-scene repos = graph repos not in active repo_ids
active_repos = set()
for rid in active.get("repo_ids") or []:
    if isinstance(rid, str) and rid.strip():
        active_repos.add(rid.strip())
stub_repos = sorted(graph_repos - active_repos)

now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
lines = [
    "---",
    "max_tokens: 6000",
    f"scene_id: {scene_id}",
    f"generated_at: {now}",
    "---",
    "",
    f"# Scene brief: {scene_id}",
    "",
    f"title: {active.get('title') or scene_id}",
    f"seed_method: {active.get('seed_method') or ''}",
    "",
    "## Repos (active)",
]
for rid in sorted(active_repos):
    kind = "shared" if rid in shared else "exclusive"
    lines.append(f"- {rid} ({kind})")
lines.append("")
lines.append("## Non-scene stubs")
if stub_repos:
    for rid in stub_repos:
        lines.append(f"- {rid}: stub — see bridges")
else:
    lines.append("- (none)")
lines.append("")
lines.append("## Bridges (required_bridges)")
if required:
    for br in required:
        lines.append(f"- {br['id']} ({br['from']} -> {br['to']})")
else:
    lines.append("- (none)")
lines.append("")
lines.append("## Hot edges")
if hot_ids:
    for hid in hot_ids:
        lines.append(f"- {hid}")
else:
    lines.append("- (none)")
lines.append("")
lines.append("## Notes")
notes = active.get("notes") or ""
lines.append(str(notes) if notes else "(none)")
lines.append("")

brief_path = briefs_dir / f"{scene_id}.md"
brief_path.write_text("\n".join(lines), encoding="utf-8")

# Append scene_bridge claims for each required bridge (proven — derived from graph edge)
for br in required:
    eid = br["id"]
    stmt = f"bridge {eid} for scene {scene_id}"
    pointer = {
        "path": "docs/vibage/maps/service_map.json",
        "quote": f'{br["from"]}->{br["to"]}',
        "branch_ref": "",
        "env_id": "",
    }
    blob = json.dumps(pointer, sort_keys=True) + eid + scene_id
    eh = hashlib.sha256(blob.encode()).hexdigest()[:16]
    claim = {
        "id": f"scene_bridge:{scene_id}:{eid}",
        "subject_type": "edge",
        "subject_id": eid,
        "claim_class": "scene_bridge",
        "statement": stmt,
        "pointers": [pointer],
        "state": "proven",
        "scene_id": scene_id,
        "updated_at": now,
        "evidence_hash": eh,
    }
    r = subprocess.run(
        ["bash", str(append_sh), str(ws), json.dumps(claim, ensure_ascii=False)],
        capture_output=True,
        text=True,
    )
    if r.returncode != 0:
        die(f"ledger-append failed for {eid}: {r.stderr or r.stdout}")

print(f"OK: wrote {brief_path}")
print(f"OK: active_scene={scene_id} required_bridges={len(required)}")
PY
