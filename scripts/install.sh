#!/usr/bin/env bash
set -euo pipefail
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$PKG_ROOT/skills/MANIFEST.txt"
PROJECT_RULE=""
PROJECT_SKILLS=""
INIT_HUB=""
FORCE=0
FORCE_HUB=0

usage() {
  cat <<EOF
Usage: $0 [options]
  --with-project-rule=/path/to/repo   Copy thin rule if missing
  --project-skills=/path/to/repo      Symlink MANIFEST skills under repo .cursor/skills
  --init-hub=/abs/path                Copy references/hub/* into path/docs/war-room/
  --force                             Replace package-owned stale project skill symlinks only
  --force-hub                         Overwrite existing hub files (still never deletes CONFIRM unless --force-hub)
  -h|--help
EOF
  exit 2
}

for arg in "$@"; do
  case "$arg" in
    --with-project-rule=*) PROJECT_RULE="${arg#*=}" ;;
    --project-skills=*) PROJECT_SKILLS="${arg#*=}" ;;
    --init-hub=*) INIT_HUB="${arg#*=}" ;;
    --force) FORCE=1 ;;
    --force-hub) FORCE_HUB=1 ;;
    -h|--help) usage ;;
    *) echo "Unknown flag: $arg" >&2; usage ;;
  esac
done

[[ -f "$MANIFEST" ]] || { echo "Missing MANIFEST: $MANIFEST" >&2; exit 1; }

mkdir -p "$HOME/.cursor/skills"

link_global_skill() {
  local name="$1"
  local src="$PKG_ROOT/skills/$name"
  local dest="$HOME/.cursor/skills/$name"
  [[ -d "$src" ]] || { echo "MANIFEST skill missing on disk: $src" >&2; exit 1; }
  ln -sfn "$src" "$dest"
  echo "Linked global skill: $dest -> $src"
}

while IFS= read -r name || [[ -n "$name" ]]; do
  [[ -z "$name" || "$name" =~ ^# ]] && continue
  link_global_skill "$name"
done < "$MANIFEST"

if [[ -n "$PROJECT_RULE" ]]; then
  mkdir -p "$PROJECT_RULE/.cursor/rules"
  if [[ -f "$PROJECT_RULE/.cursor/rules/war-room-locate.mdc" ]]; then
    echo "Skip rule: already exists"
  else
    cp "$PKG_ROOT/rules/war-room-locate.mdc" "$PROJECT_RULE/.cursor/rules/war-room-locate.mdc"
    echo "Copied project rule"
  fi
fi

link_project_skill() {
  local name="$1"
  local dest="$PROJECT_SKILLS/.cursor/skills/$name"
  local src="$PKG_ROOT/skills/$name"
  local resolved expected pkg_skills
  mkdir -p "$PROJECT_SKILLS/.cursor/skills"
  if [[ ! -e "$dest" && ! -L "$dest" ]]; then
    ln -sfn "$src" "$dest"
    echo "Linked project skill: $dest"
    return
  fi
  expected="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$src")"
  pkg_skills="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$PKG_ROOT/skills")"
  if [[ -L "$dest" ]]; then
    resolved="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$dest")"
    if [[ "$resolved" == "$expected" ]]; then
      echo "OK project skill symlink: $dest"
      return
    fi
    # Package-owned stale symlink: --force may replace the link only (never a real directory).
    case "$resolved" in
      "$pkg_skills"/*)
        echo "WARN stale package-owned project skill symlink: $dest" >&2
        if [[ "$FORCE" -eq 1 ]]; then
          rm "$dest"
          ln -sfn "$src" "$dest"
          echo "Replaced with symlink (--force): $dest"
        else
          echo "Skip (re-run with --force to replace package-owned stale link): $dest" >&2
        fi
        return
        ;;
    esac
    # Foreign symlink: do not delete; manual rm + reinstall (no --force dead path).
    echo "WARN foreign project skill symlink: $dest (resolved=$resolved)" >&2
    echo "Refusing to replace foreign symlink (even with --force)." >&2
    echo "Manual recovery: rm \"$dest\" then re-run install with --project-skills (no --force needed)." >&2
    return 0
  fi
  # Real directory/file: never rm -rf under --force.
  echo "WARN real (non-symlink) project skill path: $dest" >&2
  echo "Refusing to delete real skill directory/file (even with --force)." >&2
  echo "Manual recovery: remove that path yourself only if you intend to discard it, then re-run install with --project-skills." >&2
  return 0
}

if [[ -n "$PROJECT_SKILLS" ]]; then
  while IFS= read -r name || [[ -n "$name" ]]; do
    [[ -z "$name" || "$name" =~ ^# ]] && continue
    link_project_skill "$name"
  done < "$MANIFEST"
fi

init_hub() {
  local ws="$1"
  local hub="$ws/docs/war-room"
  local src="$PKG_ROOT/references/hub"
  [[ -d "$src" ]] || { echo "Missing hub templates: $src" >&2; exit 1; }
  mkdir -p "$hub/RUNS"
  copy_if_needed() {
    local from="$1" to="$2"
    if [[ -e "$to" && "$FORCE_HUB" -ne 1 ]]; then
      echo "Skip existing: $to"
      return
    fi
    mkdir -p "$(dirname "$to")"
    cp "$from" "$to"
    echo "Wrote: $to"
  }
  copy_if_needed "$src/STATUS.md" "$hub/STATUS.md"
  copy_if_needed "$src/DECISIONS.md" "$hub/DECISIONS.md"
  copy_if_needed "$src/UploadManifest.stub.json" "$hub/UploadManifest.stub.json"
  copy_if_needed "$src/model-routing.json" "$hub/model-routing.json"
  # SCAN_PLAN template → SCAN_PLAN.md
  if [[ -e "$hub/SCAN_PLAN.md" && "$FORCE_HUB" -ne 1 ]]; then
    echo "Skip existing: $hub/SCAN_PLAN.md"
  else
    cp "$src/SCAN_PLAN.template.md" "$hub/SCAN_PLAN.md"
    echo "Wrote: $hub/SCAN_PLAN.md"
  fi
  # Never create empty CONFIRM; never delete CONFIRM without --force-hub
  if [[ -f "$hub/CONFIRM.json" && "$FORCE_HUB" -eq 1 ]]; then
    echo "WARN: --force-hub leaves CONFIRM in place (clear manually for re-orient)" >&2
  fi
  touch "$hub/RUNS/.gitkeep"
}

if [[ -n "$INIT_HUB" ]]; then
  [[ -d "$INIT_HUB" ]] || mkdir -p "$INIT_HUB"
  init_hub "$INIT_HUB"
fi

echo "Installed. PKG_ROOT=$PKG_ROOT"
echo "MANIFEST skills linked under ~/.cursor/skills/"
echo "Pin check: $PKG_ROOT/scripts/verify-pins.sh"
echo "PKG_ROOT resolve: python3 realpath on ~/.cursor/skills/war-room-init then dirname/dirname"
