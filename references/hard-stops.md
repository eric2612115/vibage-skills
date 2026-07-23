# Vibage hard stops (SSOT)

Shared DO NOT / MUST for all surfaces (Cursor, Claude Code, Codex). Thin IDE adapters and skills **reference this file** — do not fork long copies.

## Language

- Match the **owner's language** in chat and `VIBAGE-OWNER.md`. Never assume Traditional Chinese.
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
- `vibage-orient` — SCAN_PLAN + awaiting_confirm; no dig; no dual reports.
- `vibage-locate` — dig only after `assert_gate`; do not redefine model routing.
- `vibage-bootstrap` — hand off to `vibage-init`.
- `research-survey-review` / `section-gate-review` — do not call `vibage-*` product skills.
