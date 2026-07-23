#!/usr/bin/env bash
# Mechanical honest-skip for P7 / SAT-ci-remote.
# MUST NOT be wired into scripts/test-tier0.sh.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "FAIL: $*"; exit 1; }

SAT="$ROOT/docs/superpowers/specs/satellites/SAT-ci-remote.md"
STATUS="$ROOT/STATUS.md"

[[ -f "$SAT" ]] || fail "missing SAT-ci-remote.md (REQUIRED this wave)"
[[ -f "$STATUS" ]] || fail "missing STATUS.md"

# hard: must NOT be wired into Tier-0 entry
if grep -q 'test_ci_remote_skip' scripts/test-tier0.sh; then
  fail "ci-remote skip test must not enter scripts/test-tier0.sh"
fi

# STATUS must be grep-able as skipped / SKIPPED
grep -Eiq 'skipped|SKIPPED' "$STATUS" \
  || fail "STATUS must mention skipped or SKIPPED for P7 honesty"

# Forbid dishonest remote-CI claims in STATUS
for bad in 'P7 DONE' 'CI live' 'CI green' 'remote CI Proven'; do
  if grep -Fq "$bad" "$STATUS"; then
    fail "STATUS must not claim: $bad"
  fi
done

# Pointer to satellite
grep -Fq 'SAT-ci-remote' "$STATUS" \
  || fail "STATUS P7 must point to SAT-ci-remote"

# Still ≠ publish-ready
grep -Fq 'publish-ready' "$STATUS" \
  || fail "STATUS must keep ≠ publish-ready honesty"

has_origin=0
if git remote 2>/dev/null | grep -qx 'origin'; then
  has_origin=1
fi
remote_count="$(git remote 2>/dev/null | wc -l | tr -d ' ')"

# no remotes OR no origin → no workflow YAML this wave
if [[ "$remote_count" -eq 0 || "$has_origin" -eq 0 ]]; then
  shopt -s nullglob
  workflows=(.github/workflows/*.yml .github/workflows/*.yaml)
  shopt -u nullglob
  if [[ ${#workflows[@]} -gt 0 ]]; then
    fail "no origin → must not have .github/workflows YAML (found: ${workflows[*]})"
  fi
fi

# SAT thin contract: skip + mirror command; no badge images / no workflow file dump
grep -Eiq 'SKIPPED|skipped' "$SAT" || fail "SAT-ci-remote must document SKIPPED/skipped"
grep -Fq 'test-tier0.sh' "$SAT" || fail "SAT-ci-remote must name bash scripts/test-tier0.sh mirror"
if grep -Eq '!\[|shields\.io' "$SAT"; then
  fail "SAT-ci-remote must not include CI badges"
fi
if grep -Eq '^[[:space:]]*runs-on:|^[[:space:]]*uses: actions/' "$SAT"; then
  fail "SAT-ci-remote must not embed workflow body"
fi

echo "CI_REMOTE_SKIP_OK"
