# C′ Pressure-Loop Wave Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close live-parent pressure gaps so DefiStrategy + MindOwnBuz reach honest `PRESSURE_PASS` (CONFIRM-path with disclosure), without greenwashing full-sweep.

**Architecture:** Keep「」— continuum success = entry→hub→floor→matrix terminal → ticket/orient ready. Fix discovery/inventory/exclude leaks found in pressure round-1. Loop: clean hubs → patch → unit tests → re-pressure until PASS.

**Tech Stack:** bash + Python 3 (no PyYAML/RAG); fixtures under `tests/fixtures/c-prime/`.

---

## PRESSURE_PASS gate (both parents)

Mechanical (must):
1. `PROJECT_ENTRY_OK`
2. `GRAPH_FLOOR_OK`
3. `ENV_BRANCH_MATRIX_OK`
4. `vibage-skills` ∉ `service_map` services/repos
5. MindOwnBuz: `war-room-skills` ∉ map (stale tooling remnant)
6. No false vacant: `.env.example`/sample/template **present** OR compose → ≥1 **non-vacant** cell (`local` = presence-synthesized, same class as bare-compose→local; **≠** “env swept”)
7. No `global_envs` cross-repo fan-out / foreign `extract_error` spam
8. Fill prints honest NOTE when no `MATRIX_SWEEP_SUBSTANTIVE_OK`
9. After each pressure round: delete `docs/vibage` on both parents (entry may remain)
10. Max loop rounds = **5**; then escalate to owner

Agent panel (8 agents: 2 grok + 2 composer × 2 parents) — majority (≥6/8):
- VERDICT ∈ {`READY_CONFIRM_PATH`, `PASS`, `PASS_WITH_DISCLOSURE`, `CONTINUUM_OK`} and **not** `FAIL`
- `VACANT_HONEST` not NO (presence→local is honest non-vacant; must not claim full-sweep)
- No KILL false full-sweep / false ready
- Reading ≥ 3 average

**Explicitly NOT required for PASS:** `MATRIX_SWEEP_SUBSTANTIVE_OK`.

**Loop stop:** PASS → stop + report. Else clean → amend Gaps → 3-review → implement → pressure. Abort at round 5.

---

## Gaps from pressure round-1

| ID | Gap | Fix |
|----|-----|-----|
| G1 | `.env.example` empty/comment-only → false `missing-env-config` | Presence→`local` **same class as bare-compose→local** (path+synthetic quote may proven for matrix terminal). Still **≠** full-sweep alone; true-vacant repos without file keep missing. Order: named envs 1–5; if empty → compose→local; elif example→local. Never read real `.env`. No `*skills` heuristic. |
| G2 | `global_envs` fan-out → foreign extract_error | Remove attach; delete dead `global_envs` / deploy-edge fan-out helpers if unused. |
| G3 | `war-room-skills` as product | **Union** hard defaults `{vibage-skills,vibage-skills-*,war-room-skills,war-room-skills-*}` with OWNER_POLICY globs (policy cannot drop hard defaults). Narrow globs only. |
| G4 | MATRIX OK ≠ full-sweep | Keep fill NOTE; panel must not treat presence-local as full-sweep. |

---

## File map

| File | Change |
|------|--------|
| `scripts/lib/env_discovery.py` | G1: after rule 5, if still empty and any example file exists → `local` |
| `scripts/matrix-inventory.sh` | G2: stop `attached \|= global_envs` |
| `scripts/graph-floor.sh` | G3: default exclude globs |
| `tests/test_c_prime_matrix.sh` | G1+G2 cases |
| `tests/test_c_prime_defi_pile.sh` / fixture | adjust if global_envs removal changes counts |
| `tests/fixtures/c-prime/defi_strategy_like/` | optional: empty `.env.example` repo |
| `STATUS.md` | one-line continuum note if needed |

---

### Task 1: G1 example-present → local

**Files:**
- Modify: `scripts/lib/env_discovery.py`
- Test: `tests/test_c_prime_matrix.sh`

- [ ] **Step 1:** Failing test — repo with only empty `.env.example` (no compose) → inventory has `local`, not only `missing-env-config`
- [ ] **Step 2:** In `discover_envs`, after rule 5, if `not found` and any example file from `DOTENV_EXAMPLE_NAMES` (or `*.env.example`) exists → `add("local", rel, "env example present; no named APP_ENV (default local)")`
- [ ] **Step 3:** Order vs bare compose: if both compose and empty example, either may set local once (dedupe). Prefer compose pointer if both (rule 6 before 5b, or 5b only when no compose — implement: rule 6 bare compose first; new 5b only when still empty after 5 and no compose handled — actually current 6 runs when `not found` after 5. Insert 5b: if not found and example files → local; elif not found and compose → local (keep 6).
- [ ] **Step 4:** `quote_for_env` for `local` + `.env.example` path: allow quote from file first non-comment KEY= line or the synthetic sentence
- [ ] **Step 5:** Run `tests/test_c_prime_matrix.sh`

### Task 2: G2 stop global_envs fan-out

**Files:**
- Modify: `scripts/matrix-inventory.sh` (sparse product loop)
- Test: `tests/test_c_prime_matrix.sh` or defi pile

- [ ] **Step 1:** Remove `if info["has_deploy"]: attached |= set(global_envs)`
- [ ] **Step 2:** Keep `global_envs` collection only if still useful for diagnostics — or delete unused; prefer delete dead code if unused
- [ ] **Step 3:** Test: two repos, A has staging compose, B has bare local only → B cells must not include staging
- [ ] **Step 4:** Run matrix + defi pile tests

### Task 3: G3 exclude war-room-skills

**Files:**
- Modify: `scripts/graph-floor.sh` default `exclude_repo_globs`
- Test: `tests/test_c_prime_defi_pile.sh` or new tiny test in graph floor test

- [ ] **Step 1:** Default globs: `["vibage-skills", "vibage-skills-*", "war-room-skills", "war-room-skills-*"]`
- [ ] **Step 2:** Fixture or graph-floor test with `war-room-skills` sibling → not in map
- [ ] **Step 3:** Run `tests/test_c_prime_graph_floor.sh` + defi pile

### Task 4: Pressure round + loop

- [ ] Clean `docs/vibage` on DefiStrategy + MindOwnBuz
- [ ] `install --with-project-rule --init-hub --c-prime-fill` both
- [ ] Record mechanical tokens + spot-check G1–G3
- [ ] 8-agent panel (2+2 × 2)
- [ ] Score vs PRESSURE_PASS
- [ ] If fail: clean hubs, amend this plan (new Gaps), 3-review, implement, repeat
- [ ] If pass: clean hubs, stop loop, report

---

## Honesty locks

- Never grant `MATRIX_SWEEP_SUBSTANTIVE_OK` via waiver or dotenv existence alone without proven path+quote
- Never read real `.env`
- `ENV_BRANCH_MATRIX_OK` ≠ full-sweep ≠ dig-ready
- C′ Proven-green stays NO until owner promotes after PASS (optional; this wave does not flip STATUS Proven-green without owner ask)

---

## Loop result

**PRESSURE_PASS achieved at round 2** (2026-07-25). 8/8 panel PASS-family; mechanical entry/floor/matrix OK both parents; hubs cleaned after score. Loop stopped.
