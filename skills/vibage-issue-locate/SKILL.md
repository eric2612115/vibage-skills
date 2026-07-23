---
name: vibage-issue-locate
description: >-
  Use when CONFIRM.json payload_hash matches current SCAN_PLAN and the owner
  needs post-confirm dig with dual reports. Do not install skills; do not
  redefine model routing; do not deep-dig without assert_gate.
  (Install may still symlink legacy name vibage-locate for one release.)
---

# Vibage Issue Locate

Goal: after mechanical confirm, cut "1–2 days to find where" toward minutes for the **repo owner**.

Success = dual artifacts: (1) owner-language brief, (2) engineer locate with path evidence, nested pass, ask-colleague questions — plus RUNS footprint. Not a 200-ticket dump.

## When / Not

| When | Not |
|------|-----|
| CONFIRM hash matches current SCAN_PLAN | Install / init hub |
| Post-confirm dig + dual reports | Claim survey ownership (hand to research skill) |
| Resume analyzing/done with valid confirm | Early V0 "orient in locate" as substitute for vibage-orient |

## PKG_ROOT (mandatory — portable)

```bash
bash /path/to/vibage-skills/scripts/resolve-pkg-root.sh
```

See `$PKG_ROOT/references/resolve-pkg-root.md`. Use `$PKG_ROOT/scripts/*` and `$PKG_ROOT/references/*`. Never hardcode `/Users/...`.

## Language

Match the **owner's language** in chat and `VIBAGE-ISSUE-OWNER.md`. Never assume Traditional Chinese. Paths, identifiers, template section titles in English are fine inside engineer report.

## Inputs (ask only if missing)

1. Symptom in one sentence
2. Workspace root (parent folder with `docs/vibage/`)
3. Any log / stack / failing URL / approximate time
4. What already tried (optional)
5. Owner questionnaire (if not already captured in RUNS/STATUS):
   - Who built this? (AI / freelancer / unknown)
   - Can you run tests / git / docker? (yes / no / unsure)
   - Preferred language for the owner brief?

## Milestone dual-write (MUST)

On these milestones — not every tool call — write **both**:

| Milestone | Chat (owner) | Disk |
|-----------|--------------|------|
| gate (assert_gate) | Plain: ok to dig, or plan changed / re-confirm | RunEnvelope progress; on fail → STOP + `handoff` |
| locate start | Plain: starting dig on planned subset | STATUS focus + RunEnvelope phase `analyzing` |
| locate end / success | Plain brief that dual reports exist | STATUS + RunEnvelope `done` + `VIBAGE-ISSUE-*` |
| stop / mid-fail / abort | Plain STOP + next step | STATUS STOP + `handoff`; **no** dual reports |

Rules:

- Chat = plain language only. **Never** paste RunEnvelope JSON / hashes / internal fields to the owner.
- Disk = `docs/vibage/STATUS.md` + `RUNS/<run_id>.json` (and dual reports **only** on success path).
- No hub homework on the happy path.
- Mid-fail / abort / gate fail: do **not** write `VIBAGE-ISSUE-OWNER.md` / `VIBAGE-ISSUE-LOCATE.md`.
- Terminal-then-mint: new `run_id` MUST set root `supersedes_run_id` (SSOT); `handoff.prior_run_id` optional mirror (equal or absent).
- Verify handoff shape: `"$PKG_ROOT/scripts/verify-handoff.sh" docs/vibage/RUNS/<run_id>.json`
- See `$PKG_ROOT/references/hub/STATUS.md` STOP template and `RunEnvelope.example.json`.

## Preflight gates (before dig)

1. Run `"$PKG_ROOT/scripts/verify-pins.sh"`. On failure → stop; owner-language recovery (same as init). Pin fail blocks `analyzing` (S8). Dual-write STOP + handoff; no dual reports.
2. **Map gate (F16 / S05):** Run `"$PKG_ROOT/scripts/verify-service-map.sh" "$WORKSPACE"`. On failure → stop unless owner recorded explicit `MAP_SKIP` in `docs/vibage/DECISIONS.md`. Do not dig on half-written maps. Hand to `vibage-pile-index` when appropriate.
3. Run `"$PKG_ROOT/scripts/assert_gate.sh" "$WORKSPACE"`. On failure → stop. Set run phase `stale_confirm` if hash mismatch; tell owner to re-orient / re-confirm (S13/S14). **No dig without gate.** Dual-write STOP + handoff; **never** write `VIBAGE-ISSUE-*` on gate fail.
4. Read `docs/vibage/SCAN_PLAN.md` `planned_dig_ids` / budgets — dig **only** that subset (S10). Do not pick two “interesting” repos. Do not deep-read all map services. Do **not** require Graphify / service_map pretty preview before dual reports.

## Deleted V0 behavior

- **Do not** run the old early "Orient (5 min max)" step inside locate as a substitute for `vibage-orient`.
- Shallow identity (README/deny lists) may still happen **after** assert_gate as part of dig, but SCAN_PLAN + CONFIRM are owned by orient.

## Procedure

1. **Open / update RunEnvelope** at `docs/vibage/RUNS/<run_id>.json` (**locate start** milestone):
   - phase=`analyzing`, mode=`degraded` default
   - Keep `pipeline_id: locate`
   - If minting after a terminal run: set root `supersedes_run_id` to prior `run_id` (SSOT); optional `handoff.prior_run_id` mirror
   - Optional: `preview_error` (string) — set when preview copy/serve fails (S11)
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
11. **Write dual reports** at workspace root (**success path only** — never on mid-fail):
    - `VIBAGE-ISSUE-OWNER.md` ← owner template
    - `VIBAGE-ISSUE-LOCATE.md` ← locate template  
    Capability branching: if tests/git/docker = no|unsure, owner actions must not require local runs.
    **OWNER must plain-list** unchecked external gaps (DB / log / container / not connected) — S06. Do not claim code-only completeness when externals were named.
12. **Verify (optional checklist):**  
    `"$PKG_ROOT/scripts/verify-report.sh" VIBAGE-ISSUE-LOCATE.md docs/vibage/RUNS/<run_id>.json`  
    Second arg is the RUNS JSON (required when Mode is full nested).
13. **Preview fail-soft (S11):** After dual MD exist, run:
    `"$PKG_ROOT/scripts/serve-preview.sh" "$WORKSPACE" 8765`
    (copies asset into `$WORKSPACE/vibage-preview/`, serves `$WORKSPACE` on 127.0.0.1
    so `../VIBAGE-ISSUE-*.md` links resolve). Open `http://127.0.0.1:8765/vibage-preview/`.
    Optionally edit that HTML from OWNER content before/while serving.
    If copy or serve fails: set RunEnvelope field `preview_error` to the message,
    keep `phase: done` when dual MD exist.
    Preview never blocks DONE.
    Start serve in background (or copy-only, then tell the human the URL) so later steps are not blocked by http.server.
14. Local delivery ends at dual Markdown reports + optional preview. Cloud deepening is out of scope this phase.
15. **locate end / success or stop** milestone: Update STATUS focus + RunEnvelope phase `done`|`failed`|`aborted`. On `failed`|`aborted` fill STATUS STOP + `handoff` and do **not** write dual reports. Plain chat only — never dump JSON.
16. **Finishing (required on success path):** After dual reports exist / phase `done`, **must** follow `using-vibage` finishing options (owner language): optional localhost preview (fail-soft), handoff/STOP if needed, or stop — local delivery complete. Optional issue-fix / 架構檢視 only if owner asks. **No soft CTA / no register.** Do not skip this step after DONE.

## Stale / resume

- **Resume (S12):** Read STATUS + RUNS; if CONFIRM still valid (`assert_gate` OK), continue; never wipe CONFIRM via re-init. After terminal (`done|failed|aborted|stale_confirm`), mint a **new** `run_id` with `supersedes_run_id` set (never rewrite old failed→done).
- **Stale confirm (S14):** assert_gate fail → phase `stale_confirm` → STOP + handoff (no `VIBAGE-ISSUE-*`) → orient → new CONFIRM.
- **Reject plan (S13):** clear CONFIRM, re-orient, re-confirm.

## Mode honesty

| mode value | Requirement |
|------------|-------------|
| `degraded` | OK without nested_dispatch |
| `full nested` | `nested_dispatch.investigators.length ≥ 1` AND `reviewers.length ≥ 1` |

Fake full nested must fail `verify-run.sh`.

## Hard stops

Also obey `$PKG_ROOT/references/hard-stops.md`.

- Do not dig without assert_gate.
- Do not open 20+ files "just in case".
- Do not invent Jira tickets or fake health scores.
- Do not push register / sign-up / pairing / API-key / Architecture Pass upsell (S10).
- Do not push code, edit business logic, or call external clouds unless user asks.
- Do not put `.env` secrets in chat or reports.
- Do not claim SOC2 / "passed audit".
- Do not hardcode Traditional Chinese.
- Prefer local search; no uploading whole repos.
- Do not redefine L0–L3 slug table in this skill (hub config owns slugs).
