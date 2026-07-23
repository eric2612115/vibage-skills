> **DO NOT USE FOR DEV** — Archived 2026-07-23. See v2 umbrella spec.

# Vibage OS + Locate Pipeline (P1) — Design

**Date:** 2026-07-22  
**Status:** Spec ✅ + Plan ✅ (2026-07-22); ready to execute `docs/superpowers/plans/2026-07-22-vibage-os-p1.md`  
**Package SSOT:** `/Users/eric.fang/MindOwnBuz/vibage-skills`  
**Progress tracker:** [`STATUS.md`](../../../STATUS.md) (package repo root)  
**Sibling app (P3):** `/Users/eric.fang/MindOwnBuz/vibage-app`

## Problem

V0 (`vibage-locate`) helps non-coder owners locate *where* a problem lives in a single/few-root fat or AI-built repo, but:

1. Multi-repo parent folders lack inventory → confirm → dig discipline.
2. No durable footprints (what was scanned, confirmed, decided).
3. Nested / Mode honesty is honor-system; `verify-report` is format-only.
4. No default web survey against prior art; no section-gate for design docs.
5. Soft CTA exists, but local wow (preview) and cloud upgrade path are incomplete.
6. Beginners cannot say one sentence and get a guided pipeline without understanding pins/skills.

## Goals (Phase 1)

1. **Parent-folder Vibage hub:** Cursor opens the company parent folder; agent installs skills; writes hub artifacts under that folder.
2. **Confirm-before-dig:** shallow orient → `SCAN_PLAN` → human CONFIRM (hash) → locate deep dig only after `assert_gate`.
3. **Honest inventory:** `RootRef` supports `checked_out | missing | external_ref | submodule`; post-analysis `GapQuestion` (missing repo, observability, etc.).
4. **Footprints:** STATUS (OS pointer) + per-run `RunEnvelope` in RUNS; CONFIRM; DECISIONS (human only in P1).
5. **Local wow:** dual Markdown SSOT + localhost preview (fail-soft) + soft CTA (no signup wall).
6. **Process skills in-package:** `research-survey-review` (default SKIP; MUST by predicates) and `section-gate-review` (design section gates).
7. **Model routing B:** shared L0–L3 semantics; slugs configurable in hub/init; degrade if premium model unavailable.
8. **Mechanical honesty:** Mode default `degraded`; `full nested` only with dispatch records; verify fails fake full; install deny casual `--force`.

## Non-goals (P1)

- Graphify-class full graphs, coverage enforcement, long-task AUTO_DECIDED behavior (schema reserve only).
- Cloud upload implementation / richer hosted results (P3); `UploadManifest` stub only.
- 100% cryptographic proof nested ran (platform limit — not an SLA).
- Backstage/IDP, whole-tree upload, mini FSM/runtime/survey daemon/router binary.
- Replacing V0 dual-report JTBD; P1 wraps and extends it.

## Phase map (product)

| Phase | Solves | Status |
|-------|--------|--------|
| V0 | Single-/few-root locate + dual reports | Shipped |
| **P1** | Parent OS + thin locate pipeline (this spec) | Design |
| P2 | Graphify-class map, coverage gates, long-task + AUTO_DECIDED | Later |
| P3 | Cloud Pro via UploadManifest + Architecture Pass | Later |

P1 vs P2 service-map: P1 = RootRef inventory + hot-path budget; P2 = full graph / deeper map.

Capability matrix (problem × phase): see package [`STATUS.md`](../../../STATUS.md) §二 — normative for “done means YES”.

## Architecture

**Hub layout is locked (not optional):**

```text
Parent folder workspace
  docs/vibage/                 # hub SSOT (init creates)
    STATUS.md                    # OS pointer: hub_ready, focus run_id/pipeline_id
    RUNS/<run_id>.json           # RunEnvelope (machine-read; optional .md mirror later)
    SCAN_PLAN.md
    CONFIRM.json
    DECISIONS.md
    model-routing.json           # optional slug map for L1–L3
    UploadManifest.stub.json     # schema only; no upload in P1
  VIBAGE-OWNER.md              # dual reports stay at workspace root (V0 compat)
  VIBAGE-LOCATE.md
  vibage-preview/              # static HTML for localhost serve

~/.cursor/skills/vibage-*  → package (install.sh)
```

`assert_gate`, resume (S12), and init skeleton **must** use `docs/vibage/` paths above. Do not scatter hub files at repo root.

### Skills (same install box; separate SKILL.md files)

| Skill | Owns | Must not |
|-------|------|----------|
| `vibage-init` (evolve bootstrap) | install allowlist, hub skeleton, AGENTS/rules thin entry, model slug config | dig, reports |
| `vibage-orient` | Root discovery, SCAN_PLAN, awaiting_confirm | deep dig, OWNER/LOCATE |
| `vibage-locate` | post-confirm dig, nested, dual reports, update run footprint | install; redefine routing table |
| `research-survey-review` | external survey→synthesize→critique loop | call any `vibage-*` product skill |
| `section-gate-review` | design-section 3-lens gate | product code edits; recursive gate |

**DAG:** init → orient → (CONFIRM) → locate → may call research per matrix.  
research/section-gate never call vibage product skills.  
Product skills hand off only via STATUS/RUNS/CONFIRM files.

**Trigger mutex (description WHEN + NOT):**

| Skill | When | Not |
|-------|------|-----|
| init | no hub STATUS / install unclear / NEW-CHAT cold start | write locate reports |
| orient | hub ready, no valid CONFIRM | deep dig |
| locate | CONFIRM hash matches current SCAN_PLAN | install; claim survey |
| research | matrix MUST_SURVEY | nested path+quote review; section gates |
| section-gate | design/plan section before next § | locate nested; web research |

`NEW-CHAT.md` = thin dispatcher only (no duplicated locate procedure).

### Layers

| Layer | Holds |
|-------|--------|
| OS (STATUS) | hub_ready, focus run_id / pipeline_id — not global “done” |
| Pipeline | `pipeline_id` e.g. `locate` (future: `architecture-pass`) |
| Run | `RunEnvelope.phase`: installed → plan_drafted → awaiting_confirm → analyzing → done \| failed \| aborted \| stale_confirm |

## Stable interfaces (schema-only)

All artifacts include `schema_version` where machine-read.

### RootRef

Canonical inventory unit (one checkout or missing/external unit):

`id`, `path|uri`, `presence: checked_out|missing|external_ref|submodule`, `kind: app|deploy|lib|data|unknown`, `evidence[]`, optional `hot_path: bool`.

**ServiceRef:** alias for the same schema when `kind` is `app|deploy|lib|data` — not a second type. Orient writes RootRef[]; GapQuestion may reference `root_ref_id`.

### SCAN_PLAN

Markdown human form **plus** fenced JSON block `scan_plan_v1` used for hashing, containing at least:

`schema_version`, `root_refs[]` (full RootRef objects), `budgets: { max_wall_min, max_files, max_depth }`, `hot_path_ids[]`, `known_incompleteness: string`, `planned_dig_ids[]`.

Default budgets if unspecified: `max_wall_min=25`, `max_files=40`, `max_depth=3` (seed/orient shallower; dig uses planned subset).

### CONFIRM.json

`confirm_kind` (`scan_plan` in P1), `subject_ref` (path to SCAN_PLAN), `payload_hash`, `hash_alg: "sha256"`, `timestamp`, optional `confirmed_by`.

**`payload_hash`:** SHA-256 hex of UTF-8 bytes of canonical JSON for `scan_plan_v1` only — keys sorted recursively, no insignificant whitespace, JSON numbers/strings as produced by a single agreed serializer (implementation: Python `json.dumps(obj, sort_keys=True, separators=(",", ":"))` or equivalent). Hash **only** those fields listed under SCAN_PLAN JSON; ignore prose outside the fence.

Chat “OK” only triggers writing this file — **file is the gate**.  
Plan change → hash mismatch → `stale_confirm`; recovery without `--force`: clear CONFIRM → re-orient.  
Owner-facing summary MUST show: confirming visible subset, not whole system.

### RunEnvelope

`schema_version`, `pipeline_id`, `run_id`, `phase`, `mode`, `artifact_uris[]`, `survey_refs[]`, `gap_ids[]`.

**`nested_dispatch` (required for Mode=full nested; omit or empty ⇒ must use degraded):**

```json
{
  "investigators": [{"id": "string", "label": "string", "started_at": "ISO-8601"}],
  "reviewers": [{"id": "string", "label": "string", "started_at": "ISO-8601"}],
  "critique_verdict_summary": "APPROVE|REJECT|NEEDS_REVISION|INCONCLUSIVE"
}
```

`id` should be Task/subagent identifier when the platform exposes one; otherwise a parent-generated unique label for this run.  
**Mode literal values:** exactly `"degraded"` or `"full nested"` (not shorthand `full`).  
**Mode=`"full nested"` requires** `investigators.length ≥ 1` **and** `reviewers.length ≥ 1`; if either array is empty/missing ⇒ verify FAIL and reports must use `"degraded"`.

### GapQuestion

`kind: missing_repo|observability|owner|deploy|contract`, `why_blocks_hot_path`, `owner_action`, `unanswered`.

### UploadManifest (P1 stub only)

`schema_version`, path allowlist, redaction_policy, forbid whole-hub upload. **No upload behavior in P1.**

### DECISIONS

Reserve `source: human|auto` / `AUTO_DECIDED`. **P1 forbids auto-decide writes.**

## Gates (mechanical)

1. **`assert_gate`:** matching CONFIRM hash required before `analyzing`; sole hard gate into dig.
2. **Pin:** `verify-pins` fail → cannot enter analyzing; owner-language recovery.
3. **Mode:** default `degraded`; `full nested` only if RunEnvelope has investigator+reviewer dispatch records; verify **FAIL** on fake full; `degraded` is legitimate success.
4. **Install allowlist:** symlink package skills + optional thin project rule + hub skeleton; agent must not use `--force` without explicit user approval recorded.
5. **Preview fail-soft:** dual MD + footprints = DONE even if preview fails (record in RUNS).

P1 scripts only: `assert_gate`, install MANIFEST/allowlist, verify degraded-aware. Everything else is skill MD + templates.

## Survey matrix

**Default SKIP.** MUST iff one of:

- Unknown deploy topology that would change hypotheses;
- Critical RootRef `missing`/`external_ref` on SCAN_PLAN hot path;
- Owner explicitly asks for prior art;
- Fresh nested reviewer escalates.

Session = `run_id`; ≤1 short survey; optional second only on reviewer escalate.  
Timing: after CONFIRM, after first hypotheses — not a 30-question intake.  
Cache fingerprint (same hub + plan/symptom) → SKIP.  
User “skip web” → SKIP.

## Model routing B

| Level | Meaning (package glossary SSOT) | Slug |
|-------|----------------------------------|------|
| L0 | No research dispatch | — |
| L1 | Cheap short look | Hub/init config (default prefer composer-2.5-fast) |
| L2 | Standard multi-facet | Configurable |
| L3 | Heavy model | Configurable (e.g. grok-4.5); if unavailable → degrade + `degraded_model`; never pretend L3 |

Skills reference **level ids only**, never hardcode slugs in SKILL body.

## section-gate-review

- Independent process skill; invoked by Vibage design orchestration — not hard-wired into generic brainstorming.
- Trigger: before next design/plan section, or user “§N OK” without prior gate for that digest.
- In: `section_id`, `draft_digest`, `lenses[3]`, `max_rounds≤2`.
- Out: `APPROVE|APPROVE_WITH_CHANGES|REJECT`, `must_fix[]`, `go_next`, `review_run_id`.
- Stop: no REJECT and must_fixes absorbed; or 2 rounds; or human skip.
- APPROVE_WITH_CHANGES → L0 checklist verify (no new 3-agent round); REJECT → optional round 2.
- Cap ≤6 agent calls/section; reviewers must not recurse into section-gate/research; same hash idempotent skip.
- Default models L1/L2 via routing B.

## Scenario matrix (P1 acceptance)

| ID | Scenario | Expected |
|----|----------|----------|
| S1 | Empty parent | init+orient; no dig without roots |
| S1b | Repos added later | re-orient; stale CONFIRM |
| S2 | Many `.git` roots | orient→CONFIRM→locate with budget |
| S3 | Vibing single repo | still light SCAN_PLAN+CONFIRM |
| S4 | Path iron evidence | locate; survey SKIP |
| S5 | Missing deploy/infra | GapQuestion; MUST survey if hot path |
| S6 | Missing Grafana/DB/… | ask after analysis |
| S7 | One-line install+analyze | stop at awaiting_confirm |
| S8 | Pin fail | block analyzing |
| S9 | Design section gate | section-gate; `go_next` ≠ Mode |
| S10 | User skips web | survey SKIP |
| S11 | Post-CONFIRM delivery | dual MD + RUNS + preview fail-soft + soft CTA |
| S12 | Resume | read STATUS/RUNS; do not wipe CONFIRM via re-init |
| S13 | Reject/change plan | clear/re-CONFIRM; hash mismatch blocks analyzing |
| S14 | Stale CONFIRM | phase stale_confirm; re-orient/confirm |

Columns must not mix: `phase` ≠ `Mode` ≠ section-gate `go_next`.

## Happy path (non-coder)

1. Open parent folder in Cursor.  
2. “Install Vibage and start analysis.”  
3. Agent: install (no silent `--force`) → plain-language root list + time estimate → ask for 確認.  
4. User confirms → CONFIRM.json written.  
5. Dig (optional short survey) → dual reports → localhost preview → soft CTA.

## Error / degrade table

| Failure | Behavior |
|---------|----------|
| Pin fail | Block analyzing; owner-language recovery |
| No/mismatched CONFIRM | assert_gate hard stop |
| Nested unavailable / not dispatched | Mode=degraded; still deliver dual MD |
| Survey budget / model missing | SKIP or degraded_model; continue local |
| Preview fail | Record RUNS; do not block DONE |
| Site TBD | CTA “not published yet” |
| User refuses confirm | Remain awaiting_confirm; allow plan edit |

## Deliverables (P1 implementation)

| Item | Path / note |
|------|-------------|
| Skills | `skills/vibage-init/`, `orient/`, evolve `locate/`, `research-survey-review/`, `section-gate-review/` |
| Scripts | `assert_gate`, install MANIFEST/allowlist, verify Mode honesty |
| References | scenario matrix, L0–L3 glossary, GapQuestion template, hub templates, UploadManifest stub |
| Preview | `vibage-preview` assets + serve instructions (localhost) |
| NEW-CHAT | dispatcher only |
| STATUS (package) | keep root `STATUS.md` updated when phase/success changes |
| Center-file whitelist | new skill may touch: `skills/<name>/`, matrix row, optional template, MANIFEST — not locate body / NEW-CHAT procedure copies |
| DEPENDENCIES | `required` superpowers; `optional` graphify later; `first_party` same release |

## Success criteria (P1 done)

- Scenarios S1–S14 behave as table (manual or scripted checks where applicable).  
- `assert_gate` blocks analyzing without CONFIRM.  
- Fake `Mode: full nested` fails verify.  
- Preview failure still yields DONE with dual MD.  
- Soft CTA never blocks local reports.  
- Package `STATUS.md` capability matrix P1 column is honest YES for listed rows.

## Out of scope follow-ups

P2/P3 success/non-goals: see package `STATUS.md`. Specs for those phases are separate documents.

## Design history

Brainstorming 2026-07-22: approach 2; B+D wow; routing B; research + section-gate as first-class process skills; three-phase map; §1–§4 approved after multi-agent section gates. Web research informed hub/seed/confirm, soft vs hard gates, local-first preview.
