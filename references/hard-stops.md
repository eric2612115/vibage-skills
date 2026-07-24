# Vibage hard stops (SSOT)

Shared DO NOT / MUST for all surfaces (Cursor, Claude Code, Codex). Thin IDE adapters and skills **reference this file** — do not fork long copies.

## Language

- Match the **owner's language** in chat and `VIBAGE-ISSUE-OWNER.md`. Never assume Traditional Chinese.
- Paths, identifiers, template section titles stay English inside engineer artifacts.

## Install / hub

- No silent `--force`. `--force` only replaces package-owned stale **skill symlinks**; never delete real skill directories or foreign symlinks.
- Do not wipe `CONFIRM.json` via casual re-init.
- Do not invent site URLs or commercial claims.

## Locate / reports

- Dual reports only after the correct gate: hub init → orient → CONFIRM → `assert_gate` → dig.
- MUST attempt nested investigators → fresh reviewers → synthesize (`references/nested-protocol.md`).
- `Mode: full nested` / `mode: "full nested"` **only** when investigators and reviewers were actually dispatched and recorded. Otherwise `Mode: degraded` (legitimate success).
- Engineer findings ≤ 7 after review; kill anything without `path` + evidence quote.
- Local delivery ends at dual Markdown reports + optional preview (fail-soft).
- No whole-repo upload.

## Safety

- No business code edits, no deploy, no push, unless the owner explicitly asks for a scoped follow-up.
- No `.env` / secret values in chat or reports.
- Do not claim SOC2 / "passed audit" / fake health scores.
- Prefer local search; do not upload whole repos to third parties.

## Role boundaries

- `vibage-init` — install/hub only; no OWNER/LOCATE; no deep dig.
- `vibage-pile-index` — shallow nameplate map only (`PILE_INDEX_OK`); ≠ understood ≠ Architecture Pass; no dig; no issue-fix.
- `vibage-map-deepen` — optional nested dossiers after cost + model-tier + scope freeze; claim complete only via `verify-map-deepen.sh` → `MAP_DEEPEN_OK`; no green-shrink; ≠ Plan-L Mermaid/Graphify; ≠ CONFIRM; ≠ dig-all; ∉ `assert_gate` / Tier-0.
- `vibage-orient` — SCAN_PLAN + awaiting_confirm; no dig; no dual reports. Deepen ≠ dig authorization.
- `vibage-locate` / `vibage-issue-locate` — dig only after `assert_gate`; dig ⊆ `planned_dig_ids`; do not redefine model routing; do not dig all map services because deepen finished.
- `vibage-issue-fix` — optional; dual consent (OWNER_POLICY YES + unlock); preference NO does not block locate DONE; **never** fix from thin map / folder-name match alone.
- `vibage-arch-review` (架構檢視) — optional; qualified map required; without `MAP_DEEPEN_OK` stay floor-only / nameplate; map fail does not undo locate DONE; ≠ Architecture Pass; does not unlock issue-fix.
- `vibage-bootstrap` — hand off to `vibage-init`.
- `research-survey-review` / `section-gate-review` — do not call `vibage-*` product skills.

## Map / deepen honesty

- After `PILE_INDEX_OK`: say nameplate index; cost band for N; ask deepen yes/no; ticket paste = implicit no.
- No SaaS / register / Architecture Pass upsell in cost talk.
- Child workspace (S03): do not deepen/index whole pile; ask open parent.
