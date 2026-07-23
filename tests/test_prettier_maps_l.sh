#!/usr/bin/env bash
# Plan-L — local-maps deepen proofs ONLY.
# MUST NOT be wired into scripts/test-tier0.sh or tests/test_optional_track_gates.sh.
# MUST NOT require changing scripts/verify-service-map.sh behavior.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GRAPHIFY_GEN="$ROOT/scripts/generate-service-map-graph.sh"
VERIFY="$ROOT/scripts/verify-service-map.sh"
FIX_OK="$ROOT/tests/fixtures/service-map/standard-depth-ok.json"

pass() { echo "OK: $*"; }
fail() { echo "FAIL: $*" >&2; exit 1; }

[[ -f "$FIX_OK" ]] || fail "missing standard-depth-ok fixture"
[[ -f "$VERIFY" ]] || fail "missing verify-service-map.sh"
[[ -f "$GRAPHIFY_GEN" ]] || fail "missing generate-service-map-graph.sh"

install_map() {
  local dir="$1" src="$2"
  mkdir -p "$dir/docs/vibage/maps"
  cp "$src" "$dir/docs/vibage/maps/service_map.json"
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

EMPTY_BIN="$TMP/empty_bin"
mkdir -p "$EMPTY_BIN"

# --- Missing CLI: GRAPHIFY_SKIP + still non-empty Mermaid + OK:MERMAID ---
WS_G="$TMP/mermaid_always"
install_map "$WS_G" "$FIX_OK"
set +e
OUT_G="$(PATH="$EMPTY_BIN:/usr/bin:/bin" "$GRAPHIFY_GEN" "$WS_G" 2>&1)"
RC_G=$?
set -e
[[ "$RC_G" -eq 0 ]] || fail "missing CLI must exit 0, got $RC_G; out=$OUT_G"
echo "$OUT_G" | rg -q 'OK:GRAPHIFY_SKIP' || fail "expected OK:GRAPHIFY_SKIP"
echo "$OUT_G" | rg -qv '^(OK:|FAIL:)' || fail "GRAPHIFY_SKIP must include owner sentence on stdout"
echo "$OUT_G" | rg -q 'OK:MERMAID' || fail "expected OK:MERMAID when map present"
MMD="$WS_G/docs/vibage/maps/graph.mmd"
[[ -s "$MMD" ]] || fail "graph.mmd must exist and be non-empty"
rg -q 'web' "$MMD" || fail "graph.mmd should mention service id web"
rg -q 'billing' "$MMD" || fail "graph.mmd should mention service id billing"
rg -qF -- '-->' "$MMD" || fail "graph.mmd should include --> edges"
# GRAPHIFY_SKIP must not imply no artifact — Mermaid already written
echo "$OUT_G" | rg -qi 'no graph artifact|no mermaid' && fail "GRAPHIFY_SKIP must not claim no graph artifact" || true
echo "$OUT_G" | rg -q 'OK:GRAPHIFY wrote' && fail "must not claim OK:GRAPHIFY wrote for stub/skip" || true
"$VERIFY" "$WS_G" >/dev/null
pass "missing CLI: GRAPHIFY_SKIP + non-empty Mermaid + verify PASS"

# --- Fake CLI non-zero: soft; Mermaid retained ---
FAKE_BIN="$TMP/fake_bin"
mkdir -p "$FAKE_BIN"
cat >"$FAKE_BIN/graphify" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
chmod +x "$FAKE_BIN/graphify"
WS_F="$TMP/fake_cli"
install_map "$WS_F" "$FIX_OK"
set +e
OUT_F="$(PATH="$FAKE_BIN:/usr/bin:/bin" "$GRAPHIFY_GEN" "$WS_F" 2>&1)"
RC_F=$?
set -e
[[ "$RC_F" -eq 0 ]] || fail "fake CLI non-zero must soft exit 0, got $RC_F; out=$OUT_F"
echo "$OUT_F" | rg -q 'OK:MERMAID' || fail "fake CLI path must still OK:MERMAID"
[[ -s "$WS_F/docs/vibage/maps/graph.mmd" ]] || fail "Mermaid must remain after fake CLI failure"
echo "$OUT_F" | rg -q 'OK:GRAPHIFY wrote' && fail "must not claim OK:GRAPHIFY wrote after fake CLI failure" || true
# soft token: SKIP or LIMITATION
echo "$OUT_F" | rg -q 'OK:GRAPHIFY_(SKIP|LIMITATION)' || fail "expected OK:GRAPHIFY_SKIP or OK:GRAPHIFY_LIMITATION"
"$VERIFY" "$WS_F" >/dev/null
pass "fake CLI non-zero soft; Mermaid retained; verify PASS"

# --- Auto COVERAGE_NOTES from JSON counts (single writer) ---
WS_C="$TMP/coverage_auto"
install_map "$WS_C" "$FIX_OK"
NOTES="$WS_C/docs/vibage/maps/COVERAGE_NOTES.md"
rm -f "$NOTES"
set +e
OUT_C="$(PATH="$EMPTY_BIN:/usr/bin:/bin" "$GRAPHIFY_GEN" "$WS_C" 2>&1)"
RC_C=$?
set -e
[[ "$RC_C" -eq 0 ]] || fail "coverage auto generate rc=$RC_C; out=$OUT_C"
[[ -f "$NOTES" ]] || fail "COVERAGE_NOTES.md not auto-written"
rg -q 'services_count:[[:space:]]*2' "$NOTES" || fail "expected services_count: 2"
rg -q 'edges_count:[[:space:]]*1' "$NOTES" || fail "expected edges_count: 1"
echo "$OUT_C" | rg -q 'OK:COVERAGE_NOTES|OK:MERMAID' || fail "expected coverage/mermaid OK tokens"
"$VERIFY" "$WS_C" >/dev/null
# verify does not require notes
rm -f "$NOTES"
"$VERIFY" "$WS_C" >/dev/null
pass "auto COVERAGE_NOTES counts; not a verify gate"

# --- Isolation from Tier-0 / optional gates ---
rg -q 'test_prettier_maps_l' "$ROOT/scripts/test-tier0.sh" \
  && fail "test_prettier_maps_l must NOT be wired into test-tier0.sh" || true
rg -q 'test_prettier_maps_l' "$ROOT/tests/test_optional_track_gates.sh" \
  && fail "test_prettier_maps_l must NOT be wired into test_optional_track_gates.sh" || true
pass "prettier L tests isolated from Tier-0 and optional-track gates"

echo "ALL prettier_maps_l tests passed"
