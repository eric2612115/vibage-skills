#!/usr/bin/env bash
# Optional-track proof for issue-fix usable gates.
# MUST NOT be wired into scripts/test-tier0.sh.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERIFY="$ROOT/scripts/verify-issue-fix-unlock.sh"
FIX_SKILL="$ROOT/skills/vibage-issue-fix/SKILL.md"
SAT="$ROOT/docs/superpowers/specs/satellites/SAT-issue-fix-unlock.md"
POLICY_EX="$ROOT/docs/superpowers/specs/satellites/OWNER_POLICY.example.json"
UNLOCK_EX="$ROOT/docs/superpowers/specs/satellites/unlock.example.json"

pass() { echo "OK: $*"; }
fail() { echo "FAIL: $*" >&2; exit 1; }

[[ -x "$VERIFY" || -f "$VERIFY" ]] || fail "missing verify-issue-fix-unlock.sh"
[[ -f "$FIX_SKILL" ]] || fail "missing vibage-issue-fix SKILL"
[[ -f "$SAT" ]] || fail "missing SAT-issue-fix-unlock"
[[ -f "$POLICY_EX" ]] || fail "missing OWNER_POLICY.example.json"
[[ -f "$UNLOCK_EX" ]] || fail "missing unlock.example.json"

# Skill / SAT no longer stub-only
rg -q 'usable' "$FIX_SKILL" || fail "skill must claim usable"
rg -q 'stub —|Status:\*\* stub|Status: stub' "$FIX_SKILL" && fail "skill must not remain stub-only" || true
# Positive: usable procedure present; stub title gone
rg -q 'Usable procedure|verify-issue-fix-unlock' "$FIX_SKILL" || fail "skill missing usable procedure / verify"
rg -q '\(stub\)' "$SAT" && fail "SAT must not remain stub-titled" || true
rg -q 'Dual consent|ISSUE_FIX_UNLOCK' "$SAT" || fail "SAT missing dual consent / unlock path"

# OWNER_POLICY.example required key
python3 - "$POLICY_EX" <<'PY'
import json, sys
obj = json.load(open(sys.argv[1], encoding="utf-8"))
pref = obj.get("fix_preference")
if pref not in ("YES", "NO"):
    raise SystemExit(f"OWNER_POLICY.example.json fix_preference must be YES|NO, got {pref!r}")
print("OK: OWNER_POLICY.example.json fix_preference")
PY

write_policy() {
  local dir="$1" pref="$2"
  mkdir -p "$dir/docs/vibage"
  printf '%s\n' "{\"fix_preference\": \"${pref}\"}" >"$dir/docs/vibage/OWNER_POLICY.json"
}

write_unlock() {
  local dir="$1"
  local run_id="${2:-run_example}"
  local paths_json="${3:-[\"app/example.py\"]}"
  cat >"$dir/docs/vibage/ISSUE_FIX_UNLOCK.json" <<EOF
{
  "schema_version": "1",
  "locate_run_id": "${run_id}",
  "allowed_paths": ${paths_json},
  "confirmed_at": "2026-07-23T00:00:00Z",
  "confirmed_by": "owner"
}
EOF
}

expect_rc() {
  local label="$1" expect="$2" ws="$3"
  set +e
  "$VERIFY" "$ws" >/tmp/vif_out.$$ 2>/tmp/vif_err.$$
  local rc=$?
  set -e
  if [[ "$expect" -eq 0 ]]; then
    [[ "$rc" -eq 0 ]] || {
      cat /tmp/vif_err.$$ >&2
      fail "$label: expected rc=0 got $rc"
    }
    pass "$label (rc=0)"
  else
    [[ "$rc" -ne 0 ]] || fail "$label: expected non-zero got 0"
    pass "$label (rc=$rc)"
  fi
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP" /tmp/vif_out.$$ /tmp/vif_err.$$ 2>/dev/null || true' EXIT

# 1) YES + valid unlock → 0
WS1="$TMP/yes_valid"
write_policy "$WS1" "YES"
write_unlock "$WS1"
expect_rc "YES+valid unlock" 0 "$WS1"

# 2) NO → non-zero
WS2="$TMP/pref_no"
write_policy "$WS2" "NO"
write_unlock "$WS2"
expect_rc "preference NO" 1 "$WS2"

# 3) YES missing unlock → non-zero
WS3="$TMP/yes_missing_unlock"
write_policy "$WS3" "YES"
expect_rc "YES missing unlock" 1 "$WS3"

# 4) unlock with NO preference → non-zero
WS4="$TMP/unlock_with_no"
write_policy "$WS4" "NO"
write_unlock "$WS4"
expect_rc "unlock with NO preference" 1 "$WS4"

# 5) bad schema → non-zero (empty locate_run_id + empty allowed_paths)
WS5="$TMP/bad_schema"
write_policy "$WS5" "YES"
mkdir -p "$WS5/docs/vibage"
cat >"$WS5/docs/vibage/ISSUE_FIX_UNLOCK.json" <<'EOF'
{
  "schema_version": "1",
  "locate_run_id": "",
  "allowed_paths": [],
  "confirmed_at": "2026-07-23T00:00:00Z",
  "confirmed_by": "owner"
}
EOF
expect_rc "bad schema" 1 "$WS5"

# Also call optional track gates (thin shared contracts) OR duplicate stub asserts above
bash "$ROOT/tests/test_optional_track_gates.sh"

pass "issue-fix usable fixtures"
echo "ALL issue_fix_usable tests passed"
