#!/usr/bin/env bash
# Owner install phrase + pack-feel markers. ∉ Tier-0.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail() { echo "FAIL: $*"; exit 1; }

if grep -q 'test_install_phrase' scripts/test-tier0.sh; then
  fail "must not enter Tier-0"
fi

[[ -f prompts/SAY-INSTALL-VIBAGE.md ]] || fail "missing SAY-INSTALL-VIBAGE.md"
[[ -f tests/fixtures/install-vibage-phrase.md ]] || fail "missing install-vibage-phrase fixture"
grep -Fq '幫我裝 Vibage' prompts/SAY-INSTALL-VIBAGE.md || fail "phrase missing in prompt"
grep -Fq '幫我裝 Vibage' README.md || fail "README must show install phrase"
grep -Eiq 'Install phrase|Install continuum' skills/using-vibage/SKILL.md \
  || fail "using-vibage missing Install phrase/continuum section"
grep -Fq 'PILE_INDEX_OK' skills/using-vibage/SKILL.md || fail "using-vibage must continuum to PILE_INDEX_OK"
grep -Fq 'vibage-pile-index' adapters/cursor/vibage.mdc || fail "cursor adapter must route pile-index"
grep -Fq 'EXTREMELY-IMPORTANT' skills/using-vibage/SKILL.md || fail "using-vibage missing pack-feel MUST invoke block"
grep -Fq '幫我裝 Vibage' adapters/cursor/vibage.mdc || fail "cursor adapter missing phrase"
# Continuum must not skip cost/deepen ask after PILE_INDEX_OK (ask-pressure Round0 lock)
for f in \
  adapters/cursor/vibage.mdc \
  adapters/claude/CLAUDE.vibage.md \
  adapters/codex/AGENTS.vibage.md \
  adapters/shared/AGENTS.vibage.md
do
  grep -Fq 'cost/deepen ask' "$f" || fail "$f continuum missing cost/deepen ask"
  grep -Fq 'ticket paste = skip deepen' "$f" || fail "$f continuum missing ticket=skip deepen"
done
grep -Fq 'vibage-map-deepen' skills/using-vibage/SKILL.md || fail "using-vibage session/lifecycle must name vibage-map-deepen"
grep -Fq 'cost/deepen ask' skills/using-vibage/SKILL.md || fail "using-vibage must name cost/deepen ask"
grep -Fq 'docs/maps/AI-FIRST.md' skills/using-vibage/SKILL.md || fail "using-vibage must point AI-FIRST map doc"
grep -Fq 'docs/EXTENDING.md' skills/using-vibage/SKILL.md || fail "using-vibage must point EXTENDING.md"
[[ -f docs/maps/AI-FIRST.md ]] || fail "missing AI-FIRST.md"
[[ -f docs/EXTENDING.md ]] || fail "missing EXTENDING.md"
grep -Fq 'verify-service-map' docs/maps/AI-FIRST.md || fail "AI-FIRST must name verify-service-map"
grep -Fq 'MANIFEST.txt' docs/EXTENDING.md || fail "EXTENDING must mention MANIFEST"
[[ -f tests/test_install_phrase_e2e.sh ]] || fail "missing test_install_phrase_e2e.sh"
[[ -f tests/fixtures/install-vibage-agent-transcript.md ]] || fail "missing agent transcript fixture"

echo "INSTALL_PHRASE_OK"
