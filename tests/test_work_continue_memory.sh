#!/usr/bin/env bash
# Phrase/fixture gate for WORK_CONTINUE memory (∉ Tier-0).
# Success token WORK_CONTINUE_FIXTURE_OK ≠ Proven-green ≠ locate DONE.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "FAIL: $*"; exit 1; }

TEMPLATE="$ROOT/references/hub/WORK_CONTINUE.md"
FIX="$ROOT/tests/fixtures/work_continue"
REQUIRED=(work_root run_id dual_report_uris inherited_finding_ids next_step phase side_quest forbidden updated_at)

[[ -f "$TEMPLATE" ]] || fail "missing $TEMPLATE"

for k in "${REQUIRED[@]}"; do
  grep -Fq "$k" "$TEMPLATE" || fail "template missing heading token $k"
done

grep -Fq 'FILL_AFTER_LOCATE' "$TEMPLATE" || fail "template must contain FILL_AFTER_LOCATE seed marker"
grep -Fq 'MUST-NOT' "$TEMPLATE" || fail "template missing MUST-NOT block"
grep -Fq 'hub workspace' "$TEMPLATE" || fail "template missing hub-relative path resolution note"

# Seed template must not look like a live verifiable contract
grep -Eq 'phase:[[:space:]]*blocked' "$TEMPLATE" || fail "seed template must set phase: blocked"

check_headings() {
  local f="$1"
  for k in "${REQUIRED[@]}"; do
    grep -Fq "$k" "$f" || return 1
  done
  return 0
}

[[ -f "$FIX/ok.md" ]] || fail "missing fixture ok.md"
check_headings "$FIX/ok.md" || fail "ok.md missing required headings"

[[ -f "$FIX/missing_work_root.md" ]] || fail "missing fixture missing_work_root.md"
if grep -Eq '^work_root:[[:space:]]*[^[:space:]]' "$FIX/missing_work_root.md" 2>/dev/null; then
  # allow heading without value; reject filled work_root
  if grep -Eq '^work_root:[[:space:]]+\S+' "$FIX/missing_work_root.md"; then
    fail "missing_work_root.md must not have a filled work_root value"
  fi
fi

for name in phase_blocked empty_forbidden missing_dual_reports seed_placeholders empty_inherited tbd_next_step; do
  [[ -f "$FIX/${name}.md" ]] || fail "missing fixture ${name}.md"
done

# Firewall: not wired into Tier-0 / pack-health / assert_gate
for s in scripts/test-tier0.sh scripts/pack-health.sh scripts/assert_gate.sh; do
  if [[ -f "$ROOT/$s" ]] && grep -Fq 'work_continue' "$ROOT/$s"; then
    fail "$s must not reference work_continue"
  fi
  if [[ -f "$ROOT/$s" ]] && grep -Fq 'verify-work-continue' "$ROOT/$s"; then
    fail "$s must not reference verify-work-continue"
  fi
done

echo "WORK_CONTINUE_FIXTURE_OK"
