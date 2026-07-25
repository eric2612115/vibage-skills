# Vibage Honesty Follow-up Design (Opus gaps ①②③)

**Date:** 2026-07-25  
**Status:** Design-FULL (implement after plan + review APPROVE)  
**Trigger:** Opus 5 eval (66/100) + owner: satisfy STATUS lint, live Gate B locate evidence, deliverable narrative token lint  
**Baseline commit:** `e8aa1eb` (`PRESSURE-MATRIX-20260725T123404Z`)  
**Parent design:** C′ graph/brief/ledger; W1–W4 next-waves roadmap  

## 1. Goals

| ID | Goal | Success token / artifact |
|----|------|---------------------------|
| **①** | Capability SSOT table shape is machine-checkable; fix W3a column shift | `STATUS_CAPABILITY_TABLE_OK` + corrected `STATUS.md` W3a row |
| **②** | Live parent proves CONFIRM → assert_gate → locate → dual reports (degraded OK) | `GATE_B_LOCATE_OK` evidence pack under `docs/evidence/c-prime/` |
| **③** | Deliverable reports: slogan words require Held tokens | `verify-report.sh` token lint + `VERIFY_REPORT_TOKENS_OK` test |

## 2. Non-goals / honesty locks

- ≠ chat-level narrative firewall (lint is deliverable-only)
- ≠ remove C′ Proven-green live panel requirement
- ≠ flip package `STATUS.md` C′ / Focus / letter B Proven-green from this wave
- ≠ claim live 掃透 or live stereoscopic scene cover
- ≠ Sync contract DONE; ≠ issue-fix quality
- ≠ wire ①/③ into Tier-0 / pack-health (W4 thin stays graph_floor+ledger)
- ≠ read real `.env`; no register CTA
- Parent restore after ②: may delete live `docs/vibage` + root `VIBAGE-ISSUE-*` after copying into evidence

## 3. Gap ① — STATUS capability table lint

### 3.1 Fix W3a row

Current (misaligned):

```markdown
| **C′ W3a dimension fill** | YES | P0–P2 | script | On-tree (`DIMENSION_FILL_W3A_P2_OK`); ... |
```

Required:

```markdown
| **C′ W3a dimension fill** | YES | YES | YES | script (`DIMENSION_FILL_W3A_P2_OK`; P0–P2; `MAP_DEEPEN_OK` brand retired; ≠ 掃透 ≠ understood; ∉ Tier-0) |
```

W3a `Proven-green=YES` here is **script-only** (`DIMENSION_FILL_W3A_P2_OK`); column realign ≠ C′ / Focus / letter B Proven flip; ≠ live-panel carve-out (`script+live-pressure`). Also scrub any honesty banner that still says W3a “deferred” if it contradicts the table.

### 3.2 Test `tests/test_status_capability_table.sh`

- Locate `## Capability` table; header = Capability|Designed|On-tree|Proven-green|Scope
- Each data row: exactly 5 cells
- Designed/On-tree/Proven-green ∈ {YES, NO, blank, —} (SaaS blanks OK)
- Scope when set ∈ startswith `script` | `script+live-pressure` | `agent` | `blank` | `—` | empty
- FAIL if On-tree looks like scope (`script`, `agent`, `P0–P2`, `script+live-pressure`)
- FAIL if Proven-green is bare `script`/`agent` (scope leak)
- FAIL if Scope starts with `On-tree (`
- If Proven-green=`YES` and Scope starts with `script`, Scope must contain a backtick token matching `[A-Z0-9_]{6,}_OK` (or `TIER0_OK` / `DIMENSION_FILL_W3A_P2_OK` style)
- Firewall: not referenced from `test-tier0.sh` **or** `pack-health.sh`
- Print `STATUS_CAPABILITY_TABLE_OK`

## 4. Gap ③ — Report narrative token lint

### 4.1 Behavior

- Add `## Held tokens` to owner + locate templates (may be empty).
- When **body** (outside Held / Token evidence sections) matches a slogan, requirements fire.
- No slogan → no Held required (legacy fixtures stay green).
- **Negation (tight):** ignore a slogan hit only if the slogan is in an **adjacent** negation template on that line, e.g. `≠ 掃透`, `not 掃透`, `never 掃透`, `Asking ≠ 掃透`, `不得掃透`. **Forbidden:** “anywhere on the line has `≠`/`不是` → ignore” (blocks `已掃透；≠ SaaS`).
- Held section + `## Token evidence` not scanned for slogans.
- Lint **OWNER and LOCATE** equally when those paths are passed / present.
- Call site in `verify-report.sh`: after Nested/Mode/(optional RUNS) checks, before `VERIFY_REPORT_OK`.
- Update L2 comment: checklist + token lint; still ≠ nested proof ≠ chat proof; Held alone ≠ proof.

### 4.2 Slogan → token map (v1)

| Body slogan (examples) | Required |
|------------------------|----------|
| `掃透` / `全環境全 branch 掃透` | Held `MATRIX_SWEEP_SUBSTANTIVE_OK` **and** `## Token evidence` fenced block containing that exact line |
| `無漏掃` / `矩陣終態` | Held `ENV_BRANCH_MATRIX_OK` + evidence fence with that line |
| `立體場景` / `多領域立體` / `立體場景切換` | Held `SCENE_BRIEF_OK` **and** `SCENE_COVER_OK` + evidence fence containing `SCENE_BRIEF_OK` and `SCENE_COVER_OK` |
| `全懂` / `系統已懂` / `full-understanding` / `system understood` | **Forbidden** (no held legitimizes) |
| `dig-ready` / `ready-after-install-alone` / `install→ready` | **Forbidden** in reports |

**`SCENE_COVER_OK` pin:** exact Held spelling. v1: `verify-scene-cover.sh` **prints** `SCENE_COVER_OK` on exit 0 (additive stdout). Evidence fence must paste that script stdout. Lint does not re-run cover; forged paste remains residual risk (documented; panel still required for C′ Proven-green).

Adversarial fixtures must FAIL: `已掃透；≠ SaaS`; `系統已懂（不是誇飾）`; Held-only 掃透 without evidence fence.

### 4.3 Files

- `scripts/lib/report_token_lint.py` (new)
- `scripts/verify-report.sh` (call lint; accept OWNER path optional 2nd report or lint both if sibling exists)
- `scripts/verify-scene-cover.sh` (echo `SCENE_COVER_OK` on success)
- `references/*-report-template.md`
- `skills/vibage-issue-locate/SKILL.md` + one line in `using-vibage`
- `tests/test_verify_report_tokens.sh` + fixtures → `VERIFY_REPORT_TOKENS_OK`
- Firewall: token test ∉ `test-tier0.sh` / `pack-health.sh`

## 5. Gap ② — Live Gate B locate evidence

### 5.1 Parent

`PARENT=/Users/eric.fang/MindOwnBuz` only (not DefiStrategy).

### 5.2 Mechanical recipe

1. `install.sh --init-hub=$PARENT` (+ optional graph-floor; **prefer** skip full `c-prime-fill` unless needed for map verify)
2. `graph-floor.sh` → `GRAPH_FLOOR_OK`; `verify-service-map.sh` exit 0
3. Seed `SCAN_PLAN.md` `scan_plan_v1` with `planned_dig_ids: ["SelfAutoBuz"]`, `hot_path_ids`/`root_refs` ids matching floor `service_map` (SelfAutoBuz present; never dig vibage-skills)
4. `write_confirm.sh` → `assert_gate.sh` → `ASSERT_GATE_OK`
5. Agent dig **Mode: degraded** only; dual-write RUNS; write parent-root OWNER+LOCATE — **body must not claim 掃透／立體／全懂**; Held may be empty
6. `verify-run.sh` + `verify-report.sh` on **both** OWNER and LOCATE → `VERIFY_REPORT_OK`
7. Copy artifacts to `docs/evidence/c-prime/gate-b-locate-<run_ts>/` + index `GATE-B-LOCATE-<run_ts>.md` claiming `GATE_B_LOCATE_OK` only
8. **Machine assert before claim:** package `STATUS.md` C′ / Focus / letter B Proven-green **cells unchanged** vs baseline commit (script diff or pinned hashes); fail ship of evidence if flipped
9. Restore: delete live `docs/vibage` and parent `VIBAGE-ISSUE-*` after copy; keep entry

### 5.3 NOT-claims (must appear in evidence)

≠ C′ / Focus / letter B STATUS Proven flip; ≠ 掃透; ≠ `MATRIX_SWEEP_SUBSTANTIVE_OK` on live; ≠ letter B; ≠ full nested; ≠ Sync DONE; ≠ live scene cover; `GATE_B_LOCATE_OK` ≠ C′ Proven-green upgrade.

## 6. Ordering

```text
① STATUS fix + lint test (script, fast)
③ report token lint + templates + tests (script)
② live Gate B locate evidence (agent+script; after ③ so reports can include Held)
impl review loop → pressure: test_status_capability_table + test_verify_report_tokens + Tier-0 + optional re-skim Gate B verify outs
```

## 7. Exit

| Deliverable | Token |
|-------------|-------|
| ① | `STATUS_CAPABILITY_TABLE_OK` |
| ③ | `VERIFY_REPORT_TOKENS_OK` + existing reports still `VERIFY_REPORT_OK` |
| ② | `GATE_B_LOCATE_OK` evidence file committed |
| Ship gate | `TIER0_OK` unchanged membership |

## 8. Investigation fold

- STATUS lint: [invest-status](dd5c11d1-8262-4ba3-84ff-f3811da64ce6)
- Narrative lint: [invest-narrative](2e3c7e4b-5e98-4c7e-b8d5-562d77d58f93)
- Live locate: [invest-gateb](56c364e3-a0e6-4872-97d1-e77748952c3f)

## 9. Residual risk disclosure (v1) + hardening wave

**Deliverable lint is literal / phrase matching, not a semantic firewall.**  
v1 blocks exact slogans and a closed set of universal-completion / env-vacancy paraphrase patterns. **Rewording can still pass** outside those patterns. Forged `## Token evidence` fences remain residual risk (§4.2). Lint ≠ chat-level honesty.

### 9.1 Hardening (post Opus re-verify) — goals / non-claims

| ID | Goal | Success | Must not claim |
|----|------|---------|----------------|
| **H1** | `rg` fail-closed in all tests that call `rg` | `REQUIRE_RG_OK` + `DEPENDENCIES.md` `ripgrep=required` + `verify-pins.sh` presence check | slogan guards are semantic; re-running `C_PRIME_SUITE_OK` flips Proven-green |
| **H2** | Universal completion + env-vacancy phrase rules in deliverable lint | fixtures FAIL paraphrase probes; `VERIFY_REPORT_TOKENS_OK` | chat has a firewall; lint prevents all rewording |
| **H3** | freeze-lift + STATUS W3a scope cite P0+P1+P2 | cross-doc consistent | W3a enters Tier-0; scope upgrades to `script+live-pressure` |
