# Work Continue Memory — Design

**Date:** 2026-08-02  
**Status:** owner-locked (Build on `feat/work-continue-memory` only; do not merge open todos to main as “current checklist”)  
**Owner goal:** After multi-repo dig, keep working in one app (optional brief side quest) with file-backed resume. Chat is not SSOT.

## Owner locks (2026-08-02)

| ID | Decision |
|----|----------|
| A | **No** child `PROGRESS` in wave 1 (explicit Deferred) |
| B | **Yes** — one-line pointer on all 4 thin entry adapters |
| C | **Yes** — light `verify-work-continue.sh` (∉ Tier-0 / ∉ `assert_gate`) |
| D | **D1** — missing/invalid `WORK_CONTINUE` **blocks** locate DONE (anti false-green) |
| E | Matching continue contract **short-circuits continuum dig** but **still** requires freshness + incomplete-matrix disclosure |

Plan-loop reviews (5 lenses): all ISSUES; consensus fixes below. Diversity: composer-fast ×5 (`diversity: waived` host-same-family).

## 1. Problem

After locate, new sessions often rediscover, ignore dig pointers, or side-quest without bookmarks. Gap is **memory continuity**, not another SDLC pin pack.

## 2. Non-goals (wave 1)

- No new methodology pins (OMC / gstack / Matt / Addy / GSD)
- No expanding single-repo into full locate continuum
- No CLI Ralph / stop-hook grind
- No Tier-0 / `assert_gate` wiring
- No second locate report
- **No child `PROGRESS` template or dual-path progress files** (see Deferred)

## 3. Approach

**Hub continue contract only (wave 1).**

| Artifact | Path | Role |
|----------|------|------|
| Continue contract | Parent `docs/vibage/WORK_CONTINUE.md` | `work_root`, `next_step`, dig pointers, phase, side-quest bookmark, forbidden, `run_id` |

```text
dual reports → write+verify WORK_CONTINUE → only then locate DONE
       ↓
 resume: read WORK_CONTINUE (+ freshness/matrix disclose) → skip pile-index/orient
       ↓
 side quest? bookmark (read-only) → return → clear bookmark
```

### Path resolution

- Canonical: paths **relative to parent hub workspace root** (directory that contains `docs/vibage/`).
- Prefer hub-relative over machine-absolute. If absolute used, pair with `hub_root` note in template comments.
- Missing `work_root` on disk → `phase: blocked`; ask owner; do not invent continue state from chat.

### Precedence vs RUNS / STATUS

1. `WORK_CONTINUE.md` — work root, next_step, side_quest (post-locate resume SSOT)  
2. Dual reports — evidence detail (re-read before acting on findings)  
3. `docs/vibage/RUNS/<run_id>.json` — fallback if report paths stale (`artifact_uris`)  
4. Hub `STATUS.md` — focus_run_id / Where card; does **not** override work_root  

`inherited_finding_ids` = **snapshot pointers**; re-read reports before edits. Format: `id | repo_relative_path | one-line claim` (≤7).

## 4. Required fields

| Field | Required | Meaning |
|-------|----------|---------|
| `work_root` | yes | Hub-relative path of active child checkout |
| `run_id` | yes | Locate run id |
| `dual_report_uris` | yes | OWNER + LOCATE paths (hub-relative) |
| `inherited_finding_ids` | yes | Snapshot list (see format above) |
| `next_step` | yes | Concrete next action in `work_root` (not only side_quest return) |
| `phase` | yes | Enum: `implement_in_work_root` \| `side_quest` \| `blocked` |
| `side_quest` | yes | `none` or target + why + `return_next` |
| `forbidden` | yes | Non-empty; template ships defaults (≠ full-understanding, ≠ full-sweep without tokens, ≠ CONFIRM, ≠ assert_gate, ≠ dig auth) |
| `updated_at` | yes | ISO-8601 |

Template top MUST-NOT block (fixed copy). Test stdout token: **`WORK_CONTINUE_FIXTURE_OK`** (phrase/fixture gate only — **not** Proven-green / On-tree / capability).

## 5. Behavioral rules

### 5.1 Locate DONE = D1

Order: dual reports → write/update `WORK_CONTINUE.md` → `verify-work-continue.sh` exit 0 → **then** may claim locate DONE / finishing options.  
Dual reports alone ≠ DONE. No “DONE then backfill” without owner exception.

### 5.2 Resume / routing (E)

If `docs/vibage/WORK_CONTINUE.md` exists, verifies, and task matches its `work_root`:

- One-line continuum out-of-scope disclosure  
- **Read contract before code edits**  
- **Do not** re-run pile-index / orient / CONFIRM for that continue task  
- **Still** run/parse freshness + disclose `stale_count` / incomplete matrix (+ env-vacancy tokens as today) — continue ≠ skip mother honesty  

If file missing: read dual reports if any; **ask** owner for work root; **do not** fabricate continue state.

### 5.3 Side quest

Read/bookmark only. Does **not** expand `planned_dig_ids` or authorize new locate dig. Return → `side_quest: none`, restore `phase`, refresh `next_step`.

### 5.4 Adapters (B)

Required one-liner on:

- `adapters/cursor/vibage.mdc`  
- `adapters/claude/CLAUDE.vibage.md`  
- `adapters/shared/AGENTS.vibage.md`  
- `adapters/codex/AGENTS.vibage.md`  

No sessionStart hook field dump (defer).

### 5.5 Install / old hubs

`install.sh` `init_hub` **must** seed `WORK_CONTINUE.md` template (or empty scaffold) for new hubs.  
**No migrate script** for existing hubs: first locate finishing writes the live file; owner may copy template manually.

### 5.6 Honesty

Continue ≠ system-understood ≠ full-sweep ≠ dig authorization ≠ CONFIRM substitute.

## 6. Verification (C)

`scripts/verify-work-continue.sh` (∉ Tier-0, ∉ pack-health, ∉ `assert_gate`):

- File exists under hub  
- All required field headings present  
- `forbidden` non-empty + contains standard NOT-claims substring(s)  
- `work_root` path exists (or explicit `phase: blocked`)  
- Optional: `run_id` has matching `RUNS/<run_id>.json` when RUNS dir present  

Stdout success token for verify: `WORK_CONTINUE_VERIFY_OK` (deliverable lint — still ≠ Proven-green).  
Package phrase tests: `WORK_CONTINUE_FIXTURE_OK`.

## 7. Deferred (wave 2+) — do not “forget”

Track here (and in plan Deferred); not chat memory:

1. Child `PROGRESS.md` / `.vibage/progress.md` template + “must not override hub” tests — **only when** an owner actually needs long-running child-local progress  
2. `verify-work-continue` richer schema / stale finding lint  
3. sessionStart hook injecting continue summary  
4. Ralph / stop-hook grind consuming this contract  

## 8. Success (owner-visible)

- New chat: agent states work_root + next_step from file; no pile-index slogans for continue tasks  
- Cannot claim locate DONE without verified continue file (D1)  
- Side quest bookmarked; freshness still disclosed (E)  
