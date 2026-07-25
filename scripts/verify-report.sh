#!/usr/bin/env bash
# Checklist + deliverable token lint — does NOT prove nested subagents actually ran.
# Does NOT prove chat honesty. Held tokens alone ≠ proof (need ## Token evidence fence).
# Usage:
#   verify-report.sh <VIBAGE-ISSUE-LOCATE.md> [RUNS/<run_id>.json] [--owner <VIBAGE-ISSUE-OWNER.md>]
# If --owner omitted, lints sibling VIBAGE-ISSUE-OWNER.md next to LOCATE when present.
set -euo pipefail

ARGS=("$@")
LOCATE="${ARGS[0]:-}"
RUNS_JSON=""
OWNER=""
i=1
while [[ $i -lt ${#ARGS[@]} ]]; do
  a="${ARGS[$i]}"
  if [[ "$a" == "--owner" ]]; then
    i=$((i + 1))
    OWNER="${ARGS[$i]:-}"
  elif [[ -z "$RUNS_JSON" && "$a" != --* ]]; then
    RUNS_JSON="$a"
  fi
  i=$((i + 1))
done

if [[ -z "$LOCATE" || ! -f "$LOCATE" ]]; then
  echo "Usage: $0 /path/to/VIBAGE-ISSUE-LOCATE.md [RUNS/<run_id>.json] [--owner /path/to/VIBAGE-ISSUE-OWNER.md]" >&2
  exit 2
fi
BASE="$(basename "$LOCATE")"
_legacy_owner="VIBAGE-"'OWNER.md'
_legacy_locate="VIBAGE-"'LOCATE.md'
if [[ "$BASE" == "$_legacy_owner" || "$BASE" == "$_legacy_locate" ]]; then
  echo "VERIFY_REPORT_FAIL: legacy report name '$BASE'; prefer VIBAGE-ISSUE-OWNER.md / VIBAGE-ISSUE-LOCATE.md" >&2
  exit 1
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
MD_FULL_NESTED=0
if echo "$MODE_LINE" | grep -qiE 'full nested'; then
  MD_FULL_NESTED=1
  [[ -n "$RUNS_JSON" && -f "$RUNS_JSON" ]] || fail "Mode full nested requires second arg: RUNS/<run_id>.json"
fi
if [[ -n "$RUNS_JSON" ]]; then
  [[ -f "$RUNS_JSON" ]] || fail "RUNS json not found: $RUNS_JSON"
  "$PKG_ROOT/scripts/verify-run.sh" "$RUNS_JSON" || fail "RUNS Mode honesty failed: $RUNS_JSON"
  if [[ "$MD_FULL_NESTED" -eq 1 ]]; then
    RUNS_MODE="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1],encoding="utf-8")).get("mode",""))' "$RUNS_JSON")"
    [[ "$RUNS_MODE" == "full nested" ]] || fail "Mode MD full nested requires RUNS mode == \"full nested\" (got: ${RUNS_MODE:-empty})"
  fi
fi

if [[ -z "$OWNER" ]]; then
  sib="$(dirname "$LOCATE")/VIBAGE-ISSUE-OWNER.md"
  if [[ -f "$sib" ]]; then
    OWNER="$sib"
  fi
fi
LINT_ARGS=("$LOCATE")
if [[ -n "$OWNER" ]]; then
  [[ -f "$OWNER" ]] || fail "owner report not found: $OWNER"
  LINT_ARGS+=("$OWNER")
fi
python3 "$PKG_ROOT/scripts/lib/report_token_lint.py" "${LINT_ARGS[@]}" \
  || fail "narrative token lint failed"

echo "VERIFY_REPORT_OK: $LOCATE"
exit 0
