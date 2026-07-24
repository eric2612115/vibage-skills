#!/usr/bin/env bash
# Usage: verify-map-deepen.sh <workspace_root> [RunEnvelope.json]
# Exit 0 + MAP_DEEPEN_OK when deepen claim is disk-honest.
# NOT Tier-0. NOT assert_gate. NOT pack-health by default.
# ≠ Architecture Pass. ≠ Plan-L Mermaid/Graphify.
set -euo pipefail

WS="${1:-}"
ENV_ARG="${2:-}"
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

usage() {
  echo "Usage: $0 <workspace_root> [docs/vibage/RUNS/<run>.json]" >&2
  exit 2
}

fail() { echo "VERIFY_MAP_DEEPEN_FAIL: $*" >&2; exit 1; }

[[ -n "$WS" && -d "$WS" ]] || usage
WS="$(cd "$WS" && pwd)"

find_envelope() {
  if [[ -n "$ENV_ARG" ]]; then
    if [[ "$ENV_ARG" = /* ]]; then
      echo "$ENV_ARG"
    else
      echo "$WS/$ENV_ARG"
    fi
    return
  fi
  local runs="$WS/docs/vibage/RUNS"
  [[ -d "$runs" ]] || fail "missing $runs (envelope required for MAP_DEEPEN_OK)"
  python3 - "$runs" <<'PY'
import json, sys, pathlib
runs = pathlib.Path(sys.argv[1])
cands = []
for p in sorted(runs.glob("*.json")):
    try:
        obj = json.loads(p.read_text(encoding="utf-8"))
    except Exception:
        continue
    if obj.get("pipeline_id") == "map_deepen":
        cands.append(p)
if not cands:
    print("NO_ENVELOPE", file=sys.stderr)
    sys.exit(1)
# Prefer newest mtime among map_deepen envelopes
cands.sort(key=lambda p: p.stat().st_mtime, reverse=True)
print(cands[0])
PY
}

ENV_PATH="$(find_envelope)" || fail "no map_deepen RunEnvelope (required for MAP_DEEPEN_OK)"
[[ -f "$ENV_PATH" ]] || fail "envelope not found: $ENV_PATH"

# Mode honesty shared with locate (fake full nested must fail)
bash "$PKG_ROOT/scripts/verify-run.sh" "$ENV_PATH" >/dev/null \
  || fail "verify-run Mode honesty failed for $ENV_PATH"

DECISIONS="$WS/docs/vibage/DECISIONS.md"
[[ -f "$DECISIONS" ]] || fail "missing $DECISIONS (need deepen freeze JSON fence)"

python3 - "$WS" "$ENV_PATH" "$DECISIONS" <<'PY' || fail "deepen honesty checks failed"
import hashlib, json, re, sys
from pathlib import Path

ws = Path(sys.argv[1])
env_path = Path(sys.argv[2])
dec_path = Path(sys.argv[3])

def fail(msg: str) -> None:
    print(msg, file=sys.stderr)
    sys.exit(1)

obj = json.loads(env_path.read_text(encoding="utf-8"))
if obj.get("pipeline_id") != "map_deepen":
    fail(f"pipeline_id must be map_deepen, got {obj.get('pipeline_id')!r}")

phase = obj.get("phase")
if phase not in ("done",):
    fail(f"MAP_DEEPEN_OK requires phase=done, got {phase!r}")

scope = obj.get("scope_ids")
if not isinstance(scope, list) or not scope or not all(isinstance(x, str) and x.strip() for x in scope):
    fail("scope_ids must be non-empty list of strings")

original = obj.get("original_scope_ids")
if not isinstance(original, list) or not original:
    fail("original_scope_ids required (immutable freeze snapshot)")

# Green-shrink: cannot claim OK if scope is a proper subset of original
scope_set = set(scope)
orig_set = set(original)
if scope_set != orig_set:
    if scope_set < orig_set:
        fail("green-shrink: scope_ids is a proper subset of original_scope_ids")
    if not orig_set <= scope_set:
        fail("scope_ids and original_scope_ids mismatch (not equal and not extend)")

mode = obj.get("mode")
if mode not in ("degraded", "full nested"):
    fail(f"invalid mode: {mode!r}")

text = dec_path.read_text(encoding="utf-8")
blocks = re.findall(r"```json\s*(\{.*?\})\s*```", text, flags=re.S)
freeze = None
for raw in reversed(blocks):
    if "deepen_scope_ids" not in raw:
        continue
    try:
        cand = json.loads(raw)
    except Exception:
        continue
    if isinstance(cand.get("deepen_scope_ids"), list):
        freeze = cand
        break
if freeze is None:
    fail("DECISIONS.md missing JSON fence with deepen_scope_ids")

if freeze.get("source") != "human":
    fail("deepen freeze source must be human")
if freeze.get("deepen_yes") is not True:
    fail("deepen_yes must be true in freeze")
tier = freeze.get("model_tier")
if tier not in ("fast", "balanced", "strong"):
    fail(f"model_tier must be fast|balanced|strong, got {tier!r}")

f_ids = freeze.get("deepen_scope_ids")
if set(f_ids) != set(scope):
    fail("DECISIONS deepen_scope_ids must match envelope scope_ids")

def scope_hash(ids):
    joined = ",".join(sorted(ids))
    return hashlib.sha256(joined.encode("utf-8")).hexdigest()

fh = freeze.get("deepen_scope_hash")
if fh and fh != scope_hash(scope):
    fail("deepen_scope_hash mismatch vs scope_ids")
oh = obj.get("original_scope_hash")
if oh and oh != scope_hash(original):
    fail("original_scope_hash mismatch vs original_scope_ids")
if oh and fh and set(scope) == set(original) and oh != fh:
    fail("hash mismatch between DECISIONS and envelope for same scope")

claim = obj.get("claim_coverage", "subset")
if claim not in ("subset", "full_pile"):
    fail(f"invalid claim_coverage: {claim!r}")
map_path = ws / "docs/vibage/maps/service_map.json"
if map_path.is_file():
    try:
        sm = json.loads(map_path.read_text(encoding="utf-8"))
        n = len(sm.get("services") or [])
    except Exception:
        n = 0
    if claim == "full_pile" and n and len(scope) < n:
        fail("claim_coverage=full_pile but scope_ids smaller than map services (cross-run laundry)")

required_heads = ("## Summary", "## Role", "## Notable paths")
droot = ws / "docs/vibage/dossiers"

def section_content(body: str, heading: str) -> str:
    """Return text under a ## heading until the next ## at line start."""
    m = re.search(rf"(?m)^{re.escape(heading)}\s*$", body)
    if not m:
        return ""
    rest = body[m.end() :]
    if rest.startswith("\n"):
        rest = rest[1:]
    m2 = re.match(r"(.*?)(?=^## |\Z)", rest, flags=re.S | re.M)
    return m2.group(1) if m2 else ""

for sid in scope:
    dp = droot / f"{sid}.md"
    if not dp.is_file():
        fail(f"missing dossier: {dp}")
    body = dp.read_text(encoding="utf-8")
    if not body.strip():
        fail(f"stub empty dossier: {dp}")
    for h in required_heads:
        if not re.search(rf"(?m)^{re.escape(h)}\s*$", body):
            fail(f"dossier {dp.name} missing required heading {h}")
        if not section_content(body, h).strip():
            fail(f"dossier {dp.name} has empty section under {h}")

sys.exit(0)
PY

echo "MAP_DEEPEN_OK workspace=$WS envelope=$ENV_PATH"
echo "Honesty: MAP_DEEPEN_OK ≠ Architecture Pass ≠ CONFIRM ≠ dig-all ≠ Plan-L prettier."
