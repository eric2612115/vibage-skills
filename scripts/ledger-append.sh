#!/usr/bin/env bash
# Append one claim JSON line to docs/vibage/ledger/claims.jsonl.
# On state=failed, upsert subject_id under ## Failed in ROLLUP.md.
set -euo pipefail

fail() { echo "FAIL: $*" >&2; exit 1; }

if [[ $# -lt 2 || -z "${1:-}" || -z "${2:-}" ]]; then
  cat >&2 <<EOF
FAIL: parent workspace path and claim JSON required.

Usage: $0 /path/to/parent-workspace '{"id":"...","subject_id":"...",...}'
EOF
  exit 1
fi

PARENT="$(cd "$1" && pwd)" || fail "parent is not a directory: $1"
CLAIM_JSON="$2"

LEDGER_DIR="$PARENT/docs/vibage/ledger"
CLAIMS="$LEDGER_DIR/claims.jsonl"
ROLLUP="$LEDGER_DIR/ROLLUP.md"
mkdir -p "$LEDGER_DIR"

python3 - "$CLAIMS" "$ROLLUP" "$CLAIM_JSON" <<'PY'
import json, sys
from pathlib import Path

claims_path = Path(sys.argv[1])
rollup_path = Path(sys.argv[2])
raw = sys.argv[3]

def die(msg: str) -> None:
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)

try:
    claim = json.loads(raw)
except json.JSONDecodeError as e:
    die(f"claim is not valid JSON: {e}")

if not isinstance(claim, dict):
    die("claim must be a JSON object")

for key in ("id", "subject_id", "claim_class", "state"):
    if key not in claim:
        die(f"claim missing required field: {key}")

pointers = claim.get("pointers")
if not isinstance(pointers, list) or len(pointers) < 1:
    die("claim.pointers must be a non-empty list")
for i, p in enumerate(pointers):
    if not isinstance(p, dict):
        die(f"pointers[{i}] must be an object")
    if not p.get("path"):
        die(f"pointers[{i}] must include path")

# One JSON object per line (compact)
line = json.dumps(claim, ensure_ascii=False, separators=(",", ":"))
with claims_path.open("a", encoding="utf-8") as f:
    f.write(line + "\n")

if claim.get("state") == "failed":
    subject = str(claim["subject_id"])
    header = "## Failed"
    text = rollup_path.read_text(encoding="utf-8") if rollup_path.is_file() else ""
    lines = text.splitlines()
    if header not in [ln.strip() for ln in lines]:
        if lines and lines[-1].strip():
            lines.append("")
        lines.append(header)

    in_failed = False
    found = False
    for ln in lines:
        if ln.strip() == header:
            in_failed = True
            continue
        if in_failed and ln.startswith("## "):
            in_failed = False
        if in_failed and ln.strip().lstrip("-").strip() == subject:
            found = True
            break

    if not found:
        out = []
        inserted = False
        for ln in lines:
            out.append(ln)
            if ln.strip() == header and not inserted:
                out.append(f"- {subject}")
                inserted = True
        if not inserted:
            out.extend([header, f"- {subject}"])
        lines = out

    rollup_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

print(f"OK: appended claim id={claim['id']} state={claim['state']}")
PY
