#!/usr/bin/env bash
# C′ Chunk 3: friend-chaos (F1) + local-scenes (L1) fixtures
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "OK: $*"; }

file_mtime() {
  # portable mtime seconds
  local f="$1"
  if stat -f %m "$f" >/dev/null 2>&1; then
    stat -f %m "$f"
  else
    stat -c %Y "$f"
  fi
}

# ---------------------------------------------------------------------------
# Task 3.1 — friend-chaos after c-prime-fill
# ---------------------------------------------------------------------------
FC="$TMP/friend-chaos"
bash "$ROOT/tests/fixtures/c-prime/friend-chaos/setup.sh" "$FC"

# Policy: nested on, no vacancy waiver
python3 - <<PY
import json
p=json.load(open("$FC/docs/vibage/OWNER_POLICY.json"))
assert p.get("discover_nested_git") is True, p
assert not p.get("env_vacancy_waiver"), "friend-chaos must not set env_vacancy_waiver"
print("OK policy")
PY

echo "OK: running c-prime-fill on friend-chaos (may take up to ~2 min)..."
t0="$(date +%s)"
bash "$ROOT/scripts/c-prime-fill.sh" "$FC"
t1="$(date +%s)"
echo "OK: c-prime-fill elapsed=$((t1 - t0))s"

gout="$(bash "$ROOT/scripts/verify-graph-floor.sh" "$FC")"
[[ "$gout" == "GRAPH_FLOOR_OK" ]] || fail "want GRAPH_FLOOR_OK got: $gout"
pass "GRAPH_FLOOR_OK"

python3 - <<PY
import json
m=json.load(open("$FC/docs/vibage/maps/service_map.json"))
assert m.get("discover_mode")=="nested", m.get("discover_mode")
repos=m.get("repos") or []
paths={r.get("path") for r in repos if isinstance(r, dict)}
assert "nest/deep-svc" in paths, f"nested repo missing from repos: {sorted(paths)}"
assert len(repos) >= 10, f"want ≥10 repos got {len(repos)}"
print("OK nested discover + nested path")
PY
pass "discover_mode=nested + nested repo in repos"

mout="$(bash "$ROOT/scripts/verify-env-branch-matrix.sh" "$FC")"
[[ "$mout" == "ENV_BRANCH_MATRIX_OK" ]] || fail "want ENV_BRANCH_MATRIX_OK got: $mout"
pass "ENV_BRANCH_MATRIX_OK"

sout="$(bash "$ROOT/scripts/verify-matrix-substantive.sh" "$FC")"
[[ "$sout" == "MATRIX_SWEEP_SUBSTANTIVE_OK" ]] || fail "want MATRIX_SWEEP_SUBSTANTIVE_OK got: $sout"
pass "MATRIX_SWEEP_SUBSTANTIVE_OK"

# ---------------------------------------------------------------------------
# Task 3.2 — local-scenes brief / cover / switch / matrix mtime
# ---------------------------------------------------------------------------
LS="$TMP/local-scenes"
bash "$ROOT/tests/fixtures/c-prime/local-scenes/setup.sh" "$LS"

python3 - <<PY
import json
from pathlib import Path
scenes=json.load(open("$LS/docs/vibage/scenes/SCENES.json"))["scenes"]
want={"architecture","x402","quant","mindblow"}
got={s["scene_id"] for s in scenes}
assert got==want, got
for s in scenes:
    assert s.get("keywords"), f"{s['scene_id']} keywords empty"
    assert s.get("seed_method")=="fixture", s
status=Path("$LS/docs/vibage/STATUS.md").read_text(encoding="utf-8")
assert "scenes_draft: false" in status
waivers=Path("$LS/docs/vibage/scenes/WAIVERS.json")
assert not waivers.is_file(), "isolation_waiver fixture must omit WAIVERS.json"
# membership: ≥1 shared hub, ≥1 exclusive per scene
from collections import defaultdict
n=len(scenes)
homes=defaultdict(set)
for s in scenes:
    for r in s["repo_ids"]:
        homes[r].add(s["scene_id"])
shared=[r for r,h in homes.items() if len(h)==n]
assert "hub" in shared, shared
for sid in want:
    excl=[r for r,h in homes.items() if h=={sid}]
    assert excl, f"no exclusive for {sid}"
m=json.load(open("$LS/docs/vibage/maps/service_map.json"))
edges=m.get("edges") or []
# exclusive↔exclusive: arch-a↔x402-a present
cross=False
excl_set={"arch-a","x402-a","quant-a","mindblow-a"}
for e in edges:
    a,b=e.get("from"),e.get("to")
    if a in excl_set and b in excl_set and a!=b:
        cross=True
        break
assert cross, "need ≥1 exclusive↔exclusive edge"
print("OK local-scenes shape")
PY
pass "local-scenes shape (4 scenes, hub, exclusives, cross edge)"

MATRIX="$LS/docs/vibage/maps/env_branch_matrix.json"
[[ -f "$MATRIX" ]] || fail "matrix pre-seed missing"
mtime0="$(file_mtime "$MATRIX")"

bash "$ROOT/scripts/scene-brief.sh" "$LS" "architecture"
bout="$(bash "$ROOT/scripts/verify-scene-brief.sh" "$LS")"
[[ "$bout" == "SCENE_BRIEF_OK" ]] || fail "want SCENE_BRIEF_OK got: $bout"
pass "active_scene architecture → SCENE_BRIEF_OK"

bash "$ROOT/scripts/verify-scene-cover.sh" "$LS" >/dev/null \
  || fail "verify-scene-cover should exit 0"
pass "verify-scene-cover exit 0"

# Switch scene: prior brief stale/gone; matrix mtime unchanged; cover holds
bash "$ROOT/scripts/scene-brief.sh" "$LS" "quant"
[[ -f "$LS/docs/vibage/briefs/quant.md" ]] || fail "quant brief missing"
if [[ -f "$LS/docs/vibage/briefs/architecture.md" ]]; then
  grep -qiE 'stale|invalidated' "$LS/docs/vibage/briefs/architecture.md" \
    || fail "prior architecture brief must be deleted or marked stale"
fi
mtime1="$(file_mtime "$MATRIX")"
[[ "$mtime0" == "$mtime1" ]] || fail "matrix mtime changed on scene switch ($mtime0 → $mtime1)"
pass "scene switch: prior brief stale/gone + matrix mtime unchanged"

bout="$(bash "$ROOT/scripts/verify-scene-brief.sh" "$LS")"
[[ "$bout" == "SCENE_BRIEF_OK" ]] || fail "after switch want SCENE_BRIEF_OK got: $bout"
bash "$ROOT/scripts/verify-scene-cover.sh" "$LS" >/dev/null \
  || fail "cover should still hold after scene switch"
pass "after switch SCENE_BRIEF_OK + cover holds"

echo "ALL test_c_prime_fixtures.sh PASS"
