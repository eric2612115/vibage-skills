#!/usr/bin/env bash
# Entry-doc honesty vs package STATUS + thin SAT-saas-blank.
# MUST NOT be wired into scripts/test-tier0.sh.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "FAIL: $*"; exit 1; }

SAT="$ROOT/docs/superpowers/specs/satellites/SAT-saas-blank.md"
STATUS="$ROOT/STATUS.md"
README="$ROOT/README.md"
NEWCHAT="$ROOT/prompts/NEW-CHAT.md"

ENTRY_FILES=(
  "$README"
  "$NEWCHAT"
  "$ROOT/adapters/cursor/vibage.mdc"
  "$ROOT/adapters/claude/CLAUDE.vibage.md"
  "$ROOT/adapters/codex/AGENTS.vibage.md"
  "$ROOT/adapters/shared/AGENTS.vibage.md"
)

[[ -f "$SAT" ]] || fail "missing SAT-saas-blank.md (REQUIRED this wave)"
[[ -f "$STATUS" ]] || fail "missing STATUS.md"
[[ -f "$README" ]] || fail "missing README.md"
[[ -f "$NEWCHAT" ]] || fail "missing prompts/NEW-CHAT.md"

if grep -q 'test_entry_docs_sync' scripts/test-tier0.sh; then
  fail "entry docs sync test must not enter scripts/test-tier0.sh"
fi

grep -Fq 'STATUS.md' "$README" || fail "README must point at STATUS.md"
grep -Fq 'STATUS.md' "$NEWCHAT" || fail "NEW-CHAT must point at package STATUS.md"

# Stranger hero — chat-first, not bash-first
grep -Fq '## What you say' "$README" || fail "README must have What you say hero"
grep -Fq '幫我裝 Vibage' "$README" || fail "README must show install phrase"
grep -Fq 'docs/install/' "$README" || fail "README must link docs/install/"
if grep -Eiq 'CI SKIPPED|no git remote here' "$README"; then
  fail "README must not keep stale CI SKIPPED / no-remote wording"
fi
# Public ≠ marketplace ≠ SaaS (repo is public; still must not claim store/SaaS)
if grep -Eiq 'Making the GitHub repo public.*waits until after.*SaaS|repo public / marketplace / publish-ready \*\*deferred until after SaaS' "$README" "$STATUS"; then
  fail "stale honesty: public git must not be blocked behind SaaS wave"
fi
grep -Fq 'github.com/eric2612115/vibage-skills' "$README" || fail "README must link public GitHub URL"
grep -Fq 'git clone https://github.com/eric2612115/vibage-skills.git' "$README" \
  || fail "README must show public git clone"
grep -Eiq 'This GitHub repo is public|repo is \*\*public\*\*' "$README" "$STATUS" \
  || fail "README/STATUS must state repo is public"
grep -Eiq 'marketplace' "$README" || fail "README must mention marketplace as separate"
grep -Eiq 'Public GitHub' "$STATUS" || fail "STATUS must name Public GitHub ≠ marketplace ≠ SaaS"
for f in docs/install/CURSOR.md docs/install/CLAUDE.md docs/install/CODEX.md; do
  [[ -f "$f" ]] || fail "missing $f"
  grep -Fq 'PROJECT_ENTRY_OK' "$f" || fail "$f must mention PROJECT_ENTRY_OK"
  grep -Fq 'parent' "$f" || fail "$f must say parent workspace"
done
[[ -f docs/install/MARKETPLACE.md ]] || fail "missing docs/install/MARKETPLACE.md"
grep -Fq 'MARKETPLACE.md' docs/install/CURSOR.md || fail "CURSOR.md must link MARKETPLACE.md"
grep -Fq 'MARKETPLACE.md' docs/install/CLAUDE.md || fail "CLAUDE.md must link MARKETPLACE.md"
grep -Fq '.cursor-plugin' "$README" || fail "README must mention .cursor-plugin"
grep -Fq '.claude-plugin' "$README" || fail "README must mention .claude-plugin"

# Dual-STATUS: NEW-CHAT must name package STATUS as capability SSOT (not only hub path)
grep -Eiq 'package[[:space:]]+`?STATUS\.md`?|capability SSOT' "$NEWCHAT" \
  || fail "NEW-CHAT must name package STATUS.md as capability SSOT"
grep -Fq 'using-vibage' "$NEWCHAT" || fail "NEW-CHAT must name using-vibage"
grep -Eiq "CONFIRM = .*owner" "$NEWCHAT" || fail "NEW-CHAT must plain-word CONFIRM"
grep -Fq 'do not type bash' "$NEWCHAT" || fail "NEW-CHAT must say owner do not type bash"

# Anti-fake-green: forbid stale README P2 Graphify/Later collision with plan P2-tier0-entry
if grep -Eiq '\*\*P2\*\*.*Graphify|\*\*P2\*\*.*Later' "$README"; then
  fail "README must not claim P2 Graphify/Later (collides with plan-index P2-tier0-entry)"
fi

# SaaS row honesty on STATUS
grep -Eiq 'SaaS.*/.*blank|SaaS / register' "$STATUS" \
  || fail "STATUS must keep SaaS blank row"
grep -Fq 'SAT-saas-blank' "$STATUS" \
  || fail "STATUS must point to SAT-saas-blank"

# pack-health composition must stay aligned with scripts/pack-health.sh
grep -Fq 'OWNER_ZERO_BASH_OK' "$STATUS" \
  || fail "STATUS pack-health layer must name OWNER_ZERO_BASH_OK"
grep -Fq 'INSTALL_PHRASE_OK' "$STATUS" \
  || fail "STATUS pack-health layer must name INSTALL_PHRASE_OK"
grep -Fq 'INSTALL_PHRASE_E2E_OK' "$STATUS" \
  || fail "STATUS pack-health layer must name INSTALL_PHRASE_E2E_OK"
grep -Fq 'PLUGIN_MANIFESTS_OK' "$STATUS" \
  || fail "STATUS pack-health layer must name PLUGIN_MANIFESTS_OK"

# Thin SAT contract markers
grep -Eiq 'no local CTA|no register' "$SAT" || fail "SAT-saas-blank must lock no local CTA"
grep -Fq 'UploadManifest.stub.json' "$SAT" || fail "SAT must name UploadManifest stub SSOT"
grep -Eiq 'Architecture Pass' "$SAT" || fail "SAT must name Architecture Pass boundary"
grep -Eiq 'deferred|forever-ban|shape freeze|non-normative' "$SAT" \
  || fail "SAT must document later-thicken / deferred≠forever-ban / no freeze"

# Positive CTA denylist (allow negative honesty phrasing)
deny_re='(register now|sign up|create an API key|paste your API key|pairing code|get your API key)'
for f in "${ENTRY_FILES[@]}"; do
  [[ -f "$f" ]] || fail "missing entry file: $f"
  if grep -Eiq "$deny_re" "$f"; then
    fail "positive CTA phrase in $f"
  fi
  # Soft CTA product push
  if grep -Eiq 'Soft CTA' "$f"; then
    fail "Soft CTA wording must be removed from $f"
  fi
  # Phantom docs-hygiene routing (bare skill name without SelfAutoBuz-only carve-out)
  if grep -E 'docs-hygiene' "$f" >/dev/null 2>&1; then
    if ! grep -Eiq 'SelfAutoBuz-only|not a vibage' "$f"; then
      fail "phantom docs-hygiene routing in $f (remove or label SelfAutoBuz-only)"
    fi
  fi
done

# Prefer no docs-hygiene at all in vibage entry surfaces
for f in "${ENTRY_FILES[@]}"; do
  if grep -Fq 'docs-hygiene' "$f"; then
    fail "remove docs-hygiene from vibage entry $f (SelfAutoBuz lives elsewhere)"
  fi
done

# Adapter plain gloss for CONFIRM (Plan-S W2)
for f in \
  "$ROOT/adapters/cursor/vibage.mdc" \
  "$ROOT/adapters/claude/CLAUDE.vibage.md" \
  "$ROOT/adapters/shared/AGENTS.vibage.md" \
  "$ROOT/adapters/codex/AGENTS.vibage.md"
do
  grep -Fq 'owner OK on the scan plan' "$f" || fail "missing CONFIRM plain gloss in $f"
done

echo "ENTRY_DOCS_SYNC_OK"
