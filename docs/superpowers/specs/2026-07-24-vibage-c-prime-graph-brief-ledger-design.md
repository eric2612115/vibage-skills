# Vibage C′ — Graph + Brief + Evidence Ledger

**Status:** Design-FULL; implementation plan live at `docs/superpowers/plans/2026-07-25-vibage-c-prime-graph-brief-ledger.md` (index: `…-plan-index.md`). **On-tree=YES / Proven-green=NO** after plan Chunk 5 (sync deferred; ∉ Tier-0). Freeze-lift: `2026-07-25-vibage-c-prime-freeze-lift.md`.  
**Date:** 2026-07-24  
**Package:** `vibage-skills`  
**Target (understanding substrate):** replace “thin pile-index / short deepen = understood” with graph + brief + evidence ledger  
**Does not supersede:** parent session entry; orient → CONFIRM → `assert_gate` → locate authorization; SaaS-blank honesty  

**Archived prior plans (do not execute as C′ SSOT):**  
`docs/archive/2026-07-24-pre-c-prime/plans/`

**Freeze lift:** Dual-substrate ban lifts per `2026-07-25-vibage-c-prime-freeze-lift.md` (pile-index wrapper, deepen ≠ understood, no old+new nested substrates in one session). **Still deferred:** sync (§2.5), dimension fill, Tier-0 wiring, Proven-green.

---

## §1 — Understanding substrate (rewritten; post-review)

### Product one-liner

“Understanding a multi-repo mother directory” means maintaining three on-disk artifacts under the parent hub:

1. **Graph** — structural index of repos, packages, explicit dependency / deploy / config edges, path-level nodes; incremental; stale-aware.  
   Owner language: “map usability” = whether this graph is fresh enough to navigate — **not** legacy `PILE_INDEX_OK` full-understanding narrative.  
2. **Brief** — token-budgeted navigation packs compiled for a task / repo / change-set (what to open, known warnings, relevant edges).  
3. **Evidence ledger** — every claim carries path / quote / branch / deploy pointers and state: `proven` | `unproven` | `stale` | `failed`.

Agents **fill and verify** these artifacts with tools and nested workers. They do **not** stuff all repo sources into one context, and they do **not** treat embeddings as understanding.

### Explicitly out of scope

- Embedding pipelines  
- Vector databases  
- RAG as primary or secondary memory for code understanding  

Retrieval = **agentic search** (glob / ripgrep / read) guided by graph + brief.

### Architecture (two gates — do not merge)

```mermaid
flowchart TB
  code[Mother_dir_repos] --> indexJob[Structural_index_job]
  indexJob --> graph[(Graph_SSOT)]
  graph --> matrixJob[Matrix_inventory_and_cell_workers]
  matrixJob --> matrix[(Env_branch_matrix)]
  matrix --> ledger[(Evidence_ledger)]
  graph --> scenes[Scene_registry]
  scenes --> brief[Bounded_brief_compiler]
  matrix --> brief
  ledger --> brief
  graph --> synth[Repo_synthesizers]
  synth --> dim[Dimension_searchers]
  dim --> ledger
  change[Git_or_file_change] --> invalidate[Mark_stale_reindex_slice]
  invalidate --> indexJob
  invalidate --> matrixJob
  ledger --> narrGate{Narrative_OK}
  matrix --> narrGate
  scenes --> narrGate
  narrGate -->|tokens_hold| narrYes[May_claim_covered_slice]
  narrGate -->|else| narrNo[Honest_partial]
  ticket[Ticket_or_scene_switch] --> brief
  ticket --> orient[Orient_CONFIRM_assert_gate]
  orient --> dig[Locate_dig_authorized]
  brief --> dig
  ledger --> dig
```

**Gate A — Narrative honesty (C′):**  

| Claim language | Requires |
|----------------|----------|
| Understood floor / qualified map | `UNDERSTANDING_ROLLUP_OK` only (§2.3) — **does not** require matrix |
| 矩陣已無漏掃（終態） | `ENV_BRANCH_MATRIX_OK` |
| 全環境全 branch 掃透 | `MATRIX_SWEEP_SUBSTANTIVE_OK` only (§2.3; implies matrix OK + all real-env cells proven) |
| 多領域立體場景切換 | `SCENE_BRIEF_OK` **and** `verify-scene-cover.sh` exit 0 — BRIEF alone ≠ cover; **does not** require matrix |

**Gate B — Dig authorization:** orient → CONFIRM → `assert_gate` (or `MAP_SKIP`).  

**Gate A ≠ Gate B.** Matrix/scene **read/index/sweep workers are not dig** — they only write hub artifacts under `docs/vibage/`. Editing product/business code still requires Gate B. Incomplete matrix may accept tickets but must announce matrix incomplete (§3.1).

### Nested workers (names — avoid model-routing L1/L2 clash)

| Worker | Role |
|--------|------|
| **Orchestrator** | Discover topology; run matrix inventory; dispatch cell workers + repo synthesizers; scene seed assist; rollup |
| **Matrix cell worker** | One `{repo, branch_ref, env_id}` cell → `proven` or `failed` with pointers (automatic after floor) |
| **Repo synthesizer** | Per-repo dossier; dispatch dimension searchers |
| **Dimension searcher** | One repo × one non-matrix dimension (behavior, tests, security, …) — **not** a substitute for matrix sweep |

Cross-layer payload: **summaries + pointers only**. Ground truth = on-disk graph / matrix / brief / ledger / scenes.

### Cold start (empty ledger)

1. Structural index → `GRAPH_FLOOR_OK` path  
2. Matrix inventory + cell workers → terminal cells → `ENV_BRANCH_MATRIX_OK`  
3. Scene registry seed (rules in §2.10) + briefs  
4. Optional dimension fill  

Until matrix complete: may not claim 矩陣終態／掃透／install→ready.  
`UNDERSTANDING_ROLLUP_OK` and scene cover remain independently attainable per Gate A table.

### User cognition surface

Humans see: graph usability, matrix completion %, active scene, brief hot path, proven/failed/stale counts, next step — not worker internals.

### Inherit vs replace

| Keep | Replace as “understood” definition |
|------|-------------------------------------|
| Parent `PROJECT_ENTRY_OK` | `PILE_INDEX_OK` = full understanding narrative |
| orient → CONFIRM → locate dig auth | Short deepen = “system understood” |
| Milestone honesty chain | install→ready slogan |
| SaaS / register blank | — |

### Industry alignment (non-normative)

Graph + bounded brief + evidence-backed ledger (Cartographer / Contextful-class), not “embed and done.”

---

## §2 — Milestones, migration, sync, ownership

### 2.1 New milestone tokens (names frozen here)

| Token | Meaning | ≠ |
|-------|---------|---|
| `GRAPH_FLOOR_OK` | Structural index job + verify: graph file present, schema valid, floor nodes for discovered repos | ≠ understood; ≠ CONFIRM |
| `BRIEF_USABLE_OK` | Brief compiler can emit a budgeted brief for a given scope id | ≠ dig auth |
| `LEDGER_SLICE_PROVEN` | Named slice (repo id or edge set) has required claim classes in `proven` | ≠ full mother-dir understood |
| `UNDERSTANDING_ROLLUP_OK` | Mother-dir rollup policy satisfied (see 2.3) — narrative “qualified map for locate prep” allowed | ≠ Architecture Pass; ≠ dig auth; ≠ locate DONE |
| `ENV_BRANCH_MATRIX_OK` | Inventory complete, 1:1 rows, every cell `proven` or `failed`, no overflow, env vacancy rules held | ≠ 掃透 slogan; ≠ dig auth |
| `MATRIX_SWEEP_SUBSTANTIVE_OK` | `ENV_BRANCH_MATRIX_OK` **and** discovery set has ≥1 real-env cell **and** every real-env cell is `proven` with non-empty evidence (any real-env `failed` ⇒ not OK) **and** zero `missing-env-config` cells remain **and** `env_vacancy_waiver` never grants this token | 終態 alone ≠ 掃透 |
| `SCENE_BRIEF_OK` | Active scene brief verifies (`active_scene` match, bridges terminal, not draft) | ≠ dig auth; ≠ matrix |

Legacy tokens remain valid for **shipped runtime** until migration completes:

| Legacy | Post-migration fate |
|--------|---------------------|
| `PILE_INDEX_OK` | Becomes producer of `GRAPH_FLOOR_OK` (or thin wrapper); loses “understood” narrative rights |
| `MAP_DEEPEN_OK` | Becomes optional path into repo synthesizer / dimension searcher verify; not a second substrate |
| `service_map.json` | Evolves into or is generated from Graph SSOT (single file identity — see 2.2); no parallel competing map |
| dossiers under `docs/vibage/dossiers/` | Become ledger-backed notes / brief inputs; must cite ledger ids |

**STATUS rule:** C′ capability row must stay Designed/On-tree/Proven-green accurate. Mixing legacy green with “C′ substrate done” is forbidden.

### 2.2 On-disk identity (no vector)

Hub parent paths (normative target):

| Artifact | Path (target) | Notes |
|----------|---------------|-------|
| Graph SSOT | `docs/vibage/maps/service_map.json` (evolved schema) + optional `docs/vibage/maps/graph.mmd` fail-soft render | One structural SSOT; prettier Mermaid ≠ proof |
| Branch/env matrix | `docs/vibage/maps/env_branch_matrix.json` | Cells: `{repo_id, branch_ref, env_id, pointers[], state}` |
| Domain/scene registry | `docs/vibage/scenes/SCENES.json` | Scene ids + repo membership + default hot edges |
| Briefs | `docs/vibage/briefs/<scope_id_or_scene_id>.md` (or `.json`) | Token budget header; must declare `scene_id` when set |
| Ledger | `docs/vibage/ledger/claims.jsonl` + `docs/vibage/ledger/ROLLUP.md` | Each claim: id, subject, statement, pointers[], state, updated_at, optional `scene_id` |

Verify scripts (names locked for plan): `verify-graph-floor.sh`, `verify-brief.sh`, `verify-ledger-slice.sh`, `verify-env-branch-matrix.sh`, `verify-matrix-substantive.sh`, `verify-scene-brief.sh` — print tokens in 2.1. **No** embedding/index service.

### 2.3 Rollup policy (when narrative may say qualified)

`UNDERSTANDING_ROLLUP_OK` (mother-dir floor qualified) requires:

1. `GRAPH_FLOOR_OK`  
2. For every repo id in the **discovery set**: `LEDGER_SLICE_PROVEN` for floor claim classes (identity, role summary, explicit deps edges present-or-absent with evidence), **or** terminal `failed` listed in ROLLUP (not silent `unproven`)  
3. No `stale` nodes in discovery set without callout  

**Friend chaos bar — `ENV_BRANCH_MATRIX_OK` (矩陣終態／無漏掃; 掃透另需 `MATRIX_SWEEP_SUBSTANTIVE_OK`):**

**Discovery set** = repos admitted by §2.12 (`discover_mode` recorded on graph). Same term everywhere (“in-scope” = discovery set unless scene brief narrows read set).

**Branch refs (bounded):** for each repo, collect:  
- default branch + current worktree branch + branches matching `OWNER_POLICY.branch_globs` (default: `main|master|develop|release/*|staging|prod|production`) + any branch named in deploy/ci configs;  
- **not** unbounded raw `git branch -a` unless `OWNER_POLICY.branch_enumerate=all` **and** `max_branches_per_repo` (default 30) not exceeded — overflow → extra refs recorded as `failed` cells with reason `branch_cap`, still terminal.

**Env ids (real set, no cheat):**  
- Parse deploy/compose/k8s/helm/terraform/ci for concrete env names; merge `OWNER_POLICY.env_aliases`.  
- If **zero** envs found for a repo → one cell `env_id=missing-env-config` with state **`failed`** (pointer to search roots).  
- **`ENV_BRANCH_MATRIX_OK` is FALSE** if every env in the mother-dir matrix is only `missing-env-config` / `unknown-env` **unless** owner records `OWNER_POLICY.env_vacancy_waiver=true` with reason (friend-chaos fixture must supply ≥2 real envs — waiver forbidden in that fixture).  
- `unknown-env` allowed only as temporary during inventory build; must resolve to a real env or `missing-env-config` before sweep completes.

**Inventory = sparse product, not naive bomb:**  
- Include cell `(repo, branch, env)` iff (a) branch in bounded branch set AND (b) env is attached to that repo by config **or** env is in mother-dir global env list AND repo has deploy participation edge;  
- Plus mandatory cells: `(repo, default_branch, env)` for every real env linked to repo.  
- Hard cap: `max_cells = OWNER_POLICY.max_matrix_cells` (default **500**). Over cap → inventry stops, matrix status `overflow`, **`ENV_BRANCH_MATRIX_OK` = FALSE** until owner raises cap or globs; must not silently drop cells without `overflow` record.

**Terminal rule:** every inventoried cell → `proven` or `failed`. After sweep starts, **`unproven` forbidden**. Sweep **automatic after `GRAPH_FLOOR_OK`**.  

**Verify (`verify-env-branch-matrix.sh`) must check:** inventory manifest 1:1 with matrix rows; no silent `unproven`; **zero `unknown-env` cells** (must resolve before OK); no all-missing-env green without waiver; overflow ⇒ not OK; print `ENV_BRANCH_MATRIX_OK` when those hold.

**Verify (`verify-matrix-substantive.sh`) must check:** `ENV_BRANCH_MATRIX_OK`; ≥1 real-env cell; zero `missing-env-config`; zero `unknown-env`; zero `failed` among real-env cells; every real-env cell `proven` with pointers containing non-empty `path` **and** `quote` (or verifiable `evidence_hash`) matching that cell’s `branch_ref`/`env_id`; `env_vacancy_waiver` never grants 掃透; print `MATRIX_SWEEP_SUBSTANTIVE_OK`.

| Slogan | Token |
|--------|-------|
| 矩陣已無漏掃／終態 | `ENV_BRANCH_MATRIX_OK` |
| 全環境全 branch 已掃透 | `MATRIX_SWEEP_SUBSTANTIVE_OK` only (all real-env cells proven — not “mostly failed + one proven”) |

**Local stereoscopic bar — domain/scene lens:** see §2.10. **Independent of matrix** for the scene-switch cover claim.

### 2.4 Skill ownership

| Current skill / script | C′ role |
|------------------------|---------|
| `vibage-pile-index` / `pile-index.sh` | Structural index job → `GRAPH_FLOOR_OK` |
| `vibage-map-deepen` | Migrate into orchestrated repo synthesizer + dimension searchers; verify becomes ledger-slice proof — **retire** as alternate “understood” brand |
| `using-vibage` | Continuum router; narrative honesty from ledger; still Gate B for dig |
| `vibage-orient` / `vibage-issue-locate` | Unchanged dig auth; consume briefs + ledger pointers; still ignore deepen-as-auth |

### 2.5 Sync contract

| Trigger | Action |
|---------|--------|
| Child repo HEAD / worktree hash change | Mark that repo slice `stale`; invalidate dependent edges; refresh brief for open scopes **and active scene** |
| New/removed branch or env config path | Rebuild affected matrix rows; re-sweep those cells to `proven`/`failed` |
| Compose / deploy / package manifest change | Re-run floor edges + matrix cells touching that env |
| Scene registry edit | Invalidate briefs for that `scene_id`; require `SCENE_BRIEF_OK` rebuild before scene narrative |
| Ledger claim pointer file missing / hash mismatch | Claim → `failed` or `stale`; rollup/matrix lose narrative rights for that slice/cell |
| Session start | Report stale + incomplete matrix counts; auto continue matrix sweep if previously incomplete |

Sync is **slice/cell/scene-scoped**, not silent unmarked full rewrite.

### 2.6 Failure / locate-on-error

On worker or verify failure: write `failed` claim with pointer; STOP or continue other slices per orchestrator policy; surface path to mother-dir ledger row + code pointer.  
Handoff / dual reports remain locate-wave shaped (existing `verify-handoff`); C′ does not invent a second handoff pipeline in v1.

### 2.7 Continuum (authoritative order)

`PROJECT_ENTRY_OK` → hub → `GRAPH_FLOOR_OK` → **matrix sweep** (aim `ENV_BRANCH_MATRIX_OK`, then substantive) → repo/dimension fill → ticket **or scene switch** → `SCENE_BRIEF_OK` when scene set → orient → CONFIRM → locate dig → locate DONE.  

`UNDERSTANDING_ROLLUP_OK` = `GRAPH_FLOOR_OK` + floor slices terminal for discovery set (**matrix not required**).  
Matrix / substantive / scene tokens are **additional** Gate A slogans. None authorize dig. SaaS blank unchanged.

### 2.8 Testing / proof / STATUS

| Layer | Rule |
|-------|------|
| Script proof | New verify tokens green in tests; may join pack-health only when explicitly wired |
| Agent proof | Separate; never inferred from script green |
| STATUS capability row | `C′ graph/brief/ledger` — Designed=YES; On-tree=YES after Chunk 5 suite; Proven-green=NO; sync deferred; ∉ Tier-0 |
| Design-coverage (this brainstorm) | Friend + local bars in §2.11 must be design-FULL before writing-plans; On-tree remains independent |

### 2.9 Implementation plan pointer

After full design approval + writing-plans: create a **new** plan under `docs/superpowers/plans/` (not revive archived pre-C′ plans).

### 2.10 Domain / scene lens (multi-domain stereoscopic cover)

**Problem:** One mother dir may host interdependent piles under different scenes (e.g. `architecture`, `x402`, `quant`, `mindblow`).

**Artifacts**

- `docs/vibage/scenes/SCENES.json`: `{ scene_id, title, keywords[], repo_ids[], hot_edge_ids[], default_env_ids[], notes, seed_method }`  
  (`keywords[]` required for classifier; may be empty only if owner always sets scene explicitly)  
- `docs/vibage/scenes/WAIVERS.json`: optional `{ single_scene_waiver?, isolation_waiver?, reason, at }`  
  (`isolation_waiver` = allow stereoscopic cover with ≥2 scenes but zero cross-scene exclusive edges — rare; **forbidden** in `local-scenes` fixture)  
- Active scene: hub `docs/vibage/STATUS.md` → `active_scene: <scene_id>` (required when any scene brief is used).

**Seed (deterministic, not magic):**

1. Prefer owner-edited `SCENES.json`.  
2. Else **fixture/manual seed** for first run.  
3. Else **assist draft only**: suggest scenes from top-level dir name clusters + connected components of graph edges; write `seed_method=assist_draft` and state `scenes_draft=true` in STATUS.  
4. **`SCENE_BRIEF_OK` is FALSE while `scenes_draft=true`.** Owner must accept/edit scenes (`seed_method=owner` or `fixture`) before cover claim.  
5. Auto heuristics alone never count as stereoscopic cover.

**Classifier:** ticket → scene only if exactly one scene’s `title|scene_id|keywords[]` matches; 0 matches → ask owner; ≥2 → ask owner. No silent pick.

**Switch behavior**

1. Set `STATUS.active_scene`; invalidate prior scene brief only.  
2. Compile brief for that scene; budget enforced; non-scene repos = one-line stubs + **bridge list**.  
3. **Membership (closed):** each repo is exactly one of:  
   - `exclusive(scene_id)` — listed in exactly one scene  
   - `shared` — listed in **every** scene (bridge hub)  
   - **Illegal:** listed in some but not all scenes when ≥2 scenes exist → `SCENE_BRIEF_OK` FALSE until fixed  
4. **`cross_scene_edge` (cover math):** graph edge with **both** ends `exclusive` and **different** `home scene`. Shared hubs are **not** valid endpoints for satisfying cover’s cross-scene requirement.  
5. **Bridge SSOT for active brief:** let `E_active` = repos with `exclusive(active_scene)`. `required_bridges` = graph edges with one end in `E_active` and the other end in (`exclusive(other_scene)` ∪ `shared`). (Do **not** use “∉ active `repo_ids`” — shared hubs are listed in every scene’s `repo_ids` and would be wrongly excluded.) Brief lists exactly these; each → `scene_bridge` `proven|failed`. Non-empty required + empty list ⇒ FALSE.  
6. Must **not** wipe graph/matrix; reuse terminal cells.  
7. `verify-scene-brief.sh` → `SCENE_BRIEF_OK` iff: membership legal; brief `scene_id` == `STATUS.active_scene`; repos ⊆ graph; hot edges terminal; bridges == required_bridges and terminal; budget header; `scenes_draft!=true`. **Matrix tokens not required.**

**Cover claim “多領域立體場景切換”** iff **all** of:

1. ≥2 owner/fixture scenes **or** valid `single_scene_waiver`  
2. `SCENE_BRIEF_OK` after switch + `active_scene` match  
3. If ≥2 scenes and **no** `isolation_waiver`: ≥1 `cross_scene_edge` (exclusive↔exclusive, different homes) **and** ≥1 terminal `scene_bridge` claim on a `required_bridges` entry for the active scene (shared-only edges never satisfy this alone). Zero exclusive cross edges / all-shared membership ⇒ cover FALSE without `isolation_waiver`.  
4. Does **not** require matrix 掃透  

`local-scenes` fixture: ≥1 shared hub, ≥1 exclusive repo per scene, ≥1 exclusive↔exclusive `cross_scene_edge`; `isolation_waiver` forbidden.

### 2.11 Design-coverage acceptance (friend + local) — stop bar for review loop

Judges design text only (not On-tree). **Both** must be FULL:

| ID | Scenario | FULL iff spec provides |
|----|----------|------------------------|
| F1 | Friend multi-MS + branches + envs | Nested discovery; bounded sparse matrix + caps; no unknown-env cheat; auto sweep; `ENV_BRANCH_MATRIX_OK` + `MATRIX_SWEEP_SUBSTANTIVE_OK` for 掃透 slogan; sync; `friend-chaos` forbids env vacancy waiver |
| L1 | Local multi-domain stereoscopic | `keywords[]` + classifier rules; owner/fixture scenes; switch + `active_scene`; bridge terminal; `SCENE_BRIEF_OK`; matrix reuse optional; **cover independent of matrix**; `local-scenes` |

**Shared shell:** same graph/brief/ledger/matrix/scene machinery for both — no second product.

**Forbidden false cover:** claiming FULL while cells may stay silently `unproven`; claiming scene cover without switch+brief verify; conflating design-FULL with On-tree Proven-green.

### 2.12 Discovery depth (mega-microservice)

| Mode | When | Rule |
|------|------|------|
| `flat` (default) | no policy | git children depth=1 under mother |
| `nested` | `OWNER_POLICY.discover_nested_git=true` | walk max `discover_max_depth` (default **3**); include `.git` dirs; skip submodules unless `include_submodules=true`; each repo_id = relpath from mother |
| Friend fixture | `friend-chaos` | **must** set `discover_mode=nested` and include ≥1 nested sample |

Worktrees: count as same `repo_id` with `worktree_path` pointer; do not duplicate matrix repos.  
Graph field `discover_mode` + `discover_max_depth` required for `GRAPH_FLOOR_OK`.

### 2.13 Gate B vs matrix/scene (boundary)

| Action | Gate |
|--------|------|
| Write/update graph, matrix, ledger, scenes, briefs under `docs/vibage/` | No CONFIRM |
| Read any branch/env configs for matrix cell evidence | No CONFIRM |
| Edit business/product code, open locate dig, issue-fix | Gate B (CONFIRM/assert_gate) |

Matrix incomplete ≠ block ticket intake; blocks **矩陣終態／掃透** slogans only.  
`UNDERSTANDING_ROLLUP_OK` / scene cover are independent Gate A tracks (see tables above).

---

## §3 — Budgets, schema sketches, fixtures (minimum to keep F1/L1 design-FULL)

### 3.1 Concurrency / caps / error budget

- Parallelism: `min(8, n_cells)` (override OK).  
- Caps: `max_branches_per_repo=30`, `max_matrix_cells=500` (see §2.3).  
- Cell timeout → `failed`; continue.  
- Incomplete/overflow matrix → tickets OK with disclosure; **no** 掃透 claim.  
- Dimension fan-out remains owner/ticket scoped; **matrix sweep is separate and automatic**.

### 3.2 Claim schema (minimum fields)

`id, subject_type, subject_id, claim_class, statement, pointers[{path,quote,branch_ref,env_id}], state, scene_id?, updated_at, evidence_hash`

`claim_class`: `floor_identity`, `floor_deps`, `branch_env_cell`, `dimension_*`, `scene_bridge`.

### 3.3 Brief budget

Default `max_tokens` 6k; non-scene repos → stub + bridge list (bridge claims terminal).

### 3.4 Fixtures (names locked; paths reserved ≠ On-tree proof)

- `tests/fixtures/c-prime/friend-chaos/` — ≥10 micro-repos, ≥2 branches each via globs, ≥2 **real** env configs, nested-git sample, `discover_mode=nested`; waiver env vacancy **forbidden**.  
- `tests/fixtures/c-prime/local-scenes/` — four scenes owner-seeded (`architecture`, `x402`, `quant`, `mindblow`), shared bridge repos, `scenes_draft=false`.  

Creating empty directories does **not** make design On-tree or Proven-green.

---

## §4+ — TBD after design-FULL gate

Pack-health wiring order, exact JSON schemas, skill text diffs — implementation plan only.
