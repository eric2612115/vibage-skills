# Work Continue Memory — Design

**Date:** 2026-08-02  
**Status:** draft (awaiting plan-loop freeze before Build)  
**Owner goal (plain language, confirmed):** After digging across many apps, keep working in one app (and maybe briefly check another app and come back) without losing “what we already proved” and “what to do next.” Chat is not the source of truth — files are.

## 1. Problem

Vibage is strong at multi-repo **where** (orient → CONFIRM → dig → dual reports). After locate succeeds, a new session often:

1. Re-discovers or ignores dig conclusions  
2. Treats single-repo work as “out of scope → improvise” with no memory bridge  
3. Jumps to another repo mid-work without a bookmark, then loses the main phase  

That feels like “single-repo is weak.” The root gap is **memory continuity**, not a missing third-party coding-methodology pack.

## 2. Non-goals (this wave)

- Do not pin OMC / gstack / Matt / Addy / GSD as install dependencies  
- Do not expand single-repo work into full locate continuum (pile-index / matrix / CONFIRM)  
- Do not require CLI Ralph / stop-hook grind (later, must consume this memory)  
- Do not put continue-memory into Tier-0 or `assert_gate`  
- Do not invent a second locate report; continue file is pointers + bookmarks only  

## 3. Approach

**Hub continue contract is authoritative; optional child progress is execution-only.**

| Artifact | Path | Role |
|----------|------|------|
| Continue contract | Parent hub `docs/vibage/WORK_CONTINUE.md` | Work root, pointers to dual reports + key finding ids, phase, side-quest bookmark, forbidden claims, `run_id` |
| Child progress (optional) | Child repo `PROGRESS.md` or `.vibage/progress.md` | Last commit, local gates, notes — **must not** override hub work-root / side-quest fields |

New session / host switch: **read `WORK_CONTINUE.md` before editing code.**

```text
locate dual reports → write WORK_CONTINUE
       ↓
 single-repo deep work (optional child PROGRESS)
       ↓
 side quest? → bookmark in WORK_CONTINUE → dig/read → return to work root
```

## 4. Required fields (`WORK_CONTINUE.md`)

Machine-oriented headings (English identifiers); owner chat may stay in owner language.

| Field | Required | Meaning |
|-------|----------|---------|
| `work_root` | yes | Absolute or parent-relative path of the active child checkout |
| `run_id` | yes | Locate run that produced this continue state |
| `dual_report_uris` | yes | Paths to `VIBAGE-ISSUE-OWNER.md` + `VIBAGE-ISSUE-LOCATE.md` |
| `inherited_finding_ids` | yes | Short list of locate finding ids (with path) still in force |
| `phase` | yes | e.g. `post_locate_implement` / `side_quest` / `blocked` |
| `side_quest` | yes (may be `none`) | If active: target path, why, return_next step |
| `forbidden` | yes | Claims not allowed (e.g. full-understanding, full-sweep without tokens) |
| `updated_at` | yes | ISO-8601 |

## 5. Behavioral rules

1. **Locate success finishing:** Writing/updating `WORK_CONTINUE.md` is required (same class as finishing options — not skippable).  
2. **Routing:** If hub has `WORK_CONTINUE.md` and the task is continue/implement in the named work root → one-line out-of-scope disclosure for continuum **plus** mandatory read of the contract, then proceed (prefer pinned superpowers for How).  
3. **Side quest:** Before leaving `work_root`, set `side_quest` fields; on return, clear or close bookmark and restore `phase`.  
4. **Honesty:** Continue file ≠ “system understood.” Pointers only.

## 6. Test strategy (TDD)

Prefer scripted phrase/structure tests (same family as `test_entry_docs_sync.sh` / status-lints):

- Template exists and lists all required field headings  
- `vibage-issue-locate` + `using-vibage` finishing mention `WORK_CONTINUE` as required  
- `routing-scope.md` requires read-before-edit when file present  
- Fixture: sample `WORK_CONTINUE.md` parses required keys (small Python or bash grep suite)  
- Firewall: new tests **not** wired into Tier-0 / pack-health unless later decided  

## 7. Success (owner-visible)

- New chat on parent: agent states work root + report pointers from file without re-running pile-index  
- Side quest then return: bookmark recorded; main phase not wiped  
- No slogan that continue-memory replaces CONFIRM or dual reports  
