#!/usr/bin/env bash
# Contract: optional tracks expose hard gates; unlock + OWNER_POLICY + map examples exist.
# Note: tests/test_issue_fix_usable.sh and tests/test_arch_review_usable.sh are optional-track
# proofs and MUST NOT be required here. Do NOT call verify-issue-fix-unlock.sh or
# verify-service-map.sh from this file (thin rg / example presence only).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIX="$ROOT/skills/vibage-issue-fix/SKILL.md"
ARCH="$ROOT/skills/vibage-arch-review/SKILL.md"
UNLOCK_EX="$ROOT/docs/superpowers/specs/satellites/unlock.example.json"
POLICY_EX="$ROOT/docs/superpowers/specs/satellites/OWNER_POLICY.example.json"
MAP_EX="$ROOT/docs/superpowers/specs/satellites/service_map.example.json"
SAT_ARCH="$ROOT/docs/superpowers/specs/satellites/SAT-arch-review.md"
SAT_MAP="$ROOT/docs/superpowers/specs/satellites/SAT-map-schema.md"
pass() { echo "OK: $*"; }
fail() { echo "FAIL: $*" >&2; exit 1; }

[[ -f "$FIX" ]] || fail "missing vibage-issue-fix SKILL"
[[ -f "$ARCH" ]] || fail "missing vibage-arch-review SKILL"
[[ -f "$UNLOCK_EX" ]] || fail "missing unlock.example.json"
[[ -f "$POLICY_EX" ]] || fail "missing OWNER_POLICY.example.json"
[[ -f "$MAP_EX" ]] || fail "missing service_map.example.json"
[[ -f "$SAT_ARCH" ]] || fail "missing SAT-arch-review"
[[ -f "$SAT_MAP" ]] || fail "missing SAT-map-schema"

# issue-fix: dual consent + unlock + prefer branch/PR + no dig without locate report
rg -q 'OWNER_POLICY' "$FIX" || fail "issue-fix missing OWNER_POLICY"
rg -q 'unlock' "$FIX" || fail "issue-fix missing unlock"
rg -q 'branch/PR|branch / PR' "$FIX" || fail "issue-fix missing branch/PR preference"
rg -q 'locate report|VIBAGE-ISSUE-LOCATE' "$FIX" || fail "issue-fix missing locate-report gate"
rg -q 'Locate may still DONE|locate DONE' "$FIX" || fail "issue-fix must keep locate DONE independent"
rg -q 'artifacts_ok' "$FIX" || fail "issue-fix must note artifacts_ok non-cross-pipeline"

# 架構檢視: qualified map; failure does not undo locate DONE (thin rg only — no verify calls)
rg -q 'qualified' "$ARCH" || fail "arch-review missing qualified map gate"
rg -q 'locate DONE' "$ARCH" || fail "arch-review must not undo locate DONE"
rg -q 'artifacts_ok' "$ARCH" || fail "arch-review must note artifacts_ok non-cross-pipeline"
rg -q 'usable' "$ARCH" || fail "arch-review must claim usable (non-stub)"
rg -q 'verify-service-map' "$ARCH" || fail "arch-review missing verify-service-map"
rg -q 'service_map' "$ARCH" || fail "arch-review missing service_map pipeline_id"
rg -q 'Architecture Pass' "$SAT_ARCH" || fail "SAT-arch-review must mention Architecture Pass boundary"
rg -q 'MEDIUM' "$SAT_MAP" || fail "SAT-map-schema missing MEDIUM"
rg -q '\(stub\)' "$SAT_ARCH" && fail "SAT-arch-review still stub-titled" || true
rg -q '\(stub\)' "$SAT_MAP" && fail "SAT-map-schema still stub-titled" || true

# service_map.example.json floor keys (presence / shape only — no verify-service-map call)
python3 - "$MAP_EX" <<'PY'
import json, sys
path = sys.argv[1]
obj = json.load(open(path, encoding="utf-8"))
if obj.get("pipeline_id") != "service_map":
    raise SystemExit(f"service_map.example.json pipeline_id must be service_map, got {obj.get('pipeline_id')!r}")
if obj.get("quality_bar") != "MEDIUM":
    raise SystemExit(f"service_map.example.json quality_bar must be MEDIUM, got {obj.get('quality_bar')!r}")
svcs = obj.get("services")
if not isinstance(svcs, list) or len(svcs) < 1:
    raise SystemExit("service_map.example.json services must be non-empty list")
if not all(isinstance(s, dict) and isinstance(s.get("id"), str) and s["id"].strip() for s in svcs):
    raise SystemExit("service_map.example.json each service needs non-empty id")
print("OK: service_map.example.json floor keys")
PY

# Tiny unlock JSON schema keys
python3 - "$UNLOCK_EX" <<'PY'
import json, sys
path = sys.argv[1]
obj = json.load(open(path, encoding="utf-8"))
required = ("schema_version", "locate_run_id", "allowed_paths", "confirmed_at", "confirmed_by")
missing = [k for k in required if k not in obj]
if missing:
    raise SystemExit(f"unlock.example.json missing keys: {missing}")
if not isinstance(obj["allowed_paths"], list):
    raise SystemExit("allowed_paths must be a list")
print("OK: unlock.example.json keys")
PY

# OWNER_POLICY.example required key fix_preference ∈ {YES,NO}
python3 - "$POLICY_EX" <<'PY'
import json, sys
path = sys.argv[1]
obj = json.load(open(path, encoding="utf-8"))
pref = obj.get("fix_preference")
if pref not in ("YES", "NO"):
    raise SystemExit(f"OWNER_POLICY.example.json fix_preference must be YES|NO, got {pref!r}")
print("OK: OWNER_POLICY.example.json fix_preference")
PY

# MANIFEST marks optional tracks (present + commented optional)
MANIFEST="$ROOT/skills/MANIFEST.txt"
rg -q 'vibage-issue-fix' "$MANIFEST" || fail "MANIFEST missing vibage-issue-fix"
rg -q 'vibage-arch-review' "$MANIFEST" || fail "MANIFEST missing vibage-arch-review"
rg -q 'optional' "$MANIFEST" || fail "MANIFEST missing optional track marker"

# STATUS: locate DONE independent wording for optional tracks
rg -q 'locate DONE independent' "$ROOT/STATUS.md" || fail "STATUS missing locate DONE independent"

pass "optional track gate contracts"
echo "ALL optional_track_gates tests passed"
