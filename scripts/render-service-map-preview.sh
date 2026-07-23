#!/usr/bin/env bash
# Usage: render-service-map-preview.sh <workspace_root>
# REQUIRED Plan G path: pure local SVG/HTML from hub service_map.json
# services+edges → $WS/vibage-preview/service_map.html (+ .svg).
# No external binary required for success. Fail-soft: exit 0 + OK:RENDER_SKIP.
set -euo pipefail

WS="${1:-}"
if [[ -z "$WS" || ! -d "$WS" ]]; then
  echo "FAIL: Usage: $0 <workspace_root>" >&2
  exit 2
fi

MAP="$WS/docs/vibage/maps/service_map.json"
DEST_DIR="$WS/vibage-preview"
SVG_OUT="$DEST_DIR/service_map.svg"
HTML_OUT="$DEST_DIR/service_map.html"

skip() {
  # Fail-soft: never fail verify; never non-zero for soft cases
  echo "OK:RENDER_SKIP"
  echo "$*"
  exit 0
}

[[ -f "$MAP" ]] || skip "Service map preview skipped: missing $MAP. Map qualification still uses verify-service-map.sh; locate DONE is unchanged."

mkdir -p "$DEST_DIR"

# Soft failures from Python must not abort under set -e before skip token.
set +e
PY_OUT="$(python3 - "$MAP" "$SVG_OUT" "$HTML_OUT" <<'PY'
import json, html, sys
from pathlib import Path

map_path, svg_path, html_path = sys.argv[1], sys.argv[2], sys.argv[3]

def die_soft(msg: str) -> None:
    # Non-zero exit → bash skip path (OK:RENDER_SKIP).
    print(msg, file=sys.stderr)
    raise SystemExit(1)

try:
    obj = json.loads(Path(map_path).read_text(encoding="utf-8"))
except Exception as e:
    die_soft(f"unreadable service_map.json: {e}")

services = obj.get("services") or []
edges = obj.get("edges") or []
if not isinstance(services, list) or not services:
    die_soft("services missing or empty")

nodes = []
for i, s in enumerate(services):
    if not isinstance(s, dict):
        continue
    sid = str(s.get("id") or "").strip()
    if not sid:
        continue
    name = str(s.get("name") or sid).strip()
    nodes.append((sid, name))

if not nodes:
    die_soft("no valid service ids")

# Simple grid layout — pure local, no external layout binary
cols = max(1, int(len(nodes) ** 0.5 + 0.999))
w, h, pad = 160, 64, 40
positions = {}
for i, (sid, name) in enumerate(nodes):
    r, c = divmod(i, cols)
    positions[sid] = (pad + c * (w + pad), pad + r * (h + pad) + 20)

max_x = max(x for x, _ in positions.values()) + w + pad
max_y = max(y for _, y in positions.values()) + h + pad

def esc(s: str) -> str:
    return html.escape(s, quote=True)

parts = [
    f'<svg xmlns="http://www.w3.org/2000/svg" width="{max_x}" height="{max_y}" viewBox="0 0 {max_x} {max_y}">',
    '<rect width="100%" height="100%" fill="#0f1419"/>',
]
if isinstance(edges, list):
    for e in edges:
        if not isinstance(e, dict):
            continue
        a, b = e.get("from"), e.get("to")
        if a in positions and b in positions:
            x1, y1 = positions[a]
            x2, y2 = positions[b]
            parts.append(
                f'<line x1="{x1+w/2}" y1="{y1+h/2}" x2="{x2+w/2}" y2="{y2+h/2}" '
                f'stroke="#3d9cf0" stroke-width="2"/>'
            )
for sid, name in nodes:
    x, y = positions[sid]
    parts.append(
        f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="8" '
        f'fill="#1a2332" stroke="#2a3648"/>'
    )
    parts.append(
        f'<text x="{x+8}" y="{y+28}" fill="#e7ecf3" font-size="14" '
        f'font-family="IBM Plex Sans, Segoe UI, sans-serif">{esc(sid)}</text>'
    )
    parts.append(
        f'<text x="{x+8}" y="{y+48}" fill="#9aa7b8" font-size="11" '
        f'font-family="IBM Plex Sans, Segoe UI, sans-serif">{esc(name)}</text>'
    )
parts.append("</svg>")
Path(svg_path).write_text("\n".join(parts) + "\n", encoding="utf-8")

html_doc = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Vibage Service Map Preview</title>
  <style>
    body {{ margin: 0; font-family: "IBM Plex Sans", "Segoe UI", sans-serif;
      background: linear-gradient(160deg,#0f1419,#1a2332); color: #e7ecf3; }}
    main {{ max-width: 960px; margin: 0 auto; padding: 32px 20px; }}
    .brand {{ color: #3d9cf0; font-size: 0.85rem; letter-spacing: 0.08em; text-transform: uppercase; }}
    img, object {{ max-width: 100%; background: #0f1419; border: 1px solid #2a3648; }}
    a {{ color: #3d9cf0; }}
  </style>
</head>
<body>
  <main>
    <div class="brand">Vibage</div>
    <h1>Service map preview</h1>
    <p>Local render from <code>docs/vibage/maps/service_map.json</code> (Plan G). Not cloud Architecture Pass.</p>
    <p><a href="./index.html">Back to preview index</a></p>
    <object type="image/svg+xml" data="./service_map.svg">service_map.svg</object>
  </main>
</body>
</html>
"""
Path(html_path).write_text(html_doc, encoding="utf-8")
print("OK:RENDER wrote", html_path, "and", svg_path)
PY
)"
RC=$?
set -e

if [[ "$RC" -ne 0 ]]; then
  skip "Service map preview skipped: could not render from $MAP. Map usable still follows verify-service-map.sh only."
fi

# Prefer Python success line; fall back to bash echo for token contract.
if [[ -n "$PY_OUT" ]]; then
  echo "$PY_OUT"
else
  echo "OK:RENDER wrote $HTML_OUT and $SVG_OUT"
fi
