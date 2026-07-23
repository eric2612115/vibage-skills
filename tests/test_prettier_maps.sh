#!/usr/bin/env bash
# Plan G — local prettier maps proofs ONLY.
# MUST NOT be wired into scripts/test-tier0.sh or tests/test_optional_track_gates.sh.
# MUST NOT require changing scripts/verify-service-map.sh behavior.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RENDER="$ROOT/scripts/render-service-map-preview.sh"
GRAPHIFY_GEN="$ROOT/scripts/generate-service-map-graph.sh"
VERIFY="$ROOT/scripts/verify-service-map.sh"
FIX_OK="$ROOT/tests/fixtures/service-map/standard-depth-ok.json"

pass() { echo "OK: $*"; }
fail() { echo "FAIL: $*" >&2; exit 1; }

[[ -f "$FIX_OK" ]] || fail "missing standard-depth-ok fixture"
[[ -f "$VERIFY" ]] || fail "missing verify-service-map.sh"

install_map() {
  local dir="$1" src="$2"
  mkdir -p "$dir/docs/vibage/maps"
  cp "$src" "$dir/docs/vibage/maps/service_map.json"
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- Render REQUIRED ---
[[ -f "$RENDER" ]] || fail "missing render-service-map-preview.sh"

WS_R="$TMP/render_ok"
install_map "$WS_R" "$FIX_OK"
set +e
OUT_R="$("$RENDER" "$WS_R" 2>&1)"
RC_R=$?
set -e
[[ "$RC_R" -eq 0 ]] || fail "render expected rc=0 got $RC_R; out=$OUT_R"
[[ -f "$WS_R/vibage-preview/service_map.html" ]] || fail "missing vibage-preview/service_map.html"
[[ -f "$WS_R/vibage-preview/service_map.svg" ]] || fail "missing vibage-preview/service_map.svg"
rg -q 'web|billing' "$WS_R/vibage-preview/service_map.svg" \
  || fail "svg should mention service ids from fixture"
rg -q 'service_map\.svg|Web frontend|billing' "$WS_R/vibage-preview/service_map.html" \
  || fail "html should reference svg or service labels"
echo "$OUT_R" | rg -q 'OK:RENDER' || fail "render stdout should include OK:RENDER token"
pass "render pure-local html+svg"

# Render must not place preview under maps/
[[ ! -f "$WS_R/docs/vibage/maps/service_map.html" ]] \
  || fail "preview must not land under docs/vibage/maps/"

# Missing map → fail-soft RENDER_SKIP (exit 0), no verify coupling
WS_MISS="$TMP/render_miss"
mkdir -p "$WS_MISS/docs/vibage/maps"
set +e
OUT_M="$("$RENDER" "$WS_MISS" 2>&1)"
RC_M=$?
set -e
[[ "$RC_M" -eq 0 ]] || fail "missing map render must exit 0 (fail-soft), got $RC_M"
echo "$OUT_M" | rg -q 'OK:RENDER_SKIP' || fail "expected OK:RENDER_SKIP"
# owner sentence: at least one non-token line of prose
echo "$OUT_M" | rg -qv '^(OK:|FAIL:)' || fail "RENDER_SKIP must include owner sentence on stdout"
pass "render missing map fail-soft"

# verify regression: standard fixture still qualifies (zero verify behavior change)
WS_V="$TMP/verify_still"
install_map "$WS_V" "$FIX_OK"
"$VERIFY" "$WS_V" >/dev/null
pass "verify-service-map unchanged path still PASS"

# --- Graphify OPTIONAL ---
[[ -f "$GRAPHIFY_GEN" ]] || fail "missing generate-service-map-graph.sh"

WS_G="$TMP/graphify_skip"
install_map "$WS_G" "$FIX_OK"
# Force missing CLI: prepend empty bin dir and clear PATH lookup for graphify
EMPTY_BIN="$TMP/empty_bin"
mkdir -p "$EMPTY_BIN"
set +e
# Keep system bins so shebang `env bash` works; EMPTY_BIN has no graphify.
OUT_G="$(PATH="$EMPTY_BIN:/usr/bin:/bin" "$GRAPHIFY_GEN" "$WS_G" 2>&1)"
RC_G=$?
set -e
[[ "$RC_G" -eq 0 ]] || fail "graphify missing must exit 0, got $RC_G; out=$OUT_G"
echo "$OUT_G" | rg -q 'OK:GRAPHIFY_SKIP' || fail "expected OK:GRAPHIFY_SKIP"
echo "$OUT_G" | rg -qv '^(OK:|FAIL:)' || fail "GRAPHIFY_SKIP must include owner sentence on stdout"
# Still must not break verify
"$VERIFY" "$WS_G" >/dev/null
pass "graphify missing fail-soft; verify still PASS"

# --- Coverage sidecar (not a verify field) ---
WS_C="$TMP/coverage_notes"
install_map "$WS_C" "$FIX_OK"
NOTES="$WS_C/docs/vibage/maps/COVERAGE_NOTES.md"
cat >"$NOTES" <<'EOF'
# Coverage notes (thin)

- Services in map: web, billing
- Edges present: web → billing
- This file is optional narrative; not enforced by verify-service-map.sh.
EOF
[[ -f "$NOTES" ]] || fail "COVERAGE_NOTES.md missing"
"$VERIFY" "$WS_C" >/dev/null
# Ensure verify does not require the notes file: delete and re-verify
rm -f "$NOTES"
"$VERIFY" "$WS_C" >/dev/null
pass "COVERAGE_NOTES optional; not a verify gate"

# Isolation: prettier test file must not be referenced by tier0 / optional gates
rg -q 'test_prettier_maps' "$ROOT/scripts/test-tier0.sh" \
  && fail "test_prettier_maps must NOT be wired into test-tier0.sh" || true
rg -q 'test_prettier_maps' "$ROOT/tests/test_optional_track_gates.sh" \
  && fail "test_prettier_maps must NOT be wired into test_optional_track_gates.sh" || true
pass "prettier tests isolated from Tier-0 and optional-track gates"

echo "ALL prettier_maps tests passed"
