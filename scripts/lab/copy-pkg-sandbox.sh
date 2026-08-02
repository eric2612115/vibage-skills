#!/usr/bin/env bash
# Copy vibage-skills package into an isolated sandbox for pressure trials.
# LAB_NO_DELETE: never deletes source or dest. Owner cleans /tmp later.
# Usage:
#   bash copy-pkg-sandbox.sh --source=/abs/vibage-skills --dest=/tmp/.../pkg
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
export LAB_NO_DELETE=1

SOURCE=""
DEST=""
for arg in "$@"; do
  case "$arg" in
    --source=*) SOURCE="${arg#*=}" ;;
    --dest=*) DEST="${arg#*=}" ;;
    *) echo "FAIL: unknown arg: $arg" >&2; exit 1 ;;
  esac
done

[[ -n "$SOURCE" && -d "$SOURCE" ]] || { echo "FAIL: --source= existing dir required" >&2; exit 1; }
[[ -n "$DEST" ]] || { echo "FAIL: --dest= required" >&2; exit 1; }

SOURCE="$(cd "$SOURCE" && pwd -P)"
mkdir -p "$DEST"
DEST="$(cd "$DEST" && pwd)"

EXCLUDES_FILE="$LAB_DIR/rsync-excludes.txt"
[[ -f "$EXCLUDES_FILE" ]] || { echo "FAIL: missing $EXCLUDES_FILE" >&2; exit 1; }

echo "LAB_NO_DELETE=1 owner cleans /tmp later"
echo "WC_COPY_START source=$SOURCE dest=$DEST max-size=5m"

# --max-size=5m: skip files larger than 5 MiB
# --safe-links: do not copy escaping symlinks (no write-through to live)
rsync -a \
  --safe-links \
  --max-size=5m \
  --exclude-from="$EXCLUDES_FILE" \
  --exclude 'tests/artifacts/' \
  --exclude '.git/objects/pack/' \
  --exclude '.cursor/' \
  --exclude 'agent-transcripts/' \
  "$SOURCE/" "$DEST/"

[[ -f "$DEST/scripts/verify-work-continue.sh" ]] \
  || { echo "FAIL: sandbox missing verify-work-continue.sh" >&2; exit 1; }
[[ -f "$DEST/tests/test_work_continue_memory.sh" ]] \
  || { echo "FAIL: sandbox missing test_work_continue_memory.sh" >&2; exit 1; }

if [[ -d "$DEST/.git" ]]; then
  HEAD="$(git -C "$DEST" rev-parse --short HEAD 2>/dev/null || echo unknown)"
else
  HEAD="no_git"
fi

echo "WC_COPY_OK dest=$DEST head=$HEAD"
echo "LAB_KEEP dest=$DEST"
