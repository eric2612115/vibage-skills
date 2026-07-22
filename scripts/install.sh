#!/usr/bin/env bash
set -euo pipefail
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_RULE=""
PROJECT_SKILLS=""
FORCE=0
usage() {
  echo "Usage: $0 [--with-project-rule=/path/to/repo] [--project-skills=/path/to/repo] [--force]"
  exit 2
}
for arg in "$@"; do
  case "$arg" in
    --with-project-rule=*) PROJECT_RULE="${arg#*=}" ;;
    --project-skills=*) PROJECT_SKILLS="${arg#*=}" ;;
    --force) FORCE=1 ;;
    -h|--help) usage ;;
    *) echo "Unknown flag: $arg" >&2; usage ;;
  esac
done
mkdir -p "$HOME/.cursor/skills"
# Global: force symlink refresh to MAIN package SSOT (intentional; preserved behavior)
ln -sfn "$PKG_ROOT/skills/vibage-locate" "$HOME/.cursor/skills/vibage-locate"
ln -sfn "$PKG_ROOT/skills/vibage-bootstrap" "$HOME/.cursor/skills/vibage-bootstrap"
# Drop stale war-room-* global skill names (rename complete; do not recreate).
for stale in war-room-locate war-room-bootstrap war-room-init war-room-orient; do
  if [[ -L "$HOME/.cursor/skills/$stale" || -e "$HOME/.cursor/skills/$stale" ]]; then
    rm -f "$HOME/.cursor/skills/$stale"
    echo "Removed stale global skill: $HOME/.cursor/skills/$stale"
  fi
done
if [[ -n "$PROJECT_RULE" ]]; then
  mkdir -p "$PROJECT_RULE/.cursor/rules"
  if [[ -f "$PROJECT_RULE/.cursor/rules/vibage-locate.mdc" ]]; then
    echo "Skip rule: already exists"
  else
    cp "$PKG_ROOT/rules/vibage-locate.mdc" "$PROJECT_RULE/.cursor/rules/vibage-locate.mdc"
  fi
  # Drop stale rule filename if present
  if [[ -f "$PROJECT_RULE/.cursor/rules/war-room-locate.mdc" ]]; then
    rm -f "$PROJECT_RULE/.cursor/rules/war-room-locate.mdc"
    echo "Removed stale project rule: war-room-locate.mdc"
  fi
fi
link_project_skill() {
  local name="$1"
  local dest="$PROJECT_SKILLS/.cursor/skills/$name"
  local src="$PKG_ROOT/skills/$name"
  mkdir -p "$PROJECT_SKILLS/.cursor/skills"
  if [[ ! -e "$dest" && ! -L "$dest" ]]; then
    ln -sfn "$src" "$dest"
    echo "Linked project skill: $dest"
    return
  fi
  if [[ -L "$dest" ]]; then
    local resolved
    resolved="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$dest")"
    local expected
    expected="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$src")"
    if [[ "$resolved" == "$expected" ]]; then
      echo "OK project skill symlink: $dest"
      return
    fi
  fi
  echo "WARN stale/foreign project skill: $dest" >&2
  if [[ "$FORCE" -eq 1 ]]; then
    rm -rf "$dest"
    ln -sfn "$src" "$dest"
    echo "Replaced with symlink (--force): $dest"
  else
    echo "Skip (re-run with --force to replace): $dest" >&2
  fi
}
if [[ -n "$PROJECT_SKILLS" ]]; then
  link_project_skill vibage-locate
  link_project_skill vibage-bootstrap
  for stale in war-room-locate war-room-bootstrap war-room-init war-room-orient; do
    dest="$PROJECT_SKILLS/.cursor/skills/$stale"
    if [[ -L "$dest" || -e "$dest" ]]; then
      rm -f "$dest"
      echo "Removed stale project skill: $dest"
    fi
  done
fi
echo "Installed. PKG_ROOT=$PKG_ROOT"
echo "Pin check: $PKG_ROOT/scripts/verify-pins.sh"
echo "After install, resolve PKG_ROOT with python3 realpath on ~/.cursor/skills/vibage-locate then dirname/../.."
echo "Note: vibage-init / vibage-orient / research-survey-review / section-gate-review live under"
echo "      $PKG_ROOT/.worktrees/vibage-os-p1 — run that tree's scripts/install.sh for those skills."
