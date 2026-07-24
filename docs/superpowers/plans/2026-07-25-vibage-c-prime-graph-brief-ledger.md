# Vibage C′ Graph + Brief + Evidence Ledger Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the C′ understanding substrate (graph floor, evidence ledger, env/branch matrix with substantive 掃透 gates, domain/scene briefs) per the approved design — zero vector/RAG dependencies.

**Architecture:** Evolve `service_map.json` via structural index scripts; append-only `claims.jsonl` + `ROLLUP.md`; sparse env×branch matrix with hard caps; scene registry + bounded briefs. Gate A (narrative tokens) ≠ Gate B (CONFIRM dig). Sync (stale→reindex) is **deferred** after P3 fixture green — document in STATUS; F1 On-tree for this plan = discovery + matrix + substantive + scenes, not sync.

**Tech Stack:** Bash, Python3 for JSON where needed, shell tests under `tests/`, hub under parent `docs/vibage/`.

**Spec:** `@docs/superpowers/specs/2026-07-24-vibage-c-prime-graph-brief-ledger-design.md`  
**Index:** `@docs/superpowers/plans/2026-07-25-vibage-c-prime-plan-index.md`  
**Forbidden:** Execute `docs/archive/2026-07-24-pre-c-prime/plans/*`; add embedding/vector/RAG.

---

## File map

| Path | Responsibility |
|------|----------------|
| `scripts/graph-floor.sh` | Discovery → `service_map.json` (`discover_mode`, repos, edges) |
| `scripts/verify-graph-floor.sh` | `GRAPH_FLOOR_OK` |
| `scripts/ledger-append.sh` | Append claim to `claims.jsonl`; refresh `ROLLUP.md` stub lines for failed |
| `scripts/verify-ledger-slice.sh` | `LEDGER_SLICE_PROVEN` iff required classes all **proven** (failed alone ≠ this token) |
| `scripts/verify-understanding-rollup.sh` | `UNDERSTANDING_ROLLUP_OK` |
| `scripts/matrix-inventory.sh` | Sparse inventory → `env_branch_matrix.json` |
| `scripts/matrix-extract-evidence.py` | From compose/ci extract path+quote for a cell |
| `scripts/matrix-sweep-cell.sh` | Prove/fail one cell using extract-evidence |
| `scripts/verify-env-branch-matrix.sh` | `ENV_BRANCH_MATRIX_OK` |
| `scripts/verify-matrix-substantive.sh` | `MATRIX_SWEEP_SUBSTANTIVE_OK` |
| `scripts/c-prime-fill.sh` | graph-floor → inventory → parallel cell sweep |
| `scripts/scene-validate.sh` | Membership exclusive\|shared\|illegal |
| `scripts/scene-classify.sh` | Ticket text → 0/1/many scene matches via `keywords[]` |
| `scripts/scene-brief.sh` | Compile brief; invalidate prior scene brief on switch |
| `scripts/verify-brief.sh` | `BRIEF_USABLE_OK` |
| `scripts/verify-scene-brief.sh` | `SCENE_BRIEF_OK` (full §2.10.7 checklist) |
| `scripts/verify-scene-cover.sh` | Exit 0 only if stereoscopic cover iff holds (not a STATUS capability token) |
| `scripts/pile-index.sh` | Wrapper → graph-floor; still print `PILE_INDEX_OK` |
| `tests/test_c_prime_*.sh` | Suites |
| `tests/fixtures/c-prime/friend-chaos/**` | F1 |
| `tests/fixtures/c-prime/local-scenes/**` | L1 |

---

## Chunk 0: Graph floor + ledger

### Task 0.1: GRAPH_FLOOR_OK

**Files:**
- Create: `scripts/graph-floor.sh`
- Create: `scripts/verify-graph-floor.sh`
- Create: `tests/test_c_prime_graph_floor.sh`
- Modify: `scripts/pile-index.sh` (call graph-floor, then echo `PILE_INDEX_OK`)

- [ ] **Step 1: Write failing test** (`tests/test_c_prime_graph_floor.sh`)

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/svc-a/.git" "$TMP/svc-b/.git"
bash "$ROOT/scripts/graph-floor.sh" "$TMP"
out="$(bash "$ROOT/scripts/verify-graph-floor.sh" "$TMP")"
[[ "$out" == "GRAPH_FLOOR_OK" ]]
python3 - <<PY
import json,sys
m=json.load(open("$TMP/docs/vibage/maps/service_map.json"))
assert m.get("discover_mode") in ("flat","nested")
assert len(m.get("repos") or [])>=2
PY
```

- [ ] **Step 2: Run — expect FAIL** (`graph-floor.sh` missing)

Run: `bash tests/test_c_prime_graph_floor.sh`

- [ ] **Step 3: Implement `graph-floor.sh`**

Algorithm (must implement, not “reuse vaguely”):
1. Read optional `$PARENT/docs/vibage/OWNER_POLICY.json` (or `OWNER_POLICY` path if pack already defines one — use `docs/vibage/OWNER_POLICY.json` for C′).
2. If `discover_nested_git==true`: find `.git` dirs under parent with depth ≤ `discover_max_depth` (default 3); **skip submodule `.git` files/dirs unless `include_submodules=true`**; worktrees sharing the same git dir → one `repo_id` + optional `worktree_path` pointer (no duplicate matrix repos); `repo_id` = relpath; `discover_mode=nested`. Else: one-level children with `.git` only; `discover_mode=flat`. Keep existing pile-index fallback: if no child gits and parent is git, index parent alone.
3. Empty discovery: exit 1 with `FAIL: no git repos discovered` (verify also fails). No silent empty OK.
4. Write `service_map.json` as a **compatible evolution** of current pile-index output: keep fields required by `scripts/verify-service-map.sh` / `tests/test_pile_index.sh` (including `services[]` / schema fields those tests assert today — read those files before editing and preserve them). **Add** C′ fields: `discover_mode`, `discover_max_depth`, and `repos[]` (may mirror/derive from `services[]`). Do not break pack-health map gates during freeze.
5. Nested depth beyond Chunk 0 unit test: covered in Chunk 3 friend-chaos (`discover_mode=nested` asserted there).
6. After implementing, run `bash tests/test_pile_index.sh` (or pack-health subset) and keep it green.

- [ ] **Step 4: Implement `verify-graph-floor.sh`** — map exists, JSON ok, `discover_mode` set, `len(repos)>=1`; else FAIL. Print `GRAPH_FLOOR_OK`.

- [ ] **Step 5: Wrapper** — `pile-index.sh` calls `graph-floor.sh "$PARENT"` then prints `PILE_INDEX_OK` on success (freeze compat).

- [ ] **Step 6: Test PASS + commit**

```bash
git add scripts/graph-floor.sh scripts/verify-graph-floor.sh scripts/pile-index.sh tests/test_c_prime_graph_floor.sh
git commit -m "$(cat <<'EOF'
feat(c-prime): graph-floor job and GRAPH_FLOOR_OK

EOF
)"
```

### Task 0.2: Ledger + ROLLUP + LEDGER_SLICE_PROVEN

**Files:**
- Create: `scripts/ledger-append.sh`
- Create: `scripts/verify-ledger-slice.sh`
- Create: `tests/test_c_prime_ledger.sh` (locked — do not fold into graph_floor test)

- [ ] **Step 1: Write failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/docs/vibage/ledger"
bash "$ROOT/scripts/ledger-append.sh" "$TMP" '{"id":"c1","subject_type":"repo","subject_id":"svc-a","claim_class":"floor_identity","statement":"exists","pointers":[{"path":"svc-a/README.md","quote":"# A","branch_ref":"main","env_id":""}],"state":"proven","updated_at":"t","evidence_hash":"h"}'
bash "$ROOT/scripts/ledger-append.sh" "$TMP" '{"id":"c2","subject_type":"repo","subject_id":"svc-a","claim_class":"floor_deps","statement":"no compose deps","pointers":[{"path":"svc-a","quote":"absent","branch_ref":"main","env_id":""}],"state":"proven","updated_at":"t","evidence_hash":"h2"}'
out="$(bash "$ROOT/scripts/verify-ledger-slice.sh" "$TMP" svc-a floor_identity,floor_deps)"
[[ "$out" == "LEDGER_SLICE_PROVEN" ]]
# failed-only must NOT print LEDGER_SLICE_PROVEN
bash "$ROOT/scripts/ledger-append.sh" "$TMP" '{"id":"c3","subject_type":"repo","subject_id":"svc-b","claim_class":"floor_identity","statement":"x","pointers":[{"path":"svc-b","quote":"fail","branch_ref":"main","env_id":""}],"state":"failed","updated_at":"t","evidence_hash":"h3"}'
if bash "$ROOT/scripts/verify-ledger-slice.sh" "$TMP" svc-b floor_identity; then echo "FAIL: failed slice must not be PROVEN"; exit 1; fi
grep -q 'svc-b' "$TMP/docs/vibage/ledger/ROLLUP.md"
```

- [ ] **Step 2: Run — FAIL**

- [ ] **Step 3: Implement `ledger-append.sh`** — append one JSON object line; pointer objects must include `path` (quote recommended); on `state=failed`, upsert subject into `ROLLUP.md` under `## Failed`.

- [ ] **Step 4: Implement `verify-ledger-slice.sh`** — args: `PARENT SUBJECT_ID CLASS1,CLASS2,…` — **all** listed classes must have a claim with `state=proven` for that subject. Print `LEDGER_SLICE_PROVEN` only then. Failed claims are for rollup gaps, not this token.

- [ ] **Step 5: graph-floor appends** for each repo: `floor_identity` + `floor_deps` (deps present-or-absent with evidence pointer) as **proven** when verifiable, else **failed** + ROLLUP (never silent `unproven`). Role summary may live inside `floor_identity.statement` this wave.

- [ ] **Step 6: PASS + commit**

```bash
git commit -m "$(cat <<'EOF'
feat(c-prime): ledger append, ROLLUP.md, LEDGER_SLICE_PROVEN

EOF
)"
```

### Task 0.3: UNDERSTANDING_ROLLUP_OK

**Files:**
- Create: `scripts/verify-understanding-rollup.sh`
- Modify: `tests/test_c_prime_ledger.sh`

- [ ] **Step 1: Extend test** — after graph-floor on TMP with 2 repos and proven floor slices for both, `verify-understanding-rollup.sh` prints `UNDERSTANDING_ROLLUP_OK` **without** any matrix file present.

- [ ] **Step 2: Implement verify** — require `GRAPH_FLOOR_OK`; every repo id has `LEDGER_SLICE_PROVEN` for `floor_identity,floor_deps` **or** appears under ROLLUP Failed; no claim with `state=stale` lacking ROLLUP callout. Matrix files ignored.

- [ ] **Step 3: PASS + commit**

```bash
git commit -m "$(cat <<'EOF'
feat(c-prime): UNDERSTANDING_ROLLUP_OK without matrix

EOF
)"
```

---

## Chunk 1: Matrix + substantive

**Ledger note:** Matrix cells are SSOT in `env_branch_matrix.json` for `ENV_BRANCH_MATRIX_OK` / substantive. Optional `branch_env_cell` ledger mirrors are **deferred** (not required for P1 tokens).

### Task 1.1: Inventory + ENV_BRANCH_MATRIX_OK

**Files:**
- Create: `scripts/matrix-inventory.sh`
- Create: `scripts/verify-env-branch-matrix.sh`
- Create: `tests/test_c_prime_matrix.sh`

- [ ] **Step 1: Write failing tests in `tests/test_c_prime_matrix.sh`** covering:
  1. Pre-seeded terminal matrix JSON (all proven/failed, zero unknown-env) → verify prints `ENV_BRANCH_MATRIX_OK` (tests verify before sweep-cell exists).
  2. All cells `missing-env-config` only → verify **fails** unless `OWNER_POLICY.json` has `env_vacancy_waiver=true` + reason → then matrix OK.
  3. `unknown-env` present → verify fails.
  4. `status=overflow` → verify fails.
  5. Extra branches beyond cap recorded as `failed`/`branch_cap` still allow OK if other rules hold (not treated as overflow).

- [ ] **Step 2: Run — FAIL**

- [ ] **Step 3: Implement `matrix-inventory.sh`** — bounded branches (default globs + default/current + deploy-named); real envs from compose/ci; sparse product; caps 30 / 500; overflow vs branch_cap per spec; write `docs/vibage/maps/env_branch_matrix.json` + `docs/vibage/maps/inventory_manifest.json` (1:1 rows).

- [ ] **Step 4: Implement `verify-env-branch-matrix.sh`** per spec §2.3 verify list.

- [ ] **Step 5: PASS for verify cases + commit**

### Task 1.2: Evidence extract + sweep-cell + substantive

**Files:**
- Create: `scripts/matrix-extract-evidence.py`
- Create: `scripts/matrix-sweep-cell.sh`
- Create: `scripts/verify-matrix-substantive.sh`
- Modify: `tests/test_c_prime_matrix.sh`

- [ ] **Step 1: Failing tests** — extract returns path+quote for compose env; sweep sets proven; all-failed real-env → substantive FAIL; all proven real-env → `MATRIX_SWEEP_SUBSTANTIVE_OK`; waiver never grants substantive; missing-env/unknown-env block substantive.

- [ ] **Step 2: Implement extract** — input parent, repo_id, branch_ref, env_id → stdout JSON pointers. For non-current `branch_ref`, use `git show "$branch_ref:path"` (or equivalent) so quote matches that branch; pointers must include `path`, `quote`, `branch_ref`, `env_id`.

- [ ] **Step 3: Implement sweep-cell** — calls extract; on success state=proven; on timeout/error state=failed with reason; never leave unproven after `--sweep-started`.

- [ ] **Step 4: Implement verify-matrix-substantive.sh**

- [ ] **Step 5: PASS + commit**

```bash
git commit -m "$(cat <<'EOF'
feat(c-prime): matrix evidence sweep and MATRIX_SWEEP_SUBSTANTIVE_OK

EOF
)"
```

### Task 1.3: c-prime-fill.sh

**Files:**
- Create: `scripts/c-prime-fill.sh`

- [ ] **Step 1: Test** — tiny parent with 2 repos + compose envs → fill → `ENV_BRANCH_MATRIX_OK` (and substantive if all extractable).

- [ ] **Step 2: Implement** — graph-floor → matrix-inventory → for each cell run sweep-cell with parallelism `min(8,n)` via `xargs -P`; cell timeout → failed + continue.

- [ ] **Step 3: PASS + commit**

---

## Chunk 2: Scenes + briefs

### Task 2.1: scene-validate + classify

**Files:**
- Create: `scripts/scene-validate.sh`
- Create: `scripts/scene-classify.sh`
- Create: `tests/test_c_prime_scenes.sh`

- [ ] **Step 1: Failing tests** — illegal partial membership fails; exclusive+shared OK; classify matches `title|scene_id|keywords[]` (exactly one → print id exit 0; zero → exit 2; ≥2 → exit 3).

- [ ] **Step 2: Implement both scripts** reading `SCENES.json` (`keywords[]` field required in schema; may be empty only if owner always sets scene explicitly — classifier still matches title/scene_id).

- [ ] **Step 3: PASS + commit**

### Task 2.2: scene-brief + verifies + bridges

**Files:**
- Create: `scripts/scene-brief.sh`
- Create: `scripts/verify-brief.sh`
- Create: `scripts/verify-scene-brief.sh`
- Modify: `tests/test_c_prime_scenes.sh`

- [ ] **Step 1: Failing tests** for full `SCENE_BRIEF_OK` checklist: membership legal; `brief.scene_id == STATUS.active_scene`; repos ⊆ graph; hot edges terminal; `required_bridges = E_active ↔ (exclusive(other)∪shared)`; bridges listed == required and terminal via `scene_bridge` ledger claims; budget header; `scenes_draft!=true`; **matrix files absent still OK**.

- [ ] **Step 2: Implement scene-brief.sh** — writes `docs/vibage/briefs/<scene_id>.md` with YAML/header `max_tokens: 6000` and `scene_id:`; on switch deletes/marks stale prior scene brief; appends `scene_bridge` claims for required bridges (proven/failed).

- [ ] **Step 3: Implement `verify-brief.sh`** — for a path or scope id, require budget header + non-empty body; print **`BRIEF_USABLE_OK`**. Add failing test that asserts this exact token.

- [ ] **Step 4: Implement `verify-scene-brief.sh`** (must invoke scene-validate; full checklist); print `SCENE_BRIEF_OK`.

- [ ] **Step 5: PASS + commit**

```bash
git commit -m "$(cat <<'EOF'
feat(c-prime): scene brief, bridges, SCENE_BRIEF_OK

EOF
)"
```

### Task 2.3: verify-scene-cover.sh (required)

**Files:**
- Create: `scripts/verify-scene-cover.sh`

- [ ] **Step 1: Implement cover iff** — ≥2 scenes or single_scene_waiver; SCENE_BRIEF_OK; if ≥2 and no isolation_waiver: ≥1 exclusive↔exclusive cross_scene_edge AND ≥1 terminal scene_bridge on required_bridges; shared-only edges insufficient.

- [ ] **Step 2: Tests in test_c_prime_scenes.sh** — cover fails without cross edge; passes with fixture-shaped mini graph.

- [ ] **Step 3: Commit**

---

## Chunk 3: Fixtures (sync deferred)

**Deferred:** slice/cell stale sync (§2.5) — not required for P3 green; note in STATUS when On-tree flips.

### Task 3.1: friend-chaos

**Files:**
- Create: `tests/fixtures/c-prime/friend-chaos/setup.sh` + tree
- Create: `tests/test_c_prime_fixtures.sh`

- [ ] **Step 1: setup.sh** creates ≥10 micro-repos, **≥2 branches each** (names matching default globs), ≥2 real env configs, ≥1 nested git sample, `OWNER_POLICY.json` with `discover_nested_git=true`, **no** `env_vacancy_waiver`.

- [ ] **Step 2: test asserts** after `c-prime-fill`: `GRAPH_FLOOR_OK`; map `discover_mode=nested`; nested repo in `repos`; `ENV_BRANCH_MATRIX_OK`; `MATRIX_SWEEP_SUBSTANTIVE_OK`.

- [ ] **Step 3: PASS + commit**

### Task 3.2: local-scenes

- [ ] **Step 1: Fixture** — scenes architecture/x402/quant/mindblow; `keywords[]` non-empty each; `seed_method=fixture`; `scenes_draft` false; ≥1 shared hub; ≥1 exclusive per scene; ≥1 exclusive↔exclusive edge; no isolation_waiver.

- [ ] **Step 2: test** — set active_scene → scene-brief → `SCENE_BRIEF_OK` → `verify-scene-cover.sh` exit 0; switch scene → prior brief gone/stale, matrix mtime unchanged; cover still holds.

- [ ] **Step 3: PASS + commit**

```bash
git commit -m "$(cat <<'EOF'
test(c-prime): friend-chaos and local-scenes fixtures

EOF
)"
```

---

## Chunk 4: Skills (STATUS flip in Chunk 5)

### Task 4.1: Continuum + skills + adapters

**Files:**
- Modify: `skills/using-vibage/SKILL.md`
- Modify: `skills/vibage-pile-index/SKILL.md`
- Modify: `skills/vibage-map-deepen/SKILL.md`
- Modify: `skills/vibage-orient/SKILL.md`
- Modify: `skills/vibage-issue-locate/SKILL.md`
- Modify: `adapters/cursor/vibage.mdc`
- Modify: `adapters/claude/CLAUDE.vibage.md`
- Modify: `adapters/codex/AGENTS.vibage.md`
- Modify: `adapters/shared/AGENTS.vibage.md`
- Create: `tests/test_c_prime_skills_copy.sh`

- [x] **Step 1: Continuum text** = `PROJECT_ENTRY_OK` → hub → `GRAPH_FLOOR_OK` → matrix sweep → **optional deferred dimension fill** → ticket **or** scene switch → **`SCENE_BRIEF_OK` when scene set** → orient → CONFIRM → locate. Dimension fill explicitly **deferred** this plan.

- [x] **Step 2: Gate A slogans** — 掃透 only `MATRIX_SWEEP_SUBSTANTIVE_OK`; scene cover via verify-scene-cover; pile-index/deepen must not say system understood.

- [x] **Step 3: issue-locate** — consume briefs/ledger pointers; ignore deepen-as-auth.

- [x] **Step 4: Grep test** — fail if skills/adapters contain install→ready, vector db, RAG-as-memory, or “system understood” tied to PILE_INDEX/MAP_DEEPEN.

- [x] **Step 5: Commit** (do **not** flip STATUS On-tree yet)

### Task 4.2: Freeze-lift note

**Files:**
- Create: `docs/superpowers/specs/2026-07-25-vibage-c-prime-freeze-lift.md`

- [x] **Step 1: Document** dual-substrate ban lifts only when pile-index is wrapper, deepen not “understood”, and sessions do not run old+new nested substrates together; sync still deferred.

- [x] **Step 2: Commit**

---

## Chunk 5: Suite + STATUS On-tree

- [x] **Step 1: Archive SSOT guard**

Run: `rg -n 'docs/archive/2026-07-24-pre-c-prime/plans' skills adapters scripts docs/superpowers/plans/*.md || true`  
Expected: no hit treating archive as executable checklist (mentions “do not execute” OK).

- [x] **Step 2: Full suite**

Run: `bash tests/test_c_prime_graph_floor.sh && bash tests/test_c_prime_ledger.sh && bash tests/test_c_prime_matrix.sh && bash tests/test_c_prime_scenes.sh && bash tests/test_c_prime_fixtures.sh && bash tests/test_c_prime_skills_copy.sh && bash tests/test_pile_index.sh`  
Expected: all PASS (pile-index compat still green)

- [x] **Step 3: STATUS flip** — C′ row `Designed=YES`, `On-tree=YES`, `Proven-green=NO`; keep honesty banner; note sync deferred; **not** wired to Tier-0/pack-health.

- [x] **Step 4: Update** `docs/superpowers/plans/README.md` + design doc Status to point at this live plan.

- [x] **Step 5: Commit**

```bash
git commit -m "$(cat <<'EOF'
docs(c-prime): On-tree after c-prime verify suite (Proven-green still NO)

EOF
)"
```

---

## Out of scope

- Vector/embedding/RAG; SaaS; Gate B replacement; sync implementation; dimension fill; Tier-0 membership; agent Proven-green / letter B.
