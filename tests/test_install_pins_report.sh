#!/usr/bin/env bash
# Regression: install.sh must check pins itself, not just suggest verify-pins.
# The reported failure was ordering — the owner finished the whole continuum
# before locate preflight refused on ripgrep / superpowers pin.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "OK: $*"; }

if grep -q 'test_install_pins_report' scripts/test-tier0.sh; then
  fail "must not enter Tier-0"
fi

REAL_HOME="$HOME"
TMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME"' EXIT

# Ambient pin state, resolved before HOME is swapped.
AMBIENT_PINS_OUT=""
if AMBIENT_PINS_OUT="$(HOME="$REAL_HOME" bash "$ROOT/scripts/verify-pins.sh" 2>&1)"; then
  AMBIENT_PINS_OK=1
else
  AMBIENT_PINS_OK=0
fi

# 1) Missing prerequisites → loud PINS_FAIL during install, install still exits 0.
set +e
out="$(HOME="$TMP_HOME" SUPERPOWERS_ROOT="" bash "$ROOT/scripts/install.sh" 2>&1)"
ec=$?
set -e
[[ "$ec" -eq 0 ]] || fail "install must stay exit 0 on pin failure by default (got $ec)"
printf '%s\n' "$out" | grep -Eq '^PINS_FAIL' \
  || fail "install must print PINS_FAIL when pins fail"
printf '%s\n' "$out" | grep -Fq 'verify-pins' \
  || fail "install must name verify-pins"
pass "install reports PINS_FAIL without aborting"

# 2) Remediation must be actionable, including the shallow-clone trap.
printf '%s\n' "$out" | grep -Fq 'github.com/obra/superpowers.git' \
  || fail "remediation must name the superpowers clone URL"
printf '%s\n' "$out" | grep -Fq -- '--unshallow' \
  || fail "remediation must cover the shallow-clone case"
printf '%s\n' "$out" | grep -Eq 'ripgrep' \
  || fail "remediation must cover ripgrep"
printf '%s\n' "$out" | grep -Fq 'locate' \
  || fail "PINS_FAIL must say locate will refuse"
pass "PINS_FAIL names exact remediation and downstream refusal"

# 3) --require-pins turns the report into a gate.
set +e
out_req="$(HOME="$TMP_HOME" SUPERPOWERS_ROOT="" bash "$ROOT/scripts/install.sh" --require-pins 2>&1)"
ec_req=$?
set -e
[[ "$ec_req" -ne 0 ]] || fail "--require-pins must fail when pins fail"
printf '%s\n' "$out_req" | grep -Eq '^PINS_FAIL' \
  || fail "--require-pins must still print PINS_FAIL"
pass "--require-pins gates the install"

# 4) The tip-only wording must be gone (it is what deferred the failure).
if grep -Fq 'Tip: clone obra/superpowers once' scripts/install.sh; then
  fail "install.sh still only tips about pins instead of checking them"
fi
pass "tip-only pin wording retired"

# 5) Healthy environment → PINS_OK (skipped, and disclosed, when unavailable).
if [[ "$AMBIENT_PINS_OK" -eq 1 ]]; then
  SP_ROOT="$(printf '%s\n' "$AMBIENT_PINS_OUT" | sed -n 's/^OK: superpowers@[0-9a-f]* (\(.*\))$/\1/p' | head -1)"
  [[ -n "$SP_ROOT" ]] || fail "could not parse superpowers root from verify-pins output"
  out_ok="$(HOME="$TMP_HOME" SUPERPOWERS_ROOT="$SP_ROOT" bash "$ROOT/scripts/install.sh" 2>&1)"
  printf '%s\n' "$out_ok" | grep -Eq '^PINS_OK' \
    || fail "healthy pins must print PINS_OK"
  pass "healthy pins → PINS_OK"
else
  echo "NOTE: ambient pins unavailable — PINS_OK path not exercised here (disclosed, not passed)"
fi

echo "INSTALL_PINS_REPORT_OK"
