#!/usr/bin/env bash
# Optional-track proof for 架構檢視 / service_map usable gates.
# MUST NOT be wired into scripts/test-tier0.sh.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERIFY="$ROOT/scripts/verify-service-map.sh"
ARCH_SKILL="$ROOT/skills/vibage-arch-review/SKILL.md"
SAT_ARCH="$ROOT/docs/superpowers/specs/satellites/SAT-arch-review.md"
SAT_MAP="$ROOT/docs/superpowers/specs/satellites/SAT-map-schema.md"
MAP_EX="$ROOT/docs/superpowers/specs/satellites/service_map.example.json"
FIX_Q="$ROOT/tests/fixtures/service-map/qualified.json"

pass() { echo "OK: $*"; }
fail() { echo "FAIL: $*" >&2; exit 1; }

[[ -x "$VERIFY" || -f "$VERIFY" ]] || fail "missing verify-service-map.sh"
[[ -f "$ARCH_SKILL" ]] || fail "missing vibage-arch-review SKILL"
[[ -f "$SAT_ARCH" ]] || fail "missing SAT-arch-review"
[[ -f "$SAT_MAP" ]] || fail "missing SAT-map-schema"
[[ -f "$MAP_EX" ]] || fail "missing service_map.example.json"
[[ -f "$FIX_Q" ]] || fail "missing qualified fixture"

# Skill / SAT no longer stub-only
rg -q 'usable' "$ARCH_SKILL" || fail "skill must claim usable"
rg -q 'stub —|Status:\*\* stub|Status: stub' "$ARCH_SKILL" && fail "skill must not remain stub-only" || true
rg -q 'Usable procedure|verify-service-map' "$ARCH_SKILL" || fail "skill missing usable procedure / verify"
rg -q '\(stub\)' "$SAT_ARCH" && fail "SAT-arch-review must not remain stub-titled" || true
rg -q '\(stub\)' "$SAT_MAP" && fail "SAT-map-schema must not remain stub-titled" || true
rg -q 'service_map' "$SAT_ARCH" || fail "SAT-arch-review missing service_map"
rg -q 'MEDIUM' "$SAT_MAP" || fail "SAT-map-schema missing MEDIUM quality bar"
rg -q 'Architecture Pass' "$SAT_ARCH" || fail "SAT-arch-review must deny Architecture Pass"
rg -q 'locate DONE' "$ARCH_SKILL" || fail "skill must keep locate DONE independent"

# Example passes floor keys
python3 - "$MAP_EX" <<'PY'
import json, sys
obj = json.load(open(sys.argv[1], encoding="utf-8"))
assert obj.get("pipeline_id") == "service_map"
assert obj.get("quality_bar") == "MEDIUM"
assert obj.get("scale") in ("Tiny", "Subset", "Large")
assert isinstance(obj.get("services"), list) and len(obj["services"]) >= 1
assert all(isinstance(s.get("id"), str) and s["id"].strip() for s in obj["services"])
print("OK: service_map.example.json floor keys")
PY

install_map() {
  local dir="$1" src="$2"
  mkdir -p "$dir/docs/vibage/maps"
  if [[ -n "$src" ]]; then
    cp "$src" "$dir/docs/vibage/maps/service_map.json"
  fi
}

expect_rc() {
  local label="$1" expect="$2" ws="$3"
  set +e
  "$VERIFY" "$ws" >/tmp/vsm_out.$$ 2>/tmp/vsm_err.$$
  local rc=$?
  set -e
  if [[ "$expect" -eq 0 ]]; then
    [[ "$rc" -eq 0 ]] || {
      cat /tmp/vsm_err.$$ >&2
      fail "$label: expected rc=0 got $rc"
    }
    pass "$label (rc=0)"
  else
    [[ "$rc" -ne 0 ]] || fail "$label: expected non-zero got 0"
    pass "$label (rc=$rc)"
  fi
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP" /tmp/vsm_out.$$ /tmp/vsm_err.$$ 2>/dev/null || true' EXIT

# 1) happy / qualified (+ extra keys in fixture) → 0
WS1="$TMP/happy"
install_map "$WS1" "$FIX_Q"
expect_rc "qualified map" 0 "$WS1"

# 2) missing map → non-zero
WS2="$TMP/missing"
mkdir -p "$WS2/docs/vibage/maps"
expect_rc "missing map" 1 "$WS2"

# 3) bad quality_bar → non-zero
WS3="$TMP/bad_qb"
install_map "$WS3" "$ROOT/tests/fixtures/service-map/underqualified-bad-quality.json"
expect_rc "bad quality_bar" 1 "$WS3"

# 4) empty services → non-zero
WS4="$TMP/empty_svc"
install_map "$WS4" "$ROOT/tests/fixtures/service-map/underqualified-empty-services.json"
expect_rc "empty services" 1 "$WS4"

# 5) wrong pipeline_id → non-zero
WS5="$TMP/wrong_pid"
install_map "$WS5" "$ROOT/tests/fixtures/service-map/underqualified-wrong-pipeline.json"
expect_rc "wrong pipeline_id" 1 "$WS5"

# 6) extra keys still OK (qualified fixture already has edges + extra_future_key)
# Also: inline map with only required keys + extras
WS6="$TMP/extra_ok"
mkdir -p "$WS6/docs/vibage/maps"
cat >"$WS6/docs/vibage/maps/service_map.json" <<'EOF'
{
  "schema_version": "1",
  "pipeline_id": "service_map",
  "scale": "Large",
  "quality_bar": "MEDIUM",
  "services": [{"id": "core", "name": "Core"}],
  "graphify": {"deferred": true},
  "coverage": {"pct": 0},
  "totally_unknown": 42
}
EOF
expect_rc "extra keys still OK" 0 "$WS6"

# 7) service missing id → non-zero
WS7="$TMP/no_id"
install_map "$WS7" "$ROOT/tests/fixtures/service-map/underqualified-missing-service-id.json"
expect_rc "service missing id" 1 "$WS7"

# Example itself via temp install → 0
WS8="$TMP/example"
install_map "$WS8" "$MAP_EX"
expect_rc "example.json qualifies" 0 "$WS8"

# Thin shared contracts (must NOT invoke verify-service-map inside optional gates)
bash "$ROOT/tests/test_optional_track_gates.sh"

pass "arch-review usable fixtures"
echo "ALL arch_review_usable tests passed"
