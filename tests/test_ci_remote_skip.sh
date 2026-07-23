#!/usr/bin/env bash
# Mechanical check for P7 / SAT-ci-remote (skip XOR origin+workflow).
# MUST NOT be wired into scripts/test-tier0.sh.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "FAIL: $*"; exit 1; }

SAT="$ROOT/docs/superpowers/specs/satellites/SAT-ci-remote.md"
STATUS="$ROOT/STATUS.md"

[[ -f "$SAT" ]] || fail "missing SAT-ci-remote.md (REQUIRED this wave)"
[[ -f "$STATUS" ]] || fail "missing STATUS.md"

if grep -q 'test_ci_remote_skip' scripts/test-tier0.sh; then
  fail "ci-remote skip test must not enter scripts/test-tier0.sh"
fi

grep -Fq 'SAT-ci-remote' "$STATUS" \
  || fail "STATUS P7 must point to SAT-ci-remote"
grep -Fq 'publish-ready' "$STATUS" \
  || fail "STATUS must keep ≠ publish-ready honesty"

for bad in 'P7 DONE' 'CI live' 'CI green' 'remote CI Proven'; do
  if grep -Fq "$bad" "$STATUS"; then
    fail "STATUS must not claim: $bad"
  fi
done

grep -Eiq 'SKIPPED|skipped|test-tier0\.sh' "$SAT" || fail "SAT-ci-remote must document skip and/or Tier-0 mirror"
grep -Fq 'test-tier0.sh' "$SAT" || fail "SAT-ci-remote must name bash scripts/test-tier0.sh mirror"
if grep -Eq '!\[|shields\.io' "$SAT"; then
  fail "SAT-ci-remote must not include CI badges"
fi
if grep -Eq '^[[:space:]]*runs-on:|^[[:space:]]*uses: actions/' "$SAT"; then
  fail "SAT-ci-remote must not embed workflow body"
fi

has_origin=0
if git remote 2>/dev/null | grep -qx 'origin'; then
  has_origin=1
fi

shopt -s nullglob
workflows=(.github/workflows/*.yml .github/workflows/*.yaml)
shopt -u nullglob

if [[ "$has_origin" -eq 0 ]]; then
  grep -Eiq 'skipped|SKIPPED' "$STATUS" \
    || fail "no origin → STATUS must mention skipped or SKIPPED"
  if [[ ${#workflows[@]} -gt 0 ]]; then
    fail "no origin → must not have .github/workflows YAML (found: ${workflows[*]})"
  fi
  echo "CI_REMOTE_SKIP_OK (no origin)"
  exit 0
fi

# origin present
[[ ${#workflows[@]} -gt 0 ]] || fail "origin present → must have .github/workflows YAML"
found_tier0=0
for w in "${workflows[@]}"; do
  if grep -Fq 'test-tier0.sh' "$w"; then
    found_tier0=1
    break
  fi
done
[[ "$found_tier0" -eq 1 ]] || fail "origin present → some workflow must run test-tier0.sh"
grep -Eiq 'origin|workflow|Actions|tier0\.yml' "$STATUS" \
  || fail "origin present → STATUS must describe origin/workflow state"
if grep -Eiq 'no origin.*SKIPPED|has \*\*no origin\*\*' "$STATUS"; then
  fail "STATUS must not claim no-origin SKIPPED forever when origin exists"
fi

echo "CI_REMOTE_ORIGIN_OK"
