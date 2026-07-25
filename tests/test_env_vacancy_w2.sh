#!/usr/bin/env bash
# W2 env vacancy ask — Spec §8. Outside test_c_prime_*.sh suite glob. Not Tier-0.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "OK: $*"; }

[[ -x "$ROOT/scripts/env-vacancy-check.sh" ]] || fail "missing env-vacancy-check.sh"
[[ -x "$ROOT/scripts/env-vacancy-answer.sh" ]] || fail "missing env-vacancy-answer.sh"
[[ -x "$ROOT/scripts/verify-env-vacancy.sh" ]] || fail "missing verify-env-vacancy.sh"
[[ -x "$ROOT/scripts/env-vacancy-apply-point.sh" ]] || fail "missing env-vacancy-apply-point.sh"
[[ -f "$ROOT/scripts/lib/env_vacancy.py" ]] || fail "missing env_vacancy.py"

# Firewall: vacancy ∉ Tier-0 / pack-health
! grep -Eq 'test_env_vacancy_w2|env-vacancy-check|env-vacancy-answer|verify-env-vacancy|env_vacancy\.py|env-vacancy-apply-point' \
  "$ROOT/scripts/test-tier0.sh" \
  || fail "env vacancy wired into test-tier0.sh"
! grep -Eq 'test_env_vacancy_w2|env-vacancy-check|verify-env-vacancy|env_vacancy' \
  "$ROOT/scripts/pack-health.sh" \
  || fail "env vacancy wired into pack-health.sh"
pass "Tier-0 / pack-health firewall"

case "$(basename "$0")" in
  test_c_prime_*.sh) fail "must not be named test_c_prime_*.sh" ;;
esac
pass "suite glob firewall (name)"

init_git() {
  local d="$1"
  mkdir -p "$d"
  git -C "$d" init -q
  git -C "$d" config user.email "t@example.com"
  git -C "$d" config user.name "t"
  echo "x" >"$d/README.md"
  git -C "$d" add -A
  git -C "$d" commit -qm "init"
}

make_mother() {
  local m="$1"
  shift
  mkdir -p "$m/docs/vibage/maps"
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

seed_all_missing() {
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

seed_mixed() {
  local m="$1"
  python3 - "$m" <<'PY'
import json, sys
from pathlib import Path
m = Path(sys.argv[1])
cells = [
  {
    "repo_id": "svc-a",
    "branch_ref": "main",
    "env_id": "staging",
    "pointers": [{"path": "svc-a/docker-compose.staging.yml", "quote": "APP_ENV: staging", "branch_ref": "main", "env_id": "staging"}],
    "state": "proven",
  },
  {
    "repo_id": "svc-b",
    "branch_ref": "main",
    "env_id": "missing-env-config",
    "pointers": [{"path": "svc-b", "quote": "no", "branch_ref": "main", "env_id": "missing-env-config"}],
    "state": "failed",
  },
]
rows = [
  {"repo_id": "svc-a", "branch_ref": "main", "env_id": "staging"},
  {"repo_id": "svc-b", "branch_ref": "main", "env_id": "missing-env-config"},
]
(m / "docs/vibage/maps/env_branch_matrix.json").write_text(
    json.dumps({"schema_version": "1", "status": "ok", "cells": cells}, indent=2) + "\n"
)
(m / "docs/vibage/maps/inventory_manifest.json").write_text(
    json.dumps({"schema_version": "1", "rows": rows}, indent=2) + "\n"
)
PY
}

seed_clear_real() {
  local m="$1"
  python3 - "$m" <<'PY'
import json, sys
from pathlib import Path
m = Path(sys.argv[1])
cells = [{
  "repo_id": "svc-a",
  "branch_ref": "main",
  "env_id": "local",
  "pointers": [{"path": "svc-a/docker-compose.yml", "quote": "APP_ENV: local", "branch_ref": "main", "env_id": "local"}],
  "state": "proven",
}]
rows = [{"repo_id": "svc-a", "branch_ref": "main", "env_id": "local"}]
(m / "docs/vibage/maps/env_branch_matrix.json").write_text(
    json.dumps({"schema_version": "1", "status": "ok", "cells": cells}, indent=2) + "\n"
)
(m / "docs/vibage/maps/inventory_manifest.json").write_text(
    json.dumps({"schema_version": "1", "rows": rows}, indent=2) + "\n"
)
PY
}

# --- Unanswered missing → ASK; substantive fail ---
M1="$TMP/m1"
make_mother "$M1" "svc-a" "svc-b"
seed_all_missing "$M1" "svc-a" "svc-b"
set +e
out="$(bash "$ROOT/scripts/env-vacancy-check.sh" "$M1" 2>/dev/null)"
rc=$?
set -e
[[ "$rc" -ne 0 ]] || fail "unanswered should exit ≠0, got $rc"
[[ "$out" == *"ENV_VACANCY_ASK count=2"* ]] || fail "expect ASK count=2, got: $out"
[[ "$out" != *"ENV_VACANCY_ANSWERED"* ]] || fail "ASK must not also print ANSWERED"
if bash "$ROOT/scripts/verify-matrix-substantive.sh" "$M1" >/dev/null 2>&1; then
  fail "unanswered must not grant substantive"
fi
if bash "$ROOT/scripts/verify-env-branch-matrix.sh" "$M1" >/dev/null 2>&1; then
  fail "unanswered all-special must not matrix OK"
fi
pass "unanswered missing → ENV_VACANCY_ASK; substantive fail"

# --- skip + reason (all-special) → matrix OK via (C); ANSWERED; substantive fail ---
M2="$TMP/m2"
make_mother "$M2" "svc-a" "svc-b"
seed_all_missing "$M2" "svc-a" "svc-b"
bash "$ROOT/scripts/env-vacancy-answer.sh" \
  --skip --reason="docs-only sibling" --repo=svc-a --branch=main --env=missing-env-config "$M2"
bash "$ROOT/scripts/env-vacancy-answer.sh" \
  --skip --reason="docs-only sibling" --repo=svc-b --branch=main --env=missing-env-config "$M2"
set +e
out="$(bash "$ROOT/scripts/verify-env-vacancy.sh" "$M2" 2>/dev/null)"
rc=$?
set -e
[[ "$rc" -eq 0 ]] || fail "ANSWERED should exit 0, got $rc"
[[ "$out" == *"ENV_VACANCY_ANSWERED count=2"* ]] || fail "expect ANSWERED count=2, got: $out"
[[ "$out" != *"ENV_VACANCY_CLEAR"* ]] || fail "ANSWERED ≠ CLEAR"
mout="$(bash "$ROOT/scripts/verify-env-branch-matrix.sh" "$M2")"
[[ "$mout" == "ENV_BRANCH_MATRIX_OK" ]] || fail "skip answers should matrix OK via (C), got: $mout"
if bash "$ROOT/scripts/verify-matrix-substantive.sh" "$M2" >/dev/null 2>&1; then
  fail "skip must never grant 掃透"
fi
[[ "$out" != *"MATRIX_SWEEP_SUBSTANTIVE_OK"* ]] || fail "vacancy scripts must not print 掃透"
pass "skip + reason → ANSWERED; matrix (C); substantive fail"

# --- classify + class ---
M3="$TMP/m3"
make_mother "$M3" "svc-c"
seed_all_missing "$M3" "svc-c"
bash "$ROOT/scripts/env-vacancy-answer.sh" \
  --classify=no-deploy --reason="library crate" --repo=svc-c --branch=main --env=missing-env-config "$M3"
set +e
out="$(bash "$ROOT/scripts/env-vacancy-check.sh" "$M3" 2>/dev/null)"
rc=$?
set -e
[[ "$rc" -eq 0 ]] || fail "classify ANSWERED exit 0"
[[ "$out" == *"ENV_VACANCY_ANSWERED count=1"* ]] || fail "classify ANSWERED, got: $out"
mout="$(bash "$ROOT/scripts/verify-env-branch-matrix.sh" "$M3")"
[[ "$mout" == "ENV_BRANCH_MATRIX_OK" ]] || fail "classify should matrix OK, got: $mout"
pass "classify + class → ANSWERED; matrix OK"

# --- point recorded, not applied → still ASK; not ANSWERED; not matrix (C) ---
M4="$TMP/m4"
make_mother "$M4" "svc-b"
seed_all_missing "$M4" "svc-b"
# point_path must exist
mkdir -p "$M4/svc-b/deploy"
cat >"$M4/svc-b/deploy/compose.staging.yml" <<'EOF'
services:
  app:
    image: x
    environment:
      APP_ENV: staging
EOF
(
  cd "$M4/svc-b"
  git add deploy/compose.staging.yml
  git commit -qm "add nested compose (not yet applied)"
)
bash "$ROOT/scripts/env-vacancy-answer.sh" \
  --point=deploy/compose.staging.yml --reason="compose lives under deploy/" \
  --repo=svc-b --branch=main --env=missing-env-config "$M4"
set +e
out="$(bash "$ROOT/scripts/env-vacancy-check.sh" "$M4" 2>/dev/null)"
rc=$?
set -e
[[ "$rc" -ne 0 ]] || fail "point-pending should exit ≠0"
[[ "$out" == *"ENV_VACANCY_ASK"* ]] || fail "point-pending → ASK, got: $out"
[[ "$out" != *"ENV_VACANCY_ANSWERED"* ]] || fail "point-pending must not ANSWERED"
if bash "$ROOT/scripts/verify-env-branch-matrix.sh" "$M4" >/dev/null 2>&1; then
  fail "point-pending must not satisfy matrix (C)"
fi
pass "point-pending → ASK; not matrix (C)"

# --- point applied → real-env may CLEAR gap ---
M5="$TMP/m5"
make_mother "$M5" "svc-b"
seed_all_missing "$M5" "svc-b"
# Add discoverable top-level compose after vacancy (simulates owner pointing then apply)
cat >"$M5/svc-b/docker-compose.staging.yml" <<'EOF'
services:
  app:
    image: x
    environment:
      APP_ENV: staging
EOF
(
  cd "$M5/svc-b"
  git add docker-compose.staging.yml
  git commit -qm "add staging compose"
  git branch -q staging 2>/dev/null || true
)
bash "$ROOT/scripts/env-vacancy-answer.sh" \
  --point=docker-compose.staging.yml --reason="here" \
  --repo=svc-b --branch=main --env=missing-env-config "$M5"
bash "$ROOT/scripts/env-vacancy-apply-point.sh" "$M5" "svc-b" >/dev/null
# After apply, discovery should replace missing with real env(s)
python3 - "$M5" <<'PY'
import json, sys
from pathlib import Path
m = Path(sys.argv[1])
cells = json.load(open(m / "docs/vibage/maps/env_branch_matrix.json"))["cells"]
envs = {c["env_id"] for c in cells if c.get("repo_id") == "svc-b"}
if envs == {"missing-env-config"}:
    raise SystemExit("apply-point should replace missing when discovery finds envs")
print("envs", sorted(envs))
PY
set +e
out="$(bash "$ROOT/scripts/env-vacancy-check.sh" "$M5" 2>/dev/null)"
rc=$?
set -e
# Zero missing for that gap → CLEAR (or ASK if other missings — here only svc-b)
[[ "$out" == *"ENV_VACANCY_CLEAR"* ]] || fail "after apply expect CLEAR, got: $out"
[[ "$rc" -eq 0 ]] || fail "CLEAR exit 0"
# substantive only if parent rules met (may or may not)
set +e
sout="$(bash "$ROOT/scripts/verify-matrix-substantive.sh" "$M5" 2>/dev/null)"
set -e
pass "point applied → real-env; CLEAR gap (substantive=$sout)"

# --- point to .env → BLOCKED ---
M6="$TMP/m6"
make_mother "$M6" "svc-a"
seed_all_missing "$M6" "svc-a"
echo "SECRET=1" >"$M6/svc-a/.env"
(
  cd "$M6/svc-a"
  git add -f .env
  git commit -qm "secret dotenv present"
)
set +e
bout="$(bash "$ROOT/scripts/env-vacancy-answer.sh" \
  --point=.env --reason="nope" --repo=svc-a --branch=main --env=missing-env-config "$M6" 2>&1)"
brc=$?
set -e
[[ "$brc" -ne 0 ]] || fail "point .env must fail"
[[ "$bout" == *"ENV_VACANCY_BLOCKED"* ]] || fail "point .env → BLOCKED, got: $bout"
pass "point to .env → ENV_VACANCY_BLOCKED"

# --- binary waiver alone → matrix OK via (B); substantive fail ---
M7="$TMP/m7"
make_mother "$M7" "svc-a"
seed_all_missing "$M7" "svc-a"
cat >"$M7/docs/vibage/OWNER_POLICY.json" <<'EOF'
{"env_vacancy_waiver": true, "env_vacancy_reason": "fixture has no deploy configs"}
EOF
mout="$(bash "$ROOT/scripts/verify-env-branch-matrix.sh" "$M7")"
[[ "$mout" == "ENV_BRANCH_MATRIX_OK" ]] || fail "waiver (B) should matrix OK, got: $mout"
if bash "$ROOT/scripts/verify-matrix-substantive.sh" "$M7" >/dev/null 2>&1; then
  fail "waiver must never grant substantive"
fi
# vacancy check still ASK (unanswered gaps)
set +e
out="$(bash "$ROOT/scripts/env-vacancy-check.sh" "$M7" 2>/dev/null)"
rc=$?
set -e
[[ "$rc" -ne 0 ]] || fail "waiver alone does not settle vacancy ask"
[[ "$out" == *"ENV_VACANCY_ASK"* ]] || fail "waiver alone still ASK, got: $out"
pass "binary waiver alone → matrix (B); substantive fail; still ASK"

# --- ANSWERED ≠ CLEAR: zero-missing → CLEAR only ---
M8="$TMP/m8"
make_mother "$M8" "svc-a"
seed_clear_real "$M8"
set +e
out="$(bash "$ROOT/scripts/env-vacancy-check.sh" "$M8" 2>/dev/null)"
rc=$?
set -e
[[ "$rc" -eq 0 ]] || fail "CLEAR exit 0"
[[ "$out" == "ENV_VACANCY_CLEAR" || "$out" == *$'\n'"ENV_VACANCY_CLEAR"* || "$out" == "ENV_VACANCY_CLEAR"* ]] \
  || [[ "$out" == *"ENV_VACANCY_CLEAR"* ]] || fail "zero-missing → CLEAR, got: $out"
[[ "$out" != *"ENV_VACANCY_ANSWERED"* ]] || fail "vacuous ANSWERED forbidden"
pass "ANSWERED ≠ CLEAR (zero-missing → CLEAR only)"

# --- ASK / BLOCKED exit ≠ 0; CLEAR / ANSWERED exit 0 ---
# (covered above; explicit BLOCKED malformed answers)
M9="$TMP/m9"
make_mother "$M9" "svc-a"
seed_all_missing "$M9" "svc-a"
echo 'not-json' >"$M9/docs/vibage/maps/env_vacancy_answers.json"
set +e
out="$(bash "$ROOT/scripts/env-vacancy-check.sh" "$M9" 2>/dev/null)"
rc=$?
set -e
[[ "$rc" -ne 0 ]] || fail "malformed answers BLOCKED exit ≠0"
[[ "$out" == *"ENV_VACANCY_BLOCKED"* ]] || fail "malformed → BLOCKED, got: $out"
pass "ASK/BLOCKED exit ≠0; CLEAR/ANSWERED exit 0 (token-parse only)"

# --- answers ≠ freshness waiver (swapping objects must not cross-grant) ---
M10="$TMP/m10"
make_mother "$M10" "svc-a"
seed_all_missing "$M10" "svc-a"
# Put freshness_skip_waiver object into answers file — must not grant ANSWERED/matrix (C)
python3 - "$M10" <<'PY'
import json, sys
from pathlib import Path
from datetime import datetime, timezone, timedelta
m = Path(sys.argv[1])
now = datetime.now(timezone.utc)
fake = {
  "schema_version": "1",
  "updated_at": now.strftime("%Y-%m-%dT%H:%M:%SZ"),
  "answers": {
    "freshness_skip_waiver": {
      "reason": "does not grant vacancy",
      "at": now.strftime("%Y-%m-%dT%H:%M:%SZ"),
      "scope": ["*"],
      "review_by": (now + timedelta(days=3)).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }
  },
}
(m / "docs/vibage/maps/env_vacancy_answers.json").write_text(json.dumps(fake, indent=2) + "\n")
# And put vacancy-shaped skip into OWNER_POLICY freshness slot — must not grant matrix via answers
pol = {
  "freshness_skip_waiver": {
    "action": "skip",
    "reason": "not a vacancy answer",
    "at": now.strftime("%Y-%m-%dT%H:%M:%SZ"),
    "repo_id": "svc-a",
    "branch_ref": "main",
    "env_id": "missing-env-config",
  }
}
(m / "docs/vibage/OWNER_POLICY.json").write_text(json.dumps(pol, indent=2) + "\n")
PY
set +e
out="$(bash "$ROOT/scripts/env-vacancy-check.sh" "$M10" 2>&1)"
rc=$?
set -e
# Malformed answer entry (no action) → BLOCKED, or if skipped as invalid key → ASK
[[ "$rc" -ne 0 ]] || fail "cross-object must not settle vacancy"
[[ "$out" != *"ENV_VACANCY_ANSWERED"* ]] || fail "freshness object must not grant ANSWERED"
[[ "$out" != *"ENV_VACANCY_CLEAR"* ]] || fail "must not CLEAR with missing cells"
if bash "$ROOT/scripts/verify-env-branch-matrix.sh" "$M10" >/dev/null 2>&1; then
  fail "freshness objects must not grant matrix (C)"
fi
pass "answers ≠ freshness waiver (no cross-grant)"

# --- mixed: every missing must be skip|classify; waiver does not bypass ---
M11="$TMP/m11"
make_mother "$M11" "svc-a" "svc-b"
# give svc-a a compose so map is honest
cat >"$M11/svc-a/docker-compose.staging.yml" <<'EOF'
services:
  app:
    environment:
      APP_ENV: staging
EOF
(
  cd "$M11/svc-a"
  git add docker-compose.staging.yml
  git commit -qm "staging"
)
seed_mixed "$M11"
cat >"$M11/docs/vibage/OWNER_POLICY.json" <<'EOF'
{"env_vacancy_waiver": true, "env_vacancy_reason": "must not bypass mixed"}
EOF
if bash "$ROOT/scripts/verify-env-branch-matrix.sh" "$M11" >/dev/null 2>&1; then
  fail "mixed + waiver + unanswered must fail"
fi
bash "$ROOT/scripts/env-vacancy-answer.sh" \
  --skip --reason="orphan lib" --repo=svc-b --branch=main --env=missing-env-config "$M11"
mout="$(bash "$ROOT/scripts/verify-env-branch-matrix.sh" "$M11")"
[[ "$mout" == "ENV_BRANCH_MATRIX_OK" ]] || fail "mixed + skip resolved → OK, got: $mout"
pass "mixed: skip|classify required; waiver does not bypass"

# --- friend-chaos: binary vacancy waiver still forbidden ---
FC="$TMP/friend-chaos"
bash "$ROOT/tests/fixtures/c-prime/friend-chaos/setup.sh" "$FC"
python3 - "$FC" <<'PY'
import json, sys
from pathlib import Path
p = json.load(open(Path(sys.argv[1]) / "docs/vibage/OWNER_POLICY.json"))
assert not p.get("env_vacancy_waiver"), "friend-chaos must not set env_vacancy_waiver"
print("ok")
PY
pass "friend-chaos binary vacancy waiver still forbidden"

echo "ENV_VACANCY_W2_OK"
