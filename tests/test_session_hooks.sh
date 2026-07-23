#!/usr/bin/env bash
# Cursor sessionStart hook dry-run + host-best honesty. MUST NOT enter Tier-0.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "FAIL: $*"; exit 1; }

if grep -q 'test_session_hooks\|vibage-session-start' scripts/test-tier0.sh; then
  fail "session hooks test must not enter scripts/test-tier0.sh"
fi

[[ -f references/host-best-session-entry.md ]] || fail "missing host-best-session-entry.md"
[[ -f skills/using-vibage/SKILL.md ]] || fail "missing using-vibage skill"
FIX_OWNER="tests/fixtures/owner-zero-bash-path.md"
[[ -f "$FIX_OWNER" ]] || fail "missing $FIX_OWNER (S1 evidence)"
grep -Eiq 'do not type bash|0.?bash|Owner should \*\*not\*\* type bash|不要求.*bash|不.*打 bash' "$FIX_OWNER" \
  || grep -Fq 'does not require the owner to type bash' "$FIX_OWNER" \
  || fail "owner-zero-bash fixture missing 0-bash semantics"
grep -Eiq 'Agent runs|agent runs' "$FIX_OWNER" \
  || fail "owner-zero-bash fixture must say agent runs scripts"
grep -Fxq 'using-vibage' skills/MANIFEST.txt || fail "using-vibage not in MANIFEST"
grep -Fq 'Finishing (required' skills/vibage-issue-locate/SKILL.md \
  || fail "issue-locate must require finishing pointer"

HOOK="$ROOT/adapters/cursor/hooks/vibage-session-start.sh"
[[ -x "$HOOK" ]] || fail "template hook not executable"

# Dry-run: valid JSON with additional_context
out="$(VIBAGE_PKG_ROOT="$ROOT" bash "$HOOK")"
python3 -c '
import json,sys
o=json.loads(sys.argv[1])
assert "additional_context" in o and "using-vibage" in o["additional_context"]
' "$out" || fail "hook dry-run JSON invalid or missing using-vibage"

# Claude/Codex adapters must not require Cursor hook paths for their own routing
for f in adapters/claude/CLAUDE.vibage.md adapters/shared/AGENTS.vibage.md; do
  grep -Fq 'Cursor-only hook files are **not** required' "$f" \
    || fail "missing Cursor-only hook honesty in $f"
done

# Fixture parent install includes hooks; Claude-only surfaces still get Cursor hooks (always-three)
FIX="$(mktemp -d)"
trap 'rm -rf "$FIX"' EXIT
bash scripts/install.sh --surfaces=claude --with-project-rule="$FIX" >/dev/null
[[ -f "$FIX/.cursor/hooks.json" ]] || fail "install must write Cursor hooks even when --surfaces=claude"
[[ -x "$FIX/.cursor/hooks/vibage-session-start.sh" ]] || fail "hook script missing/executable"
bash scripts/verify-project-entry.sh "$FIX" >/dev/null

echo "TEST_SESSION_HOOKS_OK"
