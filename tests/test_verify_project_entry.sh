#!/usr/bin/env bash
# Fixture exercise for verify-project-entry.sh. MUST NOT enter Tier-0.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "FAIL: $*"; exit 1; }

if grep -q 'verify-project-entry\|test_verify_project_entry' scripts/test-tier0.sh; then
  fail "verify-project-entry must not enter scripts/test-tier0.sh"
fi

# Install must read shared AGENTS SSOT; codex file is human mirror only
diff -q adapters/shared/AGENTS.vibage.md adapters/codex/AGENTS.vibage.md >/dev/null \
  || fail "adapters/codex/AGENTS.vibage.md drifted from adapters/shared (install uses shared only)"
grep -Fq 'adapters/shared/AGENTS.vibage.md' scripts/install.sh \
  || fail "install_project_rules must upsert from adapters/shared/AGENTS.vibage.md"

# --force-project-entry alone must fail
if bash scripts/install.sh --force-project-entry >/dev/null 2>&1; then
  fail "--force-project-entry alone must fail (needs --with-project-rule=)"
fi

# No args → honest fail
if bash scripts/verify-project-entry.sh >/tmp/vpe-noarg.out 2>/tmp/vpe-noarg.err; then
  fail "verify with no args must fail"
fi
grep -Eiq 'parent workspace path required|Global skill' /tmp/vpe-noarg.err \
  || fail "no-arg fail must mention parent path / global skills honesty"

# Empty fixture parent → fail missing files
FIX="$(mktemp -d)"
trap 'rm -rf "$FIX"' EXIT
if bash scripts/verify-project-entry.sh "$FIX" >/dev/null 2>&1; then
  fail "empty parent must fail"
fi

# Install project rules into fixture (surfaces filter must not drop platforms)
bash scripts/install.sh --surfaces=claude --with-project-rule="$FIX" >/tmp/vpe-install.out
bash scripts/verify-project-entry.sh "$FIX" | tee /tmp/vpe-ok.out
grep -Fq 'PROJECT_ENTRY_OK' /tmp/vpe-ok.out || fail "expected PROJECT_ENTRY_OK after install"

# Stale refresh: overwrite mdc on re-install
echo '# stale' > "$FIX/.cursor/rules/vibage.mdc"
bash scripts/install.sh --with-project-rule="$FIX" >/dev/null
grep -Fq 'vibage-init' "$FIX/.cursor/rules/vibage.mdc" \
  || fail "re-install must overwrite stale Cursor vibage.mdc"
bash scripts/verify-project-entry.sh "$FIX" >/dev/null

echo "TEST_VERIFY_PROJECT_ENTRY_OK"
