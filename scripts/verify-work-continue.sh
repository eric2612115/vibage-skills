#!/usr/bin/env bash
# Usage: verify-work-continue.sh <hub_parent_workspace>
# Live WORK_CONTINUE.md lint. ∉ Tier-0 / pack-health / assert_gate.
# WORK_CONTINUE_VERIFY_OK ≠ locate DONE ≠ Proven-green.
set -euo pipefail
WS="${1:-}"
[[ -n "$WS" && -d "$WS" ]] || { echo "Usage: $0 <hub_parent_workspace>" >&2; exit 2; }
WS="$(cd "$WS" && pwd)"
FILE="$WS/docs/vibage/WORK_CONTINUE.md"
fail() { echo "FAIL: $*"; exit 1; }

[[ -f "$FILE" ]] || fail "missing $FILE"

python3 - "$WS" "$FILE" <<'PY'
import re
import sys
from pathlib import Path

ws = Path(sys.argv[1])
text = Path(sys.argv[2]).read_text(encoding="utf-8")

REQUIRED = [
    "work_root",
    "run_id",
    "dual_report_uris",
    "inherited_finding_ids",
    "next_step",
    "phase",
    "side_quest",
    "forbidden",
    "updated_at",
]
PLACEHOLDER_RE = re.compile(
    r"FILL_AFTER_LOCATE|TODO_SET_AFTER_LOCATE|REPLACE_ME|\bTODO_[A-Z0-9_]+\b|\bTBD\b"
)


def die(msg: str) -> None:
    print(f"FAIL: {msg}")
    sys.exit(1)


for key in REQUIRED:
    if key not in text:
        die(f"missing heading token {key}")


def field_block(name: str) -> str:
    # Capture from `name:` until next top-level field or EOF
    pat = rf"(?m)^{re.escape(name)}:\s*(.*?)(?=^(?:{'|'.join(REQUIRED)}):|\Z)"
    m = re.search(pat, text, flags=re.S)
    if not m:
        die(f"cannot parse field {name}")
    return m.group(1).strip()


def first_line_value(name: str) -> str:
    m = re.search(rf"(?m)^{re.escape(name)}:\s*(.*)$", text)
    if not m:
        die(f"missing line for {name}")
    return m.group(1).strip()


work_root = first_line_value("work_root")
run_id = first_line_value("run_id")
next_step = first_line_value("next_step")
phase = first_line_value("phase")
side_quest_line = first_line_value("side_quest")

if not run_id:
    die("run_id empty")
if not next_step:
    die("next_step empty")
if not work_root:
    die("work_root empty")

for label, val in (
    ("work_root", work_root),
    ("run_id", run_id),
    ("next_step", next_step),
    ("phase", phase),
):
    if PLACEHOLDER_RE.search(val):
        die(f"placeholder in {label}: {val}")

if phase not in ("implement_in_work_root", "side_quest"):
    die(f"phase must be implement_in_work_root|side_quest (got {phase!r})")

wr_path = (ws / work_root).resolve()
if not wr_path.is_dir():
    die(f"work_root not a directory: {work_root}")

# dual_report_uris: collect markdown list paths under the field
dual_block = field_block("dual_report_uris")
uris = re.findall(r"(?m)^\s*-\s+(\S+)\s*$", dual_block)
if len(uris) < 2:
    die("dual_report_uris needs ≥2 list paths")
# Require distinct OWNER + LOCATE report paths (not the same file twice)
owner_uris = [u for u in uris if "VIBAGE-ISSUE-OWNER" in Path(u).name]
locate_uris = [u for u in uris if "VIBAGE-ISSUE-LOCATE" in Path(u).name]
if not owner_uris:
    die("dual_report_uris missing VIBAGE-ISSUE-OWNER path")
if not locate_uris:
    die("dual_report_uris missing VIBAGE-ISSUE-LOCATE path")
if Path(owner_uris[0]).resolve() == Path(locate_uris[0]).resolve() and owner_uris[0] == locate_uris[0]:
    # same relative path listed twice
    die("dual_report_uris OWNER and LOCATE must be distinct paths")
# Also reject duplicate identical strings
if uris[0] == uris[1]:
    die("dual_report_uris first two paths must be distinct")
for u in (owner_uris[0], locate_uris[0]):
    if PLACEHOLDER_RE.search(u):
        die(f"placeholder in dual_report_uris: {u}")
    p = (ws / u).resolve()
    if not p.is_file():
        die(f"dual report missing: {u}")

inh_block = field_block("inherited_finding_ids")
findings = []
for line in inh_block.splitlines():
    line = line.strip()
    if not line or line.startswith("#"):
        continue
    if line.startswith("-"):
        line = line[1:].strip()
    if not line:
        continue
    if PLACEHOLDER_RE.search(line):
        die(f"placeholder in inherited_finding_ids: {line}")
    parts = [x.strip() for x in line.split("|")]
    if len(parts) != 3 or not all(parts):
        die(f"inherited_finding_ids line must be id | path | claim: {line}")
    findings.append(line)
if not findings:
    die("inherited_finding_ids needs ≥1 pipe-triple line")

forbid = field_block("forbidden")
forbid_body = forbid.lstrip("|").strip()
if not forbid_body:
    die("forbidden empty")
for needle in ("full-understanding", "full-sweep", "CONFIRM", "assert_gate"):
    if needle not in forbid_body:
        die(f"forbidden missing NOT-claim hint: {needle}")

if PLACEHOLDER_RE.search(side_quest_line) and side_quest_line != "none":
    die(f"placeholder in side_quest: {side_quest_line}")

updated = first_line_value("updated_at")
if not updated or PLACEHOLDER_RE.search(updated):
    die("updated_at missing or placeholder")

runs_dir = ws / "docs" / "vibage" / "RUNS"
if runs_dir.is_dir():
    # optional when RUNS present: prefer matching json
    candidate = runs_dir / f"{run_id}.json"
    if list(runs_dir.glob("*.json")) and not candidate.is_file():
        # soft: only fail if other run jsons exist and this one missing
        die(f"RUNS present but missing {candidate.name}")

print("WORK_CONTINUE_VERIFY_OK")
PY
