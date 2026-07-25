# C′ W2 Env Vacancy Ask Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Implement W2 env-vacancy ask/configure per `docs/superpowers/specs/2026-07-25-vibage-c-prime-env-vacancy-ask-design.md`.

**Architecture:** `scripts/lib/env_vacancy.py` owns answers JSON + resolved/unanswered logic + token selection. Thin bash wrappers print one primary token and exit per §6. `verify-env-branch-matrix.sh` applies W2 §5 (A|B|C). Skills parse tokens; exit 0 ≠ 掃透. Tests in `tests/test_env_vacancy_w2.sh` (outside suite glob).

**Tech Stack:** bash + python3 JSON; reuse `env_discovery.SECRET_DOTENV_NAMES`; existing matrix-inventory / matrix-sweep-cell for point apply.

**Spec:** `docs/superpowers/specs/2026-07-25-vibage-c-prime-env-vacancy-ask-design.md`

---

### Task 1: `scripts/lib/env_vacancy.py` + check/answer/verify wrappers

**Files:**
- Create: `scripts/lib/env_vacancy.py`
- Create: `scripts/env-vacancy-check.sh`
- Create: `scripts/env-vacancy-answer.sh`
- Create: `scripts/verify-env-vacancy.sh`
- Create: `tests/test_env_vacancy_w2.sh` (firewall + ask/answered/clear/blocked)

- [x] Implement load/save answers; cell key; resolved vs point-pending; check() token+exit
- [x] answer CLI: `--skip|--classify|--point` with reason
- [x] Tests for ASK / ANSWERED / CLEAR / BLOCKED / vacuous ANSWERED forbidden

### Task 2: Matrix §5 + point apply

**Files:**
- Modify: `scripts/verify-env-branch-matrix.sh` (W2 §5 supersede all-special)
- Create: `scripts/env-vacancy-apply-point.sh`
- Extend: `tests/test_env_vacancy_w2.sh`

- [x] all-special: (B) waiver OR (C) all missing resolved skip|classify
- [x] mixed: every remaining missing resolved
- [x] point-pending does not satisfy matrix OK
- [x] apply-point: inventory + sweep repo; secret dotenv blocked

### Task 3: Skills + docs + suite firewall

**Files:**
- Modify: `skills/using-vibage/SKILL.md`
- Modify: adapters continuum lines (cursor/shared/claude/codex)
- Modify: freeze-lift / STATUS / plan-index after green
- Verify: ∉ `test-tier0.sh` / pack-health / `test_c_prime_*.sh` glob

- [x] Document ENV_VACANCY_* tokens; exit0≠掃透; ANSWERED≠CLEAR
- [x] `bash tests/test_env_vacancy_w2.sh` → `ENV_VACANCY_W2_OK`
- [x] suite + tier0 still green without vacancy
