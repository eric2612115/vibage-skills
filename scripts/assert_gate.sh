#!/usr/bin/env bash
# Usage: assert_gate.sh <workspace_root>
# Exit 0 if docs/war-room/CONFIRM.json payload_hash matches SCAN_PLAN.
set -euo pipefail
WS="${1:-}"
[[ -n "$WS" && -d "$WS" ]] || { echo "Usage: $0 <workspace_root>" >&2; exit 2; }
HUB="$WS/docs/war-room"
PLAN="$HUB/SCAN_PLAN.md"
CONF="$HUB/CONFIRM.json"
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "ASSERT_GATE_FAIL: $*" >&2; exit 1; }
[[ -f "$PLAN" ]] || fail "missing $PLAN"
[[ -f "$CONF" ]] || fail "missing $CONF"
HASH="$("$PKG_ROOT/scripts/lib/scan_plan_hash.py" "$PLAN")"
GOT="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1], encoding="utf-8"))["payload_hash"])' "$CONF")"
ALG="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1], encoding="utf-8")).get("hash_alg","sha256"))' "$CONF")"
[[ "$ALG" == "sha256" ]] || fail "unsupported hash_alg=$ALG"
[[ "$GOT" == "$HASH" ]] || fail "payload_hash mismatch (plan changed or stale confirm)"
echo "ASSERT_GATE_OK: $WS"
