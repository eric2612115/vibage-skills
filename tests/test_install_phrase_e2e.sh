#!/usr/bin/env bash
# Agent-equivalent of owner saying only「幫我裝 Vibage」— runs the Install phrase steps.
# Re-runnable evidence for dim4 (not a video). MUST NOT enter Tier-0.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail() { echo "FAIL: $*"; exit 1; }

if grep -q 'test_install_phrase_e2e' scripts/test-tier0.sh; then
  fail "must not enter Tier-0"
fi

# Simulate clean agent HOME for skill links; pins still use the real home (superpowers pin).
REAL_HOME="${HOME}"
TMP_HOME="$(mktemp -d)"
PARENT="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME" "$PARENT"' EXIT
export HOME="$TMP_HOME"

# Steps from skills/using-vibage § Install phrase (agent runs these; owner typed zero bash)
bash "$ROOT/scripts/install.sh" >/tmp/ipv-e2e-install.out
bash "$ROOT/scripts/install.sh" --with-project-rule="$PARENT" >/tmp/ipv-e2e-rule.out
out="$(bash "$ROOT/scripts/verify-project-entry.sh" "$PARENT")"
echo "$out" | grep -Fq 'PROJECT_ENTRY_OK' || fail "expected PROJECT_ENTRY_OK after install phrase steps"
HOME="$REAL_HOME" bash "$ROOT/scripts/verify-pins.sh" >/tmp/ipv-e2e-pins.out

# Phrase docs: owner is not asked to run shell themselves
if grep -Eiq '請(你|主人|用戶).*執行.*(bash|終端|terminal)' prompts/SAY-INSTALL-VIBAGE.md; then
  fail "SAY-INSTALL must not require owner to run shell"
fi

# Transcript stub (committed shape) — proves the intended chat evidence
TRANS="$ROOT/tests/fixtures/install-vibage-agent-transcript.md"
[[ -f "$TRANS" ]] || fail "missing $TRANS"
grep -Fq '幫我裝 Vibage' "$TRANS" || fail "transcript missing owner phrase"
grep -Fq 'PROJECT_ENTRY_OK' "$TRANS" || fail "transcript missing PROJECT_ENTRY_OK"
grep -Fq 'do not dig' "$TRANS" || grep -Fq 'Do not dig' "$TRANS" \
  || fail "transcript must stop before dig"

echo "INSTALL_PHRASE_E2E_OK parent=$PARENT"
