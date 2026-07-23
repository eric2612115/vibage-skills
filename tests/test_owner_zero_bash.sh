#!/usr/bin/env bash
# Dim4 evidence: owner path is chat-first; bash is agent/operator. ∉ Tier-0.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail() { echo "FAIL: $*"; exit 1; }

if grep -q 'test_owner_zero_bash' scripts/test-tier0.sh; then
  fail "must not enter Tier-0"
fi

FIX=tests/fixtures/owner-zero-bash-path.md
[[ -f "$FIX" ]] || fail "missing $FIX"
grep -Fq 'does not require the owner to type bash' "$FIX" || fail "fixture missing 0-bash claim"
grep -Fq 'Agent runs' "$FIX" || fail "fixture missing Agent runs"

say_line="$(grep -n '## What you say' README.md | head -1 | cut -d: -f1)"
ops_line="$(grep -n 'Operator commands' README.md | head -1 | cut -d: -f1)"
[[ -n "$say_line" && -n "$ops_line" ]] || fail "README missing What you say or Operator commands"
[[ "$say_line" -lt "$ops_line" ]] || fail "What you say must appear before Operator commands"
grep -Fq '幫我裝 Vibage' README.md || fail "README must show install phrase"
grep -Fq 'You should not type bash' README.md || fail "README must say owner should not type bash"
grep -Fq 'test_install_phrase_e2e.sh' README.md || fail "README must point install phrase e2e"

grep -Fq 'do not type bash' skills/using-vibage/SKILL.md \
  || fail "using-vibage missing owner no-bash"
grep -Fq 'do not type bash' prompts/NEW-CHAT.md || fail "NEW-CHAT missing do not type bash"
grep -Fq 'do not ask the owner to memorize bash' prompts/NEW-CHAT.md \
  || fail "NEW-CHAT must tell agent not to make owner memorize bash"

grep -Fq 'owner-zero-bash-path.md' docs/LOCAL-COMPLETE-CHECKLIST.md \
  || fail "checklist must cite owner-zero-bash fixture"
grep -Fq 'OWNER_ZERO_BASH_OK' docs/LOCAL-COMPLETE-CHECKLIST.md \
  || fail "checklist must name OWNER_ZERO_BASH_OK token"

for f in adapters/cursor/vibage.mdc adapters/claude/CLAUDE.vibage.md adapters/shared/AGENTS.vibage.md; do
  grep -Fq 'do not type bash' "$f" || fail "missing do not type bash in $f"
done

echo "OWNER_ZERO_BASH_OK"
