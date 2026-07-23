#!/usr/bin/env bash
# pile-index script + skill membership. MUST NOT enter Tier-0.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail() { echo "FAIL: $*"; exit 1; }

if grep -q 'test_pile_index\|pile-index.sh' scripts/test-tier0.sh; then
  fail "pile-index must not enter Tier-0"
fi

[[ -x scripts/pile-index.sh ]] || fail "pile-index.sh not executable"
[[ -f skills/vibage-pile-index/SKILL.md ]] || fail "missing vibage-pile-index skill"
grep -Fq 'vibage-pile-index' skills/MANIFEST.txt || fail "MANIFEST missing vibage-pile-index"
grep -Fq 'PILE_INDEX_OK' skills/vibage-pile-index/SKILL.md || fail "skill must name PILE_INDEX_OK"
grep -Fq 'which repos' skills/vibage-pile-index/SKILL.md || fail "skill must forbid which-repos substitute"

PARENT="$(mktemp -d)"
trap 'rm -rf "$PARENT"' EXIT
mkdir -p "$PARENT/svc-a/.git" "$PARENT/svc-b/.git" "$PARENT/svc-c/.git"
printf '# Payments API\n' > "$PARENT/svc-a/README.md"
printf '# Orders\n' > "$PARENT/svc-b/README.md"
printf '# Notify\n' > "$PARENT/svc-c/README.md"

out="$(bash scripts/pile-index.sh "$PARENT")"
echo "$out" | grep -Fq 'PILE_INDEX_OK' || fail "expected PILE_INDEX_OK"
MAP="$PARENT/docs/vibage/maps/service_map.json"
[[ -f "$MAP" ]] || fail "missing service_map.json"
python3 - "$MAP" <<'PY' || fail "map shape/count"
import json, sys
m = json.load(open(sys.argv[1]))
assert m["pipeline_id"] == "service_map"
assert m["quality_bar"] == "MEDIUM"
assert len(m["services"]) == 3, m["services"]
ids = {s["id"] for s in m["services"]}
assert len(ids) == 3
print("ok")
PY

bash scripts/verify-service-map.sh "$PARENT" >/dev/null

echo "PILE_INDEX_TEST_OK"
