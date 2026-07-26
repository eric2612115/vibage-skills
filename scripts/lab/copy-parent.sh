#!/usr/bin/env bash
# Copy an allowlisted parent (or package fixture) into a writable sandbox.
# Usage:
#   bash copy-parent.sh --source=/abs/allowlisted/parent --dest=/tmp/.../parent
#   bash copy-parent.sh --fixture=synthetic-parent --dest=/tmp/.../parent
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_ROOT="$(cd "$LAB_DIR/../.." && pwd)"
# shellcheck source=allowlist.sh
source "$LAB_DIR/allowlist.sh"

SOURCE=""
FIXTURE=""
DEST=""

for arg in "$@"; do
  case "$arg" in
    --source=*) SOURCE="${arg#*=}" ;;
    --fixture=*) FIXTURE="${arg#*=}" ;;
    --dest=*) DEST="${arg#*=}" ;;
    *) echo "FAIL: unknown arg: $arg" >&2; exit 1 ;;
  esac
done

[[ -n "$DEST" ]] || { echo "FAIL: --dest= required" >&2; exit 1; }
mkdir -p "$DEST"
DEST="$(cd "$DEST" && pwd)"

EXCLUDES_FILE="$LAB_DIR/rsync-excludes.txt"
[[ -f "$EXCLUDES_FILE" ]] || { echo "FAIL: missing $EXCLUDES_FILE" >&2; exit 1; }

# --safe-links: do not copy symlinks that escape the tree (prevents write-through to live).
RSYNC_EX=(--exclude-from="$EXCLUDES_FILE" --safe-links)

if [[ -n "$FIXTURE" ]]; then
  case "$FIXTURE" in
    synthetic-parent)
      SRC="$PKG_ROOT/tests/fixtures/synthetic-parent"
      [[ -d "$SRC" ]] || { echo "FAIL: missing fixture $SRC" >&2; exit 1; }
      rsync -a "${RSYNC_EX[@]}" "$SRC/" "$DEST/"
      # Ensure fake git checkouts exist for continuum
      mkdir -p "$DEST/app-a/.git" "$DEST/app-b/.git"
      ;;
    defi_strategy_like)
      bash "$PKG_ROOT/tests/fixtures/c-prime/defi_strategy_like/setup.sh" "$DEST"
      ;;
    friend-chaos)
      bash "$PKG_ROOT/tests/fixtures/c-prime/friend-chaos/setup.sh" "$DEST"
      ;;
    *)
      echo "FAIL: unknown fixture: $FIXTURE" >&2
      exit 1
      ;;
  esac
  echo "LAB_COPY_OK fixture=$FIXTURE dest=$DEST"
  exit 0
fi

[[ -n "$SOURCE" ]] || { echo "FAIL: --source= or --fixture= required" >&2; exit 1; }
lab_assert_source_allowed "$SOURCE"
SOURCE="$(cd "$SOURCE" && pwd -P)"

echo "LAB_COPY_START source=$SOURCE dest=$DEST"
rsync -a "${RSYNC_EX[@]}" "$SOURCE/" "$DEST/"
echo "LAB_COPY_OK source=$SOURCE dest=$DEST"
