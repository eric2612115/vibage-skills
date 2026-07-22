#!/usr/bin/env bash
# Checklist only — does NOT prove nested subagents actually ran.
set -euo pipefail
LOCATE="${1:-}"
if [[ -z "$LOCATE" || ! -f "$LOCATE" ]]; then
  echo "Usage: $0 /path/to/WAR-ROOM-LOCATE.md" >&2
  exit 2
fi
fail() { echo "VERIFY_REPORT_FAIL: $*" >&2; exit 1; }
grep -qiE '^##[[:space:]]*Nested pass' "$LOCATE" || fail "missing ## Nested pass heading"
grep -qiE 'Investigators' "$LOCATE" || fail "Nested pass missing Investigators"
grep -qiE 'Reviewers' "$LOCATE" || fail "Nested pass missing Reviewers"
grep -qiE 'Mode:[[:space:]]*(full nested|degraded)' "$LOCATE" || fail "Nested pass missing Mode: full nested|degraded"
if ! grep -qE '`[^`]+/[A-Za-z0-9_.-]+`|/[A-Za-z0-9_./-]+\.(ts|tsx|js|jsx|py|go|md|yml|yaml|json)' "$LOCATE"; then
  fail "no path-like evidence line found"
fi
echo "VERIFY_REPORT_OK: $LOCATE"
exit 0
