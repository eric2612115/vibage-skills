#!/usr/bin/env bash
# Contract: optional track stubs expose hard gates; unlock example schema exists.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIX="$ROOT/skills/vibage-issue-fix/SKILL.md"
ARCH="$ROOT/skills/vibage-arch-review/SKILL.md"
UNLOCK_EX="$ROOT/docs/superpowers/specs/satellites/unlock.example.json"
pass() { echo "OK: $*"; }
fail() { echo "FAIL: $*" >&2; exit 1; }

[[ -f "$FIX" ]] || fail "missing vibage-issue-fix SKILL"
[[ -f "$ARCH" ]] || fail "missing vibage-arch-review SKILL"
[[ -f "$UNLOCK_EX" ]] || fail "missing unlock.example.json"

# issue-fix: dual consent + unlock + prefer branch/PR + no dig without locate report
rg -q 'OWNER_POLICY' "$FIX" || fail "issue-fix missing OWNER_POLICY"
rg -q 'unlock' "$FIX" || fail "issue-fix missing unlock"
rg -q 'branch/PR|branch / PR' "$FIX" || fail "issue-fix missing branch/PR preference"
rg -q 'locate report|VIBAGE-ISSUE-LOCATE' "$FIX" || fail "issue-fix missing locate-report gate"
rg -q 'Locate may still DONE|locate DONE' "$FIX" || fail "issue-fix must keep locate DONE independent"
rg -q 'artifacts_ok' "$FIX" || fail "issue-fix must note artifacts_ok non-cross-pipeline"

# 架構檢視: qualified map; failure does not undo locate DONE
rg -q 'qualified' "$ARCH" || fail "arch-review missing qualified map gate"
rg -q 'locate DONE' "$ARCH" || fail "arch-review must not undo locate DONE"
rg -q 'artifacts_ok' "$ARCH" || fail "arch-review must note artifacts_ok non-cross-pipeline"

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

# MANIFEST marks optional tracks (present + commented optional)
MANIFEST="$ROOT/skills/MANIFEST.txt"
rg -q 'vibage-issue-fix' "$MANIFEST" || fail "MANIFEST missing vibage-issue-fix"
rg -q 'vibage-arch-review' "$MANIFEST" || fail "MANIFEST missing vibage-arch-review"
rg -q 'optional' "$MANIFEST" || fail "MANIFEST missing optional track marker"

# STATUS: locate DONE independent wording for optional tracks
rg -q 'locate DONE independent' "$ROOT/STATUS.md" || fail "STATUS missing locate DONE independent"

pass "optional track gate contracts"
echo "ALL optional_track_gates tests passed"
