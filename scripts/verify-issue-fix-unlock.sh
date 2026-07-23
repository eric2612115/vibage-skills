#!/usr/bin/env bash
# Usage: verify-issue-fix-unlock.sh <workspace_root>
# Exit 0 only if fix_preference=YES and ISSUE_FIX_UNLOCK.json is schema-valid.
set -euo pipefail

WS="${1:-}"
if [[ -z "$WS" || ! -d "$WS" ]]; then
  echo "FAIL: Usage: $0 <workspace_root>" >&2
  exit 2
fi

POLICY="$WS/docs/vibage/OWNER_POLICY.json"
UNLOCK="$WS/docs/vibage/ISSUE_FIX_UNLOCK.json"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "OK: $*"; }

[[ -f "$POLICY" ]] || fail "missing $POLICY"
[[ -f "$UNLOCK" ]] || fail "missing $UNLOCK"

python3 - "$POLICY" "$UNLOCK" <<'PY'
import json, sys

policy_path, unlock_path = sys.argv[1], sys.argv[2]

def die(msg: str) -> None:
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)

try:
    with open(policy_path, encoding="utf-8") as f:
        policy = json.load(f)
except Exception as e:
    die(f"OWNER_POLICY.json unreadable: {e}")

pref = policy.get("fix_preference")
if pref not in ("YES", "NO"):
    die(f"fix_preference must be YES or NO, got {pref!r}")
if pref != "YES":
    die("fix_preference is NO (unlock without YES is forbidden)")

try:
    with open(unlock_path, encoding="utf-8") as f:
        unlock = json.load(f)
except Exception as e:
    die(f"ISSUE_FIX_UNLOCK.json unreadable: {e}")

required = ("schema_version", "locate_run_id", "allowed_paths", "confirmed_at", "confirmed_by")
missing = [k for k in required if k not in unlock]
if missing:
    die(f"unlock bad schema; missing keys: {missing}")

run_id = unlock.get("locate_run_id")
if not isinstance(run_id, str) or not run_id.strip():
    die("locate_run_id must be a non-empty string")

paths = unlock.get("allowed_paths")
if not isinstance(paths, list) or len(paths) < 1:
    die("allowed_paths must be a non-empty list")
if not all(isinstance(p, str) and p.strip() for p in paths):
    die("allowed_paths entries must be non-empty strings")

print("OK: fix_preference=YES")
print("OK: unlock schema valid")
print("OK: dual-consent gates pass")
sys.exit(0)
PY
