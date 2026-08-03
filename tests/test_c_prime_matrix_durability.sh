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

# 3b) A working-tree hit must not stand in for another branch's evidence.
# Deleting the compose file on `staging` while `main` is checked out leaves the
# file on disk, so a path-existence-only gate would carry staging's proven cell
# even though extract for staging now fails.
BR="$TMP/branchref"
mkdir -p "$BR/docs/vibage/maps"
setup_repo "$BR" "repo-a" "staging"
python3 - "$P/docs/vibage/maps/service_map.json" "$BR/docs/vibage/maps/service_map.json" <<'PY'
import json, sys
m = json.load(open(sys.argv[1], encoding="utf-8"))
m["services"] = [s for s in m["services"] if s["id"] == "repo-a"]
m["repos"] = [r for r in m["repos"] if r["repo_id"] == "repo-a"]
json.dump(m, open(sys.argv[2], "w", encoding="utf-8"), indent=2)
PY
BMATRIX="$BR/docs/vibage/maps/env_branch_matrix.json"
(
  cd "$BR/repo-a"
  git branch -q staging
)
bash "$ROOT/scripts/matrix-inventory.sh" "$BR" >/dev/null
bash "$ROOT/scripts/matrix-sweep-cell.sh" "$BR" "repo-a" "staging" "staging" --sweep-started >/dev/null
[[ "$(state_of "$BMATRIX" repo-a staging staging)" == "proven" ]] \
  || fail "precondition: branch-ref fixture cell should start proven"
(
  cd "$BR/repo-a"
  git checkout -q staging
  git rm -q docker-compose.yml
  git commit -q -m "drop compose on staging"
  git checkout -q main
)
[[ -f "$BR/repo-a/docker-compose.yml" ]] \
  || fail "precondition: working tree should still hold the file on main"
br_out="$(bash "$ROOT/scripts/matrix-inventory.sh" "$BR")"
[[ "$(state_of "$BMATRIX" repo-a staging staging)" == "unproven" ]] \
  || fail "working-tree hit must not carry another branch's proven cell (false-green)"
printf '%s\n' "$br_out" | grep -Eq 'dropped_stale_evidence=[1-9]' \
  || fail "branch-scoped drop should be reported, got: $br_out"
pass "evidence is resolved per branch, not per working tree"

# 3c) Untracked evidence on the checked-out branch still counts.
(
  cd "$BR/repo-a"
  cat >docker-compose.untracked.yml <<'EOF'
services:
  app:
    image: repo-a:latest
    environment:
      APP_ENV: staging
EOF
)
bash "$ROOT/scripts/matrix-sweep-cell.sh" "$BR" "repo-a" "main" "staging" --sweep-started >/dev/null
if [[ "$(state_of "$BMATRIX" repo-a main staging)" == "proven" ]]; then
  bash "$ROOT/scripts/matrix-inventory.sh" "$BR" >/dev/null
  [[ "$(state_of "$BMATRIX" repo-a main staging)" == "proven" ]] \
    || fail "checked-out-branch evidence must stay carryable"
  pass "checked-out branch evidence still carries"
else
  echo "NOTE: main cell not proven in this fixture — untracked-carry path not exercised"
fi

# 3d) Content drift must not be carried: same path, env evidence gone.
# The compose file keeps its name (so the env is still inventoried via the
# filename rule) but loses the line that backed the verdict.
DRIFT="$TMP/drift"
mkdir -p "$DRIFT/docs/vibage/maps"
mkdir -p "$DRIFT/repo-a/deploy/production"
(
  cd "$DRIFT/repo-a"
  git init -q -b main
  git config user.email "t@t"
  git config user.name "t"
  # Pointer evidence lives in the compose body; deploy/production/ keeps the env
  # in the inventory after that line goes, so the cell survives structurally and
  # the carry gate is what has to refuse it.
  cat >docker-compose.yml <<'EOF'
services:
  app:
    image: repo-a:latest
    environment:
      APP_ENV: production
      PORT: 8080
EOF
  printf 'k8s\n' >deploy/production/.gitkeep
  git add -A
  git commit -q -m "init compose with env line + deploy dir"
)
python3 - "$P/docs/vibage/maps/service_map.json" "$DRIFT/docs/vibage/maps/service_map.json" <<'PY'
import json, sys
m = json.load(open(sys.argv[1], encoding="utf-8"))
m["services"] = [s for s in m["services"] if s["id"] == "repo-a"]
m["repos"] = [r for r in m["repos"] if r["repo_id"] == "repo-a"]
json.dump(m, open(sys.argv[2], "w", encoding="utf-8"), indent=2)
PY
DMATRIX="$DRIFT/docs/vibage/maps/env_branch_matrix.json"
bash "$ROOT/scripts/matrix-inventory.sh" "$DRIFT" >/dev/null
bash "$ROOT/scripts/matrix-sweep-cell.sh" "$DRIFT" "repo-a" "main" "production" --sweep-started >/dev/null
[[ "$(state_of "$DMATRIX" repo-a main production)" == "proven" ]] \
  || fail "precondition: drift fixture cell should start proven"
python3 - "$DMATRIX" <<'PY' || fail "drift precondition: pointer should be the compose body"
import json, sys
m = json.load(open(sys.argv[1], encoding="utf-8"))
for c in m["cells"]:
    if c["env_id"] == "production" and c["state"] == "proven":
        paths = [p["path"] for p in c.get("pointers") or []]
        assert paths == ["repo-a/docker-compose.yml"], paths
        break
else:
    raise SystemExit("no proven production cell")
PY
(
  cd "$DRIFT/repo-a"
  cat >docker-compose.yml <<'EOF'
services:
  app:
    image: repo-a:latest
    environment:
      PORT: 8080
EOF
  git add -A
  git commit -q -m "drop env line, keep file and deploy dir"
)
drift_out="$(bash "$ROOT/scripts/matrix-inventory.sh" "$DRIFT")"
[[ "$(state_of "$DMATRIX" repo-a main production)" == "unproven" ]] \
  || fail "content drift must not be carried (residual false-green)"
printf '%s\n' "$drift_out" | grep -Eq 'dropped_stale_evidence=[1-9]' \
  || fail "content drift should be reported, got: $drift_out"
pass "content drift drops durability"

# ...and a re-sweep repairs it from the surviving deploy/ evidence: fail-closed,
# not permanently red.
bash "$ROOT/scripts/matrix-sweep-cell.sh" "$DRIFT" "repo-a" "main" "production" --sweep-started >/dev/null
[[ "$(state_of "$DMATRIX" repo-a main production)" == "proven" ]] \
  || fail "re-sweep should re-prove from surviving evidence"
python3 - "$DMATRIX" <<'PY' || fail "re-swept pointer should be the surviving evidence"
import json, sys
m = json.load(open(sys.argv[1], encoding="utf-8"))
for c in m["cells"]:
    if c["env_id"] == "production" and c["state"] == "proven":
        quotes = [p["quote"] for p in c.get("pointers") or []]
        assert not any("APP_ENV: production" in q for q in quotes), quotes
        break
else:
    raise SystemExit("no proven production cell after re-sweep")
PY
pass "re-sweep repairs the dropped cell without the stale quote"

# 3e) Quote shapes that are NOT file substrings must still carry.
# Measured during design: naive substring comparison false-reds ~31% of real
# proven cells (directory pointers and synthesised presence quotes), so carrying
# must re-derive rather than string-match.
SHAPES="$TMP/shapes"
mkdir -p "$SHAPES/docs/vibage/maps" "$SHAPES/repo-a/deploy/qa"
(
  cd "$SHAPES/repo-a"
  git init -q -b main
  git config user.email "t@t"
  git config user.name "t"
  cat >docker-compose.yml <<'EOF'
services:
  app:
    image: repo-a:latest
EOF
  cat >.env.example <<'EOF'
# comment only, no KEY=value
EOF
  printf 'qa\n' >deploy/qa/.gitkeep
  git add -A
  git commit -q -m "dir + presence-only shapes"
)
python3 - "$P/docs/vibage/maps/service_map.json" "$SHAPES/docs/vibage/maps/service_map.json" <<'PY'
import json, sys
m = json.load(open(sys.argv[1], encoding="utf-8"))
m["services"] = [s for s in m["services"] if s["id"] == "repo-a"]
m["repos"] = [r for r in m["repos"] if r["repo_id"] == "repo-a"]
json.dump(m, open(sys.argv[2], "w", encoding="utf-8"), indent=2)
PY
SHMATRIX="$SHAPES/docs/vibage/maps/env_branch_matrix.json"
bash "$ROOT/scripts/matrix-inventory.sh" "$SHAPES" >/dev/null
python3 - "$SHMATRIX" "$SHAPES" "$ROOT" <<'PY' || fail "non-substring quote shapes must survive carry"
import json, subprocess, sys
from pathlib import Path

matrix_path, parent, root = Path(sys.argv[1]), sys.argv[2], sys.argv[3]
cells = json.loads(matrix_path.read_text(encoding="utf-8"))["cells"]
swept = 0
for c in cells:
    if c["env_id"] in ("missing-env-config", "unknown-env"):
        continue
    subprocess.run(
        ["bash", f"{root}/scripts/matrix-sweep-cell.sh", parent,
         c["repo_id"], c["branch_ref"], c["env_id"], "--sweep-started"],
        check=True, capture_output=True, text=True,
    )
    swept += 1
if not swept:
    raise SystemExit("fixture produced no sweepable cells")

before = json.loads(matrix_path.read_text(encoding="utf-8"))["cells"]
proven_before = {
    (c["repo_id"], c["branch_ref"], c["env_id"]): c
    for c in before if c["state"] == "proven"
}
if not proven_before:
    raise SystemExit("fixture produced no proven cells")
# Any quote that is not a literal substring of its file is exactly the shape a
# naive comparison would have dropped; assert at least one exists so this case
# cannot silently stop testing what it claims to.
non_substring = 0
for (rid, br, eid), c in proven_before.items():
    for p in c.get("pointers") or []:
        rel = p["path"].split("/", 1)[1] if "/" in p["path"] else p["path"]
        r = subprocess.run(
            ["git", "-C", f"{parent}/{rid}", "show", f"{br}:{rel}"],
            capture_output=True, text=True,
        )
        if r.returncode != 0 or p["quote"] not in (r.stdout or ""):
            non_substring += 1
if not non_substring:
    raise SystemExit("fixture no longer contains a non-substring quote shape")

out = subprocess.run(
    ["bash", f"{root}/scripts/matrix-inventory.sh", parent],
    capture_output=True, text=True, check=True,
).stdout
after = {
    (c["repo_id"], c["branch_ref"], c["env_id"]): c
    for c in json.loads(matrix_path.read_text(encoding="utf-8"))["cells"]
}
lost = [k for k in proven_before if after.get(k, {}).get("state") != "proven"]
if lost:
    raise SystemExit(f"carry false-red on non-substring quotes: {lost}\n{out}")
print(f"non_substring_quotes={non_substring} preserved={len(proven_before)}")
PY
pass "directory and presence-only quote shapes still carry"

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
