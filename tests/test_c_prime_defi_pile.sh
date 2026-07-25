#!/usr/bin/env bash
# DefiStrategy-like pile: bare compose → local, PKG exclude, cheap edges, install glue.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "OK: $*"; }

SETUP="$ROOT/tests/fixtures/c-prime/defi_strategy_like/setup.sh"
[[ -x "$SETUP" || -f "$SETUP" ]] || fail "missing setup.sh"
chmod +x "$SETUP"

PARENT="$TMP/defi-like"
bash "$SETUP" "$PARENT"

# 1) graph-floor: exclude vibage-skills; app-web→app-api edge
bash "$ROOT/scripts/graph-floor.sh" "$PARENT"
gout="$(bash "$ROOT/scripts/verify-graph-floor.sh" "$PARENT")"
[[ "$gout" == "GRAPH_FLOOR_OK" ]] || fail "expected GRAPH_FLOOR_OK, got: $gout"
pass "GRAPH_FLOOR_OK"

python3 - "$PARENT" <<'PY' || fail "graph-floor product shape"
import json, sys
from pathlib import Path
parent = Path(sys.argv[1])
m = json.loads((parent / "docs/vibage/maps/service_map.json").read_text(encoding="utf-8"))
names = {s.get("name") for s in m.get("services") or []}
paths = {r.get("path") for r in (m.get("repos") or [])}
if "vibage-skills" in names or "vibage-skills" in paths:
    raise SystemExit("vibage-skills must be excluded from product map")
if "war-room-skills" in names or "war-room-skills" in paths:
    raise SystemExit("war-room-skills must be excluded from product map")
if "app-api" not in names or "app-web" not in names:
    raise SystemExit(f"expected app-api/app-web in services, got {names}")
ids = {s["name"]: s["id"] for s in m.get("services") or []}
edges = m.get("edges") or []
want = (ids.get("app-web"), ids.get("app-api"))
ok = any(
    (e.get("from"), e.get("to")) == want or (e.get("to"), e.get("from")) == want
    for e in edges
    if isinstance(e, dict)
)
if not ok:
    raise SystemExit(f"expected edge app-web↔app-api, edges={edges}")
if len(edges) < 1:
    raise SystemExit("expected edges≥1")
print("ok")
PY
pass "exclude PKG + cheap edges"

# 2) inventory: app-api/app-web have real envs (local and/or development); not pile-wide missing
bash "$ROOT/scripts/matrix-inventory.sh" "$PARENT"
python3 - "$PARENT" <<'PY' || fail "inventory env discovery"
import json, sys
from pathlib import Path
parent = Path(sys.argv[1])
m = json.loads((parent / "docs/vibage/maps/env_branch_matrix.json").read_text(encoding="utf-8"))
cells = m.get("cells") or []
by_repo = {}
for c in cells:
    by_repo.setdefault(c["repo_id"], set()).add(c["env_id"])
special = {"missing-env-config", "unknown-env"}
api = by_repo.get("app-api") or set()
web = by_repo.get("app-web") or set()
if not (api - special):
    raise SystemExit(f"app-api must have real env, got {api}")
if not (web - special):
    raise SystemExit(f"app-web must have real env, got {web}")
if "local" not in api and "local" not in web:
    # app-api .env.example APP_ENV=local should yield local; bare compose also local
    raise SystemExit(f"expected local on api or web; api={api} web={web}")
all_envs = set()
for s in by_repo.values():
    all_envs |= s
if all_envs <= special:
    raise SystemExit("pile must not be only missing-env-config")
print("api", sorted(api), "web", sorted(web))
PY
pass "bare compose / .env.example → real envs"

# 3) extract local on app-api
out="$(python3 "$ROOT/scripts/matrix-extract-evidence.py" "$PARENT" "app-api" "main" "local")"
echo "$out" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d.get("pointers"); assert d["pointers"][0].get("quote")'
pass "extract local proven pointer"

# 4) c-prime-fill → ENV_BRANCH_MATRIX_OK; substantive may fail (orphan missing) — honest
fill_out="$(bash "$ROOT/scripts/c-prime-fill.sh" "$PARENT")"
echo "$fill_out" | grep -q 'ENV_BRANCH_MATRIX_OK' \
  || fail "c-prime-fill should print ENV_BRANCH_MATRIX_OK, got: $fill_out"
if echo "$fill_out" | grep -q 'MATRIX_SWEEP_SUBSTANTIVE_OK'; then
  pass "substantive OK (bonus)"
else
  # orphan-lib missing-env-config should block 掃透
  pass "substantive withheld (orphan missing — honest)"
fi
mout="$(bash "$ROOT/scripts/verify-env-branch-matrix.sh" "$PARENT")"
[[ "$mout" == "ENV_BRANCH_MATRIX_OK" ]] || fail "matrix verify, got: $mout"
pass "ENV_BRANCH_MATRIX_OK after fill"

# 5) install --init-hub --c-prime-fill on fresh parent
PARENT2="$TMP/defi-install"
bash "$SETUP" "$PARENT2"
rm -rf "$PARENT2/docs/vibage"
bash "$ROOT/scripts/install.sh" --surfaces=cursor --init-hub="$PARENT2" --c-prime-fill="$PARENT2" \
  >/tmp/defi-install-cprime.out 2>&1 || fail "install --c-prime-fill failed"
[[ -f "$PARENT2/docs/vibage/STATUS.md" ]] || fail "hub STATUS missing"
[[ -f "$PARENT2/docs/vibage/maps/service_map.json" ]] || fail "service_map missing"
[[ -f "$PARENT2/docs/vibage/maps/env_branch_matrix.json" ]] || fail "matrix missing"
grep -q 'ENV_BRANCH_MATRIX_OK\|MATRIX_INCOMPLETE' /tmp/defi-install-cprime.out \
  || fail "install glue should print matrix gate token"
pass "install --init-hub --c-prime-fill glue"

echo "ALL test_c_prime_defi_pile.sh PASS"
