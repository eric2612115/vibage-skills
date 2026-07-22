#!/usr/bin/env bash
# Usage:
#   serve-preview.sh <workspace_root> [port]
# Copies package assets into $WS/war-room-preview/ then serves localhost.
set -euo pipefail
WS="${1:-}"
PORT="${2:-8765}"
[[ -n "$WS" && -d "$WS" ]] || { echo "Usage: $0 <workspace_root> [port]" >&2; exit 2; }
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$PKG_ROOT/assets/war-room-preview/index.html"
DEST_DIR="$WS/war-room-preview"
[[ -f "$SRC" ]] || { echo "Missing package asset: $SRC" >&2; exit 1; }
mkdir -p "$DEST_DIR"
cp "$SRC" "$DEST_DIR/index.html"
echo "Copied preview → $DEST_DIR/index.html"
cd "$DEST_DIR"
echo "Serving http://127.0.0.1:$PORT  (Ctrl+C to stop)"
python3 -m http.server "$PORT" --bind 127.0.0.1
