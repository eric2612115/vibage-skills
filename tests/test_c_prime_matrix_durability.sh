#!/usr/bin/env bash
# Regression: terminal matrix cell states must survive re-inventory.
# Guards the silent data-loss bug where matrix-inventory.sh rewrote every cell
# as unproven, so refreshing repo-b destroyed repo-a's proven cells.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "OK: $*"; }

state_of() {
  python3 - "$1" "$2" "$3" "$4" <<'PY'
import json, sys
m = json.load(open(sys.argv[1], encoding="utf-8"))
rid, br, eid = sys.argv[2], sys.argv[3], sys.argv[4]
for c in m.get("cells") or []:
    if (c.get("repo_id"), c.get("branch_ref"), c.get("env_id")) == (rid, br, eid):
        print(c.get("state") or "")
        break
else:
    print("MISSING")
PY
}

cell_count_for() {
  python3 - "$1" "$2" <<'PY'
import json, sys
m = json.load(open(sys.argv[1], encoding="utf-8"))
print(sum(1 for c in m.get("cells") or [] if c.get("repo_id") == sys.argv[2]))
PY
}

setup_repo() {
  local parent="$1" name="$2" env_name="$3"
  mkdir -p "$parent/$name"
  (
    cd "$parent/$name"
    git init -q -b main
    git config user.email "t@t"
    git config user.name "t"
    cat >docker-compose.yml <<EOF
services:
  app:
    image: ${name}:latest
    environment:
      APP_ENV: ${env_name}
EOF
    git add -A
    git commit -q -m "init ${env_name}"
  )
}

P="$TMP/parent"
mkdir -p "$P/docs/vibage/maps"
setup_repo "$P" "repo-a" "staging"
setup_repo "$P" "repo-b" "prod"
cat >"$P/docs/vibage/maps/service_map.json" <<'EOF'
{
  "schema_version": "1",
  "pipeline_id": "service_map",
  "scale": "Tiny",
  "quality_bar": "MEDIUM",
  "discover_mode": "flat",
  "discover_max_depth": 1,
  "services": [
    {"id": "repo-a", "name": "repo-a", "path": "repo-a", "definition": "a"},
    {"id": "repo-b", "name": "repo-b", "path": "repo-b", "definition": "b"}
  ],
  "repos": [
    {"id": "repo-a", "repo_id": "repo-a", "name": "repo-a", "path": "repo-a", "definition": "a"},
    {"id": "repo-b", "repo_id": "repo-b", "name": "repo-b", "path": "repo-b", "definition": "b"}
  ],
  "edges": []
}
EOF
MATRIX="$P/docs/vibage/maps/env_branch_matrix.json"

bash "$ROOT/scripts/matrix-inventory.sh" "$P" >/dev/null
[[ -f "$MATRIX" ]] || fail "inventory wrote no matrix"

bash "$ROOT/scripts/matrix-sweep-cell.sh" "$P" "repo-a" "main" "staging" --sweep-started >/dev/null
[[ "$(state_of "$MATRIX" repo-a main staging)" == "proven" ]] \
  || fail "precondition: sweep should prove repo-a@main/staging"
pass "sweep proves repo-a cell"

# 1) Plain re-inventory must not downgrade a proven cell.
inv_out="$(bash "$ROOT/scripts/matrix-inventory.sh" "$P")"
[[ "$(state_of "$MATRIX" repo-a main staging)" == "proven" ]] \
  || fail "re-inventory destroyed proven state (regression)"
printf '%s\n' "$inv_out" | grep -Eq 'mode=merge' \
  || fail "inventory should report mode=merge, got: $inv_out"
printf '%s\n' "$inv_out" | grep -Eq 'preserved_terminal=[1-9]' \
  || fail "inventory should report preserved_terminal>=1, got: $inv_out"
pass "re-inventory preserves proven cell"

# 2) Bounded per-repo refresh must not touch another repo's proven cell.
cat >"$P/docs/vibage/STATUS.md" <<'EOF'
# Hub STATUS (fixture)
EOF
bash "$ROOT/scripts/freshness-refresh-repo.sh" "$P" "repo-b" >/dev/null
[[ "$(state_of "$MATRIX" repo-a main staging)" == "proven" ]] \
  || fail "freshness-refresh-repo repo-b destroyed repo-a proven state (regression)"
out="$(bash "$ROOT/scripts/verify-env-branch-matrix.sh" "$P")"
[[ "$out" == "ENV_BRANCH_MATRIX_OK" ]] \
  || fail "matrix should stay OK after bounded refresh, got: $out"
pass "bounded refresh keeps other repo proven + matrix OK"

# Sanity: the refreshed repo really was swept, not just carried.
[[ "$(state_of "$MATRIX" repo-b main prod)" == "proven" ]] \
  || fail "refreshed repo-b should be swept to a terminal state"
pass "refreshed repo is swept"

# 3) Durability must not resurrect evidence that no longer resolves.
# Renaming the compose file keeps the env discoverable, so the cell is still
# inventoried — but the old pointer path is gone, so carrying `proven` would
# keep MATRIX_SWEEP_SUBSTANTIVE_OK green on evidence that does not exist.
STALE="$TMP/stale"
mkdir -p "$STALE/docs/vibage/maps"
setup_repo "$STALE" "repo-a" "staging"
python3 - "$P/docs/vibage/maps/service_map.json" "$STALE/docs/vibage/maps/service_map.json" <<'PY'
import json, sys
m = json.load(open(sys.argv[1], encoding="utf-8"))
m["services"] = [s for s in m["services"] if s["id"] == "repo-a"]
m["repos"] = [r for r in m["repos"] if r["repo_id"] == "repo-a"]
json.dump(m, open(sys.argv[2], "w", encoding="utf-8"), indent=2)
PY
SMATRIX="$STALE/docs/vibage/maps/env_branch_matrix.json"
bash "$ROOT/scripts/matrix-inventory.sh" "$STALE" >/dev/null
bash "$ROOT/scripts/matrix-sweep-cell.sh" "$STALE" "repo-a" "main" "staging" --sweep-started >/dev/null
[[ "$(state_of "$SMATRIX" repo-a main staging)" == "proven" ]] \
  || fail "precondition: stale fixture cell should start proven"
(
  cd "$STALE/repo-a"
  git mv -f docker-compose.yml compose.yaml
  git commit -q -m "rename compose"
)
stale_out="$(bash "$ROOT/scripts/matrix-inventory.sh" "$STALE")"
[[ "$(state_of "$SMATRIX" repo-a main staging)" == "unproven" ]] \
  || fail "cell with vanished evidence must fall back to unproven (false-green)"
printf '%s\n' "$stale_out" | grep -Eq 'dropped_stale_evidence=[1-9]' \
  || fail "inventory should report dropped_stale_evidence, got: $stale_out"
if bash "$ROOT/scripts/verify-matrix-substantive.sh" "$STALE" >/dev/null 2>&1; then
  fail "vanished evidence must not keep MATRIX_SWEEP_SUBSTANTIVE_OK green"
fi
pass "vanished evidence drops durability and fails closed"

# 4) Deleted branches must not survive as ghost proven cells.
GHOST="$TMP/ghost"
mkdir -p "$GHOST/docs/vibage/maps"
setup_repo "$GHOST" "repo-a" "staging"
setup_repo "$GHOST" "repo-b" "prod"
cp "$P/docs/vibage/maps/service_map.json" "$GHOST/docs/vibage/maps/service_map.json"
cat >"$GHOST/docs/vibage/STATUS.md" <<'EOF'
# Hub STATUS (fixture)
EOF
GMATRIX="$GHOST/docs/vibage/maps/env_branch_matrix.json"
(
  cd "$GHOST/repo-a"
  git branch -q staging
)
bash "$ROOT/scripts/matrix-inventory.sh" "$GHOST" >/dev/null
bash "$ROOT/scripts/matrix-sweep-cell.sh" "$GHOST" "repo-a" "staging" "staging" --sweep-started >/dev/null
[[ "$(state_of "$GMATRIX" repo-a staging staging)" == "proven" ]] \
  || fail "precondition: ghost fixture branch cell should start proven"
(
  cd "$GHOST/repo-a"
  git branch -q -D staging
)
bash "$ROOT/scripts/freshness-refresh-repo.sh" "$GHOST" "repo-b" >/dev/null
[[ "$(state_of "$GMATRIX" repo-a staging staging)" == "MISSING" ]] \
  || fail "deleted branch must not survive as a ghost cell"
pass "deleted branch cell is dropped, not carried"

# 5) --reset is the explicit rebuild escape hatch.
reset_out="$(bash "$ROOT/scripts/matrix-inventory.sh" "$P" --reset)"
[[ "$(state_of "$MATRIX" repo-a main staging)" == "unproven" ]] \
  || fail "--reset must rebuild cells as unproven"
printf '%s\n' "$reset_out" | grep -Eq 'mode=reset' \
  || fail "--reset should report mode=reset"
pass "--reset rebuilds unproven"

# 6) Unknown flags fail loudly.
if bash "$ROOT/scripts/matrix-inventory.sh" "$P" --bogus >/dev/null 2>&1; then
  fail "unknown flag must fail"
fi
if bash "$ROOT/scripts/matrix-inventory.sh" "$P" --only-repo=repo-a >/dev/null 2>&1; then
  fail "retired --only-repo must not silently succeed"
fi
pass "flag misuse fails closed"

# 7) never-scanned is disclosed distinctly from stale.
NS="$TMP/never"
mkdir -p "$NS/docs/vibage/maps"
cat >"$NS/docs/vibage/STATUS.md" <<'EOF'
# Hub STATUS (fixture)
EOF
cp "$P/docs/vibage/maps/service_map.json" "$NS/docs/vibage/maps/service_map.json"
set +e
fr_err="$(bash "$ROOT/scripts/verify-freshness.sh" "$NS" 2>&1 >/dev/null)"
set -e
printf '%s\n' "$fr_err" | grep -Eq 'never_scanned_count=2' \
  || fail "freshness should disclose never_scanned_count=2, got: $fr_err"
printf '%s\n' "$fr_err" | grep -Eq 'stale_reasons=.*missing_freshness_json' \
  || fail "freshness should disclose stale_reasons, got: $fr_err"
printf '%s\n' "$fr_err" | grep -Fq 'run c-prime-fill' \
  || fail "never-scanned note should name c-prime-fill, got: $fr_err"
pass "never-scanned disclosed distinctly from stale"

echo "MATRIX_DURABILITY_OK"
