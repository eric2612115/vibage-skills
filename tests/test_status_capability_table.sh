#!/usr/bin/env bash
# Lint STATUS.md capability table shape. ∉ Tier-0 / pack-health.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "FAIL: $*"; exit 1; }
pass() { echo "PASS: $*"; }

if grep -qE 'test_status_capability_table' scripts/test-tier0.sh 2>/dev/null; then
  fail "must not wire into scripts/test-tier0.sh"
fi
if grep -qE 'test_status_capability_table' scripts/pack-health.sh 2>/dev/null; then
  fail "must not wire into scripts/pack-health.sh"
fi

python3 - <<'PY'
from pathlib import Path
import re
import sys

text = Path("STATUS.md").read_text(encoding="utf-8")
m = re.search(r"^## Capability.*?\n\n(\|.+\n\|[-| ]+\n(?:\|.+\n)+)", text, flags=re.M)
if not m:
    print("FAIL: capability table not found", file=sys.stderr)
    sys.exit(1)
block = m.group(1).strip().splitlines()
header = [c.strip() for c in block[0].strip("|").split("|")]
want = ["Capability", "Designed", "On-tree", "Proven-green", "Scope"]
if header != want:
    print(f"FAIL: bad header {header}", file=sys.stderr)
    sys.exit(1)

tri = {"YES", "NO", "blank", "—", ""}
scope_ok_prefix = ("script", "script+live-pressure", "agent", "blank", "—", "")
bad_ontree = re.compile(r"^(script(\+live-pressure)?|agent|P[0-9])")

for line in block[2:]:
    if not line.startswith("|"):
        continue
    cells = [c.strip() for c in line.strip().strip("|").split("|")]
    if len(cells) != 5:
        print(f"FAIL: want 5 cells got {len(cells)}: {line}", file=sys.stderr)
        sys.exit(1)
    cap, designed, on_tree, proven, scope = cells
    for name, val in (("Designed", designed), ("On-tree", on_tree), ("Proven-green", proven)):
        if val not in tri:
            print(f"FAIL: {cap}: {name}={val!r} not in YES/NO/blank/—", file=sys.stderr)
            sys.exit(1)
    if bad_ontree.match(on_tree):
        print(f"FAIL: {cap}: On-tree looks like scope ({on_tree!r})", file=sys.stderr)
        sys.exit(1)
    if proven in ("script", "agent", "script+live-pressure"):
        print(f"FAIL: {cap}: Proven-green leaked scope word ({proven!r})", file=sys.stderr)
        sys.exit(1)
    if scope.startswith("On-tree ("):
        print(f"FAIL: {cap}: Scope starts with On-tree (", file=sys.stderr)
        sys.exit(1)
    if scope and not any(scope == p or scope.startswith(p + " ") or scope.startswith(p + " (") or scope.startswith(p + "(") for p in ("script", "script+live-pressure", "agent", "blank", "—")):
        # allow bare —
        if scope not in ("—", "blank"):
            print(f"FAIL: {cap}: Scope bad prefix {scope!r}", file=sys.stderr)
            sys.exit(1)
    # If Scope cites evidence in backticks, it must cite something checkable:
    # an *_OK token, or a run_ts= (agent-scope rows have no token to name).
    if proven == "YES" and "`" in scope:
        has_token = re.search(r"`[A-Z0-9_]{6,}_OK`", scope)
        has_run_ts = re.search(r"run_ts\s*=\s*`?\d{8}T\d{6}Z`?", scope)
        if not (has_token or has_run_ts):
            print(
                f"FAIL: {cap}: Scope has backticks but cites neither an `*_OK` token "
                "nor a run_ts=",
                file=sys.stderr,
            )
            sys.exit(1)

# banner must not say Dimension fill deferred
banner = text.split("## Capability")[0]
if re.search(r"Dimension fill deferred", banner, flags=re.I):
    print("FAIL: honesty banner still says Dimension fill deferred", file=sys.stderr)
    sys.exit(1)
print("OK: capability table shape")
PY

pass "capability table shape"
echo "STATUS_CAPABILITY_TABLE_OK"
