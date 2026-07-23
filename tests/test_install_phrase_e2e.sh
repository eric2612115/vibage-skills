#!/usr/bin/env bash
# Agent-equivalent of owner saying only「幫我裝 Vibage」— Install continuum.
# Re-runnable evidence. MUST NOT enter Tier-0.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail() { echo "FAIL: $*"; exit 1; }

if grep -q 'test_install_phrase_e2e' scripts/test-tier0.sh; then
  fail "must not enter Tier-0"
fi

REAL_HOME="${HOME}"
TMP_HOME="$(mktemp -d)"
PARENT="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME" "$PARENT"' EXIT
export HOME="$TMP_HOME"

# Synthetic multi-app parent (S05 shape)
mkdir -p "$PARENT/app-a/.git" "$PARENT/app-b/.git"
printf '# App A\n' > "$PARENT/app-a/README.md"
printf '# App B\n' > "$PARENT/app-b/README.md"

bash "$ROOT/scripts/install.sh" >/tmp/ipv-e2e-install.out
bash "$ROOT/scripts/install.sh" --with-project-rule="$PARENT" >/tmp/ipv-e2e-rule.out
out="$(bash "$ROOT/scripts/verify-project-entry.sh" "$PARENT")"
echo "$out" | grep -Fq 'PROJECT_ENTRY_OK' || fail "expected PROJECT_ENTRY_OK"
grep -Eq '^alwaysApply:[[:space:]]*true' "$PARENT/.cursor/rules/vibage.mdc" \
  || fail "mdc alwaysApply missing after install"
HOME="$REAL_HOME" bash "$ROOT/scripts/verify-pins.sh" >/tmp/ipv-e2e-pins.out

# Continuum: init-hub + pile-index (S04-amended) — still no dig
bash "$ROOT/scripts/install.sh" --init-hub="$PARENT" >/tmp/ipv-e2e-hub.out
[[ -f "$PARENT/docs/vibage/STATUS.md" ]] || fail "hub STATUS missing after init-hub"
pout="$(bash "$ROOT/scripts/pile-index.sh" "$PARENT")"
echo "$pout" | grep -Fq 'PILE_INDEX_OK' || fail "expected PILE_INDEX_OK in continuum"

if grep -Eiq '請(你|主人|用戶).*執行.*(bash|終端|terminal)' prompts/SAY-INSTALL-VIBAGE.md; then
  fail "SAY-INSTALL must not require owner to run shell"
fi

TRANS="$ROOT/tests/fixtures/install-vibage-agent-transcript.md"
[[ -f "$TRANS" ]] || fail "missing $TRANS"
grep -Fq '幫我裝 Vibage' "$TRANS" || fail "transcript missing owner phrase"
grep -Fq 'PROJECT_ENTRY_OK' "$TRANS" || fail "transcript missing PROJECT_ENTRY_OK"
grep -Fq 'PILE_INDEX_OK' "$TRANS" || fail "transcript missing PILE_INDEX_OK continuum"
grep -Fq 'Do not dig' "$TRANS" || grep -Fq 'do not dig' "$TRANS" \
  || fail "transcript must forbid dig"
grep -Fq 'pile-index' skills/using-vibage/SKILL.md || fail "using-vibage must continuum to pile-index"
grep -Fq 'init-hub' prompts/SAY-INSTALL-VIBAGE.md || fail "SAY-INSTALL must mention init-hub"
if grep -Fq 'Install ready. What problem should we find?' "$TRANS"; then
  fail "transcript must not use cold-stop Install ready wording"
fi

echo "INSTALL_PHRASE_E2E_OK parent=$PARENT"
