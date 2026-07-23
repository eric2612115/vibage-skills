#!/usr/bin/env bash
# Structural presence only — MUST NOT flip Focus Proven-green (SAT §10).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "FAIL: $*"; exit 1; }

# gitignore covers evidence packs
grep -q 'tests/artifacts/agent-pressure/' .gitignore \
  || fail "missing gitignore for tests/artifacts/agent-pressure/"

# card templates frozen (locate this-wave + B-path set; presence ≠ Proven / ≠ letter B)
for card in AP-C1-happy AP-C2-gate-RED AP-C3-handoff-resume \
            AP-C4-issue-fix AP-C5-service-map; do
  for f in card.md checklist.md oracle.md; do
    [[ -f "tests/fixtures/agent-pressure/cards/$card/$f" ]] \
      || fail "missing $card/$f"
  done
done

# runbook present
[[ -f tests/fixtures/agent-pressure/RUNBOOK.md ]] \
  || fail "missing RUNBOOK.md"

# synthetic parent roots exist
[[ -d tests/fixtures/synthetic-parent/app-a ]] || fail "missing app-a"
[[ -d tests/fixtures/synthetic-parent/app-b ]] || fail "missing app-b"

# hard: must NOT be wired into Tier-0 entry
if grep -q 'test_agent_pressure_smoke' scripts/test-tier0.sh; then
  fail "Focus smoke must not enter scripts/test-tier0.sh"
fi

# hard: smoke must not affirm Proven-green=YES (narrow — ignore MUST NOT / never comments)
if grep -Ei 'Proven-green[[:space:]]*=[[:space:]]*YES' tests/test_agent_pressure_smoke.sh \
  | grep -Eivq 'MUST NOT|never|not[[:space:]]+flip|do[[:space:]]+not|≠|!=|forbid'; then
  fail "smoke must not assert Proven-green=YES"
fi

# hard: smoke must not claim letter B agent-proven (structural presence only)
if grep -Ei 'letter[[:space:]]+B[[:space:]]+agent-proven' tests/test_agent_pressure_smoke.sh \
  | grep -Eivq 'MUST NOT|never|not[[:space:]]+flip|do[[:space:]]+not|≠|!=|forbid|presence'; then
  fail "smoke must not assert letter B agent-proven"
fi

echo "AGENT_PRESSURE_SMOKE_OK"
