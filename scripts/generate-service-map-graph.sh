#!/usr/bin/env bash
# Usage: generate-service-map-graph.sh <workspace_root>
# Plan-L (local-maps deepen): always emit Mermaid graph.mmd + COVERAGE_NOTES
# from hub service_map.json when present. Graphify CLI is optional/fail-soft.
# OK:GRAPHIFY_SKIP = CLI path skipped only — never means "no graph artifact".
# Never fails verify-service-map; never required for map qualification.
set -euo pipefail

WS="${1:-}"
if [[ -z "$WS" || ! -d "$WS" ]]; then
  echo "FAIL: Usage: $0 <workspace_root>" >&2
  exit 2
fi

MAP="$WS/docs/vibage/maps/service_map.json"
MMD="$WS/docs/vibage/maps/graph.mmd"
NOTES="$WS/docs/vibage/maps/COVERAGE_NOTES.md"
CLI="${VIBAGE_GRAPHIFY_CLI:-graphify}"

graphify_skip() {
  echo "OK:GRAPHIFY_SKIP"
  echo "$*"
  exit 0
}

[[ -f "$MAP" ]] || graphify_skip "Graphify CLI path skipped: missing $MAP. Optional only; map qualification uses verify-service-map.sh. No Mermaid emitted."

mkdir -p "$WS/docs/vibage/maps"

# Always emit Mermaid + coverage notes from JSON (single writer for counts).
set +e
PY_OUT="$(python3 - "$MAP" "$MMD" "$NOTES" <<'PY'
import json
import re
import sys
from pathlib import Path

map_path, mmd_path, notes_path = sys.argv[1], sys.argv[2], sys.argv[3]

def die_soft(msg: str) -> None:
    print(msg, file=sys.stderr)
    raise SystemExit(1)

try:
    obj = json.loads(Path(map_path).read_text(encoding="utf-8"))
except Exception as e:
    die_soft(f"unreadable service_map.json: {e}")

services = obj.get("services") or []
edges = obj.get("edges") or []
if not isinstance(services, list):
    die_soft("services must be a list")
if not isinstance(edges, list):
    edges = []

def mermaid_id(raw: str) -> str:
    # Mermaid-safe id: alnum/underscore; prefix if starts with digit.
    s = re.sub(r"[^A-Za-z0-9_]", "_", raw.strip())
    if not s:
        return ""
    if s[0].isdigit():
        s = "n_" + s
    return s

nodes = []
seen = set()
for s in services:
    if not isinstance(s, dict):
        continue
    sid = str(s.get("id") or "").strip()
    if not sid:
        continue
    mid = mermaid_id(sid)
    if not mid or mid in seen:
        continue
    seen.add(mid)
    nodes.append((mid, sid))

if not nodes:
    die_soft("no valid service ids")

edge_pairs = []
for e in edges:
    if not isinstance(e, dict):
        continue
    a = mermaid_id(str(e.get("from") or "").strip())
    b = mermaid_id(str(e.get("to") or "").strip())
    if a in seen and b in seen:
        edge_pairs.append((a, b))

lines = ["flowchart LR"]
for mid, _sid in nodes:
    lines.append(f"  {mid}")
for a, b in edge_pairs:
    lines.append(f"  {a}-->{b}")
# Guarantee non-empty useful body beyond header alone
body = "\n".join(lines) + "\n"
if len(body.strip()) < 12:
    die_soft("refusing empty Mermaid body")
Path(mmd_path).write_text(body, encoding="utf-8")

services_count = len(nodes)
edges_count = len(edge_pairs)
notes = f"""# Coverage notes (auto)

- services_count: {services_count}
- edges_count: {edges_count}
- Source: `docs/vibage/maps/service_map.json`
- Writer: `scripts/generate-service-map-graph.sh` (Plan-L single writer)
- Not a `verify-service-map` field / floor gate.
"""
Path(notes_path).write_text(notes, encoding="utf-8")
print(f"OK:MERMAID wrote {mmd_path}")
print(f"OK:COVERAGE_NOTES wrote {notes_path} services_count={services_count} edges_count={edges_count}")
PY
)"
PY_RC=$?
set -e

if [[ "$PY_RC" -ne 0 ]]; then
  graphify_skip "Graphify CLI path skipped: could not emit Mermaid/coverage from $MAP. Map qualification still uses verify-service-map.sh only."
fi

if [[ -n "$PY_OUT" ]]; then
  echo "$PY_OUT"
else
  echo "OK:MERMAID wrote $MMD"
fi

# Refuse empty Mermaid after write (defense in depth).
if [[ ! -s "$MMD" ]]; then
  graphify_skip "Graphify CLI path skipped: Mermaid emit produced empty $MMD. Map qualification unchanged."
fi

# --- Optional Graphify CLI path (never overwrites Mermaid with empty stub) ---
if ! command -v "$CLI" >/dev/null 2>&1; then
  graphify_skip "Graphify CLI \`$CLI\` not on PATH. CLI path skipped only — Mermaid graph artifact already at docs/vibage/maps/graph.mmd. Service map qualification is unchanged."
fi

set +e
"$CLI" --help >/dev/null 2>&1
HELP_RC=$?
set -e

if [[ "$HELP_RC" -ne 0 ]]; then
  # Soft: keep Mermaid; do not claim Graphify wrote.
  echo "OK:GRAPHIFY_SKIP"
  echo "Graphify CLI \`$CLI\` present but not usable (--help failed). Mermaid floor retained at docs/vibage/maps/graph.mmd; map qualification unchanged."
  exit 0
fi

# Honest limitation: CLI present but emit contract unknown this wave.
# Do NOT overwrite graph.mmd. Do NOT claim OK:GRAPHIFY wrote for a stub.
echo "OK:GRAPHIFY_LIMITATION"
echo "Graphify CLI \`$CLI\` is on PATH but no known local emit contract this wave. Mermaid floor at docs/vibage/maps/graph.mmd remains the graph artifact. Not SAT option-L platform; ≠ Architecture Pass."
exit 0
