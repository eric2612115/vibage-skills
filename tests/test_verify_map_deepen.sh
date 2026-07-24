#!/usr/bin/env bash
# verify-map-deepen honesty. MUST NOT enter Tier-0 or pack-health.
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
grep -Fq 'MAP_DEEPEN_OK' skills/vibage-map-deepen/SKILL.md || fail "skill must name MAP_DEEPEN_OK"
grep -Fq 'green-shrink' skills/vibage-map-deepen/SKILL.md || fail "skill must forbid green-shrink"
grep -Fq 'Plan-L' skills/vibage-map-deepen/SKILL.md || fail "skill must name-lock vs Plan-L"
grep -Fq 'thin map alone never unlocks' skills/vibage-issue-fix/SKILL.md \
  || grep -Fq 'Thin map alone never unlocks' skills/vibage-issue-fix/SKILL.md \
  || fail "issue-fix must deny thin-map fix"
grep -Fq 'floor-only' skills/vibage-arch-review/SKILL.md \
  || grep -Fq 'Thin-map floor' skills/vibage-arch-review/SKILL.md \
  || fail "arch-review must floor-only without MAP_DEEPEN_OK"
grep -Fq 'implicit no' skills/vibage-pile-index/SKILL.md || fail "pile-index must implicit-no deepen"
grep -Fq 'Cost / deepen talk' skills/using-vibage/SKILL.md || fail "using-vibage cost talk section"
grep -Fq 'dig all N because' skills/vibage-issue-locate/SKILL.md || fail "locate must not dig-all after deepen"

WS="$(mktemp -d)"
trap 'rm -rf "$WS"' EXIT
mkdir -p "$WS/docs/vibage/RUNS" "$WS/docs/vibage/dossiers" "$WS/docs/vibage/maps"

HASH="$(python3 - <<'PY'
import hashlib
print(hashlib.sha256("svc-a,svc-b".encode()).hexdigest())
PY
)"

write_dossier() {
  local id="$1"
  cat > "$WS/docs/vibage/dossiers/${id}.md" <<EOF
# ${id}
## Summary
Short dossier for ${id}.
## Role
Service role for ${id}.
## Notable paths
- ${id}/README.md
EOF
}

write_decisions() {
  local ids_json="$1"
  local h="$2"
  cat > "$WS/docs/vibage/DECISIONS.md" <<EOF
# DECISIONS

## Map deepen freeze

\`\`\`json
{
  "deepen_yes": true,
  "model_tier": "balanced",
  "deepen_scope_ids": ${ids_json},
  "deepen_scope_hash": "${h}",
  "deepen_scope_frozen_at": "2026-07-24T00:00:00Z",
  "source": "human",
  "run_id": "map-deepen-test-1"
}
\`\`\`
EOF
}

write_envelope() {
  local path="$1"
  local mode="$2"
  local phase="$3"
  local scope_json="$4"
  local orig_json="$5"
  local claim="$6"
  local nested="$7"
  cat > "$path" <<EOF
{
  "schema_version": "1",
  "pipeline_id": "map_deepen",
  "run_id": "map-deepen-test-1",
  "phase": "${phase}",
  "mode": "${mode}",
  "scope_ids": ${scope_json},
  "original_scope_ids": ${orig_json},
  "original_scope_hash": "${HASH}",
  "claim_coverage": "${claim}",
  "nested_dispatch": ${nested},
  "artifact_uris": [],
  "survey_refs": [],
  "gap_ids": []
}
EOF
}

# Happy path (degraded)
write_dossier svc-a
write_dossier svc-b
write_decisions '["svc-a","svc-b"]' "$HASH"
write_envelope "$WS/docs/vibage/RUNS/map-deepen-test-1.json" "degraded" "done" \
  '["svc-a","svc-b"]' '["svc-a","svc-b"]' "subset" '{}'

out="$(bash scripts/verify-map-deepen.sh "$WS" docs/vibage/RUNS/map-deepen-test-1.json)"
echo "$out" | grep -Fq 'MAP_DEEPEN_OK' || fail "expected MAP_DEEPEN_OK on happy path"
echo "OK: happy degraded"

# Fake full nested (empty nested_dispatch) must fail
write_envelope "$WS/docs/vibage/RUNS/map-deepen-fake.json" "full nested" "done" \
  '["svc-a","svc-b"]' '["svc-a","svc-b"]' "subset" '{}'
set +e
bash scripts/verify-map-deepen.sh "$WS" docs/vibage/RUNS/map-deepen-fake.json >/dev/null 2>&1
RC=$?
set -e
[[ "$RC" -ne 0 ]] || fail "fake full nested should fail"
echo "OK: fake full nested rejected"

# Partial dossiers (missing svc-b) + done must fail
rm -f "$WS/docs/vibage/dossiers/svc-b.md"
set +e
bash scripts/verify-map-deepen.sh "$WS" docs/vibage/RUNS/map-deepen-test-1.json >/dev/null 2>&1
RC=$?
set -e
[[ "$RC" -ne 0 ]] || fail "missing dossier should fail"
write_dossier svc-b
echo "OK: missing dossier rejected"

# Stub empty section fails
cat > "$WS/docs/vibage/dossiers/svc-a.md" <<'EOF'
# svc-a
## Summary

## Role
x
## Notable paths
- a
EOF
set +e
bash scripts/verify-map-deepen.sh "$WS" docs/vibage/RUNS/map-deepen-test-1.json >/dev/null 2>&1
RC=$?
set -e
[[ "$RC" -ne 0 ]] || fail "stub empty Summary should fail"
write_dossier svc-a
echo "OK: stub dossier rejected"

# Green-shrink: original 2, scope 1
HASH2="$(python3 - <<'PY'
import hashlib
print(hashlib.sha256("svc-a".encode()).hexdigest())
PY
)"
write_decisions '["svc-a"]' "$HASH2"
# envelope with green-shrink (scope subset of original) — hash on original was for 2 ids
cat > "$WS/docs/vibage/RUNS/map-deepen-shrink.json" <<EOF
{
  "schema_version": "1",
  "pipeline_id": "map_deepen",
  "run_id": "map-deepen-shrink",
  "phase": "done",
  "mode": "degraded",
  "scope_ids": ["svc-a"],
  "original_scope_ids": ["svc-a", "svc-b"],
  "original_scope_hash": "${HASH}",
  "claim_coverage": "subset",
  "nested_dispatch": {},
  "artifact_uris": [],
  "survey_refs": [],
  "gap_ids": []
}
EOF
set +e
bash scripts/verify-map-deepen.sh "$WS" docs/vibage/RUNS/map-deepen-shrink.json >/dev/null 2>&1
RC=$?
set -e
[[ "$RC" -ne 0 ]] || fail "green-shrink should fail"
echo "OK: green-shrink rejected"

# Cross-run laundry: claim full_pile with subset of map
python3 - "$WS/docs/vibage/maps/service_map.json" <<'PY'
import json, sys
path = sys.argv[1]
json.dump({
  "schema_version": "1",
  "pipeline_id": "service_map",
  "quality_bar": "MEDIUM",
  "scale": "Subset",
  "services": [
    {"id": "svc-a", "definition": "a"},
    {"id": "svc-b", "definition": "b"},
    {"id": "svc-c", "definition": "c"},
  ],
}, open(path, "w"), indent=2)
PY
write_decisions '["svc-a","svc-b"]' "$HASH"
write_envelope "$WS/docs/vibage/RUNS/map-deepen-laundry.json" "degraded" "done" \
  '["svc-a","svc-b"]' '["svc-a","svc-b"]' "full_pile" '{}'
set +e
bash scripts/verify-map-deepen.sh "$WS" docs/vibage/RUNS/map-deepen-laundry.json >/dev/null 2>&1
RC=$?
set -e
[[ "$RC" -ne 0 ]] || fail "full_pile claim with subset scope should fail"
echo "OK: cross-run laundry rejected"

# Scenario matrix markers present
MATRIX="$ROOT/tests/fixtures/map-deepen/SCENARIOS.md"
[[ -f "$MATRIX" ]] || fail "missing SCENARIOS.md"
for id in M01 M02 M03 M04 M05 M06 M07 M08 M09 M10; do
  grep -Fq "$id" "$MATRIX" || fail "SCENARIOS missing $id"
done
echo "OK: M01-M10 matrix"

echo "MAP_DEEPEN_TEST_OK"
