# P1 manual scenario checklist (S1–S14)

Use after scripts smoke is green. Each row is an agent-run checkbox.

## Prep

- [ ] Package installed via `scripts/install.sh` (final MANIFEST)
- [ ] Pins green: `scripts/verify-pins.sh`
- [ ] Fresh parent folder workspace open in Cursor

## Scenarios

- [ ] **S1 Empty parent** — init+orient; SCAN_PLAN with empty/missing roots; stop at awaiting_confirm; no dig
- [ ] **S1b Repos added later** — re-orient; old CONFIRM becomes stale; assert_gate fails until re-confirm
- [ ] **S2 Many `.git` roots** — orient lists roots; CONFIRM; locate digs planned subset only (budgets)
- [ ] **S3 Vibing single repo** — still writes light SCAN_PLAN + CONFIRM before dig
- [ ] **S4 Path iron evidence** — locate delivers dual MD; survey SKIP
- [ ] **S5 Missing deploy/infra on hot path** — GapQuestion; research MUST if hot-path missing/external
- [ ] **S6 Missing Grafana/DB/…** — ask after analysis (GapQuestion), not 30-question intake
- [ ] **S7 One-line install+analyze** — stops at awaiting_confirm (does not auto-dig)
- [ ] **S8 Pin fail** — verify-pins fail blocks analyzing; owner-language recovery
- [ ] **S9 Design section gate** — section-gate-review runs; `go_next` is not Mode
- [ ] **S10 User skips web** — survey SKIP despite optional curiosity
- [ ] **S11 Post-CONFIRM delivery** — dual MD + RUNS + preview fail-soft + soft CTA (preview fail still DONE)
- [ ] **S12 Resume** — STATUS/RUNS read; CONFIRM not wiped by re-init
- [ ] **S13 Reject/change plan** — clear/re-CONFIRM; hash mismatch blocks analyzing
- [ ] **S14 Stale CONFIRM** — phase stale_confirm; re-orient/confirm

## Mechanical gates (scripted already; re-check in agent path)

- [ ] assert_gate blocks dig without CONFIRM
- [ ] Fake `Mode: full nested` / RUNS without investigators+reviewers fails verify-run
- [ ] Soft CTA never blocks local reports

## Package tracker

- [ ] Root `STATUS.md` P1 capability rows set YES only when above are honestly true
