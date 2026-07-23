#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_HOME="$(mktemp -d)"
TMP_WS="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME" "$TMP_WS"' EXIT
export HOME="$TMP_HOME"

# Minimal skill dirs already exist in package for MANIFEST names.
# Install into fake HOME.
bash "$ROOT/scripts/install.sh" --init-hub="$TMP_WS"

for name in vibage-init vibage-bootstrap vibage-locate; do
  link="$HOME/.cursor/skills/$name"
  [[ -L "$link" ]] || { echo "FAIL: missing symlink $link"; exit 1; }
  resolved="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$link")"
  expected="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$ROOT/skills/$name")"
  [[ "$resolved" == "$expected" ]] || { echo "FAIL: bad target $resolved"; exit 1; }
done

[[ -f "$TMP_WS/docs/vibage/STATUS.md" ]] || { echo "FAIL: hub STATUS missing"; exit 1; }
[[ -f "$TMP_WS/docs/vibage/DECISIONS.md" ]] || { echo "FAIL: hub DECISIONS missing"; exit 1; }
[[ -f "$TMP_WS/docs/vibage/SCAN_PLAN.md" ]] || { echo "FAIL: hub SCAN_PLAN missing"; exit 1; }
[[ -f "$TMP_WS/docs/vibage/UploadManifest.stub.json" ]] || { echo "FAIL: stub missing"; exit 1; }
[[ -f "$TMP_WS/docs/vibage/model-routing.json" ]] || { echo "FAIL: model-routing missing"; exit 1; }
[[ -d "$TMP_WS/docs/vibage/RUNS" ]] || { echo "FAIL: RUNS dir missing"; exit 1; }

# Re-init must not clobber existing CONFIRM
mkdir -p "$TMP_WS/docs/vibage"
echo '{"schema_version":"1","payload_hash":"abc"}' > "$TMP_WS/docs/vibage/CONFIRM.json"
bash "$ROOT/scripts/install.sh" --init-hub="$TMP_WS"
grep -q '"payload_hash":"abc"' "$TMP_WS/docs/vibage/CONFIRM.json" \
  || { echo "FAIL: CONFIRM was clobbered"; exit 1; }

echo "ALL install_manifest tests passed"
