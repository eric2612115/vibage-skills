---
name: war-room-locate
description: >-
  Use when CONFIRM.json payload_hash matches current SCAN_PLAN and the owner
  needs post-confirm dig with dual reports. Do not install skills; do not
  redefine model routing; do not deep-dig without assert_gate.
---

# War Room Locate

Goal: after mechanical confirm, cut "1–2 days to find where" toward minutes for the **repo owner**.

Success = dual artifacts: (1) owner-language brief, (2) engineer locate with path evidence, nested pass, ask-colleague questions — plus RUNS footprint. Not a 200-ticket dump.

## When / Not

| When | Not |
|------|-----|
| CONFIRM hash matches current SCAN_PLAN | Install / init hub |
| Post-confirm dig + dual reports | Claim survey ownership (hand to research skill) |
| Resume analyzing/done with valid confirm | Early V0 "orient in locate" as substitute for war-room-orient |

## PKG_ROOT (mandatory — portable)

Prefer:

```bash
python3 -c 'import os; print(os.path.dirname(os.path.dirname(os.path.realpath(os.path.expanduser("~/.cursor/skills/war-room-init")))))'
```

Fallback (V0):

```bash
python3 -c 'import os; print(os.path.dirname(os.path.dirname(os.path.realpath(os.path.expanduser("~/.cursor/skills/war-room-locate")))))'
```

Use `$PKG_ROOT/scripts/*` and `$PKG_ROOT/references/*`. Never hardcode `/Users/...`.

## Language

Match the **owner's language** in chat and `WAR-ROOM-OWNER.md`. Never assume Traditional Chinese. Paths, identifiers, template section titles in English are fine inside engineer report.

## Inputs (ask only if missing)

1. Symptom in one sentence
2. Workspace root (parent folder with `docs/war-room/`)
3. Any log / stack / failing URL / approximate time
4. What already tried (optional)
5. Owner questionnaire (if not already captured in RUNS/STATUS):
   - Who built this? (AI / freelancer / unknown)
   - Can you run tests / git / docker? (yes / no / unsure)
   - Preferred language for the owner brief?

## Preflight gates (before dig)

1. Run `"$PKG_ROOT/scripts/verify-pins.sh"`. On failure → stop; owner-language recovery (same as init). Pin fail blocks `analyzing` (S8).
2. Run `"$PKG_ROOT/scripts/assert_gate.sh" "$WORKSPACE"`. On failure → stop. Set run phase `stale_confirm` if hash mismatch; tell owner to re-orient / re-confirm (S13/S14). **No dig without gate.**
3. Read `docs/war-room/SCAN_PLAN.md` `planned_dig_ids` / budgets — dig only that subset.

## Deleted V0 behavior

- **Do not** run the old early "Orient (5 min max)" step inside locate as a substitute for `war-room-orient`.
- Shallow identity (README/deny lists) may still happen **after** assert_gate as part of dig, but SCAN_PLAN + CONFIRM are owned by orient.

## Procedure

1. **Open / update RunEnvelope** at `docs/war-room/RUNS/<run_id>.json`:
   - phase=`analyzing`, mode=`degraded` default
   - Keep `pipeline_id: locate`
2. **Fat-repo identity line** (after gate): if dual trees / LEGACY appear, write `Active surface: … | Legacy/ignore: …` with path+quote.
3. **Deny / quarantine:** do not deep-read `.venv/`, `node_modules/`, `.worktrees/`, large artifacts, or paths marked LEGACY unless owner asks.
4. **Hypothesize first** — 2–4 hypotheses. Consult `$PKG_ROOT/references/vibe-debt-smells.md`.
5. **Optional survey:** Read `$PKG_ROOT/references/survey-matrix.md`. If MUST → hand off to `research-survey-review` (do not reimplement). Default SKIP.
6. **Pinned superpowers (MUST):** follow `systematic-debugging` and `verification-before-completion` under pinned superpowers.
7. **Nested investigation (MUST attempt):** follow `$PKG_ROOT/references/nested-protocol.md`.  
   - Fill `nested_dispatch` **only if** investigators + reviewers were actually dispatched.  
   - Else keep `mode: degraded` (legitimate success).  
   - **Never** write `Mode: full nested` / `mode: "full nested"` without both arrays length ≥ 1.
8. **Search with budget** from SCAN_PLAN. Stop when one hypothesis has path evidence OR two strong candidates remain.
9. **Engineer challenge + adversarial kill** — cap ≤7 findings after review.
10. **GapQuestions** after analysis — use `$PKG_ROOT/references/gap-question-template.md`; record `gap_ids` on RunEnvelope.
11. **Write dual reports** at workspace root:
    - `WAR-ROOM-OWNER.md` ← owner template
    - `WAR-ROOM-LOCATE.md` ← locate template  
    Capability branching: if tests/git/docker = no|unsure, owner actions must not require local runs.
12. **Verify (optional checklist):**  
    `"$PKG_ROOT/scripts/verify-report.sh" WAR-ROOM-LOCATE.md docs/war-room/RUNS/<run_id>.json`  
    Second arg is the RUNS JSON (required when Mode is full nested).
13. **Preview fail-soft (S11):** After dual MD exist, run `"$PKG_ROOT/scripts/serve-preview.sh" "$WORKSPACE" 8765` (copies package asset into `$WORKSPACE/war-room-preview/`). If copy/serve fails, set RunEnvelope `preview_error` and still mark phase `done` when dual MD exist.
14. **Soft CTA** only after both MD exist — `$PKG_ROOT/references/feature-call.md`. Never block reports.
15. Update STATUS focus + RunEnvelope phase `done`|`failed`|`aborted`.

## Stale / resume

- **Resume (S12):** Read STATUS + RUNS; if CONFIRM still valid (`assert_gate` OK), continue; never wipe CONFIRM via re-init.
- **Stale confirm (S14):** assert_gate fail → phase `stale_confirm` → orient → new CONFIRM.
- **Reject plan (S13):** clear CONFIRM, re-orient, re-confirm.

## Mode honesty

| mode value | Requirement |
|------------|-------------|
| `degraded` | OK without nested_dispatch |
| `full nested` | `nested_dispatch.investigators.length ≥ 1` AND `reviewers.length ≥ 1` |

Fake full nested must fail `verify-run.sh`.

## Hard stops

- Do not dig without assert_gate.
- Do not open 20+ files "just in case".
- Do not invent Jira tickets or fake health scores.
- Do not push code, edit business logic, or call external clouds unless user asks.
- Do not put `.env` secrets in chat or reports.
- Do not claim SOC2 / "passed audit".
- Do not hardcode Traditional Chinese.
- Prefer local search; no uploading whole repos.
- Do not redefine L0–L3 slug table in this skill (hub config owns slugs).
