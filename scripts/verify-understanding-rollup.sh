#!/usr/bin/env bash
# Usage: verify-understanding-rollup.sh <workspace_root>
# Exit 0 and print UNDERSTANDING_ROLLUP_OK when mother-dir floor rollup holds.
# Requires GRAPH_FLOOR_OK; floor slices terminal per discovery repo; no stale
# without ROLLUP callout. Matrix files are ignored (not required).
set -euo pipefail

PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

fail() { echo "FAIL: $*" >&2; exit 1; }

WS="${1:-}"
if [[ -z "$WS" || ! -d "$WS" ]]; then
  echo "FAIL: Usage: $0 <workspace_root>" >&2
  exit 2
fi
WS="$(cd "$WS" && pwd)"

gf_out="$(bash "$PKG_ROOT/scripts/verify-graph-floor.sh" "$WS")" || fail "GRAPH_FLOOR_OK required"
[[ "$gf_out" == "GRAPH_FLOOR_OK" ]] || fail "expected GRAPH_FLOOR_OK, got: $gf_out"

MAP="$WS/docs/vibage/maps/service_map.json"
CLAIMS="$WS/docs/vibage/ledger/claims.jsonl"
ROLLUP="$WS/docs/vibage/ledger/ROLLUP.md"
SLICE_SH="$PKG_ROOT/scripts/verify-ledger-slice.sh"

python3 - "$WS" "$MAP" "$CLAIMS" "$ROLLUP" "$SLICE_SH" <<'PY'
import json, re, subprocess, sys
from pathlib import Path

ws, map_path, claims_path, rollup_path, slice_sh = sys.argv[1:6]

def die(msg: str) -> None:
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)

try:
    obj = json.loads(Path(map_path).read_text(encoding="utf-8"))
except Exception as e:
    die(f"service_map.json unreadable: {e}")

repos = obj.get("repos")
if not isinstance(repos, list) or not repos:
    die("discovery set repos[] empty or missing")

repo_ids = []
for r in repos:
    if not isinstance(r, dict):
        continue
    rid = r.get("id") or r.get("repo_id")
    if rid:
        repo_ids.append(str(rid))
if not repo_ids:
    die("no repo ids in discovery set")

rollup_text = Path(rollup_path).read_text(encoding="utf-8") if Path(rollup_path).is_file() else ""


def section_subjects(text: str, header: str) -> set[str]:
    """Subjects listed under a ## Header (bullet lines)."""
    subjects = set()
    lines = text.splitlines()
    in_sec = False
    for ln in lines:
        stripped = ln.strip()
        if stripped == header:
            in_sec = True
            continue
        if in_sec and ln.startswith("## "):
            break
        if not in_sec:
            continue
        m = re.match(r"^-\s+(.+)$", stripped)
        if m:
            subjects.add(m.group(1).strip())
    return subjects


failed_subjects = section_subjects(rollup_text, "## Failed")
stale_callouts = section_subjects(rollup_text, "## Stale")

# Any stale claim must have a ROLLUP ## Stale callout for its subject_id
if Path(claims_path).is_file():
    with open(claims_path, encoding="utf-8") as f:
        for lineno, line in enumerate(f, 1):
            line = line.strip()
            if not line:
                continue
            try:
                claim = json.loads(line)
            except json.JSONDecodeError as e:
                die(f"claims.jsonl line {lineno}: {e}")
            if not isinstance(claim, dict):
                continue
            if claim.get("state") != "stale":
                continue
            sid = str(claim.get("subject_id") or "")
            if not sid:
                die(f"stale claim missing subject_id at line {lineno}")
            if sid not in stale_callouts:
                die(f"stale claim subject={sid} lacks ROLLUP ## Stale callout")

for rid in repo_ids:
    r = subprocess.run(
        ["bash", slice_sh, ws, rid, "floor_identity,floor_deps"],
        capture_output=True,
        text=True,
    )
    proven = r.returncode == 0 and "LEDGER_SLICE_PROVEN" in (r.stdout or "")
    if proven:
        continue
    if rid in failed_subjects:
        continue
    die(
        f"repo={rid} not LEDGER_SLICE_PROVEN for floor_identity,floor_deps "
        f"and not listed under ROLLUP ## Failed"
    )

sys.exit(0)
PY

echo "UNDERSTANDING_ROLLUP_OK"
