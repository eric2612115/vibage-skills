#!/usr/bin/env bash
# Cursor project sessionStart — emit using-vibage pointer as JSON.
# Cursor may drop additional_context (known race); .cursor/rules/vibage.mdc remains reliable.
set -euo pipefail

resolve_pkg_root() {
  if [[ -n "${VIBAGE_PKG_ROOT:-}" && -f "${VIBAGE_PKG_ROOT}/skills/using-vibage/SKILL.md" ]]; then
    printf '%s' "$VIBAGE_PKG_ROOT"
    return 0
  fi
  local home name skill_dir pkg
  for home in "${HOME}/.cursor/skills" "${HOME}/.claude/skills" "${HOME}/.agents/skills"; do
    for name in using-vibage vibage-init vibage-issue-locate; do
      if [[ -e "$home/$name/SKILL.md" ]]; then
        skill_dir="$(cd "$home/$name" && pwd -P)"
        pkg="$(cd "$skill_dir/../.." && pwd)"
        if [[ -f "$pkg/skills/using-vibage/SKILL.md" ]]; then
          printf '%s' "$pkg"
          return 0
        fi
      fi
    done
  done
  return 1
}

PKG_ROOT="$(resolve_pkg_root || true)"
SKILL=""
if [[ -n "$PKG_ROOT" && -f "$PKG_ROOT/skills/using-vibage/SKILL.md" ]]; then
  SKILL="$(cat "$PKG_ROOT/skills/using-vibage/SKILL.md")"
fi

if [[ ${#SKILL} -gt 12000 ]]; then
  SKILL="${SKILL:0:12000}
…(truncated)…"
fi

escape_json() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

ctx="VIBAGE session routing (using-vibage). Parent routers SSOT: .cursor/rules/vibage.mdc. Read package STATUS.md first. Route: no hub STATUS → vibage-init; no CONFIRM → vibage-orient; CONFIRM OK → vibage-issue-locate. Thin entry — do not paste nested locate procedure. no register CTA. Owner: do not type bash; agent runs scripts. After locate DONE → finishing options in using-vibage."
if [[ -n "$SKILL" ]]; then
  ctx="${ctx}"$'\n\n'"--- using-vibage SKILL.md ---"$'\n'"${SKILL}"
fi

escaped="$(escape_json "$ctx")"
printf '{"additional_context":"%s"}\n' "$escaped"
exit 0
