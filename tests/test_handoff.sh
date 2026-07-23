#!/usr/bin/env bash
# Contract tests for RunEnvelope.handoff (§8.3)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERIFY="$ROOT/scripts/verify-handoff.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

[[ -x "$VERIFY" ]] || chmod +x "$VERIFY"

pass() { echo "OK: $*"; }
fail() { echo "FAIL: $*" >&2; exit 1; }

# Happy: failed mid-run fixture
set +e
"$VERIFY" "$ROOT/tests/fixtures/run_failed_handoff.json"
RC=$?
set -e
[[ "$RC" -eq 0 ]] || fail "run_failed_handoff.json should pass"
pass "failed handoff fixture"

# Happy: Terminal-then-mint with supersedes_run_id + optional prior_run_id mirror
set +e
"$VERIFY" "$ROOT/tests/fixtures/run_mint_supersedes.json"
RC=$?
set -e
[[ "$RC" -eq 0 ]] || fail "run_mint_supersedes.json should pass"
python3 - "$ROOT/tests/fixtures/run_mint_supersedes.json" <<'PY'
import json, sys
obj = json.load(open(sys.argv[1], encoding="utf-8"))
assert obj.get("supersedes_run_id"), "mint fixture must set supersedes_run_id SSOT"
prior = (obj.get("handoff") or {}).get("prior_run_id")
assert prior is None or prior == obj["supersedes_run_id"]
PY
pass "mint supersedes_run_id (+ optional prior_run_id mirror)"

# Mint without prior_run_id (optional absent) still OK
python3 - "$ROOT/tests/fixtures/run_mint_supersedes.json" "$TMP/mint_no_prior.json" <<'PY'
import json, sys
obj = json.load(open(sys.argv[1], encoding="utf-8"))
obj["handoff"].pop("prior_run_id", None)
json.dump(obj, open(sys.argv[2], "w", encoding="utf-8"))
PY
set +e
"$VERIFY" "$TMP/mint_no_prior.json"
RC=$?
set -e
[[ "$RC" -eq 0 ]] || fail "mint without prior_run_id should pass"
pass "mint without optional prior_run_id"

# RED: phase inside handoff
python3 - "$ROOT/tests/fixtures/run_failed_handoff.json" "$TMP/bad_phase.json" <<'PY'
import json, sys
obj = json.load(open(sys.argv[1], encoding="utf-8"))
obj["handoff"]["phase"] = "failed"
json.dump(obj, open(sys.argv[2], "w", encoding="utf-8"))
PY
set +e
"$VERIFY" "$TMP/bad_phase.json"
RC=$?
set -e
[[ "$RC" -ne 0 ]] || fail "phase inside handoff should fail"
pass "rejects phase inside handoff"

# RED: pipeline_id inside handoff
python3 - "$ROOT/tests/fixtures/run_failed_handoff.json" "$TMP/bad_pipe.json" <<'PY'
import json, sys
obj = json.load(open(sys.argv[1], encoding="utf-8"))
obj["handoff"]["pipeline_id"] = "locate"
json.dump(obj, open(sys.argv[2], "w", encoding="utf-8"))
PY
set +e
"$VERIFY" "$TMP/bad_pipe.json"
RC=$?
set -e
[[ "$RC" -ne 0 ]] || fail "pipeline_id inside handoff should fail"
pass "rejects pipeline_id inside handoff"

# RED: non-locate root pipeline_id (locate-wave only)
python3 - "$ROOT/tests/fixtures/run_failed_handoff.json" "$TMP/bad_root_pipe.json" <<'PY'
import json, sys
obj = json.load(open(sys.argv[1], encoding="utf-8"))
obj["pipeline_id"] = "issue_fix"
json.dump(obj, open(sys.argv[2], "w", encoding="utf-8"))
PY
set +e
"$VERIFY" "$TMP/bad_root_pipe.json"
RC=$?
set -e
[[ "$RC" -ne 0 ]] || fail "non-locate pipeline_id should fail"
pass "rejects non-locate root pipeline_id"

# RED: missing required handoff key
python3 - "$ROOT/tests/fixtures/run_failed_handoff.json" "$TMP/missing_key.json" <<'PY'
import json, sys
obj = json.load(open(sys.argv[1], encoding="utf-8"))
del obj["handoff"]["stop_reason"]
json.dump(obj, open(sys.argv[2], "w", encoding="utf-8"))
PY
set +e
"$VERIFY" "$TMP/missing_key.json"
RC=$?
set -e
[[ "$RC" -ne 0 ]] || fail "missing stop_reason should fail"
pass "rejects missing required handoff key"

# RED: prior_run_id != supersedes_run_id
python3 - "$ROOT/tests/fixtures/run_mint_supersedes.json" "$TMP/bad_mirror.json" <<'PY'
import json, sys
obj = json.load(open(sys.argv[1], encoding="utf-8"))
obj["handoff"]["prior_run_id"] = "wrong-run"
json.dump(obj, open(sys.argv[2], "w", encoding="utf-8"))
PY
set +e
"$VERIFY" "$TMP/bad_mirror.json"
RC=$?
set -e
[[ "$RC" -ne 0 ]] || fail "mismatched prior_run_id should fail"
pass "rejects prior_run_id != supersedes_run_id"

# Example envelope in references/hub (if present)
EXAMPLE="$ROOT/references/hub/RunEnvelope.example.json"
if [[ -f "$EXAMPLE" ]]; then
  set +e
  "$VERIFY" "$EXAMPLE"
  RC=$?
  set -e
  [[ "$RC" -eq 0 ]] || fail "RunEnvelope.example.json should pass verify-handoff"
  pass "references/hub/RunEnvelope.example.json"
fi

echo "ALL handoff tests passed"
