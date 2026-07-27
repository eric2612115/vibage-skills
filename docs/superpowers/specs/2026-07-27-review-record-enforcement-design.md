# Review-record enforcement (Batch 3)

**Date:** 2026-07-27  
**Status:** **Frozen** after plan-loop round 2 (three APPROVE, zero class 1–3).
Build may start. Round-2 class-4 discloses left as residual (E5 window only before
`no_trigger_paths`; status-lints test files untriggered by design).  
**Branch:** `feat/review-record-schema-hardening` (continues Batches 1–2)  
**Baseline:** HEAD after `c1062e0` (Batch 2 + finding-class frozen)  
**Prior:** Batch 1 schema hardening; Batch 2 invocation provenance  
  (`docs/superpowers/specs/2026-07-26-review-record-invocation-provenance-design.md`)  
**Process:** Plan/Impl loops obey `references/looping-review.md` § Finding class  
  (apply 1–3 only; two class-4-only rounds → freeze).

**Round-1 applied (class 1–3):** E5 promoted into §2; E3 wording fixed to allow-list
fail-closed; E1 verification requires token parse; gate entrypoint helper closure
added to §4; tests-class list frozen from `test-tier0.sh` / `pack-health.sh`;
STATUS.md sync in §8.

## 1. The defect

Batch 2 closed the argv false-green class and documented honest-failure holes it
deliberately left open. Three of those holes outrank the remaining redirect class
(Batch 2 §5 ranking):

1. **`tests/test_review_record.sh` runs in no CI job.** Everything Batches 1–2 added
   is unenforced on push.
2. **Measurement can lie about a clean tree:** `git update-index --skip-worktree`
   (or `--assume-unchanged`) on a gate-class file yields
   `REVIEW_RECORD_SKIP reason=no_trigger_paths` while the modified content sits on
   disk. Separately, `base == HEAD` on a shallow tip can yield a vacuous empty diff.
3. **`pack-health.sh` treats every `SKIP` as a pass**, which keeps (1) and (2) quiet
   when they surface as SKIP.

Two further Batch-2 hand-offs belong here:

4. **`.github/workflows/tier0.yml` is not a trigger.** Editing CI to drop
   pack-health or weaken fetch-depth needs no review record.
5. **Trigger set is by naming convention** (`scripts/verify-*.sh`, entire `tests/`,
   entire `skills/`, …), not by “this path can forge or silence the gate.” That both
   over-triggers (fixture churn, unrelated verify scripts) and under-triggers
   (workflow YAML).

This batch is **enforcement and trigger honesty**. It is not a second pass at git
redirects, record forgery (still cheaper than any row here), or rewriting Batch 2's
threat model.

## 2. Goals (promised surface)

| ID | Promise | Done when |
|----|---------|-----------|
| E1 | Suite runs in CI | Job `review-record` (not inside `tier0`) runs `bash tests/test_review_record.sh` with `fetch-depth: 0`, and the job fails unless stdout contains `REVIEW_RECORD_TEST_OK` (exit 0 alone insufficient) |
| E2 | Workflow is guarded | `.github/workflows/tier0.yml` is a review-record trigger; changing it without a record fails the gate |
| E3 | Dangerous SKIPs are not pack-health passes | After Batch-2 anchored FAIL/exit checks: `REVIEW_RECORD_SKIP` is a pack-health pass **only** for `reason=no_trigger_paths` or `reason=git_scope_mismatch`; any other `SKIP reason=` fails pack-health. A test locks that `git_scope_mismatch` remains accepted |
| E4 | Triggers follow capability | `is_trigger` / blast match §4 allow-list + helper closure; tests assert membership and non-membership; `lab/` and `docs/evidence/reviews/` stay out |
| E5 | Hidden worktree / vacuous base cannot look clean | Default (non-flagged) runs that would have emitted `no_trigger_paths` while a trigger path is `skip-worktree`/`assume-unchanged` with disk≠HEAD, or while `base == HEAD` yet trigger paths differ on disk/index, instead emit production `REVIEW_RECORD_FAIL` with a pinned reason (`hidden_worktree` and/or `vacuous_base` — pick in impl, tests pin). Pack-health fails on that FAIL |

**Non-goals (unpromised — class 4 if reviewers demand them):**

- Closing `.git`/commondir/PATH-fake-git redirects (Batch 2 §5/§6 open).
- Making record forgery expensive.
- Merging pack-health into the `tier0` job (STATUS / SAT-ci-remote forbid that shape).
- Shrinking `adapters/` or `skills/` out of narrative blast without a separate design.
- Perfect detection of every `skip-worktree` spelling on every host.
- Guarding every `scripts/verify-*.sh` that pack-health calls (`verify-pins`,
  `verify-project-entry`, …) — those affect `PACK_HEALTH_OK`, not `REVIEW_RECORD_*`;
  leaving them untriggered is intentional and disclosed in §9.

## 3. Threat / accident ranking (what E3 must catch)

| Signal | Today | Batch 3 |
|--------|-------|---------|
| `reason=no_trigger_paths` | pack-health pass | **Keep pass** (honest clean tree), after E5 has turned *lying* cleans into FAIL |
| `reason=git_scope_mismatch` | pack-health pass | **Keep pass** (vendored / mistaken subdir; Batch 2 accepted this downgrade) |
| Vacuous empty diff / skip-worktree hide | often `no_trigger_paths` | **E5 → FAIL** (not by denying all `no_trigger_paths`) |
| Unknown future `SKIP reason=` | would pass | **Fail-closed:** only the two reasons above are allowed |

**E3 rule (precise) — allow-list, not deny-list:**

After anchored `FAIL` / exit checks (Batch 2), if the token is `REVIEW_RECORD_SKIP`:

- Pass pack-health **only if** `reason=no_trigger_paths` **or** `reason=git_scope_mismatch`.
- Any other `REVIEW_RECORD_SKIP reason=…` → pack-health **fail**.
- `REVIEW_RECORD_OK` unchanged (still not “quality”).

## 4. Trigger set by capability

### 4.1 Principle

A path is a trigger iff changing it can (a) alter `REVIEW_RECORD_*` outcome tokens,
(b) alter who consumes them, or (c) alter the looping-review / budget rules the gate
encodes — **or** it is a direct runtime helper of a gate-class entrypoint in §4.2
(dependency closure). Filename prefixes are an implementation detail of the
allow-list, not the definition.

### 4.2 Allow-list (V1 — frozen for impl)

**Gate class — entrypoints**

- `scripts/lib/review_record.py`
- `scripts/verify-review-record.sh`
- `scripts/pack-health.sh`
- `scripts/test-tier0.sh`
- `scripts/assert_gate.sh`
- `scripts/write_confirm.sh`
- `scripts/coverage-box.sh`
- `.github/workflows/tier0.yml`

**Gate class — helper closure of those entrypoints** (round-1 finding: omitting
these yields `no_trigger_paths` while changing CONFIRM/hash/pack-health lock behavior)

- `scripts/lib/scan_plan_hash.py` ← `assert_gate.sh`, `write_confirm.sh`
- `scripts/lib/coverage_box.py` ← `coverage-box.sh`
- `scripts/lib/proven_lock.py` ← `verify-proven-lock.sh` as invoked by `pack-health.sh`

Tests must assert these three are triggers. If impl discovers another direct
`scripts/lib/*` import/exec from a §4.2 gate entrypoint, add it to this list and
the test table in the same change (do not silently leave a hole).

**Narrative class**

- `references/hard-stops.md`
- `references/looping-review.md`
- `references/routing-scope.md`
- `references/review-budget.md`
- entire `adapters/`
- entire `skills/`

**Tests class** (frozen enumeration from current `test-tier0.sh` + `pack-health.sh`
+ the review-record suite itself — only `tests/test_*.sh` / `tests/test_*.py`,
never `scripts/verify-*` via this bullet)

From `scripts/test-tier0.sh`:

- `tests/test_scan_plan_hash.py`
- `tests/test_assert_gate.sh`
- `tests/test_verify_run.sh`
- `tests/test_report_names.sh`
- `tests/test_handoff.sh`
- `tests/test_optional_track_gates.sh`
- `tests/test_p1_smoke.sh`
- `tests/test_install_force_safety.sh` (if present)
- `tests/test_install_manifest.sh` (if present)
- `tests/test_c_prime_graph_floor.sh`
- `tests/test_c_prime_ledger.sh`

From `scripts/pack-health.sh`:

- `tests/test_entry_docs_sync.sh`
- `tests/test_owner_zero_bash.sh`
- `tests/test_install_phrase.sh`
- `tests/test_install_phrase_e2e.sh`
- `tests/test_plugin_manifests.sh`
- `tests/test_pile_index.sh`
- `tests/test_pack_health.sh`

Review-record / plan hygiene:

- `tests/test_review_record.sh`
- `tests/test_plan_loop_hygiene.sh`

**Removed from trigger by this batch (explicit)**

- Blanket `scripts/verify-*.sh` except `scripts/verify-review-record.sh`.
  Notably untriggered after migration (intended): `verify-pins.sh`,
  `verify-project-entry.sh`, `verify-proven-lock.sh` (the **script**; its lib
  `proven_lock.py` stays triggered via helper closure), `verify-freshness.sh`, etc.
- Blanket `tests/` prefix — only the frozen list above.
- Nothing under `lab/` (if present) and nothing under `docs/evidence/reviews/`.
- Other `scripts/lib/*` not in the helper closure (`freshness.py`, `env_vacancy.py`,
  `dimension_fill.py`, `report_token_lint.py`, …) unless a gate entrypoint grows a
  new direct dependency.

**Migration honesty:** Edits to unlisted verify scripts / test files no longer
require a review record. Adapters/skills stay narrative.

### 4.3 Blast rules

Unchanged severity order: `gate > narrative > tests`.  
`.github/workflows/tier0.yml` and helper-closure paths → **gate**.

## 5. Measurement integrity (E5)

Before emitting `no_trigger_paths` in default (non-flagged) mode:

1. **Hidden bits:** if any path that `is_trigger` would treat as a trigger is marked
   `skip-worktree` or `assume-unchanged` **and** working-tree bytes differ from
   `HEAD:<path>`, emit `REVIEW_RECORD_FAIL reason=hidden_worktree` (exact spelling
   pinned by tests). Detection must compare disk to `git show HEAD:<path>` (or
   equivalent); relying only on `git diff` is insufficient because skip-worktree
   hides those paths from diff.
2. **Vacuous base:** if `resolve_base` equals `HEAD` yet any trigger path differs
   between HEAD and the index or worktree, emit `FAIL reason=vacuous_base` **or**
   fold into `hidden_worktree` — one reason chosen in impl, pinned by tests.

Flagged library runs (`--paths-file=` / `--base=`) are unchanged by E5.
If the probe cannot run, fail closed or print an honesty line and FAIL — never
silent `no_trigger_paths`.

## 6. CI shape

Add job `review-record` (name exact) alongside existing `pack-health` / `status-lints`:

- `fetch-depth: 0`
- run `bash tests/test_review_record.sh`
- **parse stdout:** fail the step/job if `REVIEW_RECORD_TEST_OK` is absent
  (grep or equivalent; exit 0 of the suite alone must not green the job)
- **not** part of `TIER0_OK`

Do not add the suite into `scripts/test-tier0.sh`.

## 7. Verification plan

Parse tokens; exit 0 ≠ pass.

1. `bash tests/test_review_record.sh` → `REVIEW_RECORD_TEST_OK`
2. `bash scripts/test-tier0.sh` → `TIER0_OK`
3. `bash tests/test_pack_health.sh` → `TEST_PACK_HEALTH_OK`
4. Fixture: `skip-worktree` on `scripts/assert_gate.sh` with disk≠HEAD → production
   `FAIL reason=hidden_worktree` (or chosen spelling); pack-health fails
5. Fixture: subdirectory / vendored scope mismatch → `SKIP reason=git_scope_mismatch`;
   pack-health **passes** (asserted — must not regress)
6. Fixture: unknown `SKIP reason=synthetic` in pack-health consumer test → pack-health fails
7. `is_trigger` true for `.github/workflows/tier0.yml`, `scan_plan_hash.py`,
   `proven_lock.py`, `coverage_box.py`; false for `scripts/verify-freshness.sh`
8. Workflow YAML: job `review-record` exists, invokes `test_review_record.sh`, and
   contains an explicit check for the string `REVIEW_RECORD_TEST_OK`
9. Dirty tree with only `scripts/verify-freshness.sh` changed →
   `REVIEW_RECORD_SKIP reason=no_trigger_paths` (intended)

## 8. Impl order

1. Trigger allow-list + helper closure + frozen tests list + membership tests (E4)  
2. E5 hidden worktree / vacuous base FAIL  
3. pack-health SKIP allow-list (E3) + lock `git_scope_mismatch` still accepted  
4. Guard `tier0.yml` (E2)  
5. CI job `review-record` with token parse (E1)  
6. Update `STATUS.md` P7/CI job list to name `review-record` (capability table /
   prose as required by existing STATUS discipline)  
7. Impl loop under finding-class; review record  

## 9. Freeze disclosure (plan)

Open and out of scope: record forgery; PATH-fake git; `.git` file redirects.
Untriggered after migration (named): `scripts/verify-pins.sh`,
`scripts/verify-project-entry.sh`, `scripts/verify-proven-lock.sh` (wrapper),
and other non-listed verify/test files — they can still affect `PACK_HEALTH_OK` /
other tokens without a review record; this batch only closes
`REVIEW_RECORD_*` trigger honesty. E5 may be incomplete on exotic git builds —
fail closed or disclose, never silent pass.

---

**Reading order for reviewers:** §1–§2 (promises), §3–§5 (mechanics), §6–§7 (CI/verify).  
§ Finding class applies: demands to re-open Batch 2 redirects, guard all
pack-health verify scripts, or add finding-class schema fields are class 4 unless
they break a promise in §2.
