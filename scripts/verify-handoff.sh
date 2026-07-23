#!/usr/bin/env bash
# Usage: verify-handoff.sh <RunEnvelope.json>
# Exit 0 if §8.3 handoff structural rules pass.
#
# Scope: locate-wave shaped only (pipeline_id locate + locate artifacts keys).
# Not pipeline-agnostic — do not reuse as a generic handoff verifier for fix /
# 架構檢視 / other pipelines without a dedicated contract.
# artifacts_ok does not cross pipelines by default (umbrella §8.4).
set -euo pipefail
RUN="${1:-}"
[[ -n "$RUN" && -f "$RUN" ]] || { echo "Usage: $0 <RunEnvelope.json>" >&2; exit 2; }
fail() { echo "VERIFY_HANDOFF_FAIL: $*" >&2; exit 1; }
python3 - "$RUN" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    obj = json.load(f)

ROOT_REQUIRED = (
    "schema_version",
    "pipeline_id",
    "run_id",
    "phase",
    "mode",
    "supersedes_run_id",
)
HANDOFF_REQUIRED = (
    "stop_reason",
    "progress",
    "blockers",
    "next_action",
    "artifacts_ok",
    "artifacts_ok_source",
    "known_incompleteness",
)
PROGRESS_REQUIRED = (
    "steps_done",
    "dig_ids_done",
    "dig_ids_pending",
    "confirm_payload_hash",
)
FORBIDDEN_IN_HANDOFF = ("phase", "pipeline_id", "run_id")
ARTIFACT_KEYS = ("SCAN_PLAN", "CONFIRM", "OWNER_POLICY")
ARTIFACT_VALUES = ("reuse", "redo", "unknown")
SOURCE_VALUES = ("script", "agent")


def die(msg: str) -> None:
    print(msg, file=sys.stderr)
    sys.exit(1)


if not isinstance(obj, dict):
    die("envelope must be a JSON object")

for key in ROOT_REQUIRED:
    if key not in obj:
        die(f"missing root field: {key}")

if obj.get("pipeline_id") != "locate":
    die("pipeline_id must be locate (locate-wave only)")

handoff = obj.get("handoff")
if not isinstance(handoff, dict):
    die("handoff must be a nested object")

for key in FORBIDDEN_IN_HANDOFF:
    if key in handoff:
        die(f"handoff must not contain root field: {key}")

for key in HANDOFF_REQUIRED:
    if key not in handoff:
        die(f"missing handoff field: {key}")

progress = handoff.get("progress")
if not isinstance(progress, dict):
    die("handoff.progress must be an object")
for key in PROGRESS_REQUIRED:
    if key not in progress:
        die(f"missing handoff.progress field: {key}")

if not isinstance(handoff.get("blockers"), list):
    die("handoff.blockers must be a list")

next_action = handoff.get("next_action")
if not isinstance(next_action, dict) or "summary" not in next_action:
    die("handoff.next_action must be an object with summary")

artifacts_ok = handoff.get("artifacts_ok")
if not isinstance(artifacts_ok, dict):
    die("handoff.artifacts_ok must be an object")
for key in ARTIFACT_KEYS:
    if key not in artifacts_ok:
        die(f"missing artifacts_ok key: {key}")
    if artifacts_ok[key] not in ARTIFACT_VALUES:
        die(f"artifacts_ok.{key} must be one of {ARTIFACT_VALUES}")

source = handoff.get("artifacts_ok_source")
if source not in SOURCE_VALUES:
    die(f"artifacts_ok_source must be one of {SOURCE_VALUES}")

if not isinstance(handoff.get("known_incompleteness"), list):
    die("handoff.known_incompleteness must be a list")

# prior_run_id is optional mirror; if present must equal supersedes_run_id (root SSOT)
if "prior_run_id" in handoff:
    if handoff["prior_run_id"] != obj.get("supersedes_run_id"):
        die(
            "handoff.prior_run_id must equal root supersedes_run_id "
            "(root is SSOT; rewrite mirror on conflict)"
        )

sys.exit(0)
PY
RC=$?
[[ "$RC" -eq 0 ]] || fail "Handoff contract failed for $RUN"
echo "VERIFY_HANDOFF_OK: $RUN"
