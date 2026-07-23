#!/usr/bin/env bash
# Install vibage skills for Cursor, Claude Code, and/or Codex surfaces.
set -euo pipefail
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$PKG_ROOT/skills/MANIFEST.txt"
PROJECT_RULE=""
PROJECT_SKILLS=""
INIT_HUB=""
FORCE=0
FORCE_HUB=0
FORCE_PROJECT_ENTRY=0
SURFACES="cursor,claude,codex"

usage() {
  cat <<EOF
Usage: $0 [options]
  --surfaces=cursor,claude,codex   Which skill homes to link (default: all three)
  --with-project-rule=/path/to/parent-workspace
      Parent workspace only (not each child repo). Always writes ALL three
      platforms (ignores --surfaces for these files):
      Cursor: overwrite .cursor/rules/vibage.mdc + upsert sessionStart hooks
      Claude: upsert CLAUDE.md vibage block + .claude/vibage-entry.md
      Codex: upsert AGENTS.md from adapters/shared/AGENTS.vibage.md
      Verify: bash scripts/verify-project-entry.sh /path/to/parent-workspace
  --force-project-entry            Must be paired with --with-project-rule=… (refresh is default)
  --project-skills=/path/to/repo   Symlink MANIFEST skills under each surface's project skills dir
  --init-hub=/abs/path             Copy references/hub/* into path/docs/vibage/
  --force                          Replace package-owned stale project skill symlinks only
  --force-hub                      Overwrite existing hub files (never deletes CONFIRM)
  -h|--help
EOF
  exit 2
}

for arg in "$@"; do
  case "$arg" in
    --surfaces=*) SURFACES="${arg#*=}" ;;
    --with-project-rule=*) PROJECT_RULE="${arg#*=}" ;;
    --force-project-entry) FORCE_PROJECT_ENTRY=1 ;;
    --project-skills=*) PROJECT_SKILLS="${arg#*=}" ;;
    --init-hub=*) INIT_HUB="${arg#*=}" ;;
    --force) FORCE=1 ;;
    --force-hub) FORCE_HUB=1 ;;
    -h|--help) usage ;;
    *) echo "Unknown flag: $arg" >&2; usage ;;
  esac
done

[[ -f "$MANIFEST" ]] || { echo "Missing MANIFEST: $MANIFEST" >&2; exit 1; }

if [[ "$FORCE_PROJECT_ENTRY" -eq 1 && -z "$PROJECT_RULE" ]]; then
  echo "ERROR: --force-project-entry requires --with-project-rule=/path/to/parent-workspace" >&2
  echo "(Refresh is already the default when --with-project-rule is set.)" >&2
  exit 2
fi

surface_enabled() {
  local name="$1"
  [[ ",$SURFACES," == *",$name,"* ]]
}

# Returns global skill home for a surface
global_skill_home() {
  case "$1" in
    cursor) echo "$HOME/.cursor/skills" ;;
    claude) echo "$HOME/.claude/skills" ;;
    codex) echo "$HOME/.agents/skills" ;;
    *) return 1 ;;
  esac
}

project_skill_home() {
  local repo="$1" surface="$2"
  case "$surface" in
    cursor) echo "$repo/.cursor/skills" ;;
    claude) echo "$repo/.claude/skills" ;;
    codex) echo "$repo/.agents/skills" ;;
    *) return 1 ;;
  esac
}

STALE_NAMES=(war-room-locate war-room-bootstrap war-room-init war-room-orient)

# link_global_skill SURFACE DEST_NAME [SRC_NAME]
# SRC_NAME defaults to DEST_NAME. Used for one-release vibage-locate redirect.
link_global_skill() {
  local surface="$1" dest_name="$2" src_name="${3:-$2}"
  local home src dest
  home="$(global_skill_home "$surface")"
  src="$PKG_ROOT/skills/$src_name"
  dest="$home/$dest_name"
  [[ -d "$src" ]] || { echo "MANIFEST skill missing on disk: $src" >&2; exit 1; }
  mkdir -p "$home"
  ln -sfn "$src" "$dest"
  echo "Linked global ($surface): $dest -> $src"
}

cleanup_stale_global() {
  local surface="$1"
  local home stale dest
  home="$(global_skill_home "$surface")"
  [[ -d "$home" ]] || return 0
  for stale in "${STALE_NAMES[@]}"; do
    dest="$home/$stale"
    if [[ -L "$dest" || -e "$dest" ]]; then
      rm -f "$dest"
      echo "Removed stale global skill ($surface): $dest"
    fi
  done
}

# link_project_skill SURFACE DEST_NAME [SRC_NAME]
link_project_skill() {
  local surface="$1" dest_name="$2" src_name="${3:-$2}"
  local home src dest resolved expected pkg_skills
  home="$(project_skill_home "$PROJECT_SKILLS" "$surface")"
  src="$PKG_ROOT/skills/$src_name"
  dest="$home/$dest_name"
  mkdir -p "$home"
  if [[ ! -e "$dest" && ! -L "$dest" ]]; then
    ln -sfn "$src" "$dest"
    echo "Linked project skill ($surface): $dest"
    return
  fi
  expected="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$src")"
  pkg_skills="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$PKG_ROOT/skills")"
  if [[ -L "$dest" ]]; then
    resolved="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$dest")"
    if [[ "$resolved" == "$expected" ]]; then
      echo "OK project skill symlink ($surface): $dest"
      return
    fi
    case "$resolved" in
      "$pkg_skills"/*)
        echo "WARN stale package-owned project skill symlink ($surface): $dest" >&2
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
    echo "WARN foreign project skill symlink ($surface): $dest (resolved=$resolved)" >&2
    echo "Refusing to replace foreign symlink (even with --force)." >&2
    echo "Manual recovery: rm \"$dest\" then re-run install with --project-skills." >&2
    return 0
  fi
  echo "WARN real (non-symlink) project skill path ($surface): $dest" >&2
  echo "Refusing to delete real skill directory/file (even with --force)." >&2
  return 0
}

cleanup_stale_project() {
  local surface="$1"
  local home stale dest
  home="$(project_skill_home "$PROJECT_SKILLS" "$surface")"
  [[ -d "$home" ]] || return 0
  for stale in "${STALE_NAMES[@]}"; do
    dest="$home/$stale"
    if [[ -L "$dest" || -e "$dest" ]]; then
      rm -f "$dest"
      echo "Removed stale project skill ($surface): $dest"
    fi
  done
}

# Upsert marked markdown block into a target file
upsert_marked_block() {
  local target="$1"
  local block_file="$2"
  python3 - "$target" "$block_file" <<'PY'
import pathlib, sys
target = pathlib.Path(sys.argv[1])
block = pathlib.Path(sys.argv[2]).read_text(encoding="utf-8")
if not block.endswith("\n"):
    block += "\n"
start, end = "<!-- vibage:start -->", "<!-- vibage:end -->"
if not (start in block and end in block):
    raise SystemExit(f"adapter block missing markers: {sys.argv[2]}")
text = target.read_text(encoding="utf-8") if target.exists() else ""
if start in text and end in text:
    pre = text.split(start, 1)[0]
    post = text.split(end, 1)[1]
    # drop leading newline from post if present after replace
    new = pre.rstrip() + "\n\n" + block + post.lstrip("\n")
    action = "Updated"
else:
    if text and not text.endswith("\n"):
        text += "\n"
    new = (text + ("\n" if text else "") + block).lstrip("\n") if not text else text.rstrip() + "\n\n" + block
    action = "Appended"
target.parent.mkdir(parents=True, exist_ok=True)
target.write_text(new if new.endswith("\n") else new + "\n", encoding="utf-8")
print(f"{action} vibage block: {target}")
PY
}

install_cursor_session_hooks() {
  # Parent-only Cursor sessionStart (host-best). Does not touch Claude/Codex hook files.
  local repo="$1"
  local hook_dir hook_sh
  hook_dir="$repo/.cursor/hooks"
  mkdir -p "$hook_dir"
  hook_sh="$hook_dir/vibage-session-start.sh"
  cp "$PKG_ROOT/adapters/cursor/hooks/vibage-session-start.sh" "$hook_sh"
  chmod +x "$hook_sh"
  echo "Wrote Cursor hook script: $hook_sh"
  python3 - "$repo" "$PKG_ROOT/adapters/cursor/hooks/hooks.json" <<'PY'
import json, pathlib, sys
repo = pathlib.Path(sys.argv[1])
template = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding="utf-8"))
target = repo / ".cursor" / "hooks.json"
cmd = ".cursor/hooks/vibage-session-start.sh"
data = {"version": 1, "hooks": {}}
if target.exists():
    try:
        data = json.loads(target.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        raise SystemExit(f"invalid existing hooks.json: {target}: {e}")
if not isinstance(data, dict):
    raise SystemExit(f"hooks.json root must be object: {target}")
data.setdefault("version", template.get("version", 1))
hooks = data.setdefault("hooks", {})
if not isinstance(hooks, dict):
    raise SystemExit(f"hooks.json hooks must be object: {target}")
ss = hooks.get("sessionStart") or []
if not isinstance(ss, list):
    ss = []
ss = [h for h in ss if isinstance(h, dict) and "vibage-session-start" not in str(h.get("command", ""))]
ss.append({"command": cmd})
hooks["sessionStart"] = ss
target.parent.mkdir(parents=True, exist_ok=True)
target.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
print(f"Upserted Cursor hooks.json sessionStart: {target}")
PY
}

install_project_rules() {
  # Parent workspace only. Always refresh all three platforms (ignore --surfaces).
  local repo="$1"
  local mdc legacy
  mkdir -p "$repo/.cursor/rules"
  mdc="$repo/.cursor/rules/vibage.mdc"
  legacy="$repo/.cursor/rules/vibage-locate.mdc"
  cp "$PKG_ROOT/adapters/cursor/vibage.mdc" "$mdc"
  echo "Wrote Cursor rule: $mdc"
  if [[ -f "$legacy" ]]; then
    echo "Note: legacy $legacy still present; prefer vibage.mdc (routing + hard-stops pointer)"
  fi
  install_cursor_session_hooks "$repo"

  mkdir -p "$repo/.claude"
  cp "$PKG_ROOT/adapters/claude/CLAUDE.vibage.md" "$repo/.claude/vibage-entry.md"
  echo "Wrote: $repo/.claude/vibage-entry.md"
  upsert_marked_block "$repo/CLAUDE.md" "$PKG_ROOT/adapters/claude/CLAUDE.vibage.md"

  # Codex + Cursor AGENTS readers — SSOT body is adapters/shared only
  upsert_marked_block "$repo/AGENTS.md" "$PKG_ROOT/adapters/shared/AGENTS.vibage.md"
}

init_hub() {
  local ws="$1"
  local hub="$ws/docs/vibage"
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
  if [[ -e "$hub/SCAN_PLAN.md" && "$FORCE_HUB" -ne 1 ]]; then
    echo "Skip existing: $hub/SCAN_PLAN.md"
  else
    cp "$src/SCAN_PLAN.template.md" "$hub/SCAN_PLAN.md"
    echo "Wrote: $hub/SCAN_PLAN.md"
  fi
  if [[ -f "$hub/CONFIRM.json" && "$FORCE_HUB" -eq 1 ]]; then
    echo "WARN: --force-hub leaves CONFIRM in place (clear manually for re-orient)" >&2
  fi
  touch "$hub/RUNS/.gitkeep"
}

# --- global skills ---
for surface in cursor claude codex; do
  surface_enabled "$surface" || continue
  while IFS= read -r name || [[ -n "$name" ]]; do
    [[ -z "$name" || "$name" =~ ^# ]] && continue
    link_global_skill "$surface" "$name"
  done < "$MANIFEST"
  # One-release redirect: legacy vibage-locate → vibage-issue-locate
  if [[ -d "$PKG_ROOT/skills/vibage-issue-locate" ]]; then
    link_global_skill "$surface" "vibage-locate" "vibage-issue-locate"
  fi
  cleanup_stale_global "$surface"
done

# --- project rules ---
if [[ -n "$PROJECT_RULE" ]]; then
  [[ -d "$PROJECT_RULE" ]] || mkdir -p "$PROJECT_RULE"
  install_project_rules "$PROJECT_RULE"
fi

# --- project skills ---
if [[ -n "$PROJECT_SKILLS" ]]; then
  for surface in cursor claude codex; do
    surface_enabled "$surface" || continue
    while IFS= read -r name || [[ -n "$name" ]]; do
      [[ -z "$name" || "$name" =~ ^# ]] && continue
      link_project_skill "$surface" "$name"
    done < "$MANIFEST"
    # One-release redirect: legacy vibage-locate → vibage-issue-locate
    if [[ -d "$PKG_ROOT/skills/vibage-issue-locate" ]]; then
      link_project_skill "$surface" "vibage-locate" "vibage-issue-locate"
    fi
    cleanup_stale_project "$surface"
  done
fi

# --- hub ---
if [[ -n "$INIT_HUB" ]]; then
  [[ -d "$INIT_HUB" ]] || mkdir -p "$INIT_HUB"
  init_hub "$INIT_HUB"
fi

echo "Installed. PKG_ROOT=$PKG_ROOT"
echo "Surfaces: $SURFACES"
echo "MANIFEST skills linked under enabled global skill homes."
echo "Pin check: $PKG_ROOT/scripts/verify-pins.sh"
echo "PKG_ROOT resolve: $PKG_ROOT/scripts/resolve-pkg-root.sh"
echo "Tip: clone obra/superpowers once, then symlink into each skill home; verify-pins probes all three."
