# Vibage v2 — Plan Index (many small plans)

> **For agentic workers:** Execute plans **in order**. Do not start `Pn` until `P(n-1)` DoD is green (except noted parallels). Use `@superpowers:subagent-driven-development` per plan file. Spec SSOT: `@docs/superpowers/specs/2026-07-23-vibage-v2-superpowers-grade-design.md`.

**Goal:** Ship local complete **C** (Tier-0 script green + honest docs) on a single clean trunk; leave B-path and Focus agent-pressure as later plans.

**Architecture:** Approach 1 thin runtime — merge p1 gate/tests onto vibage trunk, archive conflicting docs, then rename reports, wire `test-tier0.sh`, handoff dual-write, optional tracks.

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

## Do not execute from

- `docs/superpowers/plans/2026-07-22-vibage-os-p1.md` — archive in P0
- `coverage/*` — archive in P0
- Old soft CTA / `references/feature-call.md` live happy-path links — unlink in P0
