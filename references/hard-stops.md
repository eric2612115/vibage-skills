# Vibage hard stops (SSOT)

Shared DO NOT / MUST for all surfaces (Cursor, Claude Code, Codex). Thin IDE adapters and skills **reference this file** — do not fork long copies.

## Language

- Match the **owner's language** in chat and `VIBAGE-ISSUE-OWNER.md`. Never assume Traditional Chinese.
- Paths, identifiers, template section titles stay English inside engineer artifacts.

## Routing scope

- Do not silently invent in-scope vs out-of-scope. Unclear → ask. Out of scope → one-line disclosure; do not run init/orient/locate. See `references/routing-scope.md`.

## Install / hub

- No silent `--force`. `--force` only replaces package-owned stale **skill symlinks**; never delete real skill directories or foreign symlinks.
- Do not wipe `CONFIRM.json` via casual re-init.
- Do not invent site URLs or commercial claims.

## Locate / reports

- Dual reports only after the correct gate: hub init → orient → CONFIRM → `assert_gate` → dig.
- MUST attempt nested investigators → fresh reviewers → synthesize (`references/nested-protocol.md`).
- `Mode: full nested` / `mode: "full nested"` **only** when investigators and reviewers were actually dispatched and recorded. Otherwise `Mode: degraded` (legitimate success).
- Engineer findings ≤ 7 after review; kill anything without `path` + evidence quote.
- Local delivery ends at dual Markdown reports + optional preview (fail-soft) + **required** live `docs/vibage/WORK_CONTINUE.md` verified via `verify-work-continue.sh` before plain `locate DONE` (D1). Dual reports alone ≠ DONE. Exception only via `WORK_CONTINUE_EXCEPTION.md` and exact `locate DONE (WORK_CONTINUE_EXCEPTION)`.
- Do not pretend there is no post-locate memory when a verified `WORK_CONTINUE` exists; do not start a side-quest without updating `side_quest`.
- No whole-repo upload.

## Safety

- No business code edits, no deploy, no push, unless the owner explicitly asks for a scoped follow-up.
- No `.env` / secret values in chat or reports.
- Do not claim SOC2 / "passed audit" / fake health scores.
- Prefer local search; do not upload whole repos to third parties.

## Role boundaries

- `vibage-init` — install/hub only; no OWNER/LOCATE; no deep dig.
- `vibage-pile-index` — shallow nameplate map only (`PILE_INDEX_OK`); ≠ understood ≠ Architecture Pass; no dig; no issue-fix.
- `vibage-map-deepen` — thin pointer to dimension-fill; claim only via `verify-dimension-fill.sh` → `DIMENSION_FILL_*` (`MAP_DEEPEN_OK` brand retired; migrate shim never emits it); no green-shrink; ≠ Plan-L Mermaid/Graphify; ≠ CONFIRM; ≠ dig-all; ∉ `assert_gate` / Tier-0.
- `vibage-orient` — SCAN_PLAN + awaiting_confirm; no dig; no dual reports. Deepen ≠ dig authorization.
- `vibage-locate` / `vibage-issue-locate` — dig only after `assert_gate`; dig ⊆ `planned_dig_ids`; do not redefine model routing; do not dig all map services because deepen finished.
- `vibage-issue-fix` — optional; dual consent (OWNER_POLICY YES + unlock); preference NO does not block locate DONE; **never** fix from thin map / folder-name match alone.
- `vibage-arch-review` (architecture review) — optional; qualified map required; without dimension-fill depth stay floor-only / nameplate; map fail does not undo locate DONE; ≠ Architecture Pass; does not unlock issue-fix.
- `vibage-bootstrap` — hand off to `vibage-init`.
- `research-survey-review` / `section-gate-review` — do not call `vibage-*` product skills.

## Map / dimension-fill honesty

- After `PILE_INDEX_OK`: say nameplate index; cost band for N; ask dimension-fill yes/no; ticket paste = implicit no.
- No SaaS / register / Architecture Pass upsell in cost talk.
- Child workspace (S03): do not deepen/index whole pile; ask open parent.
- Legacy `deepen_yes` / `MAP_DEEPEN_OK` do not authorize fill or dig.

## Docs / context

- Live SSOT = package `STATUS.md` + live files under `docs/superpowers/` + `docs/evidence/` + skills/scripts.
- Do **not** restore deleted `docs/archive/**` from git history into the working context unless the owner explicitly asks for archaeology.
- Pre-C′ plans are gone from the tree on purpose — history ≠ current instructions.
