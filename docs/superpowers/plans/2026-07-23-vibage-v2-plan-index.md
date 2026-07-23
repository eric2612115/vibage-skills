# Vibage v2 — Plan Index (many small plans)

> **For agentic workers:** Execute plans **in order**. Do not start `Pn` until `P(n-1)` DoD is green (except noted parallels). Use `@superpowers:subagent-driven-development` per plan file. Spec SSOT: `@docs/superpowers/specs/2026-07-23-vibage-v2-superpowers-grade-design.md`.

**Goal:** Ship local complete **C** (Tier-0 script green + honest docs) on a single clean trunk; then optional path-to-B script tracks; then map-depth (Plan M) and B-path agent-proven Focus cards (Plan F).

**Architecture:** Approach 1 thin runtime — merge p1 gate/tests onto vibage trunk, archive conflicting docs, then rename reports, wire `test-tier0.sh`, handoff dual-write, optional tracks, additive `depth:standard` edges verify, append-only Focus cards.

**Tech Stack:** Bash, Python 3, pytest, Markdown skills/templates, Cursor skills install.

---

## Ordered plans

| Order | Plan ID | File | Ship? |
|------:|---------|------|-------|
| 1 | `P0-merge-main` | [2026-07-23-vibage-v2-p0-merge-main.md](./2026-07-23-vibage-v2-p0-merge-main.md) | Prerequisite |
| 2 | `P1-report-hardcut` | [2026-07-23-vibage-v2-p1-report-hardcut.md](./2026-07-23-vibage-v2-p1-report-hardcut.md) | Before Tier-0 name asserts |
| 3 | `P2-tier0-entry` | [2026-07-23-vibage-v2-p2-tier0-entry.md](./2026-07-23-vibage-v2-p2-tier0-entry.md) | **This-wave ship** |
| 4 | `P3-handoff-schema` | [2026-07-23-vibage-v2-p3-handoff-schema.md](./2026-07-23-vibage-v2-p3-handoff-schema.md) | Script-proven UX |
| 5 | `P4-optional-tracks` | [2026-07-23-vibage-v2-p4-p7-follow-ons.md](./2026-07-23-vibage-v2-p4-p7-follow-ons.md) §P4 | Optional |
| 6 | `P5-skill-rename` | same file §P5 | Optional cleanup |
| 7 | `P6-focus-stub` | same file §P6 | Deferred Focus row |
| 8 | `P7-ci-when-remote` | same file §P7 | Only if `git remote` exists |
| 9 | `Focus-agent-pressure` | [2026-07-23-vibage-focus-agent-pressure.md](./2026-07-23-vibage-focus-agent-pressure.md) | After P6 stub + SAT-agent-pressure; Approach 1 thin harness — fixtures/smoke/runbook first; dual-phase agent RED→GREEN deferred; Proven-green only from scorer-PASS (not Tier-0) |
| 10 | `Plan-M` (map-depth) | [2026-07-23-vibage-map-depth.md](./2026-07-23-vibage-map-depth.md) | After path-to-B script-usable; **before** Plan-F. `depth==="standard"` (string) requires non-empty id-valid `edges`; non-string depth FAIL; non-standard edges not validated. Graphify/coverage/render **unlocked by Plan-G** (M Pretty-local ≠终局; deeper L later OK). **Honesty:** Plan M alone ≠ letter B agent-proven; do not touch Focus locate Proven-green / Tier-0 |
| 11 | `Plan-F` (B-path agent-pressure) | [2026-07-23-vibage-focus-b-path-agent-pressure.md](./2026-07-23-vibage-focus-b-path-agent-pressure.md) | After Plan-M + Focus locate C1–C3 Proven-green. Claim id **`B-path agent-proven set`** = `AP-C4-issue-fix` (`issue-fix`) + `AP-C5-service-map` (`service-map`) — **never** call these “this-wave required-set”. **Honesty:** letter B agent-proven ⇔ both dual-PHASE scorer-PASS; claim only after M+F Done; do not redefine/reflip Focus locate Proven-green; path-to-B script-usable unchanged; ≠ fix quality ≠ SaaS ≠ Architecture Pass |
| 12 | `Plan-G` (local prettier maps) | [2026-07-23-vibage-local-prettier-maps.md](./2026-07-23-vibage-local-prettier-maps.md) | After Plan-M (floor + `depth:standard`). **M Pretty-local** — REQUIRED pure-local `render-service-map-preview.sh` → `vibage-preview/service_map.{html,svg}`; OPTIONAL fail-soft `generate-service-map-graph.sh` (`OK:GRAPHIFY_SKIP`); coverage = `COVERAGE_NOTES.md` sidecar (not verify field). Tests: `tests/test_prettier_maps.sh` **only** (never Tier-0 / optional-track gates). `verify-service-map.sh` zero behavior change. M ≠终局; deeper Graphify/L later OK. No SaaS / Architecture Pass / letter B / Focus rewrite |)
| 13 | `Plan-L` (local-maps deepen) | [2026-07-23-vibage-local-prettier-maps-L.md](./2026-07-23-vibage-local-prettier-maps-L.md) | After Plan-G. **local-maps deepen** (NOT “option L platform done”): always emit non-empty `docs/vibage/maps/graph.mmd` from JSON + `OK:MERMAID`; auto `COVERAGE_NOTES.md` counts via generate script (single writer); `OK:GRAPHIFY_SKIP` = CLI path skipped only (≠ no graph artifact); CLI present → best-effort or honest limitation — never empty-overwrite / never `OK:GRAPHIFY wrote` stub. Tests: `tests/test_prettier_maps_l.sh` **only** (never Tier-0 / optional-track). `verify-service-map.sh` zero diff. **Honesty:** Plan-L ≠终局 ≠ Architecture Pass ≠ SAT option-L platform; deferred≠forever-ban. No SaaS / letter B / Focus rewrite |
| 14 | `Plan-E` (entry docs + SAT-saas-blank) | [2026-07-23-vibage-entry-docs-saas-blank.md](./2026-07-23-vibage-entry-docs-saas-blank.md) | After Plan-L. Thin `SAT-saas-blank` + sync README/NEW-CHAT/adapters to package `STATUS.md`; dual-STATUS rule; no register CTA; optional `tests/test_entry_docs_sync.sh` **only** (never Tier-0). **Honesty:** STATUS firewall; thin SAT ≠ SaaS YES; ≠ publish-ready ≠ score slogan; no Focus / letter B rewrite |
| 15 | `Plan-R` (session entry routing) | [2026-07-23-vibage-session-entry-routing.md](./2026-07-23-vibage-session-entry-routing.md) | After Plan-E. Parent-only thin routers (Cursor/Claude/Codex) + `verify-project-entry.sh`; `--with-project-rule` always writes all three (ignore `--surfaces` for entry); overwrite Cursor `vibage.mdc` (no Skip-forever); AGENTS SSOT=`adapters/shared`. Tests: `tests/test_verify_project_entry.sh` **only** (never Tier-0). **Honesty:** global skills ≠ project routing; `PROJECT_ENTRY_OK` ≠ CONFIRM/locate DONE; not per-child-repo; ≠ SaaS |
| 16 | `Plan-S` (scorecard ≥9 excl. remote/CI) | [2026-07-23-vibage-scorecard-to-nine.md](./2026-07-23-vibage-scorecard-to-nine.md) | After Plan-R. Waves W1 auto-trigger/`using-vibage` → W2 stranger README → W3 pack-health. Target all scorecard dims ≥9 **except** remote/CI class (dim 13 / origin / Actions). Marketplace deferred to Plan-P. Re-score after W3. **Honesty:** ≥9 ≠ SaaS ≠ publish-ready; new scripts ∉ Tier-0 unless later claim |
| 17 | `Plan-P` (public shell) | [2026-07-23-vibage-plan-p-public.md](./2026-07-23-vibage-plan-p-public.md) | After Plan-S. LICENSE → `origin` → Tier-0-only Actions (SAT-ci-remote). **No workflow YAML while origin missing.** Marketplace optional later. ≠ SaaS |
## Satellites (thick docs; not blocking P0–P2 ship)

Write under `docs/superpowers/specs/satellites/` when starting the matching plan:

| ID | When |
|----|------|
| `SAT-map-schema` | Before implementing 架構檢視 depth |
| `SAT-issue-fix-unlock` | With P4 fix unlock |
| `SAT-arch-review` | With P4 架構檢視 |
| `SAT-agent-pressure` | With Focus execution (after P6 stub) |
| `SAT-ci-remote` | With P7 |
| `SAT-saas-blank` | Anytime; no local CTA |
| `SAT-optional-proof` | With Plan-S W3; command→YES→not table (∉ Tier-0) |

## Do not execute from

- `docs/superpowers/plans/2026-07-22-vibage-os-p1.md` — archive in P0
- `coverage/*` — archive in P0
- Old soft CTA / `references/feature-call.md` live happy-path links — unlink in P0
