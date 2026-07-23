#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LEGACY_RE='VIBAGE-OWNER\.md|VIBAGE-LOCATE\.md|WAR-ROOM-OWNER|WAR-ROOM-LOCATE'

# Legacy names must NOT be the instructed deliverable in skill/templates
if rg -n "$LEGACY_RE" \
  "$ROOT/skills/vibage-locate/SKILL.md" \
  "$ROOT/references/owner-report-template.md" \
  "$ROOT/references/locate-report-template.md"; then
  echo "FAIL: legacy report names still present in live templates/skill"
  exit 1
fi

# Also fail if legacy names appear in rules / adapters / prompts
if rg -n "$LEGACY_RE" \
  "$ROOT/rules" \
  "$ROOT/adapters" \
  "$ROOT/prompts"; then
  echo "FAIL: legacy report names still present in rules/adapters/prompts"
  exit 1
fi

# Legacy filenames under examples/ must not remain
if find "$ROOT/examples" -type f \( \
  -name '*VIBAGE-OWNER*' -o -name '*VIBAGE-LOCATE*' -o \
  -name '*WAR-ROOM-OWNER*' -o -name '*WAR-ROOM-LOCATE*' \
\) ! -name '*VIBAGE-ISSUE-*' | grep -q .; then
  echo "FAIL: legacy report filenames still present under examples/"
  find "$ROOT/examples" -type f \( \
    -name '*VIBAGE-OWNER*' -o -name '*VIBAGE-LOCATE*' -o \
    -name '*WAR-ROOM-OWNER*' -o -name '*WAR-ROOM-LOCATE*' \
  \) ! -name '*VIBAGE-ISSUE-*'
  exit 1
fi

rg -n 'VIBAGE-ISSUE-OWNER\.md' "$ROOT/skills/vibage-locate/SKILL.md" \
  "$ROOT/references/owner-report-template.md"
rg -n 'VIBAGE-ISSUE-LOCATE\.md' "$ROOT/skills/vibage-locate/SKILL.md" \
  "$ROOT/references/locate-report-template.md"
echo "OK: hard-cut names present; legacy absent"
