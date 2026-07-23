#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# Legacy names must NOT be the instructed deliverable in skill/templates
if rg -n 'VIBAGE-OWNER\.md|VIBAGE-LOCATE\.md|WAR-ROOM-OWNER|WAR-ROOM-LOCATE' \
  "$ROOT/skills/vibage-locate/SKILL.md" \
  "$ROOT/references/owner-report-template.md" \
  "$ROOT/references/locate-report-template.md"; then
  echo "FAIL: legacy report names still present in live templates/skill"
  exit 1
fi
rg -n 'VIBAGE-ISSUE-OWNER\.md' "$ROOT/skills/vibage-locate/SKILL.md" \
  "$ROOT/references/owner-report-template.md"
rg -n 'VIBAGE-ISSUE-LOCATE\.md' "$ROOT/skills/vibage-locate/SKILL.md" \
  "$ROOT/references/locate-report-template.md"
echo "OK: hard-cut names present; legacy absent"
