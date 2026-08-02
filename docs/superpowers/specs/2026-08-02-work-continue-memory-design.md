# Work Continue Memory — Design

**Date:** 2026-08-02  
**Status:** owner-locked; plan-loop round 2 patches applied (feat branch only)  
**Owner goal:** After multi-repo dig, keep working in one app (optional brief side quest) with file-backed resume. Chat is not SSOT.

## Owner locks (2026-08-02)

| ID | Decision |
|----|----------|
| A | **No** child `PROGRESS` in wave 1 (explicit Deferred) |
| B | **Yes** — one-line pointer on all 4 thin entry adapters |
| C | **Yes** — light `verify-work-continue.sh` (∉ Tier-0 / ∉ pack-health / ∉ `assert_gate`) |
| D | **D1** — missing/invalid `WORK_CONTINUE` **blocks** locate DONE (anti false-green) |
| E | Matching continue contract **short-circuits continuum dig** but **still** requires freshness + incomplete-matrix disclosure |

Plan-loop: round-1 five lenses (composer) → rewrite; round-2 three lenses (grok 4.5 high) → patches below. `diversity: waived` (same model family; reason: owner-required grok-only).

## 1. Problem

After locate, new sessions often rediscover, ignore dig pointers, or side-quest without bookmarks. Gap is **memory continuity**, not another SDLC pin pack.

## 2. Non-goals (wave 1)

- No new methodology pins (OMC / gstack / Matt / Addy / GSD)
- No expanding single-repo into full locate continuum
- No CLI Ralph / stop-hook grind (Deferred §7.4)
- No Tier-0 / pack-health / `assert_gate` wiring
- No second locate report
- **No child `PROGRESS`** (Deferred §7.1)

## 3. Approach

**Hub continue contract only (wave 1).**

| Artifact | Path | Role |
|----------|------|------|
| Continue contract | Parent `docs/vibage/WORK_CONTINUE.md` | Live post-locate resume SSOT |
| Package template | `references/hub/WORK_CONTINUE.md` | Seeded by init_hub; **must not** verify green for DONE |

```text
dual reports on disk → write live WORK_CONTINUE → verify-work-continue exit 0
       → only then locate DONE
 resume: verified live contract (+ freshness/matrix disclose) → skip pile-index/orient
```

### Path resolution

- Canonical: paths **relative to parent hub workspace root** (dir containing `docs/vibage/`).
- Missing `work_root` on disk → set `phase: blocked` in the **live** file; ask owner; do not invent from chat.
- `phase: blocked` **fails** `verify-work-continue.sh` (resume may still *read* the file; agent **must not** claim locate DONE or `WORK_CONTINUE_VERIFY_OK`).

### Precedence vs RUNS / STATUS

1. Live `WORK_CONTINUE.md` — work root, next_step, side_quest  
2. Dual reports — evidence (re-read before acting)  
3. `RUNS/<run_id>.json` — fallback if report paths stale  
4. Hub `STATUS.md` — does **not** override work_root  

`inherited_finding_ids` format: `id | repo_relative_path | one-line claim` (≤7). Snapshot only.

## 4. Required fields (live contract)

| Field | Required | Meaning |
|-------|----------|---------|
| `work_root` | yes | Hub-relative; directory **must exist** for verify OK |
| `run_id` | yes | Non-empty; not placeholder |
| `dual_report_uris` | yes | OWNER + LOCATE hub-relative paths; **both files must exist** |
| `inherited_finding_ids` | yes | ≥1 non-placeholder line in format above |
| `next_step` | yes | Non-empty; not placeholder (`TODO_*` / `REPLACE_*` / `TBD`) |
| `phase` | yes | For verify OK: `implement_in_work_root` \| `side_quest` only (`blocked` → verify FAIL) |
| `side_quest` | yes | `none` or target + why + `return_next` |
| `forbidden` | yes | Non-empty + standard NOT-claims substrings |
| `updated_at` | yes | ISO-8601 |

Package phrase-test token: **`WORK_CONTINUE_FIXTURE_OK`** (≠ Proven-green / On-tree / locate DONE).  
Verify success token: **`WORK_CONTINUE_VERIFY_OK`** (≠ Proven-green / On-tree / **≠ locate DONE by itself** — DONE still requires skill-order dual→write→verify).

## 5. Behavioral rules

### 5.1 Locate DONE = D1

Hard order (skills + tests phrase-gate):

1. Dual report files exist  
2. Write/update live `WORK_CONTINUE.md` (no `TODO_*` placeholders)  
3. `bash scripts/verify-work-continue.sh <hub_parent>` → `WORK_CONTINUE_VERIFY_OK`  
4. **Then** may claim locate DONE / offer finishing options  

`WORK_CONTINUE_VERIFY_OK` alone ≠ locate DONE. Dual reports alone ≠ DONE.

**Owner exception (only escape):** file `docs/vibage/WORK_CONTINUE_EXCEPTION.md` with fields `owner_quote`, `reason`, `run_id`, `updated_at`. Without that file, no DONE-then-backfill. Exception path is disclosed in chat; still not Proven-green.

**Legacy:** install may symlink `vibage-locate` → `vibage-issue-locate`; D1 lives in `vibage-issue-locate/SKILL.md` only (no separate legacy body to desync).

### 5.2 Resume / routing (E)

If live contract **verifies** and task matches `work_root`:

- One-line continuum out-of-scope disclosure  
- Read contract before code edits  
- Do **not** re-run pile-index / orient / CONFIRM for that continue task  
- **Still** parse freshness → need `FRESHNESS_OK` or (`FRESHNESS_WAIVED` + `STALE_DISCLOSED`); disclose stale_count / incomplete matrix; env-vacancy tokens as today  

If file missing or verify fails: ask owner; do not fabricate; do not claim DONE.

### 5.3 Side quest

Read/bookmark only. No dig-auth expansion. Return clears bookmark.

### 5.4 Adapters (B)

One-liner on four thin entries (cursor/claude/shared/codex). No sessionStart field dump.

### 5.5 Install / seed vs live

`init_hub` copies package template into `docs/vibage/WORK_CONTINUE.md`.  
Seed **must** contain `FILL_AFTER_LOCATE` (or equivalent) placeholders and/or `phase: blocked` so **`verify-work-continue.sh` FAILs** on a fresh hub.  
Locate finishing **overwrites** with a live contract that can verify.  
No migrate script for old hubs.

### 5.6 Honesty

Continue ≠ system-understood ≠ full-sweep ≠ dig authorization ≠ CONFIRM.

## 6. Verification (C)

`scripts/verify-work-continue.sh` (∉ Tier-0, ∉ pack-health, ∉ `assert_gate`):

**FAIL unless all of:**

- File exists  
- All required headings present  
- No `FILL_AFTER_LOCATE` / `TODO_SET_AFTER_LOCATE` / `REPLACE_ME` placeholders in required value lines  
- `next_step` non-empty  
- Both `dual_report_uris` paths exist on disk  
- `work_root` directory exists  
- `phase` is `implement_in_work_root` or `side_quest` (not `blocked`)  
- `forbidden` non-empty + NOT-claims substrings  

Optional: `RUNS/<run_id>.json` exists when `docs/vibage/RUNS/` directory present.

Fixtures (fail-first): `ok.md` (+ temp report files), `missing_work_root.md`, `phase_blocked.md`, `empty_forbidden.md`, `missing_dual_reports.md`, `seed_placeholders.md`.

## 7. Deferred (wave 2+) — plan must mirror this list

1. Child `PROGRESS.md` / `.vibage/progress.md` + must-not-override-hub tests  
2. Richer verify / stale finding lint  
3. sessionStart continue summary  
4. Ralph / stop-hook grind consuming this contract  
5. Hub migrate script for pre-existing parents  

## 8. Success (owner-visible)

- Cannot claim locate DONE without verified live contract (D1)  
- Fresh hub seed does **not** verify green  
- Resume without pile-index; freshness/matrix still disclosed (E)  
