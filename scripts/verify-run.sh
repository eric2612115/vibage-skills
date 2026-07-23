#!/usr/bin/env bash
# Usage: verify-run.sh <RunEnvelope.json>
# Exit 0 if mode honesty rules pass.
set -euo pipefail
RUN="${1:-}"
[[ -n "$RUN" && -f "$RUN" ]] || { echo "Usage: $0 <RunEnvelope.json>" >&2; exit 2; }
fail() { echo "VERIFY_RUN_FAIL: $*" >&2; exit 1; }
python3 - "$RUN" <<'PY'
import json, sys
path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    obj = json.load(f)
mode = obj.get("mode")
if mode not in ("degraded", "full nested"):
    print(f"invalid mode literal: {mode!r}", file=sys.stderr)
    sys.exit(1)
if mode == "full nested":
    nd = obj.get("nested_dispatch") or {}
    inv = nd.get("investigators") or []
    rev = nd.get("reviewers") or []
    if len(inv) < 1 or len(rev) < 1:
        print(
            "full nested requires nested_dispatch.investigators>=1 and reviewers>=1",
            file=sys.stderr,
        )
        sys.exit(1)
sys.exit(0)
PY
RC=$?
[[ "$RC" -eq 0 ]] || fail "Mode honesty failed for $RUN"
echo "VERIFY_RUN_OK: $RUN"
