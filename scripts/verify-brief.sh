#!/usr/bin/env bash
# Usage: verify-brief.sh <workspace_root> <path_or_scope_id>
# Exit 0 and print BRIEF_USABLE_OK when brief has budget header + non-empty body.
set -euo pipefail

fail() { echo "FAIL: $*" >&2; exit 1; }

WS="${1:-}"
SCOPE="${2:-}"
if [[ -z "$WS" || ! -d "$WS" || -z "$SCOPE" ]]; then
  echo "FAIL: Usage: $0 <workspace_root> <path_or_scope_id>" >&2
  exit 2
fi
WS="$(cd "$WS" && pwd)"

if [[ -f "$SCOPE" ]]; then
  BRIEF="$SCOPE"
elif [[ -f "$WS/$SCOPE" ]]; then
  BRIEF="$WS/$SCOPE"
elif [[ -f "$WS/docs/vibage/briefs/${SCOPE}.md" ]]; then
  BRIEF="$WS/docs/vibage/briefs/${SCOPE}.md"
elif [[ -f "$WS/docs/vibage/briefs/${SCOPE}" ]]; then
  BRIEF="$WS/docs/vibage/briefs/${SCOPE}"
else
  fail "brief not found for scope/path: $SCOPE"
fi

python3 - "$BRIEF" <<'PY'
import re, sys
from pathlib import Path

path = Path(sys.argv[1])

def die(msg: str) -> None:
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)

text = path.read_text(encoding="utf-8")
if not text.strip():
    die("brief is empty")

# Budget header: max_tokens in YAML frontmatter or key: value header line
has_budget = bool(
    re.search(r"(?im)^max_tokens:\s*\d+\s*$", text)
    or re.search(r"(?im)^---[\s\S]*?max_tokens:\s*\d+[\s\S]*?---", text)
)
if not has_budget:
    die("brief missing max_tokens budget header")

# Non-empty body: strip frontmatter if present
body = text
if text.lstrip().startswith("---"):
    parts = text.split("---", 2)
    if len(parts) >= 3:
        body = parts[2]
body = body.strip()
if not body:
    die("brief body is empty")

sys.exit(0)
PY

echo "BRIEF_USABLE_OK"
