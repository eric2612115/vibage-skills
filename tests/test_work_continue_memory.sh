#!/usr/bin/env bash
# Phrase/fixture + verify gate for WORK_CONTINUE memory (∉ Tier-0).
# WORK_CONTINUE_FIXTURE_OK ≠ Proven-green ≠ locate DONE.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "FAIL: $*"; exit 1; }

TEMPLATE="$ROOT/references/hub/WORK_CONTINUE.md"
FIX="$ROOT/tests/fixtures/work_continue"
VERIFY="$ROOT/scripts/verify-work-continue.sh"
REQUIRED=(work_root run_id dual_report_uris inherited_finding_ids next_step phase side_quest forbidden updated_at)

[[ -f "$TEMPLATE" ]] || fail "missing $TEMPLATE"
[[ -x "$VERIFY" || -f "$VERIFY" ]] || fail "missing $VERIFY"
chmod +x "$VERIFY" 2>/dev/null || true

for k in "${REQUIRED[@]}"; do
  grep -Fq "$k" "$TEMPLATE" || fail "template missing heading token $k"
done

grep -Fq 'FILL_AFTER_LOCATE' "$TEMPLATE" || fail "template must contain FILL_AFTER_LOCATE seed marker"
grep -Fq 'MUST-NOT' "$TEMPLATE" || fail "template missing MUST-NOT block"
grep -Fq 'hub workspace' "$TEMPLATE" || fail "template missing hub-relative path resolution note"
grep -Eq 'phase:[[:space:]]*blocked' "$TEMPLATE" || fail "seed template must set phase: blocked"

for name in ok missing_work_root phase_blocked empty_forbidden missing_dual_reports seed_placeholders empty_inherited tbd_next_step duplicate_dual; do
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

# --- verify matrix on temp hubs ---
run_verify_fixture() {
  local fixture="$1"
  local expect_ok="$2" # ok|fail
  local tmp
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/apps/demo-child" "$tmp/docs/vibage/RUNS"
  cp "$FIX/${fixture}.md" "$tmp/docs/vibage/WORK_CONTINUE.md"
  # dual report files for fixtures that reference them
  : >"$tmp/VIBAGE-ISSUE-OWNER.md"
  : >"$tmp/VIBAGE-ISSUE-LOCATE.md"
  set +e
  out="$(bash "$VERIFY" "$tmp" 2>&1)"
  ec=$?
  set -e
  rm -rf "$tmp"
  if [[ "$expect_ok" == "ok" ]]; then
    [[ $ec -eq 0 ]] || fail "verify expected OK for $fixture: $out"
    echo "$out" | grep -Fq 'WORK_CONTINUE_VERIFY_OK' || fail "missing WORK_CONTINUE_VERIFY_OK for $fixture"
  else
    [[ $ec -ne 0 ]] || fail "verify expected FAIL for $fixture but passed: $out"
    echo "$out" | grep -Fq 'FAIL:' || fail "verify FAIL for $fixture missing FAIL: token: $out"
  fi
}

run_verify_fixture ok ok
run_verify_fixture missing_work_root fail
run_verify_fixture phase_blocked fail
run_verify_fixture empty_forbidden fail
run_verify_fixture missing_dual_reports fail
run_verify_fixture seed_placeholders fail
run_verify_fixture empty_inherited fail
run_verify_fixture tbd_next_step fail
run_verify_fixture duplicate_dual fail

# Package template as hub file must fail verify
tmp_seed="$(mktemp -d)"
mkdir -p "$tmp_seed/docs/vibage/RUNS" "$tmp_seed/apps/demo-child"
cp "$TEMPLATE" "$tmp_seed/docs/vibage/WORK_CONTINUE.md"
set +e
seed_out="$(bash "$VERIFY" "$tmp_seed" 2>&1)"
seed_ec=$?
set -e
rm -rf "$tmp_seed"
[[ $seed_ec -ne 0 ]] || fail "package seed template must fail verify: $seed_out"

# --- skill / adapter phrase gates (filled as later tasks land; require files exist) ---
LOCATE="$ROOT/skills/vibage-issue-locate/SKILL.md"
USING="$ROOT/skills/using-vibage/SKILL.md"
[[ -f "$LOCATE" && -f "$USING" ]] || fail "missing locate/using skills"

# D1 + exception honesty (Task 3) — lock order / anti false-green phrases
for f in "$LOCATE" "$USING"; do
  grep -Fq 'verify-work-continue' "$f" || fail "$f must mention verify-work-continue"
  grep -Fq 'WORK_CONTINUE' "$f" || fail "$f must mention WORK_CONTINUE"
  grep -Fq 'WORK_CONTINUE_EXCEPTION' "$f" || fail "$f must mention WORK_CONTINUE_EXCEPTION"
  grep -Fq 'WORK_CONTINUE_VERIFY_OK' "$f" || fail "$f must mention WORK_CONTINUE_VERIFY_OK"
  grep -Fq 'locate DONE (WORK_CONTINUE_EXCEPTION)' "$f" || fail "$f missing exception DONE phrase"
  grep -Fq 'Dual reports alone ≠ locate DONE' "$f" || grep -Fq 'Dual reports alone ≠ DONE' "$f" \
    || fail "$f must say dual reports alone ≠ DONE"
  grep -Fq 'no DONE-then-backfill' "$f" || fail "$f must forbid DONE-then-backfill without exception file"
  grep -Fq 'never `WORK_CONTINUE_VERIFY_OK`' "$f" || grep -Fq 'never WORK_CONTINUE_VERIFY_OK' "$f" \
    || fail "$f exception path must forbid WORK_CONTINUE_VERIFY_OK"
done
grep -Fq 'WORK_CONTINUE_VERIFY_OK` alone ≠ locate DONE' "$LOCATE" \
  || grep -Fq 'WORK_CONTINUE_VERIFY_OK alone ≠ locate DONE' "$LOCATE" \
  || fail "locate must say VERIFY_OK alone ≠ locate DONE"
# Banned leftovers (coexistence FAIL)
if grep -Fq 'After dual reports exist / phase `done`' "$LOCATE"; then
  fail "banned leftover still in locate skill: After dual reports exist / phase done"
fi
if grep -Fq 'After dual reports exist / phase `done`' "$USING"; then
  fail "banned leftover still in using-vibage"
fi

# Routing / adapters (Task 4)
RS="$ROOT/references/routing-scope.md"
HS="$ROOT/references/hard-stops.md"
grep -Fq 'WORK_CONTINUE' "$RS" || fail "routing-scope must mention WORK_CONTINUE"
grep -Fq 'WORK_CONTINUE' "$HS" || fail "hard-stops must mention WORK_CONTINUE"
for a in \
  adapters/cursor/vibage.mdc \
  adapters/claude/CLAUDE.vibage.md \
  adapters/shared/AGENTS.vibage.md \
  adapters/codex/AGENTS.vibage.md
do
  grep -Fq 'WORK_CONTINUE' "$ROOT/$a" || fail "$a must mention WORK_CONTINUE"
done

EXC="$ROOT/references/hub/WORK_CONTINUE_EXCEPTION.md"
[[ -f "$EXC" ]] || fail "missing WORK_CONTINUE_EXCEPTION template"
for k in owner_quote reason run_id updated_at; do
  grep -Fq "$k" "$EXC" || fail "exception template missing $k"
done

echo "WORK_CONTINUE_FIXTURE_OK"
