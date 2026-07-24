#!/usr/bin/env bash
# C′ skills/adapters copy guard — forbid install→ready / vector-db / RAG-as-memory /
# and "system understood" slogans tied to PILE_INDEX / MAP_DEEPEN.
# MUST NOT be wired into scripts/test-tier0.sh.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "FAIL: $*"; exit 1; }
pass() { echo "PASS: $*"; }

if grep -qE 'test_c_prime_skills_copy' scripts/test-tier0.sh 2>/dev/null; then
  fail "c-prime skills copy test must not enter scripts/test-tier0.sh"
fi

SCOPE=(skills adapters)

# Literal slogan bans (must not appear even as "do not say X")
if rg -n --hidden -g '!*.git*' 'install→ready|install->ready' "${SCOPE[@]}" 2>/dev/null | grep -q .; then
  rg -n 'install→ready|install->ready' "${SCOPE[@]}" || true
  fail "skills/adapters must not contain install→ready slogan text"
fi
pass "no install→ready"

if rg -n -i --hidden -g '!*.git*' 'vector[[:space:]]+db|vector[[:space:]]+database' "${SCOPE[@]}" 2>/dev/null | grep -q .; then
  rg -n -i 'vector[[:space:]]+db|vector[[:space:]]+database' "${SCOPE[@]}" || true
  fail "skills/adapters must not contain vector db dependency language"
fi
pass "no vector db"

if rg -n -i --hidden -g '!*.git*' 'RAG-as-memory|RAG[[:space:]]+as[[:space:]]+memory|RAG[[:space:]]+as[[:space:]]+primary' "${SCOPE[@]}" 2>/dev/null | grep -q .; then
  rg -n -i 'RAG-as-memory|RAG[[:space:]]+as[[:space:]]+memory' "${SCOPE[@]}" || true
  fail "skills/adapters must not contain RAG-as-memory language"
fi
pass "no RAG-as-memory"

# Affirmative "system understood" tied to PILE_INDEX / MAP_DEEPEN on same/nearby line
# Allow anti-illusion with ≠ / not / never / must not on the same line.
bad_understood="$(
  rg -n -i 'system[[:space:]]+understood' "${SCOPE[@]}" 2>/dev/null || true
)"
if [[ -n "$bad_understood" ]]; then
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if echo "$line" | grep -Eiq 'PILE_INDEX|MAP_DEEPEN'; then
      if ! echo "$line" | grep -Eiq '≠|!=|\bnot\b|\bnever\b|must[[:space:]]+not|do[[:space:]]+not|forbid'; then
        echo "$line"
        fail "affirmative system-understood tied to PILE_INDEX/MAP_DEEPEN"
      fi
    fi
  done <<< "$bad_understood"
fi
pass "no affirmative system-understood on PILE_INDEX/MAP_DEEPEN"

# Continuum markers present in using-vibage + thin adapters
for f in \
  skills/using-vibage/SKILL.md \
  adapters/cursor/vibage.mdc \
  adapters/claude/CLAUDE.vibage.md \
  adapters/codex/AGENTS.vibage.md \
  adapters/shared/AGENTS.vibage.md
do
  [[ -f "$f" ]] || fail "missing $f"
  grep -Fq 'GRAPH_FLOOR_OK' "$f" || fail "$f must name GRAPH_FLOOR_OK"
  grep -Fq 'SCENE_BRIEF_OK' "$f" || fail "$f must name SCENE_BRIEF_OK"
  grep -Fq 'MATRIX_SWEEP_SUBSTANTIVE_OK' "$f" || fail "$f must name MATRIX_SWEEP_SUBSTANTIVE_OK"
done
pass "continuum tokens in using-vibage + adapters"

grep -Fq 'ignore deepen-as-auth' skills/vibage-issue-locate/SKILL.md \
  || grep -Fq 'Ignore deepen-as-auth' skills/vibage-issue-locate/SKILL.md \
  || fail "issue-locate must say ignore deepen-as-auth"
grep -Eiq 'briefs?/|ledger' skills/vibage-issue-locate/SKILL.md \
  || fail "issue-locate must consume briefs/ledger"
pass "issue-locate briefs/ledger + deepen-as-auth"

echo "C_PRIME_SKILLS_COPY_OK"
