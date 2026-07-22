#!/usr/bin/env bash
# Checklist only — does NOT prove nested subagents actually ran.
# Usage: verify-report.sh <WAR-ROOM-LOCATE.md> [RUNS/<run_id>.json]
# Second arg: path to RunEnvelope JSON. When Mode in the MD is "full nested",
# the RUNS json is REQUIRED and must pass verify-run.sh.
set -euo pipefail
LOCATE="${1:-}"
RUNS_JSON="${2:-}"
if [[ -z "$LOCATE" || ! -f "$LOCATE" ]]; then
  echo "Usage: $0 /path/to/WAR-ROOM-LOCATE.md [RUNS/<run_id>.json]" >&2
  exit 2
fi
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "VERIFY_REPORT_FAIL: $*" >&2; exit 1; }
grep -qiE '^##[[:space:]]*Nested pass' "$LOCATE" || fail "missing ## Nested pass heading"
grep -qiE 'Investigators' "$LOCATE" || fail "Nested pass missing Investigators"
grep -qiE 'Reviewers' "$LOCATE" || fail "Nested pass missing Reviewers"
grep -qiE 'Mode:[[:space:]]*(full nested|degraded)' "$LOCATE" || fail "Nested pass missing Mode: full nested|degraded"
if ! grep -qE '`[^`]+/[A-Za-z0-9_.-]+`|/[A-Za-z0-9_./-]+\.(ts|tsx|js|jsx|py|go|md|yml|yaml|json)' "$LOCATE"; then
  fail "no path-like evidence line found"
fi
MODE_LINE="$(grep -iE 'Mode:[[:space:]]*(full nested|degraded)' "$LOCATE" | head -n1 || true)"
if echo "$MODE_LINE" | grep -qiE 'full nested'; then
  [[ -n "$RUNS_JSON" && -f "$RUNS_JSON" ]] || fail "Mode full nested requires second arg: RUNS/<run_id>.json"
fi
if [[ -n "$RUNS_JSON" ]]; then
  [[ -f "$RUNS_JSON" ]] || fail "RUNS json not found: $RUNS_JSON"
  "$PKG_ROOT/scripts/verify-run.sh" "$RUNS_JSON" || fail "RUNS Mode honesty failed: $RUNS_JSON"
fi
echo "VERIFY_REPORT_OK: $LOCATE"
exit 0
