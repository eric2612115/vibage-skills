# C′ Wave-2 — Env Vacancy Ask / Configure Design

**Date:** 2026-07-25  
**Status:** Design-FULL — **On-tree=YES** (`ENV_VACANCY_W2_OK`); phrase: `W2 env-vacancy On-tree ≠ 掃透 ≠ letter B`  
**Roadmap:** `docs/superpowers/specs/2026-07-25-vibage-c-prime-next-waves-roadmap.md`  
**Tri-review fold:** `docs/superpowers/specs/2026-07-25-vibage-c-prime-next-waves-tri-review.md`  
**Parent matrix rules:** `docs/superpowers/specs/2026-07-24-vibage-c-prime-graph-brief-ledger-design.md` §2.3  

**Phrase locks:**

- Asking / skip / classify / refuse / binary `env_vacancy_waiver` **never** grant `MATRIX_SWEEP_SUBSTANTIVE_OK`
- `env_vacancy_*` columns **≠** `freshness_skip_waiver`
- Never read real `.env`
- W2 On-tree ≠ letter B ≠ Gate B ≠ Sync contract DONE

---

## 1. Goal

Turn `missing-env-config` cells from a dead-end (manual binary waiver only) into **answerable gaps**: the agent must ask; the owner chooses skip / point / classify; the mother hub records answers without pretending 掃透.

## 2. Coexistence with binary `env_vacancy_waiver`

| Mechanism | SSOT | When | Grants |
|-----------|------|------|--------|
| **Binary hatch (kept)** | `OWNER_POLICY.json` → `env_vacancy_waiver=true` + non-empty `env_vacancy_reason` | Whole matrix is special-only (`missing-env-config` / formerly blocked all-missing) | May allow `ENV_BRANCH_MATRIX_OK` only; **never** 掃透 |
| **Per-gap answers (W2)** | `docs/vibage/maps/env_vacancy_answers.json` | One or more `missing-env-config` cells need owner choice | Same: matrix terminal honesty; **never** 掃透 |

**Rules:**

1. Binary waiver remains the **whole-matrix escape hatch** (friend-chaos fixture still **forbids** it).  
2. Per-gap answers are an **overlay** — they do not delete the binary keys.  
3. No aliasing: freshness waiver objects must not satisfy vacancy checks and vice versa.  
4. If both exist, substantive verify still fails whenever any `missing-env-config` remains (unchanged parent rule).

## 3. Matrix cell interface (fail-closed)

`verify-env-branch-matrix.sh` continues to accept only cell `state` ∈ {`proven`,`failed`}.

**Forbidden:** new matrix states such as `skipped` / `classified`.

| Owner choice | Matrix cell | Overlay effect |
|--------------|-------------|----------------|
| **skip** | stays `failed` + `env_id=missing-env-config` | Answer recorded; counts toward “gaps addressed” for matrix OK when rules in §5 hold |
| **classify** | same | Answer + `repo_class` recorded; same matrix effect as skip |
| **point** | after bounded re-inventory/sweep of that repo | Cell should become a real-env `proven`/`failed` (or remain missing if path still empty) |

## 4. Data: `docs/vibage/maps/env_vacancy_answers.json`

```json
{
  "schema_version": "1",
  "updated_at": "2026-07-25T00:00:00Z",
  "answers": {
    "svc-a|main|missing-env-config": {
      "action": "skip",
      "reason": "docs-only sibling",
      "at": "2026-07-25T00:00:00Z",
      "repo_id": "svc-a",
      "branch_ref": "main",
      "env_id": "missing-env-config"
    },
    "svc-b|main|missing-env-config": {
      "action": "point",
      "reason": "compose lives under deploy/",
      "at": "2026-07-25T00:00:00Z",
      "repo_id": "svc-b",
      "branch_ref": "main",
      "env_id": "missing-env-config",
      "point_path": "deploy/compose.staging.yml"
    },
    "svc-c|main|missing-env-config": {
      "action": "classify",
      "reason": "library crate",
      "at": "2026-07-25T00:00:00Z",
      "repo_id": "svc-c",
      "branch_ref": "main",
      "env_id": "missing-env-config",
      "repo_class": "no-deploy"
    }
  }
}
```

**Key** = `repo_id|branch_ref|env_id` for the missing cell.

**`action`:** `skip` | `point` | `classify` only.

**Required fields:** `action`, `reason` (non-empty), `at` (ISO UTC), `repo_id`, `branch_ref`, `env_id`.  
**point:** also `point_path` (repo-relative; must exist; never a real `.env` secret file).  
**classify:** also `repo_class` ∈ frozen set: `no-deploy` | `docs-only` | `tooling` | `other`.

## 5. Matrix OK rules (W2 delta)

**Supersede one-liner:** W2 §5 **supersedes** parent design §2.3 “all-missing ⇒ binary `env_vacancy_waiver` only” — all-special matrices may instead clear via **(B)** waiver **or** **(C)** per-gap resolved answers. All other parent matrix checks stay (manifest 1:1, terminal states only, zero `unknown-env`, no overflow, friend-chaos forbids binary waiver).

`ENV_BRANCH_MATRIX_OK` when:

1. Every cell terminal (`proven|failed`), no `unknown-env`, no overflow; **and**
2. One of:
   - **(A)** matrix is **not** all-special (has ≥1 real-env cell) **and** every remaining `missing-env-config` cell is **resolved** per §5.1, **or**
   - **(B)** matrix is all-special **and** binary `env_vacancy_waiver` valid (whole-matrix hatch only — must not bypass (A) on mixed piles), **or**
   - **(C)** matrix is all-special **and** every `missing-env-config` cell is **resolved** per §5.1 (no binary waiver required)

### 5.1 Resolved vs unanswered (anti-greenwash)

A missing cell is **resolved** only if:

- answer `action` ∈ {`skip`,`classify`} with valid fields, **or**
- the matrix cell was **replaced** by a real-env cell after successful `env-vacancy-apply-point.sh` (cell no longer `env_id=missing-env-config`)

**Point-pending is unanswered:** `action=point` recorded in answers JSON but cell still `missing-env-config` ⇒ **unanswered** ⇒ must print `ENV_VACANCY_ASK` (never `ENV_VACANCY_ANSWERED`); does **not** satisfy (A)/(C).

`MATRIX_SWEEP_SUBSTANTIVE_OK` unchanged: ≥1 real-env all-proven, **zero** `missing-env-config` cells. Skip/classify/answers/waiver/point-pending **never** satisfy substantive.

## 6. Scripts / tokens

| Script | Role |
|--------|------|
| `scripts/env-vacancy-check.sh` | List unanswered missing cells; print tokens |
| `scripts/env-vacancy-answer.sh` | Record skip/point/classify into answers JSON |
| `scripts/env-vacancy-apply-point.sh` | Bounded: re-inventory mother + sweep cells for `repo_id` after point (not silent full fill) |
| `scripts/verify-env-vacancy.sh` | Thin wrap for skills — parse tokens; exit 0 ≠ 掃透 |

### Frozen stdout tokens (exactly one primary status line)

Priority (first match wins; never print two status tokens):

1. `ENV_VACANCY_BLOCKED` — malformed answers / invalid `point_path` / secret dotenv  
2. `ENV_VACANCY_ASK count=<n>` — `n≥1` unanswered missing cells (includes point-pending)  
3. `ENV_VACANCY_ANSWERED count=<n>` — **non-vacuous:** matrix still has `n≥1` `missing-env-config` cells **and** every one is skip|classify **resolved**  
4. `ENV_VACANCY_CLEAR` — **iff** zero `missing-env-config` cells remain in matrix  

**Forbidden:** printing `ENV_VACANCY_ANSWERED` when missing-count is 0 (that case is **only** `CLEAR`).  
**Mutual exclusion:** exactly one of `CLEAR` | `ASK` | `ANSWERED` | `BLOCKED` per check invocation.

### Exit-code matrix (`env-vacancy-check.sh` / `verify-env-vacancy.sh`)

| Primary token | Exit | Skill rule |
|---------------|------|------------|
| `ENV_VACANCY_CLEAR` | 0 | Parse token; exit 0 ≠ 掃透 ≠ continuum-complete |
| `ENV_VACANCY_ANSWERED` | 0 | Parse token; **≠ CLEAR**; disclose substantive still FAIL while any missing remains |
| `ENV_VACANCY_ASK` | ≠ 0 | Must ask; do not claim matrix vacancy settled |
| `ENV_VACANCY_BLOCKED` | ≠ 0 | Fix answers / path; do not proceed as settled |

**Token honesty:** `ANSWERED` ≠ `CLEAR` ≠ continuum-complete ≠ 掃透. Never print `MATRIX_SWEEP_SUBSTANTIVE_OK` / `FRESHNESS_OK` / dig-ready from vacancy scripts.

Frozen ask (English for hooks; agent may translate):

```text
VIBAGE_ENV_VACANCY_ASK: repo=<id> has missing-env-config. Choose skip | point:<rel-path> | classify:<class> — reason required. Asking ≠ 掃透.
```

## 7. Skill / adapter surface

- After matrix fill / session start on mother: if missing cells unanswered → emit `ENV_VACANCY_ASK` + ask line; do not claim continuum complete / 掃透.  
- Continuum may proceed to ticket/orient with **disclosure** when `ENV_BRANCH_MATRIX_OK` via (B) or (C), same honesty as today for incomplete substantive.  
- Child repos: no hard git block; optional soft note only.  
- Point path: refuse if basename is a secret dotenv (`.env`, `.env.local`, …) — reuse `env_discovery.SECRET_DOTENV_NAMES` class.

## 8. Testing (`tests/test_env_vacancy_w2.sh`)

Named outside `test_c_prime_*.sh` suite glob. Must grep-firewall ∉ `test-tier0.sh` / pack-health.

| Case | Expect |
|------|--------|
| Unanswered missing | `ENV_VACANCY_ASK`; substantive fail |
| skip + reason (all-special) | matrix OK via (C); `ANSWERED`; substantive fail; no 掃透 |
| classify + class | same as skip |
| point recorded, not applied | still `ENV_VACANCY_ASK`; not ANSWERED; not matrix (C) |
| point applied → real-env | may CLEAR that gap; substantive only if parent rules met |
| point to `.env` | `ENV_VACANCY_BLOCKED` |
| binary waiver alone | matrix OK via (B); substantive fail |
| ANSWERED ≠ CLEAR | zero-missing → CLEAR only (never vacuous ANSWERED); exit matrix as §6 |
| ASK / BLOCKED exit ≠ 0 | CLEAR / ANSWERED exit 0 still token-parse only |
| answers ≠ freshness waiver | swapping objects must not cross-grant |
| friend-chaos | binary vacancy waiver still forbidden |

## 9. Out of scope

W3a dimension; W3b letter B; W4 Tier-0; W1b sync remainder; reading real `.env`; silent full `c-prime-fill` as the only point path; granting 掃透 via ask.

## 10. Freeze-lift note

**W2 env-vacancy On-tree ≠ 掃透 ≠ letter B** — scripts + `tests/test_env_vacancy_w2.sh`.

## 11. Next after this design

1. Owner reviews this design (+ tri-review fold).  
2. `writing-plans` → `docs/superpowers/plans/2026-07-25-vibage-c-prime-env-vacancy-ask.md`.  
3. Implement **only** when owner says execute.
