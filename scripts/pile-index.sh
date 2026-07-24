#!/usr/bin/env bash
# Shallow pile-index: wrapper → graph-floor → PILE_INDEX_OK
# Token: PILE_INDEX_OK. NOT Tier-0. ≠ Architecture Pass. ≠ deep-read all files.
set -euo pipefail
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

fail() { echo "FAIL: $*" >&2; exit 1; }

if [[ $# -lt 1 || -z "${1:-}" ]]; then
  cat >&2 <<EOF
FAIL: parent workspace path required.

Usage: $0 /path/to/parent-workspace

Writes docs/vibage/maps/service_map.json from one-level child git checkouts.
Shallow only (README/compose/package names). No deep dig. No locate reports.
EOF
  exit 1
fi

PARENT="$(cd "$1" && pwd)" || fail "parent is not a directory: $1"
MAP="$PARENT/docs/vibage/maps/service_map.json"

bash "$PKG_ROOT/scripts/graph-floor.sh" "$PARENT" || fail "graph-floor failed"

svc_count="$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["services"]))' "$MAP")"
child_count="$(python3 -c 'import json,sys; m=json.load(open(sys.argv[1])); print(len(m.get("repos") or m["services"]))' "$MAP")"

echo "PILE_INDEX_OK parent=$PARENT services=$svc_count children=$child_count"
echo "Honesty: PILE_INDEX_OK ≠ Architecture Pass ≠ locate DONE ≠ Graphify required."
