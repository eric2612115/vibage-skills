#!/usr/bin/env bash
# W3a P2 migrate shim (was: MAP_DEEPEN_OK verifier).
# Usage: verify-map-deepen.sh <workspace_root> [RunEnvelope.json ignored]
# Never emits MAP_DEEPEN_OK.
# With dimension_yes freeze → wrap verify-dimension-fill.sh (DIMENSION_FILL_* only).
# Else → hard-fail migrate + DIMENSION_FILL_BLOCKED reason=deepen_retired.
# NOT Tier-0. NOT assert_gate. NOT pack-health by default.
# ≠ Architecture Pass. ≠ Plan-L Mermaid/Graphify. ≠ understood.
set -euo pipefail

WS="${1:-}"
# ENV_ARG kept for CLI compat; ignored after migrate (deepen envelope ≠ dimension consent)
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

usage() {
  echo "Usage: $0 <workspace_root> [docs/vibage/RUNS/<run>.json ignored]" >&2
  exit 2
}

[[ -n "$WS" && -d "$WS" ]] || usage
WS="$(cd "$WS" && pwd)"

# Adversarial: never allow MAP_DEEPEN_OK brand on stdout of this script.
# Dimension consent probe (same keys as dimension_fill.load_freeze / consent_ok).
has_dimension_consent() {
  python3 - "$WS" <<'PY'
import json, re, sys
from pathlib import Path
p = Path(sys.argv[1]) / "docs" / "vibage" / "DECISIONS.md"
if not p.is_file():
    sys.exit(1)
text = p.read_text(encoding="utf-8")
fence = re.compile(r"```(?:json)?\s*\n(.*?)```", re.S)
freeze = None
for raw in fence.findall(text):
    if "dimension_yes" not in raw:
        continue
    try:
        cand = json.loads(raw)
    except json.JSONDecodeError:
        continue
    if isinstance(cand, dict) and "dimension_yes" in cand:
        freeze = cand
if freeze and freeze.get("dimension_yes") is True:
    sys.exit(0)
sys.exit(1)
PY
}

if has_dimension_consent; then
  exec bash "$PKG_ROOT/scripts/verify-dimension-fill.sh" "$WS"
fi

cat <<EOF
DIMENSION_FILL_BLOCKED reason=deepen_retired
VERIFY_MAP_DEEPEN_MIGRATED: MAP_DEEPEN_OK brand retired (W3a).
Use dimension-fill: freeze dimension_yes + scripts/dimension-fill.sh / verify-dimension-fill.sh.
Legacy deepen_yes / pipeline_id=map_deepen do NOT authorize dimension-fill.
EOF
exit 1
