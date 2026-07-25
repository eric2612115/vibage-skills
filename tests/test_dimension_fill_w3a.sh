#!/usr/bin/env bash
# W3a P0+P1 dimension-fill — Spec §9. Outside test_c_prime_*.sh suite glob. Not Tier-0.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "OK: $*"; }

[[ -x "$ROOT/scripts/dimension-search.sh" ]] || fail "missing dimension-search.sh"
[[ -x "$ROOT/scripts/verify-dimension-fill.sh" ]] || fail "missing verify-dimension-fill.sh"
[[ -x "$ROOT/scripts/dimension-fill.sh" ]] || fail "missing dimension-fill.sh"
[[ -x "$ROOT/scripts/dimension-synth-repo.sh" ]] || fail "missing dimension-synth-repo.sh"
[[ -f "$ROOT/scripts/lib/dimension_fill.py" ]] || fail "missing dimension_fill.py"

# Firewall: dimension-fill ∉ Tier-0 / pack-health
! grep -Eq 'test_dimension_fill_w3a|dimension-search|verify-dimension-fill|dimension_fill\.py|dimension-fill\.sh|dimension-synth' \
  "$ROOT/scripts/test-tier0.sh" \
  || fail "dimension-fill wired into test-tier0.sh"
! grep -Eq 'test_dimension_fill_w3a|dimension-search|verify-dimension-fill|dimension_fill|dimension-synth' \
  "$ROOT/scripts/pack-health.sh" \
  || fail "dimension-fill wired into pack-health.sh"
pass "Tier-0 / pack-health firewall"

# Suite firewall: this file must not match test_c_prime_*.sh
case "$(basename "$0")" in
  test_c_prime_*.sh) fail "must not be named test_c_prime_*.sh" ;;
esac
# Also: suite must not invoke this test by name
! grep -Eq 'test_dimension_fill_w3a' "$ROOT/tests/test_c_prime_suite.sh" 2>/dev/null \
  || fail "dimension-fill wired into test_c_prime_suite.sh"
pass "suite glob firewall (name)"

init_git() {
  local d="$1"
  mkdir -p "$d"
  git -C "$d" init -q
  git -C "$d" config user.email "t@example.com"
  git -C "$d" config user.name "t"
  echo "# $d" >"$d/README.md"
  printf 'services:\n  app:\n    environment:\n      APP_ENV: local\n' >"$d/docker-compose.yml"
  git -C "$d" add -A
  git -C "$d" commit -qm "init"
}

make_mother() {
  local m="$1"
  shift
  mkdir -p "$m/docs/vibage/maps" "$m/docs/vibage/ledger"
  echo "# hub" >"$m/docs/vibage/STATUS.md"
  echo '{}' >"$m/docs/vibage/OWNER_POLICY.json"
  local repos_json="["
  local first=1
  local rid
  for rid in "$@"; do
    init_git "$m/$rid"
    if [[ "$first" -eq 1 ]]; then first=0; else repos_json+=","; fi
    repos_json+="{\"id\":\"$rid\",\"repo_id\":\"$rid\",\"name\":\"$rid\",\"path\":\"$rid\",\"definition\":\"test\"}"
  done
  repos_json+="]"
  python3 - "$m" "$repos_json" <<'PY'
import json, sys
from pathlib import Path
m = Path(sys.argv[1])
repos = json.loads(sys.argv[2])
services = [{"id": r["id"], "name": r["name"], "path": r["path"], "definition": "test"} for r in repos]
obj = {
  "schema_version": "1",
  "pipeline_id": "service_map",
  "scale": "Tiny",
  "quality_bar": "MEDIUM",
  "discover_mode": "flat",
  "discover_max_depth": 1,
  "services": services,
  "repos": repos,
  "notes": "test",
  "generated_at": "2026-07-25T00:00:00Z",
}
(m / "docs/vibage/maps/service_map.json").write_text(json.dumps(obj, indent=2) + "\n", encoding="utf-8")
PY
}

seed_matrix_clear() {
  local m="$1"
  shift
  python3 - "$m" "$@" <<'PY'
import json, sys
from pathlib import Path
m = Path(sys.argv[1])
repos = sys.argv[2:]
cells, rows = [], []
for rid in repos:
    cells.append({
        "repo_id": rid,
        "branch_ref": "main",
        "env_id": "local",
        "pointers": [{"path": f"{rid}/docker-compose.yml", "quote": "APP_ENV: local", "branch_ref": "main", "env_id": "local"}],
        "state": "proven",
    })
    rows.append({"repo_id": rid, "branch_ref": "main", "env_id": "local"})
(m / "docs/vibage/maps/env_branch_matrix.json").write_text(
    json.dumps({"schema_version": "1", "status": "ok", "cells": cells}, indent=2) + "\n"
)
(m / "docs/vibage/maps/inventory_manifest.json").write_text(
    json.dumps({"schema_version": "1", "rows": rows}, indent=2) + "\n"
)
PY
}

seed_matrix_missing() {
  local m="$1"
  shift
  python3 - "$m" "$@" <<'PY'
import json, sys
from pathlib import Path
m = Path(sys.argv[1])
repos = sys.argv[2:]
cells, rows = [], []
for rid in repos:
    cells.append({
        "repo_id": rid,
        "branch_ref": "main",
        "env_id": "missing-env-config",
        "pointers": [{"path": rid, "quote": "no env", "branch_ref": "main", "env_id": "missing-env-config"}],
        "state": "failed",
        "reason": "missing-env-config",
    })
    rows.append({"repo_id": rid, "branch_ref": "main", "env_id": "missing-env-config"})
(m / "docs/vibage/maps/env_branch_matrix.json").write_text(
    json.dumps({"schema_version": "1", "status": "ok", "cells": cells}, indent=2) + "\n"
)
(m / "docs/vibage/maps/inventory_manifest.json").write_text(
    json.dumps({"schema_version": "1", "rows": rows}, indent=2) + "\n"
)
PY
}

write_dimension_freeze() {
  local m="$1"
  local rid="$2"
  cat >"$m/docs/vibage/DECISIONS.md" <<EOF
# Decisions

\`\`\`json
{
  "dimension_yes": true,
  "model_tier": "balanced",
  "dimension_scope_ids": ["${rid}"],
  "dimension_classes": ["dimension_behavior", "dimension_tests", "dimension_security", "dimension_ops"],
  "dimension_scope_hash": "test",
  "dimension_frozen_at": "2026-07-25T00:00:00Z",
  "source": "human",
  "run_id": "dimension-fill-p0"
}
\`\`\`
EOF
}

write_claim() {
  local out="$1"
  local id="$2"
  local rid="$3"
  local cls="$4"
  local state="$5"
  local path="$6"
  python3 - "$out" "$id" "$rid" "$cls" "$state" "$path" <<'PY'
import json, sys
from pathlib import Path
out, cid, rid, cls, state, path = sys.argv[1:7]
obj = {
  "id": cid,
  "subject_type": "repo",
  "subject_id": rid,
  "claim_class": cls,
  "statement": f"{cls} note",
  "pointers": [{"path": path, "quote": "evidence", "branch_ref": "main", "env_id": "local"}],
  "state": state,
  "updated_at": "2026-07-25T00:00:00Z",
  "evidence_hash": cid,
}
Path(out).write_text(json.dumps(obj) + "\n", encoding="utf-8")
PY
}

# --- No consent → BLOCKED ---
M0="$TMP/m0"
make_mother "$M0" "svc-a"
seed_matrix_clear "$M0" "svc-a"
# No DECISIONS freeze
set +e
out="$(bash "$ROOT/scripts/verify-dimension-fill.sh" "$M0" 2>/dev/null)"
rc=$?
set -e
[[ "$rc" -ne 0 ]] || fail "no consent should exit ≠0, got $rc"
[[ "$out" == *"DIMENSION_FILL_BLOCKED reason=no_consent"* ]] \
  || fail "expect BLOCKED no_consent, got: $out"
[[ "$out" != *"DIMENSION_FILL_OK"* ]] || fail "no consent must not OK"
pass "no consent → BLOCKED"

# --- Happy path: freeze + 4 claims → OK tally ---
M1="$TMP/m1"
make_mother "$M1" "svc-a"
seed_matrix_clear "$M1" "svc-a"
write_dimension_freeze "$M1" "svc-a"
gout="$(bash "$ROOT/scripts/verify-graph-floor.sh" "$M1")"
[[ "$gout" == "GRAPH_FLOOR_OK" ]] || fail "graph floor, got: $gout"
mout="$(bash "$ROOT/scripts/verify-env-branch-matrix.sh" "$M1")"
[[ "$mout" == "ENV_BRANCH_MATRIX_OK" ]] || fail "matrix OK, got: $mout"
vout="$(bash "$ROOT/scripts/verify-env-vacancy.sh" "$M1" 2>/dev/null || true)"
echo "$vout" | grep -q 'ENV_VACANCY_CLEAR' || fail "expect vacancy CLEAR, got: $vout"

CLASSES=(dimension_behavior dimension_tests dimension_security dimension_ops)
i=0
for cls in "${CLASSES[@]}"; do
  i=$((i + 1))
  write_claim "$TMP/c${i}.json" "d${i}" "svc-a" "$cls" "proven" "svc-a/README.md"
  bash "$ROOT/scripts/dimension-search.sh" "$M1" "svc-a" "$cls" "$TMP/c${i}.json" \
    || fail "dimension-search failed for $cls"
done

set +e
out="$(bash "$ROOT/scripts/verify-dimension-fill.sh" "$M1" 2>/dev/null)"
rc=$?
set -e
[[ "$rc" -eq 0 ]] || fail "happy verify exit 0, got $rc"
[[ "$out" == "DIMENSION_FILL_OK tally=proven:4,failed:0" ]] \
  || fail "expect OK tally proven:4,failed:0, got: $out"
[[ "$out" != *"MAP_DEEPEN_OK"* ]] || fail "must never print MAP_DEEPEN_OK"
pass "happy path → DIMENSION_FILL_OK tally="

# --- Secret dotenv pointer → search fails; not OK ---
M2="$TMP/m2"
make_mother "$M2" "svc-a"
seed_matrix_clear "$M2" "svc-a"
write_dimension_freeze "$M2" "svc-a"
write_claim "$TMP/secret.json" "sec1" "svc-a" "dimension_behavior" "proven" "svc-a/.env"
set +e
sout="$(bash "$ROOT/scripts/dimension-search.sh" "$M2" "svc-a" "dimension_behavior" "$TMP/secret.json" 2>&1)"
src=$?
set -e
[[ "$src" -ne 0 ]] || fail "secret dotenv search must fail"
echo "$sout" | grep -qi 'secret\|dotenv\|\.env' || fail "expect secret refusal, got: $sout"
# Only one class attempted; verify must not OK
set +e
out="$(bash "$ROOT/scripts/verify-dimension-fill.sh" "$M2" 2>/dev/null)"
rc=$?
set -e
[[ "$out" != *"DIMENSION_FILL_OK"* ]] || fail "secret path must not yield OK, got: $out"
[[ "$out" == *"DIMENSION_FILL_PARTIAL"* || "$out" == *"DIMENSION_FILL_BLOCKED"* ]] \
  || fail "expect PARTIAL/BLOCKED after secret refuse, got: $out"
pass "secret dotenv pointer → search fails; not OK"

# --- Vacancy ASK → PARTIAL not OK ---
M3="$TMP/m3"
make_mother "$M3" "svc-a"
seed_matrix_missing "$M3" "svc-a"
write_dimension_freeze "$M3" "svc-a"
# unanswered missing → ASK (no answers file)
set +e
vask="$(bash "$ROOT/scripts/verify-env-vacancy.sh" "$M3" 2>/dev/null)"
vrc=$?
set -e
[[ "$vrc" -ne 0 ]] || fail "unanswered should vacancy exit ≠0"
echo "$vask" | grep -q 'ENV_VACANCY_ASK' || fail "expect ENV_VACANCY_ASK, got: $vask"
# Append all 4 claims anyway — still PARTIAL vacancy_ask, never OK
i=0
for cls in "${CLASSES[@]}"; do
  i=$((i + 1))
  write_claim "$TMP/ask${i}.json" "a${i}" "svc-a" "$cls" "proven" "svc-a/README.md"
  bash "$ROOT/scripts/dimension-search.sh" "$M3" "svc-a" "$cls" "$TMP/ask${i}.json" \
    || fail "search under ASK mother failed for $cls"
done
set +e
out="$(bash "$ROOT/scripts/verify-dimension-fill.sh" "$M3" 2>/dev/null)"
rc=$?
set -e
[[ "$rc" -eq 0 ]] || fail "PARTIAL vacancy_ask should exit 0, got $rc"
[[ "$out" == *"DIMENSION_FILL_PARTIAL reason=vacancy_ask"* ]] \
  || fail "expect PARTIAL vacancy_ask, got: $out"
[[ "$out" != *"DIMENSION_FILL_OK"* ]] || fail "ASK must forbid OK"
pass "vacancy ASK → PARTIAL not OK"

echo "DIMENSION_FILL_W3A_P0_OK"

# --- P1: legacy deepen freeze alone → BLOCKED ---
M4="$TMP/m4"
make_mother "$M4" "svc-a"
seed_matrix_clear "$M4" "svc-a"
cat >"$M4/docs/vibage/DECISIONS.md" <<'EOF'
# Decisions

```json
{
  "deepen_yes": true,
  "model_tier": "balanced",
  "deepen_scope_ids": ["svc-a"],
  "source": "human",
  "run_id": "map-deepen-legacy"
}
```
EOF
set +e
out="$(bash "$ROOT/scripts/dimension-fill.sh" "$M4" 2>/dev/null)"
rc=$?
set -e
[[ "$rc" -ne 0 ]] || fail "legacy deepen freeze must BLOCKED"
[[ "$out" == *"DIMENSION_FILL_BLOCKED reason=no_consent"* ]] \
  || fail "expect no_consent for deepen-only, got: $out"
[[ "$out" != *"MAP_DEEPEN_OK"* ]] || fail "fill must never print MAP_DEEPEN_OK"
pass "legacy deepen freeze only → BLOCKED"

# --- P1: orchestrator happy path with claims-dir + synth ---
M5="$TMP/m5"
make_mother "$M5" "svc-a"
seed_matrix_clear "$M5" "svc-a"
write_dimension_freeze "$M5" "svc-a"
CLAIMS="$TMP/claims5"
mkdir -p "$CLAIMS/svc-a"
i=0
for cls in "${CLASSES[@]}"; do
  i=$((i + 1))
  write_claim "$CLAIMS/svc-a/${cls}.json" "f${i}" "svc-a" "$cls" "proven" "svc-a/README.md"
done
set +e
out="$(bash "$ROOT/scripts/dimension-fill.sh" "$M5" --claims-dir="$CLAIMS" 2>/dev/null)"
rc=$?
set -e
[[ "$rc" -eq 0 ]] || fail "fill happy exit 0, got $rc"
[[ "$out" == "DIMENSION_FILL_OK tally=proven:4,failed:0" ]] \
  || fail "fill expect OK tally, got: $out"
[[ -f "$M5/docs/vibage/dossiers/svc-a.md" ]] || fail "synth stub missing"
grep -q 'Stub alone' "$M5/docs/vibage/dossiers/svc-a.md" \
  || fail "dossier must state stub ≠ depth"
[[ "$out" != *"MAP_DEEPEN_OK"* ]] || fail "no MAP_DEEPEN_OK"
pass "orchestrator happy path + synth stub"

echo "DIMENSION_FILL_W3A_P1_OK"
