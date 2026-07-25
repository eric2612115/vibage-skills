#!/usr/bin/env bash
# verify-map-deepen migrate shim (W3a P2). MUST NOT enter Tier-0 or pack-health.
# Never emits MAP_DEEPEN_OK. Success brand = DIMENSION_FILL_* only.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail() { echo "FAIL: $*"; exit 1; }

if grep -qE 'test_verify_map_deepen|verify-map-deepen' scripts/test-tier0.sh; then
  fail "map-deepen must not enter Tier-0"
fi
if grep -qE 'test_verify_map_deepen|verify-map-deepen' scripts/pack-health.sh; then
  fail "map-deepen must not enter pack-health by default"
fi
if grep -qE 'MAP_DEEPEN|map_deepen|verify-map-deepen' scripts/assert_gate.sh; then
  fail "MAP_DEEPEN must not enter assert_gate"
fi

[[ -x scripts/verify-map-deepen.sh ]] || fail "verify-map-deepen.sh not executable"
[[ -f skills/vibage-map-deepen/SKILL.md ]] || fail "missing vibage-map-deepen skill"
grep -Fq 'vibage-map-deepen' skills/MANIFEST.txt || fail "MANIFEST missing vibage-map-deepen"
grep -Fq 'dimension-fill' skills/vibage-map-deepen/SKILL.md || fail "skill must point to dimension-fill"
grep -Fq 'Never claim MAP_DEEPEN_OK' skills/vibage-map-deepen/SKILL.md \
  || grep -Fq 'never claim MAP_DEEPEN_OK' skills/vibage-map-deepen/SKILL.md \
  || grep -Fq 'Never print or claim `MAP_DEEPEN_OK`' skills/vibage-map-deepen/SKILL.md \
  || fail "skill must forbid claiming MAP_DEEPEN_OK"
grep -Fq 'DIMENSION_FILL' skills/vibage-map-deepen/SKILL.md || fail "skill must name DIMENSION_FILL"
grep -Fq 'thin map alone never unlocks' skills/vibage-issue-fix/SKILL.md \
  || grep -Fq 'Thin map alone never unlocks' skills/vibage-issue-fix/SKILL.md \
  || fail "issue-fix must deny thin-map fix"
grep -Fq 'floor-only' skills/vibage-arch-review/SKILL.md \
  || grep -Fq 'Thin-map floor' skills/vibage-arch-review/SKILL.md \
  || fail "arch-review must floor-only without deepen brand"
grep -Fq 'implicit no' skills/vibage-pile-index/SKILL.md || fail "pile-index must implicit-no deepen"
grep -Fq 'Cost / deepen talk' skills/using-vibage/SKILL.md || fail "using-vibage cost talk section"
grep -Fq 'dig all N because' skills/vibage-issue-locate/SKILL.md || fail "locate must not dig-all after deepen"

# Shim must never contain echo of MAP_DEEPEN_OK success token
! grep -Eq 'echo "MAP_DEEPEN_OK|echo '\''MAP_DEEPEN_OK' scripts/verify-map-deepen.sh \
  || fail "verify-map-deepen.sh must not echo MAP_DEEPEN_OK"
! grep -Fq 'MAP_DEEPEN_OK workspace=' scripts/verify-map-deepen.sh \
  || fail "legacy MAP_DEEPEN_OK success line must be gone"

WS="$(mktemp -d)"
trap 'rm -rf "$WS"' EXIT
mkdir -p "$WS/docs/vibage/RUNS" "$WS/docs/vibage/dossiers" "$WS/docs/vibage/maps"
echo "# hub" >"$WS/docs/vibage/STATUS.md"

# Legacy deepen-only freeze → BLOCKED deepen_retired; never MAP_DEEPEN_OK
cat >"$WS/docs/vibage/DECISIONS.md" <<'EOF'
# DECISIONS

```json
{
  "deepen_yes": true,
  "model_tier": "balanced",
  "deepen_scope_ids": ["svc-a", "svc-b"],
  "source": "human",
  "run_id": "map-deepen-legacy"
}
```
EOF
set +e
out="$(bash scripts/verify-map-deepen.sh "$WS" 2>&1)"
RC=$?
set -e
[[ "$RC" -ne 0 ]] || fail "legacy deepen must exit ≠0"
echo "$out" | grep -Fq 'DIMENSION_FILL_BLOCKED reason=deepen_retired' \
  || fail "expect deepen_retired, got: $out"
echo "$out" | grep -Fq 'VERIFY_MAP_DEEPEN_MIGRATED' \
  || fail "expect migrate banner, got: $out"
# Migrate text may name the retired brand; forbid success-token line only
echo "$out" | grep -Eq '^MAP_DEEPEN_OK( |$)' \
  && fail "success MAP_DEEPEN_OK line leaked" || true
echo "OK: legacy deepen → deepen_retired"

# Dimension consent wrap → DIMENSION_FILL_* (BLOCKED no_floor ok; never MAP_DEEPEN_OK)
cat >"$WS/docs/vibage/DECISIONS.md" <<'EOF'
# DECISIONS

```json
{
  "dimension_yes": true,
  "model_tier": "balanced",
  "dimension_scope_ids": ["svc-a"],
  "dimension_classes": ["dimension_behavior", "dimension_tests", "dimension_security", "dimension_ops"],
  "source": "human",
  "run_id": "dimension-wrap-1"
}
```
EOF
set +e
out="$(bash scripts/verify-map-deepen.sh "$WS" 2>&1)"
RC=$?
set -e
echo "$out" | grep -Eq '^DIMENSION_FILL_(OK|PARTIAL|BLOCKED)' \
  || fail "wrap must print DIMENSION_FILL_*, got: $out"
echo "$out" | grep -Eq '^MAP_DEEPEN_OK' && fail "wrap must not MAP_DEEPEN_OK" || true
echo "OK: dimension consent wraps to DIMENSION_FILL_*"

# Scenario matrix markers present (historical M01–M10)
MATRIX="$ROOT/tests/fixtures/map-deepen/SCENARIOS.md"
[[ -f "$MATRIX" ]] || fail "missing SCENARIOS.md"
for id in M01 M02 M03 M04 M05 M06 M07 M08 M09 M10; do
  grep -Fq "$id" "$MATRIX" || fail "SCENARIOS missing $id"
done
echo "OK: M01-M10 matrix"

echo "DIMENSION_FILL_W3A_P2_OK"
echo "MAP_DEEPEN_TEST_OK"
