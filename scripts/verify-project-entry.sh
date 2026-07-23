#!/usr/bin/env bash
# Verify parent-workspace thin entry routers (Cursor + Claude + Codex).
# Global skills ≠ project routing. Parent only — not each child repo.
# MUST NOT be wired into scripts/test-tier0.sh.
set -euo pipefail
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

fail() { echo "FAIL: $*" >&2; exit 1; }

if [[ $# -lt 1 || -z "${1:-}" ]]; then
  cat >&2 <<EOF
FAIL: parent workspace path required.

Usage: $0 /path/to/parent-workspace

Global skill install (~/.cursor/skills, etc.) is NOT project session routing.
Install parent routers first:
  bash $PKG_ROOT/scripts/install.sh --with-project-rule=/path/to/parent-workspace
Then re-run this verify.
EOF
  exit 1
fi

PARENT="$(cd "$1" && pwd)" || fail "parent is not a directory: $1"

MDC="$PARENT/.cursor/rules/vibage.mdc"
CLAUDE_MD="$PARENT/CLAUDE.md"
CLAUDE_ENTRY="$PARENT/.claude/vibage-entry.md"
AGENTS_MD="$PARENT/AGENTS.md"

[[ -f "$MDC" ]] || fail "missing Cursor rule: $MDC"
[[ -f "$CLAUDE_MD" ]] || fail "missing CLAUDE.md: $CLAUDE_MD"
[[ -f "$CLAUDE_ENTRY" ]] || fail "missing Claude entry: $CLAUDE_ENTRY"
[[ -f "$AGENTS_MD" ]] || fail "missing AGENTS.md: $AGENTS_MD"

grep -Fq '<!-- vibage:start -->' "$CLAUDE_MD" || fail "CLAUDE.md missing vibage:start marker"
grep -Fq '<!-- vibage:end -->' "$CLAUDE_MD" || fail "CLAUDE.md missing vibage:end marker"
grep -Fq '<!-- vibage:start -->' "$AGENTS_MD" || fail "AGENTS.md missing vibage:start marker"
grep -Fq '<!-- vibage:end -->' "$AGENTS_MD" || fail "AGENTS.md missing vibage:end marker"

# Marker SSOT (adapters must include these strings)
REQUIRED=(
  'vibage-init'
  'vibage-orient'
  'vibage-issue-locate'
  'using-vibage'
  'STATUS.md'
  'docs/vibage/STATUS.md'
  'do not paste nested locate procedure'
  'no register CTA'
  'hard-stops.md'
  'do not type bash'
)

ENTRY_FILES=("$MDC" "$CLAUDE_MD" "$CLAUDE_ENTRY" "$AGENTS_MD")

for f in "${ENTRY_FILES[@]}"; do
  for m in "${REQUIRED[@]}"; do
    grep -Fq "$m" "$f" || fail "missing marker \"$m\" in $f"
  done
done

# Executable denylist (positive CTA / soft CTA). Negative honesty phrasing is allowed.
DENY_RE='(Soft CTA|register now|sign up|create an API key|paste your API key|pairing code|get your API key)'
for f in "${ENTRY_FILES[@]}"; do
  if grep -Eiq "$DENY_RE" "$f"; then
    fail "forbidden CTA / Soft CTA phrasing in $f"
  fi
done

# Cursor host-best: sessionStart hook files (Claude/Codex must NOT be required to have these)
HOOK_JSON="$PARENT/.cursor/hooks.json"
HOOK_SH="$PARENT/.cursor/hooks/vibage-session-start.sh"
[[ -f "$HOOK_JSON" ]] || fail "missing Cursor hooks.json: $HOOK_JSON"
[[ -f "$HOOK_SH" ]] || fail "missing Cursor hook script: $HOOK_SH"
[[ -x "$HOOK_SH" ]] || fail "Cursor hook script not executable: $HOOK_SH"
grep -Fq 'vibage-session-start' "$HOOK_JSON" || fail "hooks.json missing vibage-session-start command"
grep -Fq 'sessionStart' "$HOOK_JSON" || fail "hooks.json missing sessionStart"

echo "PROJECT_ENTRY_OK parent=$PARENT"
echo "Note: PROJECT_ENTRY_OK ≠ hub CONFIRM / locate DONE."
echo "Note: Cursor hooks installed; Claude/Codex use always-on blocks (host-best). See references/host-best-session-entry.md"
