#!/usr/bin/env bash
# --force must never rm -rf real dirs; foreign symlinks refused; package-owned stale OK.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_HOME="$(mktemp -d)"
TMP_WS="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME" "$TMP_WS"' EXIT
export HOME="$TMP_HOME"

PROJ="$TMP_WS/.cursor/skills"
mkdir -p "$PROJ"

# Real directory must survive --force
mkdir -p "$PROJ/war-room-locate"
echo keep > "$PROJ/war-room-locate/KEEP.txt"
bash "$ROOT/scripts/install.sh" --project-skills="$TMP_WS" --force
[[ -f "$PROJ/war-room-locate/KEEP.txt" ]] || { echo "FAIL: real dir deleted under --force"; exit 1; }
[[ ! -L "$PROJ/war-room-locate" ]] || { echo "FAIL: real dir became symlink unexpectedly"; exit 1; }
echo "OK: real dir preserved under --force"

# Foreign symlink must survive --force (manual rm path)
rm -rf "$PROJ/war-room-locate"
mkdir -p "$TMP_WS/foreign-skill"
echo foreign > "$TMP_WS/foreign-skill/SKILL.md"
ln -sfn "$TMP_WS/foreign-skill" "$PROJ/war-room-locate"
bash "$ROOT/scripts/install.sh" --project-skills="$TMP_WS" --force
[[ -L "$PROJ/war-room-locate" ]] || { echo "FAIL: foreign symlink removed"; exit 1; }
resolved="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$PROJ/war-room-locate")"
foreign="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$TMP_WS/foreign-skill")"
[[ "$resolved" == "$foreign" ]] || { echo "FAIL: foreign symlink retargeted to $resolved"; exit 1; }
echo "OK: foreign symlink preserved under --force"

# Package-owned stale symlink may be replaced with --force
rm -f "$PROJ/war-room-locate"
# Point at a different skill dir inside the package (stale package-owned)
ln -sfn "$ROOT/skills/war-room-init" "$PROJ/war-room-locate"
bash "$ROOT/scripts/install.sh" --project-skills="$TMP_WS" --force
resolved="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$PROJ/war-room-locate")"
expected="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$ROOT/skills/war-room-locate")"
[[ "$resolved" == "$expected" ]] || { echo "FAIL: stale package link not replaced: $resolved"; exit 1; }
echo "OK: package-owned stale symlink replaced with --force"

echo "ALL install_force_safety tests passed"
