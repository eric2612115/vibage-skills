#!/usr/bin/env bash
# C′ Chunk 1: env/branch matrix inventory, sweep, substantive, c-prime-fill
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "OK: $*"; }

write_matrix() {
  local dir="$1"
  mkdir -p "$dir/docs/vibage/maps"
  cat >"$dir/docs/vibage/maps/env_branch_matrix.json"
}

write_manifest() {
  local dir="$1"
  mkdir -p "$dir/docs/vibage/maps"
  cat >"$dir/docs/vibage/maps/inventory_manifest.json"
}

# ---------------------------------------------------------------------------
# Task 1.1 — verify-env-branch-matrix.sh
# ---------------------------------------------------------------------------

# 1) Pre-seeded terminal matrix → ENV_BRANCH_MATRIX_OK
M1="$TMP/m1"
mkdir -p "$M1/docs/vibage"
write_matrix "$M1" <<'EOF'
{
  "schema_version": "1",
  "status": "ok",
  "max_branches_per_repo": 30,
  "max_matrix_cells": 500,
  "cells": [
    {
      "repo_id": "svc-a",
      "branch_ref": "main",
      "env_id": "staging",
      "pointers": [{"path": "svc-a/docker-compose.yml", "quote": "APP_ENV: staging", "branch_ref": "main", "env_id": "staging"}],
      "state": "proven"
    },
    {
      "repo_id": "svc-b",
      "branch_ref": "main",
      "env_id": "prod",
      "pointers": [{"path": "svc-b/compose.yml", "quote": "APP_ENV: prod", "branch_ref": "main", "env_id": "prod"}],
      "state": "failed",
      "reason": "extract_error"
    }
  ]
}
EOF
write_manifest "$M1" <<'EOF'
{
  "schema_version": "1",
  "rows": [
    {"repo_id": "svc-a", "branch_ref": "main", "env_id": "staging"},
    {"repo_id": "svc-b", "branch_ref": "main", "env_id": "prod"}
  ]
}
EOF
out="$(bash "$ROOT/scripts/verify-env-branch-matrix.sh" "$M1")"
[[ "$out" == "ENV_BRANCH_MATRIX_OK" ]] || fail "terminal matrix should OK, got: $out"
pass "terminal matrix → ENV_BRANCH_MATRIX_OK"

# 2) All missing-env-config → fail unless env_vacancy_waiver
M2="$TMP/m2"
write_matrix "$M2" <<'EOF'
{
  "schema_version": "1",
  "status": "ok",
  "cells": [
    {
      "repo_id": "svc-a",
      "branch_ref": "main",
      "env_id": "missing-env-config",
      "pointers": [{"path": "svc-a", "quote": "no env configs", "branch_ref": "main", "env_id": "missing-env-config"}],
      "state": "failed"
    },
    {
      "repo_id": "svc-b",
      "branch_ref": "main",
      "env_id": "missing-env-config",
      "pointers": [{"path": "svc-b", "quote": "no env configs", "branch_ref": "main", "env_id": "missing-env-config"}],
      "state": "failed"
    }
  ]
}
EOF
write_manifest "$M2" <<'EOF'
{
  "schema_version": "1",
  "rows": [
    {"repo_id": "svc-a", "branch_ref": "main", "env_id": "missing-env-config"},
    {"repo_id": "svc-b", "branch_ref": "main", "env_id": "missing-env-config"}
  ]
}
EOF
if bash "$ROOT/scripts/verify-env-branch-matrix.sh" "$M2" >/dev/null 2>&1; then
  fail "all missing-env-config must fail without waiver"
fi
pass "all missing-env-config → fail without waiver"

mkdir -p "$M2/docs/vibage"
cat >"$M2/docs/vibage/OWNER_POLICY.json" <<'EOF'
{"env_vacancy_waiver": true, "env_vacancy_reason": "fixture has no deploy configs"}
EOF
out="$(bash "$ROOT/scripts/verify-env-branch-matrix.sh" "$M2")"
[[ "$out" == "ENV_BRANCH_MATRIX_OK" ]] || fail "waiver should allow matrix OK, got: $out"
pass "all missing-env-config + waiver → ENV_BRANCH_MATRIX_OK"

# 3) unknown-env → fail
M3="$TMP/m3"
write_matrix "$M3" <<'EOF'
{
  "schema_version": "1",
  "status": "ok",
  "cells": [
    {
      "repo_id": "svc-a",
      "branch_ref": "main",
      "env_id": "unknown-env",
      "pointers": [{"path": "svc-a", "quote": "tmp", "branch_ref": "main", "env_id": "unknown-env"}],
      "state": "failed"
    },
    {
      "repo_id": "svc-a",
      "branch_ref": "main",
      "env_id": "staging",
      "pointers": [{"path": "svc-a/c.yml", "quote": "APP_ENV: staging", "branch_ref": "main", "env_id": "staging"}],
      "state": "proven"
    }
  ]
}
EOF
write_manifest "$M3" <<'EOF'
{
  "schema_version": "1",
  "rows": [
    {"repo_id": "svc-a", "branch_ref": "main", "env_id": "unknown-env"},
    {"repo_id": "svc-a", "branch_ref": "main", "env_id": "staging"}
  ]
}
EOF
if bash "$ROOT/scripts/verify-env-branch-matrix.sh" "$M3" >/dev/null 2>&1; then
  fail "unknown-env must fail verify"
fi
pass "unknown-env → fail"

# 4) overflow → fail
M4="$TMP/m4"
write_matrix "$M4" <<'EOF'
{
  "schema_version": "1",
  "status": "overflow",
  "cells": [
    {
      "repo_id": "svc-a",
      "branch_ref": "main",
      "env_id": "staging",
      "pointers": [{"path": "svc-a/c.yml", "quote": "APP_ENV: staging", "branch_ref": "main", "env_id": "staging"}],
      "state": "proven"
    }
  ]
}
EOF
write_manifest "$M4" <<'EOF'
{
  "schema_version": "1",
  "rows": [
    {"repo_id": "svc-a", "branch_ref": "main", "env_id": "staging"}
  ]
}
EOF
if bash "$ROOT/scripts/verify-env-branch-matrix.sh" "$M4" >/dev/null 2>&1; then
  fail "overflow must fail verify"
fi
pass "overflow → fail"

# 5) branch_cap failed cells can still OK
M5="$TMP/m5"
write_matrix "$M5" <<'EOF'
{
  "schema_version": "1",
  "status": "ok",
  "cells": [
    {
      "repo_id": "svc-a",
      "branch_ref": "main",
      "env_id": "staging",
      "pointers": [{"path": "svc-a/c.yml", "quote": "APP_ENV: staging", "branch_ref": "main", "env_id": "staging"}],
      "state": "proven"
    },
    {
      "repo_id": "svc-a",
      "branch_ref": "feature/extra-31",
      "env_id": "staging",
      "pointers": [{"path": "svc-a", "quote": "branch_cap", "branch_ref": "feature/extra-31", "env_id": "staging"}],
      "state": "failed",
      "reason": "branch_cap"
    }
  ]
}
EOF
write_manifest "$M5" <<'EOF'
{
  "schema_version": "1",
  "rows": [
    {"repo_id": "svc-a", "branch_ref": "main", "env_id": "staging"},
    {"repo_id": "svc-a", "branch_ref": "feature/extra-31", "env_id": "staging"}
  ]
}
EOF
out="$(bash "$ROOT/scripts/verify-env-branch-matrix.sh" "$M5")"
[[ "$out" == "ENV_BRANCH_MATRIX_OK" ]] || fail "branch_cap failed cells should still allow OK, got: $out"
pass "branch_cap failed cells → still ENV_BRANCH_MATRIX_OK"

# ---------------------------------------------------------------------------
# Task 1.2 — extract / sweep / substantive
# ---------------------------------------------------------------------------

# Helper: real tiny git repo with compose env on main + staging branch
setup_compose_repo() {
  local parent="$1" name="$2" env_name="$3"
  local r="$parent/$name"
  mkdir -p "$r"
  (
    cd "$r"
    git init -q -b main
    git config user.email "test@example.com"
    git config user.name "Test"
    cat >docker-compose.yml <<EOF
services:
  app:
    image: ${name}:latest
    environment:
      APP_ENV: ${env_name}
EOF
    git add docker-compose.yml
    git commit -q -m "init compose ${env_name}"
    git branch -q staging
    # staging branch has different quote
    git checkout -q staging
    cat >docker-compose.yml <<EOF
services:
  app:
    image: ${name}:latest
    environment:
      APP_ENV: ${env_name}
      STAGE: yes
EOF
    git add docker-compose.yml
    git commit -q -m "staging compose"
    git checkout -q main
  )
}

# Extract returns path+quote for compose env (non-current branch via git show)
EX="$TMP/extract"
mkdir -p "$EX"
setup_compose_repo "$EX" "svc-a" "staging"
# Need service_map for inventory path resolution — extract uses parent+repo_id
mkdir -p "$EX/docs/vibage/maps"
cat >"$EX/docs/vibage/maps/service_map.json" <<'EOF'
{
  "schema_version": "1",
  "pipeline_id": "service_map",
  "scale": "Tiny",
  "quality_bar": "MEDIUM",
  "discover_mode": "flat",
  "discover_max_depth": 1,
  "services": [{"id": "svc-a", "name": "svc-a", "path": "svc-a", "definition": "a"}],
  "repos": [{"id": "svc-a", "repo_id": "svc-a", "name": "svc-a", "path": "svc-a", "definition": "a"}],
  "edges": []
}
EOF
ext_out="$(python3 "$ROOT/scripts/matrix-extract-evidence.py" "$EX" "svc-a" "staging" "staging")"
printf '%s\n' "$ext_out" | python3 -c '
import json,sys
obj=json.load(sys.stdin)
ptrs=obj if isinstance(obj,list) else obj.get("pointers") or []
if isinstance(obj,dict) and "path" in obj:
  ptrs=[obj]
assert ptrs, "extract must return pointers"
p=ptrs[0]
assert p.get("path"), "path required"
assert p.get("quote"), "quote required"
assert p.get("branch_ref")=="staging", p
assert p.get("env_id")=="staging", p
assert "APP_ENV" in p["quote"] or "staging" in p["quote"].lower() or "STAGE" in p["quote"]
print("OK extract fields")
'
pass "extract path+quote for non-current branch"

# Sweep sets proven
write_matrix "$EX" <<'EOF'
{
  "schema_version": "1",
  "status": "ok",
  "cells": [
    {
      "repo_id": "svc-a",
      "branch_ref": "staging",
      "env_id": "staging",
      "pointers": [],
      "state": "unproven"
    }
  ]
}
EOF
write_manifest "$EX" <<'EOF'
{
  "schema_version": "1",
  "rows": [
    {"repo_id": "svc-a", "branch_ref": "staging", "env_id": "staging"}
  ]
}
EOF
bash "$ROOT/scripts/matrix-sweep-cell.sh" "$EX" "svc-a" "staging" "staging" --sweep-started
python3 - <<PY
import json
m=json.load(open("$EX/docs/vibage/maps/env_branch_matrix.json"))
c=m["cells"][0]
assert c["state"]=="proven", c
assert c.get("pointers") and c["pointers"][0].get("path") and c["pointers"][0].get("quote")
print("OK sweep proven")
PY
pass "sweep-cell → proven"

# Substantive: all-failed real-env → fail
MS1="$TMP/sub1"
write_matrix "$MS1" <<'EOF'
{
  "schema_version": "1",
  "status": "ok",
  "cells": [
    {
      "repo_id": "svc-a",
      "branch_ref": "main",
      "env_id": "staging",
      "pointers": [{"path": "svc-a/c.yml", "quote": "x", "branch_ref": "main", "env_id": "staging"}],
      "state": "failed",
      "reason": "timeout"
    },
    {
      "repo_id": "svc-b",
      "branch_ref": "main",
      "env_id": "prod",
      "pointers": [{"path": "svc-b/c.yml", "quote": "y", "branch_ref": "main", "env_id": "prod"}],
      "state": "failed"
    }
  ]
}
EOF
write_manifest "$MS1" <<'EOF'
{
  "schema_version": "1",
  "rows": [
    {"repo_id": "svc-a", "branch_ref": "main", "env_id": "staging"},
    {"repo_id": "svc-b", "branch_ref": "main", "env_id": "prod"}
  ]
}
EOF
# matrix OK (terminal, real envs, mixed/all failed ok for 終態)
out="$(bash "$ROOT/scripts/verify-env-branch-matrix.sh" "$MS1")"
[[ "$out" == "ENV_BRANCH_MATRIX_OK" ]] || fail "all-failed real-env should still be matrix OK"
if bash "$ROOT/scripts/verify-matrix-substantive.sh" "$MS1" >/dev/null 2>&1; then
  fail "all-failed real-env must fail substantive"
fi
pass "all-failed real-env → substantive fail"

# Substantive: all proven with path+quote → OK
MS2="$TMP/sub2"
write_matrix "$MS2" <<'EOF'
{
  "schema_version": "1",
  "status": "ok",
  "cells": [
    {
      "repo_id": "svc-a",
      "branch_ref": "main",
      "env_id": "staging",
      "pointers": [{"path": "svc-a/docker-compose.yml", "quote": "APP_ENV: staging", "branch_ref": "main", "env_id": "staging"}],
      "state": "proven"
    },
    {
      "repo_id": "svc-b",
      "branch_ref": "main",
      "env_id": "prod",
      "pointers": [{"path": "svc-b/compose.yml", "quote": "APP_ENV: prod", "branch_ref": "main", "env_id": "prod"}],
      "state": "proven"
    }
  ]
}
EOF
write_manifest "$MS2" <<'EOF'
{
  "schema_version": "1",
  "rows": [
    {"repo_id": "svc-a", "branch_ref": "main", "env_id": "staging"},
    {"repo_id": "svc-b", "branch_ref": "main", "env_id": "prod"}
  ]
}
EOF
out="$(bash "$ROOT/scripts/verify-matrix-substantive.sh" "$MS2")"
[[ "$out" == "MATRIX_SWEEP_SUBSTANTIVE_OK" ]] || fail "all proven should substantive OK, got: $out"
pass "all proven path+quote → MATRIX_SWEEP_SUBSTANTIVE_OK"

# Waiver never grants substantive
MS3="$TMP/sub3"
write_matrix "$MS3" <<'EOF'
{
  "schema_version": "1",
  "status": "ok",
  "cells": [
    {
      "repo_id": "svc-a",
      "branch_ref": "main",
      "env_id": "missing-env-config",
      "pointers": [{"path": "svc-a", "quote": "no env", "branch_ref": "main", "env_id": "missing-env-config"}],
      "state": "failed"
    }
  ]
}
EOF
write_manifest "$MS3" <<'EOF'
{
  "schema_version": "1",
  "rows": [
    {"repo_id": "svc-a", "branch_ref": "main", "env_id": "missing-env-config"}
  ]
}
EOF
mkdir -p "$MS3/docs/vibage"
cat >"$MS3/docs/vibage/OWNER_POLICY.json" <<'EOF'
{"env_vacancy_waiver": true, "env_vacancy_reason": "test"}
EOF
out="$(bash "$ROOT/scripts/verify-env-branch-matrix.sh" "$MS3")"
[[ "$out" == "ENV_BRANCH_MATRIX_OK" ]] || fail "waiver matrix OK expected"
if bash "$ROOT/scripts/verify-matrix-substantive.sh" "$MS3" >/dev/null 2>&1; then
  fail "waiver must never grant MATRIX_SWEEP_SUBSTANTIVE_OK"
fi
pass "waiver never grants substantive"

# missing-env / unknown-env block substantive (even with some proven)
MS4="$TMP/sub4"
write_matrix "$MS4" <<'EOF'
{
  "schema_version": "1",
  "status": "ok",
  "cells": [
    {
      "repo_id": "svc-a",
      "branch_ref": "main",
      "env_id": "staging",
      "pointers": [{"path": "a.yml", "quote": "APP_ENV: staging", "branch_ref": "main", "env_id": "staging"}],
      "state": "proven"
    },
    {
      "repo_id": "svc-b",
      "branch_ref": "main",
      "env_id": "missing-env-config",
      "pointers": [{"path": "svc-b", "quote": "no", "branch_ref": "main", "env_id": "missing-env-config"}],
      "state": "failed"
    }
  ]
}
EOF
write_manifest "$MS4" <<'EOF'
{
  "schema_version": "1",
  "rows": [
    {"repo_id": "svc-a", "branch_ref": "main", "env_id": "staging"},
    {"repo_id": "svc-b", "branch_ref": "main", "env_id": "missing-env-config"}
  ]
}
EOF
if bash "$ROOT/scripts/verify-matrix-substantive.sh" "$MS4" >/dev/null 2>&1; then
  fail "missing-env-config must block substantive"
fi
pass "missing-env-config blocks substantive"

# ---------------------------------------------------------------------------
# Task 1.3 — c-prime-fill on tiny 2-repo compose parent
# ---------------------------------------------------------------------------
FILL="$TMP/fill"
mkdir -p "$FILL"
setup_compose_repo "$FILL" "svc-a" "staging"
setup_compose_repo "$FILL" "svc-b" "prod"
# second env on svc-b; cherry-pick onto staging so both branches have extractable evidence
(
  cd "$FILL/svc-b"
  cat >docker-compose.staging.yml <<'EOF'
services:
  app:
    image: svc-b:staging
    environment:
      APP_ENV: staging
EOF
  git add docker-compose.staging.yml
  git commit -q -m "add staging compose file"
  git checkout -q staging
  git checkout -q main -- docker-compose.staging.yml
  git add docker-compose.staging.yml
  git commit -q -m "staging branch has staging compose"
  git checkout -q main
)
# svc-a already uses staging as APP_ENV; add prod compose on both branches for ≥2 real envs
(
  cd "$FILL/svc-a"
  cat >docker-compose.prod.yml <<'EOF'
services:
  app:
    image: svc-a:prod
    environment:
      APP_ENV: prod
EOF
  git add docker-compose.prod.yml
  git commit -q -m "add prod compose file"
  git checkout -q staging
  git checkout -q main -- docker-compose.prod.yml
  git add docker-compose.prod.yml
  git commit -q -m "staging branch has prod compose"
  git checkout -q main
)

bash "$ROOT/scripts/c-prime-fill.sh" "$FILL"
out="$(bash "$ROOT/scripts/verify-env-branch-matrix.sh" "$FILL")"
[[ "$out" == "ENV_BRANCH_MATRIX_OK" ]] || fail "c-prime-fill should reach ENV_BRANCH_MATRIX_OK, got: $out"
pass "c-prime-fill → ENV_BRANCH_MATRIX_OK"

out_sub="$(bash "$ROOT/scripts/verify-matrix-substantive.sh" "$FILL")"
[[ "$out_sub" == "MATRIX_SWEEP_SUBSTANTIVE_OK" ]] || fail "c-prime-fill should reach substantive, got: $out_sub"
pass "c-prime-fill → MATRIX_SWEEP_SUBSTANTIVE_OK"

echo "ALL test_c_prime_matrix.sh PASS"
