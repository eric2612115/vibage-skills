#!/usr/bin/env bash
# Deliverable narrative token lint. ∉ Tier-0 / pack-health.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
FX=tests/fixtures/report_tokens

fail() { echo "FAIL: $*"; exit 1; }
pass() { echo "PASS: $*"; }

if grep -qE 'test_verify_report_tokens' scripts/test-tier0.sh 2>/dev/null; then
  fail "must not wire into test-tier0.sh"
fi
if grep -qE 'test_verify_report_tokens' scripts/pack-health.sh 2>/dev/null; then
  fail "must not wire into pack-health.sh"
fi

bash scripts/verify-report.sh tests/fixtures/sample_LOCATE_degraded.md \
  || fail "clean degraded sample must still pass"
pass "ok_clean sample_LOCATE_degraded"

bash scripts/verify-report.sh "$FX/ok_negation.md" || fail "≠ 掃透 must pass"
pass "ok_negation"

bash scripts/verify-report.sh "$FX/ok_held_saotou.md" || fail "held+evidence must pass"
pass "ok_held_saotou"

if bash scripts/verify-report.sh "$FX/bad_saotou.md" >/dev/null 2>&1; then
  fail "bad_saotou must fail"
fi
pass "bad_saotou fails"

if bash scripts/verify-report.sh "$FX/bad_same_line_negation.md" >/dev/null 2>&1; then
  fail "已掃透；≠ SaaS must fail"
fi
pass "bad_same_line_negation fails"

if bash scripts/verify-report.sh "$FX/bad_cross_negation.md" >/dev/null 2>&1; then
  fail "已掃透；≠ 立體 must fail (cross-slogan)"
fi
pass "bad_cross_negation fails"

if bash scripts/verify-report.sh "$FX/bad_cross_negation_scene.md" >/dev/null 2>&1; then
  fail "立體…；≠ 掃透 must fail (cross-slogan)"
fi
pass "bad_cross_negation_scene fails"

if bash scripts/verify-report.sh "$FX/bad_held_no_fence.md" >/dev/null 2>&1; then
  fail "Held without evidence fence must fail"
fi
pass "bad_held_no_fence fails"

if bash scripts/verify-report.sh "$FX/bad_paraphrase_saotou.md" >/dev/null 2>&1; then
  fail "universal 掃 paraphrase must fail"
fi
pass "bad_paraphrase_saotou fails"

if bash scripts/verify-report.sh "$FX/bad_env_vacancy_inflation.md" >/dev/null 2>&1; then
  fail "環境都確認/全部釐清 without ENV_VACANCY_CLEAR must fail"
fi
pass "bad_env_vacancy_inflation fails"

if bash scripts/verify-report.sh "$FX/bad_paraphrase_dig_ready.md" >/dev/null 2>&1; then
  fail "fully mapped / ready to dig paraphrase must fail"
fi
pass "bad_paraphrase_dig_ready fails"

if bash scripts/verify-report.sh "$FX/bad_scene.md" >/dev/null 2>&1; then
  fail "scene without SCENE_COVER_OK must fail"
fi
pass "bad_scene fails"

# OWNER forbidden slogan via --owner + minimal locate
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
cp tests/fixtures/sample_LOCATE_degraded.md "$TMP/VIBAGE-ISSUE-LOCATE.md"
cp "$FX/bad_owner_quandong.md" "$TMP/VIBAGE-ISSUE-OWNER.md"
if bash scripts/verify-report.sh "$TMP/VIBAGE-ISSUE-LOCATE.md" --owner "$TMP/VIBAGE-ISSUE-OWNER.md" >/dev/null 2>&1; then
  fail "OWNER 系統已懂 must fail"
fi
pass "bad_owner fails via --owner"

# sibling auto-pick
if bash scripts/verify-report.sh "$TMP/VIBAGE-ISSUE-LOCATE.md" >/dev/null 2>&1; then
  fail "sibling OWNER with 全懂 must fail"
fi
pass "sibling OWNER lint"

echo "VERIFY_REPORT_TOKENS_OK"
