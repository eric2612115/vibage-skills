#!/usr/bin/env bash
# W1 freshness — Spec §8. Outside test_c_prime_*.sh suite glob. Not Tier-0.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "OK: $*"; }

[[ -x "$ROOT/scripts/freshness-check.sh" ]] || fail "missing freshness-check.sh"
[[ -x "$ROOT/scripts/freshness-mark.sh" ]] || fail "missing freshness-mark.sh"
[[ -x "$ROOT/scripts/verify-freshness.sh" ]] || fail "missing verify-freshness.sh"

# Firewall: freshness ∉ Tier-0 / pack-health
! grep -Eq 'test_freshness_w1|freshness-check|verify-freshness|freshness-mark' \
  "$ROOT/scripts/test-tier0.sh" \
  || fail "freshness wired into test-tier0.sh"
! grep -Eq 'test_freshness_w1|freshness-check|verify-freshness' \
  "$ROOT/scripts/pack-health.sh" \
  || fail "freshness wired into pack-health.sh"
pass "Tier-0 / pack-health firewall"

# Suite firewall: this file must not match test_c_prime_*.sh
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
  printf 'services:\n  app:\n    environment:\n      APP_ENV: local\n' >"$d/docker-compose.yml"
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

seed_matrix_terminal() {
  local m="$1"
  shift
  python3 - "$m" "$@" <<'PY'
import json, sys
from pathlib import Path
m = Path(sys.argv[1])
repos = sys.argv[2:]
cells = []
rows = []
for rid in repos:
    cells.append({
        "repo_id": rid,
        "branch_ref": "main",
        "env_id": "local",
        "pointers": [{"path": f"{rid}/docker-compose.yml", "quote": "APP_ENV: local", "branch_ref": "main", "env_id": "local"}],
        "state": "proven",
    })
    rows.append({"repo_id": rid, "branch_ref": "main", "env_id": "local"})
obj = {"schema_version": "1", "status": "ok", "cells": cells}
(m / "docs/vibage/maps/env_branch_matrix.json").write_text(json.dumps(obj, indent=2) + "\n")
(m / "docs/vibage/maps/inventory_manifest.json").write_text(
    json.dumps({"schema_version": "1", "rows": rows}, indent=2) + "\n"
)
PY
}

mark_ok() {
  bash "$ROOT/scripts/freshness-mark.sh" --success "$1" "$2"
}

# --- Missing freshness.json → hard-fail ---
M0="$TMP/m0"
make_mother "$M0" "svc-a"
seed_matrix_terminal "$M0" "svc-a"
set +e
out="$(bash "$ROOT/scripts/freshness-check.sh" --mode=mother "$M0" 2>/dev/null)"
rc=$?
set -e
[[ "$rc" -eq 1 ]] || fail "missing freshness.json should exit 1, got $rc"
[[ "$out" == *"STALE_BLOCKS_MOTHER count=1"* ]] || fail "missing json token: $out"
pass "missing freshness.json → STALE_BLOCKS_MOTHER"

# --- Mark success + FRESHNESS_OK ---
mark_ok "$M0" "svc-a" || fail "mark success should work with terminal cells"
out="$(bash "$ROOT/scripts/verify-freshness.sh" "$M0" 2>/dev/null)"
[[ "$out" == *"FRESHNESS_OK"* ]] || fail "expected FRESHNESS_OK got: $out"
[[ "$out" != *"FRESHNESS_WAIVED"* ]] || fail "should not waive when fresh"
pass "mark success → FRESHNESS_OK"

# --- HEAD change → mother fail, child warn ---
echo "y" >>"$M0/svc-a/README.md"
git -C "$M0/svc-a" add -A && git -C "$M0/svc-a" commit -qm "change"
set +e
out="$(bash "$ROOT/scripts/freshness-check.sh" --mode=mother "$M0" 2>/dev/null)"
rc=$?
set -e
[[ "$rc" -eq 1 ]] || fail "HEAD change mother should exit 1"
[[ "$out" == *"STALE_BLOCKS_MOTHER count=1"* ]] || fail "HEAD change mother token: $out"
cout="$(bash "$ROOT/scripts/freshness-check.sh" --mode=child --repo=svc-a "$M0/svc-a" 2>/dev/null)"
[[ "$cout" == *"FRESHNESS_CHILD_WARN"* ]] || fail "child warn missing: $cout"
pass "HEAD change → mother block + child warn"

# --- Partial waiver scope ---
M1="$TMP/m1"
make_mother "$M1" "svc-a" "svc-b"
seed_matrix_terminal "$M1" "svc-a" "svc-b"
# leave freshness missing → both stale
python3 - "$M1" <<'PY'
import json, sys
from pathlib import Path
from datetime import datetime, timezone, timedelta
m = Path(sys.argv[1])
now = datetime.now(timezone.utc)
review = (now + timedelta(days=7)).strftime("%Y-%m-%dT%H:%M:%SZ")
pol = {
  "freshness_skip_waiver": {
    "reason": "partial test",
    "at": now.strftime("%Y-%m-%dT%H:%M:%SZ"),
    "scope": ["svc-a"],
    "review_by": review,
  }
}
(m / "docs/vibage/OWNER_POLICY.json").write_text(json.dumps(pol, indent=2) + "\n")
PY
set +e
out="$(bash "$ROOT/scripts/freshness-check.sh" --mode=mother "$M1" 2>/dev/null)"
rc=$?
set -e
[[ "$rc" -eq 1 ]] || fail "partial waiver should still block"
[[ "$out" == *"STALE_BLOCKS_MOTHER"* ]] || fail "partial waiver token: $out"
pass "partial waiver scope → STALE_BLOCKS_MOTHER"

# --- Valid full waiver ---
python3 - "$M1" <<'PY'
import json, sys
from pathlib import Path
from datetime import datetime, timezone, timedelta
m = Path(sys.argv[1])
now = datetime.now(timezone.utc)
review = (now + timedelta(days=7)).strftime("%Y-%m-%dT%H:%M:%SZ")
pol = {
  "freshness_skip_waiver": {
    "reason": "full waive test",
    "at": now.strftime("%Y-%m-%dT%H:%M:%SZ"),
    "scope": ["*"],
    "review_by": review,
  }
}
(m / "docs/vibage/OWNER_POLICY.json").write_text(json.dumps(pol, indent=2) + "\n")
PY
set +e
out="$(bash "$ROOT/scripts/freshness-check.sh" --mode=mother "$M1" 2>/dev/null)"
rc=$?
set -e
[[ "$rc" -eq 0 ]] || fail "valid waiver should exit 0"
[[ "$out" == *"FRESHNESS_WAIVED"* ]] || fail "missing FRESHNESS_WAIVED: $out"
[[ "$out" == *"STALE_DISCLOSED count=2"* ]] || fail "missing STALE_DISCLOSED: $out"
[[ "$out" != *"FRESHNESS_OK"* ]] || fail "waiver must not print FRESHNESS_OK"
pass "valid waiver → WAIVED + DISCLOSED, no FRESHNESS_OK"

# --- Expired / empty waiver ---
python3 - "$M1" <<'PY'
import json, sys
from pathlib import Path
m = Path(sys.argv[1])
pol = {
  "freshness_skip_waiver": {
    "reason": "",
    "at": "2020-01-01T00:00:00Z",
    "scope": ["*"],
    "review_by": "2020-01-02T00:00:00Z",
  }
}
(m / "docs/vibage/OWNER_POLICY.json").write_text(json.dumps(pol, indent=2) + "\n")
PY
set +e
out="$(bash "$ROOT/scripts/freshness-check.sh" --mode=mother "$M1" 2>/dev/null)"
rc=$?
set -e
[[ "$rc" -eq 1 ]] || fail "empty/expired waiver should hard-fail"
pass "empty/expired waiver → hard-fail"

# --- TTL expired without HEAD change ---
M2="$TMP/m2"
make_mother "$M2" "svc-a"
seed_matrix_terminal "$M2" "svc-a"
mark_ok "$M2" "svc-a"
python3 - "$M2" <<'PY'
import json, sys
from pathlib import Path
m = Path(sys.argv[1])
p = m / "docs/vibage/maps/freshness.json"
obj = json.loads(p.read_text(encoding="utf-8"))
obj["ttl_days"] = 7
obj["repos"]["svc-a"]["scanned_at"] = "2020-01-01T00:00:00Z"
p.write_text(json.dumps(obj, indent=2) + "\n")
PY
set +e
out="$(bash "$ROOT/scripts/freshness-check.sh" --mode=mother "$M2" 2>/dev/null)"
rc=$?
set -e
[[ "$rc" -eq 1 ]] || fail "TTL should stale"
[[ "$out" == *"STALE_BLOCKS_MOTHER"* ]] || fail "TTL token: $out"
pass "TTL expired → stale"

# --- Refuse 3× → escalate on mother check ---
M3="$TMP/m3"
make_mother "$M3" "svc-a"
seed_matrix_terminal "$M3" "svc-a"
mark_ok "$M3" "svc-a"
# force stale + refuse
bash "$ROOT/scripts/freshness-mark.sh" --refuse "$M3" "svc-a"
bash "$ROOT/scripts/freshness-mark.sh" --refuse "$M3" "svc-a"
bash "$ROOT/scripts/freshness-mark.sh" --refuse "$M3" "svc-a"
out="$(bash "$ROOT/scripts/freshness-check.sh" --mode=mother "$M3" 2>/dev/null || true)"
[[ "$out" == *"VIBAGE_FRESHNESS_ESCALATE"* ]] || fail "escalate missing on mother: $out"
[[ "$out" == *"STALE_BLOCKS_MOTHER"* ]] || fail "refuse should keep blocking: $out"
pass "refuse 3× → escalate on mother check"

# --- Parent unresolved ---
CHILD_ALONE="$TMP/alone"
init_git "$CHILD_ALONE"
unset VIBAGE_PARENT || true
cout="$(bash "$ROOT/scripts/freshness-check.sh" --mode=child "$CHILD_ALONE" 2>/dev/null)"
[[ "$cout" == *"VIBAGE_PARENT_UNRESOLVED"* ]] || fail "unresolved missing: $cout"
[[ "$cout" == *"FRESHNESS_CHILD_WARN"* ]] || fail "unresolved should warn: $cout"
pass "parent unresolved → soft skip ask tokens"

# --- Mark after floor-only must NOT clear stale ---
M4="$TMP/m4"
make_mother "$M4" "svc-a"
# no matrix / empty cells
python3 - "$M4" <<'PY'
import json, sys, subprocess
from pathlib import Path
m = Path(sys.argv[1])
(m / "docs/vibage/maps/env_branch_matrix.json").write_text(
    json.dumps({"schema_version": "1", "status": "ok", "cells": []}, indent=2) + "\n"
)
head = subprocess.check_output(["git", "-C", str(m/"svc-a"), "rev-parse", "HEAD"], text=True).strip()
obj = {
  "schema_version": "1",
  "ttl_days": 7,
  "repos": {"svc-a": {"head": head, "scanned_at": "2020-01-01T00:00:00Z", "stale": True, "refuse_count": 0}},
}
(m / "docs/vibage/maps/freshness.json").write_text(json.dumps(obj, indent=2) + "\n")
PY
# graph-floor alone (re-run) then mark should fail
bash "$ROOT/scripts/graph-floor.sh" "$M4" >/dev/null
set +e
bash "$ROOT/scripts/freshness-mark.sh" --success "$M4" "svc-a" >/dev/null 2>&1
rc=$?
set -e
[[ "$rc" -ne 0 ]] || fail "floor-only mark must fail"
stale="$(python3 -c 'import json;print(json.load(open("'"$M4"'/docs/vibage/maps/freshness.json"))["repos"]["svc-a"]["stale"])')"
[[ "$stale" == "True" ]] || fail "stale must remain true after failed mark"
pass "mark after floor-only must NOT clear stale"

# --- Zero cells mark fail ---
set +e
bash "$ROOT/scripts/freshness-mark.sh" --success "$M4" "svc-a" >/dev/null 2>&1
rc=$?
set -e
[[ "$rc" -ne 0 ]] || fail "zero cells mark must fail"
pass "mark --success zero cells → fail"

# --- Waiver ≠ substantive ---
M5="$TMP/m5"
make_mother "$M5" "svc-a"
seed_matrix_terminal "$M5" "svc-a"
# make cell failed with non-substantive? Use missing-env style — simpler: leave proven then wipe pointers? 
# Spec: substantive verify unchanged under waiver. Seed all missing-env-config failed + waiver freshness.
python3 - "$M5" <<'PY'
import json, sys
from pathlib import Path
from datetime import datetime, timezone, timedelta
m = Path(sys.argv[1])
obj = {
  "schema_version": "1",
  "status": "ok",
  "cells": [{
    "repo_id": "svc-a",
    "branch_ref": "main",
    "env_id": "missing-env-config",
    "pointers": [{"path": "svc-a", "quote": "no env", "branch_ref": "main", "env_id": "missing-env-config"}],
    "state": "failed",
    "reason": "missing_env",
  }],
}
(m / "docs/vibage/maps/env_branch_matrix.json").write_text(json.dumps(obj, indent=2) + "\n")
(m / "docs/vibage/maps/inventory_manifest.json").write_text(
    json.dumps({"schema_version": "1", "rows": [{"repo_id": "svc-a", "branch_ref": "main", "env_id": "missing-env-config"}]}, indent=2) + "\n"
)
now = datetime.now(timezone.utc)
pol = {
  "freshness_skip_waiver": {
    "reason": "does not grant substantive",
    "at": now.strftime("%Y-%m-%dT%H:%M:%SZ"),
    "scope": ["*"],
    "review_by": (now + timedelta(days=3)).strftime("%Y-%m-%dT%H:%M:%SZ"),
  }
}
(m / "docs/vibage/OWNER_POLICY.json").write_text(json.dumps(pol, indent=2) + "\n")
PY
fout="$(bash "$ROOT/scripts/freshness-check.sh" --mode=mother "$M5" 2>/dev/null || true)"
[[ "$fout" == *"FRESHNESS_WAIVED"* ]] || fail "expect waived for substantive test setup: $fout"
set +e
sout="$(bash "$ROOT/scripts/verify-matrix-substantive.sh" "$M5" 2>/dev/null)"
src=$?
set -e
[[ "$src" -ne 0 ]] || fail "waiver must not grant substantive OK"
[[ "$sout" != *"MATRIX_SWEEP_SUBSTANTIVE_OK"* ]] || fail "substantive must stay failed"
pass "waiver ≠ substantive"

# --- Skill gate documentation ---
grep -q 'exit 0' "$ROOT/skills/using-vibage/SKILL.md" 2>/dev/null || true
# Will be asserted after skill update; soft check for now via later step

# --- c-prime-fill prints FULL_MOTHER_FILL_REFRESH + can reach FRESHNESS_OK ---
M6="$TMP/m6"
make_mother "$M6" "svc-a"
set +e
fill_out="$(bash "$ROOT/scripts/c-prime-fill.sh" "$M6" 2>&1)"
frc=$?
set -e
[[ "$frc" -eq 0 ]] || fail "c-prime-fill failed: $fill_out"
[[ "$fill_out" == *"FULL_MOTHER_FILL_REFRESH"* ]] || fail "missing FULL_MOTHER_FILL_REFRESH: $fill_out"
fcheck="$(bash "$ROOT/scripts/freshness-check.sh" --mode=mother "$M6" 2>/dev/null || true)"
[[ "$fcheck" == *"FRESHNESS_OK"* ]] || fail "after fill expect FRESHNESS_OK got: $fcheck"
pass "c-prime-fill → FULL_MOTHER_FILL_REFRESH + FRESHNESS_OK"

# --- bounded refresh after HEAD change ---
echo "z" >>"$M6/svc-a/README.md"
git -C "$M6/svc-a" add -A && git -C "$M6/svc-a" commit -qm "refresh-me"
set +e
bash "$ROOT/scripts/freshness-check.sh" --mode=mother "$M6" >/dev/null 2>&1
[[ $? -eq 1 ]] || fail "pre-refresh should be stale"
set -e
rout="$(bash "$ROOT/scripts/freshness-refresh-repo.sh" "$M6" "svc-a" 2>&1)" || fail "refresh failed: $rout"
fcheck2="$(bash "$ROOT/scripts/freshness-check.sh" --mode=mother "$M6" 2>/dev/null || true)"
[[ "$fcheck2" == *"FRESHNESS_OK"* ]] || fail "after refresh expect FRESHNESS_OK got: $fcheck2"
pass "freshness-refresh-repo → FRESHNESS_OK"

# --- Skill / adapter copy must document exit0 ≠ FRESHNESS_OK ---
grep -q 'FRESHNESS_OK' "$ROOT/skills/using-vibage/SKILL.md" \
  || fail "using-vibage must document FRESHNESS_OK"
grep -Eq 'exit 0.*FRESHNESS_OK|FRESHNESS_OK.*exit 0|≠.*FRESHNESS_OK|Forbidden:.*exit' \
  "$ROOT/skills/using-vibage/SKILL.md" \
  || fail "using-vibage must forbid treating exit 0 as FRESHNESS_OK"

# --- Empty service_map must NOT FRESHNESS_OK ---
M7="$TMP/m7"
mkdir -p "$M7/docs/vibage/maps"
echo "# hub" >"$M7/docs/vibage/STATUS.md"
echo '{}' >"$M7/docs/vibage/OWNER_POLICY.json"
set +e
out="$(bash "$ROOT/scripts/freshness-check.sh" --mode=mother "$M7" 2>/dev/null)"
rc=$?
set -e
[[ "$rc" -eq 1 ]] || fail "empty map should block"
[[ "$out" != *"FRESHNESS_OK"* ]] || fail "empty map must not OK"
[[ "$out" == *"STALE_BLOCKS_MOTHER"* ]] || fail "empty map token: $out"
pass "empty service_map → not FRESHNESS_OK"

# --- Empty stored head cannot stay fresh after git appears ---
M8="$TMP/m8"
make_mother "$M8" "svc-a"
seed_matrix_terminal "$M8" "svc-a"
# Craft empty head + stale=false (greenwash attempt)
python3 - "$M8" <<'PY'
import json, sys
from pathlib import Path
m = Path(sys.argv[1])
obj = {
  "schema_version": "1",
  "ttl_days": 7,
  "repos": {
    "svc-a": {
      "head": "",
      "scanned_at": "2099-01-01T00:00:00Z",
      "stale": False,
      "refuse_count": 0,
    }
  },
}
(m / "docs/vibage/maps/freshness.json").write_text(json.dumps(obj, indent=2) + "\n")
PY
set +e
out="$(bash "$ROOT/scripts/freshness-check.sh" --mode=mother "$M8" 2>/dev/null)"
rc=$?
set -e
[[ "$rc" -eq 1 ]] || fail "empty head must block"
[[ "$out" == *"STALE_BLOCKS_MOTHER"* ]] || fail "empty head token: $out"
# mark without git HEAD must fail — temporarily move .git
mv "$M8/svc-a/.git" "$M8/svc-a/.git.bak"
set +e
bash "$ROOT/scripts/freshness-mark.sh" --success "$M8" "svc-a" >/dev/null 2>&1
mrc=$?
set -e
[[ "$mrc" -ne 0 ]] || fail "mark without HEAD must fail"
mv "$M8/svc-a/.git.bak" "$M8/svc-a/.git"
pass "empty head / mark without HEAD fail-closed"

echo "FRESHNESS_W1_OK"
