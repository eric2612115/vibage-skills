#!/usr/bin/env bash
# W2 apply point answer: re-inventory mother + sweep cells for one repo_id.
# Never silent full c-prime-fill. On success, missing cell may be replaced
# if discovery finds real envs for that repo.
# Usage: env-vacancy-apply-point.sh <mother> <repo_id>
set -euo pipefail
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

fail() { echo "FAIL: $*" >&2; exit 1; }

if [[ $# -lt 2 || -z "${1:-}" || -z "${2:-}" ]]; then
  cat >&2 <<EOF
FAIL: Usage: $0 <mother-workspace> <repo_id>
EOF
  exit 1
fi

PARENT="$(cd "$1" && pwd)" || fail "not a directory: $1"
REPO_ID="$2"
ANSWERS="$PARENT/docs/vibage/maps/env_vacancy_answers.json"
MATRIX="$PARENT/docs/vibage/maps/env_branch_matrix.json"

[[ -f "$PARENT/docs/vibage/STATUS.md" ]] || fail "mother missing docs/vibage/STATUS.md"
[[ -f "$ANSWERS" ]] || fail "missing env_vacancy_answers.json — record --point first"

# Validate at least one point answer for this repo; refuse secret dotenv
python3 - "$PARENT" "$REPO_ID" "$PKG_ROOT" <<'PY' || exit 1
import json, sys
from pathlib import Path

mother = Path(sys.argv[1])
repo_id = sys.argv[2]
pkg = Path(sys.argv[3])
sys.path.insert(0, str(pkg / "scripts"))
from lib.env_vacancy import (  # noqa: E402
    answers_path,
    validate_answer_entry,
)

p = answers_path(mother)
obj = json.loads(p.read_text(encoding="utf-8"))
answers = obj.get("answers") or {}
points = [
    e
    for e in answers.values()
    if isinstance(e, dict)
    and e.get("action") == "point"
    and e.get("repo_id") == repo_id
]
if not points:
    print(f"FAIL: no point answer for repo_id={repo_id}", file=sys.stderr)
    sys.exit(1)
for e in points:
    err = validate_answer_entry(e, mother, require_point_exists=True)
    if err:
        print("ENV_VACANCY_BLOCKED")
        print(f"FAIL: {err}", file=sys.stderr)
        sys.exit(1)
print(f"OK: {len(points)} point answer(s) for {repo_id}")
PY

# Bounded: full mother inventory (needed for 1:1 manifest) then sweep THIS repo only
bash "$PKG_ROOT/scripts/matrix-inventory.sh" "$PARENT" || fail "matrix-inventory failed"
[[ -f "$MATRIX" ]] || fail "missing matrix after inventory"

CELL_LIST="$(mktemp)"
trap 'rm -f "$CELL_LIST"' EXIT

python3 - "$MATRIX" "$REPO_ID" "$CELL_LIST" <<'PY'
import json, sys
from pathlib import Path

matrix = json.load(open(sys.argv[1], encoding="utf-8"))
repo_id = sys.argv[2]
out = Path(sys.argv[3])
lines = []
for c in matrix.get("cells") or []:
    if c.get("repo_id") != repo_id:
        continue
    rid = c.get("repo_id") or ""
    br = c.get("branch_ref") or ""
    eid = c.get("env_id") or ""
    if rid and br and eid:
        lines.append(f"{rid}|{br}|{eid}")
out.write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")
print(len(lines))
PY

n="$(wc -l <"$CELL_LIST" | tr -d ' ')"
if [[ "$n" -eq 0 ]]; then
  fail "no matrix cells for repo_id=$REPO_ID after inventory"
fi

echo "OK: apply-point sweeping repo=$REPO_ID n_cells=$n (not full c-prime-fill)"

while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" ]] && continue
  IFS='|' read -r rid br eid <<<"$line"
  bash "$PKG_ROOT/scripts/matrix-sweep-cell.sh" \
    "$PARENT" "$rid" "$br" "$eid" --sweep-started || true
done <"$CELL_LIST"

echo "OK: env-vacancy-apply-point done for $REPO_ID"
