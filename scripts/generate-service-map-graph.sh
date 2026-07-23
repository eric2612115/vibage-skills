#!/usr/bin/env bash
# Usage: generate-service-map-graph.sh <workspace_root>
# OPTIONAL Plan G: if `graphify` (documented CLI) is on PATH, may write a
# sidecar under docs/vibage/maps/. Else exit 0 + OK:GRAPHIFY_SKIP + owner sentence.
# Never fails verify-service-map; never required for map qualification.
set -euo pipefail

WS="${1:-}"
if [[ -z "$WS" || ! -d "$WS" ]]; then
  echo "FAIL: Usage: $0 <workspace_root>" >&2
  exit 2
fi

MAP="$WS/docs/vibage/maps/service_map.json"
SIDE="$WS/docs/vibage/maps/service_map.graphify.md"
CLI="${VIBAGE_GRAPHIFY_CLI:-graphify}"

skip() {
  echo "OK:GRAPHIFY_SKIP"
  echo "$*"
  exit 0
}

[[ -f "$MAP" ]] || skip "Graphify sidecar skipped: missing $MAP. Optional only; map qualification uses verify-service-map.sh."

if ! command -v "$CLI" >/dev/null 2>&1; then
  skip "Graphify CLI \`$CLI\` not on PATH. Optional local prettier skipped; service map qualification is unchanged. Install locally later if you want a Graphify sidecar under docs/vibage/maps/."
fi

mkdir -p "$WS/docs/vibage/maps"

# Best-effort local invoke. Any failure → soft skip (do not fail qualification).
set +e
"$CLI" --help >/dev/null 2>&1
HELP_RC=$?
set -e
if [[ "$HELP_RC" -ne 0 ]]; then
  skip "Graphify CLI \`$CLI\` present but not usable. Sidecar not written; map qualification unchanged."
fi

# Minimal sidecar proof when CLI exists — do not upload repos; local only.
# Real graphify flags vary; keep thin: record that CLI was available and point at hub map.
cat >"$SIDE" <<EOF
# service_map Graphify sidecar (local, optional)

- Hub map: \`docs/vibage/maps/service_map.json\`
- Generator: \`$CLI\` (Plan G OPTIONAL)
- Deeper Graphify/L pipelines may replace this stub later (M Pretty-local ≠终局).
EOF

echo "OK:GRAPHIFY wrote $SIDE"
