#!/usr/bin/env bash
# Usage: scene-classify.sh <workspace_root> <ticket_text>
# Match ticket against title|scene_id|keywords[] of each scene.
# Exactly one match → print scene_id, exit 0
# Zero matches → exit 2
# Two or more → exit 3
set -euo pipefail

fail() { echo "FAIL: $*" >&2; exit 1; }

WS="${1:-}"
TEXT="${2:-}"
if [[ -z "$WS" || ! -d "$WS" ]]; then
  echo "FAIL: Usage: $0 <workspace_root> <ticket_text>" >&2
  exit 2
fi
if [[ -z "$TEXT" ]]; then
  echo "FAIL: Usage: $0 <workspace_root> <ticket_text>" >&2
  exit 2
fi
WS="$(cd "$WS" && pwd)"

SCENES="$WS/docs/vibage/scenes/SCENES.json"
[[ -f "$SCENES" ]] || fail "missing $SCENES"

python3 - "$SCENES" "$TEXT" <<'PY'
import json, sys

path = sys.argv[1]
text = sys.argv[2]
text_l = text.lower()

def die(msg: str, code: int = 1) -> None:
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(code)

try:
    raw = json.loads(open(path, encoding="utf-8").read())
except Exception as e:
    die(f"SCENES.json unreadable: {e}")

if isinstance(raw, list):
    scenes = raw
elif isinstance(raw, dict):
    scenes = raw.get("scenes") or []
else:
    die("SCENES.json invalid shape")

if not isinstance(scenes, list):
    die("scenes must be a list")

matches = []
for sc in scenes:
    if not isinstance(sc, dict):
        continue
    sid = sc.get("scene_id")
    if not isinstance(sid, str) or not sid.strip():
        continue
    sid = sid.strip()
    needles = [sid]
    title = sc.get("title")
    if isinstance(title, str) and title.strip():
        needles.append(title.strip())
    kws = sc.get("keywords")
    if isinstance(kws, list):
        for kw in kws:
            if isinstance(kw, str) and kw.strip():
                needles.append(kw.strip())
    hit = False
    for n in needles:
        if n.lower() in text_l:
            hit = True
            break
    if hit:
        matches.append(sid)

# de-dupe preserving order
seen = set()
uniq = []
for m in matches:
    if m not in seen:
        seen.add(m)
        uniq.append(m)

if len(uniq) == 1:
    print(uniq[0])
    sys.exit(0)
if len(uniq) == 0:
    sys.exit(2)
sys.exit(3)
PY
