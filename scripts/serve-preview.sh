#!/usr/bin/env bash
# Usage:
#   serve-preview.sh <workspace_root> [port]
# Copies package assets into $WS/vibage-preview/ then serves $WS on localhost
# so ../VIBAGE-*.md links resolve. Open /vibage-preview/.
set -euo pipefail
WS="${1:-}"
PORT="${2:-8765}"
[[ -n "$WS" && -d "$WS" ]] || { echo "Usage: $0 <workspace_root> [port]" >&2; exit 2; }
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$PKG_ROOT/assets/vibage-preview/index.html"
DEST_DIR="$WS/vibage-preview"
[[ -f "$SRC" ]] || { echo "Missing package asset: $SRC" >&2; exit 1; }
mkdir -p "$DEST_DIR"
cp "$SRC" "$DEST_DIR/index.html"
echo "Copied preview → $DEST_DIR/index.html"
cd "$WS"
echo "Serving http://127.0.0.1:$PORT/vibage-preview/  (Ctrl+C to stop)"
python3 -m http.server "$PORT" --bind 127.0.0.1
