# Honesty hardening (rg fail-closed + phrase lint + W3a doc sync)

**Date:** 2026-07-25 
**Design:** `docs/superpowers/specs/2026-07-25-vibage-honesty-followup-design.md` §9 
**Locks:** ≠ Proven-green flip; ≠ chat firewall claim; ≠ semantic lint claim; ≠ W3a Tier-0 / `script+live-pressure`

## Task H1 — rg fail-closed

- [x] `scripts/lib/require_rg.sh`
- [x] Source from all `tests/*.sh` that invoke `rg`
- [x] `DEPENDENCIES.md` `ripgrep=required` + `verify-pins.sh` presence check
- [x] `tests/test_require_rg.sh` → `REQUIRE_RG_OK` (∉ Tier-0)

## Task H2 — deliverable phrase rules

- [x] Universal scan / fully-mapped patterns → Held `MATRIX_SWEEP_SUBSTANTIVE_OK` + fence
- [x] Env 「confirm/allclarify」 → Held `ENV_VACANCY_CLEAR` + fence
- [x] `ready to dig` / `dig anywhere` → forbidden
- [x] Design §9 residual disclosure (literal ≠ semantic)
- [x] Fixtures + `VERIFY_REPORT_TOKENS_OK`

## Task H3 — W3a cross-doc

- [x] `freeze-lift.md` P0+P1+P2 On-tree
- [x] `STATUS.md` banner + scope cite P0/P1/P2 tokens

## Verify

- [x] `bash tests/test_require_rg.sh`
- [x] `bash tests/test_verify_report_tokens.sh`
- [x] `bash tests/test_status_capability_table.sh`
- [x] `bash tests/test_c_prime_skills_copy.sh` (with rg present)
- [x] `bash scripts/test-tier0.sh` → `TIER0_OK`
- [x] No C′/Focus/letter B Proven cell flip
