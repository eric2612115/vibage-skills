#!/usr/bin/env bash
# C′ Chunk 2: scenes, classify, briefs, bridges, cover
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "OK: $*"; }

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

write_status() {
  local dir="$1" active="${2:-}" draft="${3:-false}"
  mkdir -p "$dir/docs/vibage"
  cat >"$dir/docs/vibage/STATUS.md" <<EOF
# Vibage Hub STATUS

schema_version: 1
hub_ready: true
active_scene: ${active}
scenes_draft: ${draft}
phase: installed
notes: "c-prime scene test hub"
EOF
}

write_scenes() {
  local dir="$1"
  mkdir -p "$dir/docs/vibage/scenes"
  cat >"$dir/docs/vibage/scenes/SCENES.json"
}

write_map() {
  local dir="$1"
  mkdir -p "$dir/docs/vibage/maps"
  cat >"$dir/docs/vibage/maps/service_map.json"
}

# Mini graph: arch-a (exclusive arch), x402-a (exclusive x402), hub (shared)
# Edges: arch-a -> hub, x402-a -> hub, arch-a -> x402-a (exclusive↔exclusive)
seed_mini_graph() {
  local dir="$1"
  write_map "$dir" <<'EOF'
{
  "schema_version": "1",
  "pipeline_id": "service_map",
  "scale": "Tiny",
  "quality_bar": "MEDIUM",
  "discover_mode": "flat",
  "discover_max_depth": 1,
  "depth": "standard",
  "services": [
    {"id": "arch-a", "name": "arch-a", "path": "arch-a", "definition": "arch"},
    {"id": "x402-a", "name": "x402-a", "path": "x402-a", "definition": "x402"},
    {"id": "hub", "name": "hub", "path": "hub", "definition": "shared hub"}
  ],
  "repos": [
    {"id": "arch-a", "repo_id": "arch-a", "name": "arch-a", "path": "arch-a"},
    {"id": "x402-a", "repo_id": "x402-a", "name": "x402-a", "path": "x402-a"},
    {"id": "hub", "repo_id": "hub", "name": "hub", "path": "hub"}
  ],
  "edges": [
    {"id": "arch-a->hub", "from": "arch-a", "to": "hub"},
    {"id": "x402-a->hub", "from": "x402-a", "to": "hub"},
    {"id": "arch-a->x402-a", "from": "arch-a", "to": "x402-a"}
  ]
}
EOF
}

seed_legal_two_scenes() {
  local dir="$1"
  write_scenes "$dir" <<'EOF'
{
  "scenes": [
    {
      "scene_id": "architecture",
      "title": "Architecture Domain",
      "keywords": ["arch", "infra"],
      "repo_ids": ["arch-a", "hub"],
      "hot_edge_ids": ["arch-a->hub"],
      "default_env_ids": [],
      "notes": "",
      "seed_method": "fixture"
    },
    {
      "scene_id": "x402",
      "title": "X402 Payments",
      "keywords": ["payment", "x402"],
      "repo_ids": ["x402-a", "hub"],
      "hot_edge_ids": ["x402-a->hub"],
      "default_env_ids": [],
      "notes": "",
      "seed_method": "fixture"
    }
  ]
}
EOF
}

# ---------------------------------------------------------------------------
# Task 2.1 — scene-validate + scene-classify
# ---------------------------------------------------------------------------

# Illegal partial membership fails (repo in some-but-not-all scenes; needs ≥3 scenes)
ILL="$TMP/illegal"
mkdir -p "$ILL/docs/vibage"
write_scenes "$ILL" <<'EOF'
{
  "scenes": [
    {
      "scene_id": "architecture",
      "title": "Architecture",
      "keywords": ["arch"],
      "repo_ids": ["arch-a", "partial", "hub"],
      "hot_edge_ids": [],
      "default_env_ids": [],
      "notes": "",
      "seed_method": "owner"
    },
    {
      "scene_id": "x402",
      "title": "X402",
      "keywords": ["pay"],
      "repo_ids": ["x402-a", "partial", "hub"],
      "hot_edge_ids": [],
      "default_env_ids": [],
      "notes": "",
      "seed_method": "owner"
    },
    {
      "scene_id": "quant",
      "title": "Quant",
      "keywords": ["quant"],
      "repo_ids": ["quant-a", "hub"],
      "hot_edge_ids": [],
      "default_env_ids": [],
      "notes": "",
      "seed_method": "owner"
    }
  ]
}
EOF
if bash "$ROOT/scripts/scene-validate.sh" "$ILL" >/dev/null 2>&1; then
  fail "illegal partial membership must fail validate"
fi
pass "illegal partial membership fails validate"

# Exclusive + shared OK
OKM="$TMP/okmem"
mkdir -p "$OKM/docs/vibage"
seed_legal_two_scenes "$OKM"
bash "$ROOT/scripts/scene-validate.sh" "$OKM" >/dev/null
pass "exclusive+shared membership OK"

# Classify: exactly one → print id exit 0
CL="$TMP/classify"
mkdir -p "$CL/docs/vibage"
seed_legal_two_scenes "$CL"
out="$(bash "$ROOT/scripts/scene-classify.sh" "$CL" "please dig the payment flow")"
rc=0
bash "$ROOT/scripts/scene-classify.sh" "$CL" "please dig the payment flow" >/dev/null || rc=$?
[[ "$rc" -eq 0 ]] || fail "classify single match exit want 0 got $rc"
[[ "$out" == "x402" ]] || fail "classify single match want x402 got: $out"
pass "classify exactly one → id exit 0"

# Classify: zero → exit 2
rc=0
bash "$ROOT/scripts/scene-classify.sh" "$CL" "unrelated widget toast" >/dev/null 2>&1 || rc=$?
[[ "$rc" -eq 2 ]] || fail "classify zero match want exit 2 got $rc"
pass "classify zero → exit 2"

# Classify: ≥2 → exit 3 (ticket hits both scene_id/title/keywords)
rc=0
bash "$ROOT/scripts/scene-classify.sh" "$CL" "architecture and x402 payment arch" >/dev/null 2>&1 || rc=$?
[[ "$rc" -eq 3 ]] || fail "classify multi match want exit 3 got $rc"
pass "classify ≥2 → exit 3"

# Classify matches title|scene_id|keywords[]
out="$(bash "$ROOT/scripts/scene-classify.sh" "$CL" "Architecture Domain review")"
[[ "$out" == "architecture" ]] || fail "title match want architecture got: $out"
out="$(bash "$ROOT/scripts/scene-classify.sh" "$CL" "scene architecture please")"
[[ "$out" == "architecture" ]] || fail "scene_id match want architecture got: $out"
out="$(bash "$ROOT/scripts/scene-classify.sh" "$CL" "need infra help")"
[[ "$out" == "architecture" ]] || fail "keywords match want architecture got: $out"
pass "classify matches title|scene_id|keywords[]"

# ---------------------------------------------------------------------------
# Task 2.2 — scene-brief + verify-brief + verify-scene-brief
# ---------------------------------------------------------------------------

BRIEF="$TMP/brief"
mkdir -p "$BRIEF/docs/vibage/ledger"
seed_mini_graph "$BRIEF"
seed_legal_two_scenes "$BRIEF"
write_status "$BRIEF" "" "false"
# Matrix must be absent — scene track independent
[[ ! -f "$BRIEF/docs/vibage/maps/env_branch_matrix.json" ]]

bash "$ROOT/scripts/scene-brief.sh" "$BRIEF" "architecture"
[[ -f "$BRIEF/docs/vibage/briefs/architecture.md" ]] || fail "brief file missing"
grep -q 'active_scene: architecture' "$BRIEF/docs/vibage/STATUS.md" || fail "STATUS.active_scene not set"

# verify-brief → BRIEF_USABLE_OK
bout="$(bash "$ROOT/scripts/verify-brief.sh" "$BRIEF" architecture)"
[[ "$bout" == "BRIEF_USABLE_OK" ]] || fail "verify-brief want BRIEF_USABLE_OK got: $bout"
pass "verify-brief → BRIEF_USABLE_OK"

# SCENE_BRIEF_OK full checklist; matrix absent still OK
sout="$(bash "$ROOT/scripts/verify-scene-brief.sh" "$BRIEF")"
[[ "$sout" == "SCENE_BRIEF_OK" ]] || fail "want SCENE_BRIEF_OK got: $sout"
[[ ! -f "$BRIEF/docs/vibage/maps/env_branch_matrix.json" ]] || fail "matrix must stay absent"
pass "SCENE_BRIEF_OK with matrix absent"

# Switch invalidates prior scene brief
bash "$ROOT/scripts/scene-brief.sh" "$BRIEF" "x402"
[[ -f "$BRIEF/docs/vibage/briefs/x402.md" ]] || fail "new scene brief missing"
if [[ -f "$BRIEF/docs/vibage/briefs/architecture.md" ]]; then
  # allowed only if marked stale
  grep -qiE 'stale|invalidated' "$BRIEF/docs/vibage/briefs/architecture.md" \
    || fail "prior brief must be deleted or marked stale"
fi
grep -q 'active_scene: x402' "$BRIEF/docs/vibage/STATUS.md" || fail "active_scene not switched"
sout="$(bash "$ROOT/scripts/verify-scene-brief.sh" "$BRIEF")"
[[ "$sout" == "SCENE_BRIEF_OK" ]] || fail "after switch want SCENE_BRIEF_OK got: $sout"
pass "scene switch invalidates prior + SCENE_BRIEF_OK"

# scenes_draft=true → SCENE_BRIEF_OK false
write_status "$BRIEF" "x402" "true"
if bash "$ROOT/scripts/verify-scene-brief.sh" "$BRIEF" >/dev/null 2>&1; then
  fail "scenes_draft=true must not SCENE_BRIEF_OK"
fi
write_status "$BRIEF" "x402" "false"
# re-compile so brief matches
bash "$ROOT/scripts/scene-brief.sh" "$BRIEF" "x402" >/dev/null
pass "scenes_draft=true blocks SCENE_BRIEF_OK"

# required_bridges listed + scene_bridge ledger terminal
python3 - <<PY
import json, re
from pathlib import Path
brief = Path("$BRIEF/docs/vibage/briefs/x402.md").read_text(encoding="utf-8")
# x402 exclusive = {x402-a}; other exclusive∪shared = {arch-a, hub}
# graph edges touching E_active: x402-a->hub, arch-a->x402-a
required = {"x402-a->hub", "arch-a->x402-a"}
listed = set(re.findall(r"(?:^|\s)([A-Za-z0-9._-]+->[A-Za-z0-9._-]+)", brief, flags=re.M))
# bridges section should include required
missing = required - listed
assert not missing, f"brief missing required_bridges: {missing}"
claims = Path("$BRIEF/docs/vibage/ledger/claims.jsonl").read_text(encoding="utf-8").splitlines()
latest = {}
for line in claims:
    if not line.strip():
        continue
    c = json.loads(line)
    if c.get("claim_class") != "scene_bridge":
        continue
    if c.get("scene_id") != "x402":
        continue
    latest[c["subject_id"]] = c
for edge in required:
    assert edge in latest, f"missing scene_bridge claim for {edge}"
    assert latest[edge]["state"] in ("proven", "failed"), latest[edge]
print("OK: required_bridges + scene_bridge terminal")
PY
pass "required_bridges = E_active ↔ (exclusive(other)∪shared)"

# ---------------------------------------------------------------------------
# Task 2.3 — verify-scene-cover.sh
# ---------------------------------------------------------------------------

COVER="$TMP/cover"
mkdir -p "$COVER/docs/vibage/ledger"
seed_mini_graph "$COVER"
seed_legal_two_scenes "$COVER"
write_status "$COVER" "" "false"
bash "$ROOT/scripts/scene-brief.sh" "$COVER" "architecture" >/dev/null
bash "$ROOT/scripts/verify-scene-cover.sh" "$COVER" >/dev/null \
  || fail "cover should pass with exclusive↔exclusive edge + bridges"
pass "cover passes with fixture-shaped mini graph"

# Cover fails without cross_scene_edge (shared-only edges insufficient)
NOSHARE="$TMP/nocross"
mkdir -p "$NOSHARE/docs/vibage/ledger"
write_map "$NOSHARE" <<'EOF'
{
  "schema_version": "1",
  "pipeline_id": "service_map",
  "scale": "Tiny",
  "quality_bar": "MEDIUM",
  "discover_mode": "flat",
  "discover_max_depth": 1,
  "depth": "standard",
  "services": [
    {"id": "arch-a", "name": "arch-a", "path": "arch-a", "definition": "arch"},
    {"id": "x402-a", "name": "x402-a", "path": "x402-a", "definition": "x402"},
    {"id": "hub", "name": "hub", "path": "hub", "definition": "shared hub"}
  ],
  "repos": [
    {"id": "arch-a", "repo_id": "arch-a", "name": "arch-a", "path": "arch-a"},
    {"id": "x402-a", "repo_id": "x402-a", "name": "x402-a", "path": "x402-a"},
    {"id": "hub", "repo_id": "hub", "name": "hub", "path": "hub"}
  ],
  "edges": [
    {"id": "arch-a->hub", "from": "arch-a", "to": "hub"},
    {"id": "x402-a->hub", "from": "x402-a", "to": "hub"}
  ]
}
EOF
seed_legal_two_scenes "$NOSHARE"
write_status "$NOSHARE" "" "false"
bash "$ROOT/scripts/scene-brief.sh" "$NOSHARE" "architecture" >/dev/null
# SCENE_BRIEF_OK may still hold (bridges to shared exist), but cover must fail
if bash "$ROOT/scripts/verify-scene-cover.sh" "$NOSHARE" >/dev/null 2>&1; then
  fail "cover must fail without exclusive↔exclusive cross_scene_edge"
fi
pass "cover fails without exclusive↔exclusive cross edge"

echo "ALL test_c_prime_scenes.sh PASS"
