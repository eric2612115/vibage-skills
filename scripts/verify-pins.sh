#!/usr/bin/env bash
# Verify pinned superpowers SHA. Probes Cursor / Claude / Codex skill homes.
set -euo pipefail
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
expected="$(grep -E '^superpowers_sha=' "$PKG_ROOT/DEPENDENCIES.md" | head -1 | cut -d= -f2 | tr -d '[:space:]')"
if [[ -z "$expected" || ${#expected} -lt 40 ]]; then
  echo "ERROR: superpowers_sha missing/invalid in DEPENDENCIES.md" >&2
  exit 1
fi

candidates=()
if [[ -n "${SUPERPOWERS_ROOT:-}" ]]; then
  candidates+=("$SUPERPOWERS_ROOT")
fi
candidates+=(
  "$HOME/.cursor/skills/superpowers"
  "$HOME/.claude/skills/superpowers"
  "$HOME/.agents/skills/superpowers"
)

found=""
for root in "${candidates[@]}"; do
  if [[ -d "$root/.git" ]] || [[ -d "$root" && -e "$root/.git" ]]; then
    if git -C "$root" rev-parse HEAD >/dev/null 2>&1; then
      found="$root"
      break
    fi
  fi
done

if [[ -z "$found" ]]; then
  echo "ERROR: superpowers checkout not found in:" >&2
  for root in "${candidates[@]}"; do
    echo "  - $root" >&2
  done
  echo "Clone obra/superpowers, checkout the pin SHA, symlink into skill homes, re-run." >&2
  exit 1
fi

actual="$(git -C "$found" rev-parse HEAD)"
if [[ "$actual" != "$expected" ]]; then
  echo "ERROR: superpowers pin mismatch at $found expected=$expected actual=$actual" >&2
  exit 1
fi
echo "OK: superpowers@$actual ($found)"
exit 0
