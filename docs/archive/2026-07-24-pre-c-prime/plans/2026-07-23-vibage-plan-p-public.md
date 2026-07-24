> **ARCHIVED · DO NOT EXECUTE as live SSOT.**
> Live C′ plan: `docs/superpowers/plans/2026-07-25-vibage-c-prime-graph-brief-ledger.md`

# Plan-P — Public shell (LICENSE → origin → Tier-0 CI)

> **For agentic workers:** Execute only after human provides copyright string + GitHub login/repo. Do not violate `SAT-ci-remote`: **no** `.github/workflows/*.yml` while `origin` is missing.

**Goal:** Raise dim13 (public-release readiness) honestly: filled LICENSE, git `origin`, GitHub Actions that runs **only** `bash scripts/test-tier0.sh`, STATUS P7 updated from SKIPPED to remote-CI-on-tree (Proven only after Actions green).

**Architecture:** Follow `SAT-ci-remote.md`. Order is locked: LICENSE → create/push remote → **then** add workflow → push → confirm Actions → update STATUS/tests. Marketplace listing is optional follow-on (not required for “public git + CI”).

**Tech Stack:** git, gh, GitHub Actions, Markdown STATUS.

---

## Hard locks

| ID | Lock |
|----|------|
| P0 | No workflow YAML on tree until `git remote` has `origin` |
| P1 | Workflow job = exactly `bash scripts/test-tier0.sh` (no widening) |
| P2 | Local `TIER0_OK` ≠ remote CI Proven until Actions run is green |
| P3 | No SaaS / register CTA; no publish-ready slogan before remote green |
| P4 | `tests/test_ci_remote_skip.sh` must be updated for “has origin → workflow required” branch |

---

### Task 1: LICENSE copyright

- [ ] Human provides copyright holder string (e.g. `Eric Fang` or company).
- [ ] Replace `[TBD — Eric to fill]` in `LICENSE` (+ README License line if needed).
- [ ] Commit.

### Task 2: GitHub origin

- [ ] Human: `gh auth login` (currently **not** logged in).
- [ ] Create public repo (recommended name: `vibage-skills`) under chosen org/user.
- [ ] `git remote add origin <url>` + `git push -u origin main` (only when human asks to push).
- [ ] Verify `git remote -v` shows `origin`.

### Task 3: Tier-0 workflow (only after origin)

- [ ] Create `.github/workflows/tier0.yml` — on push/PR to main, checkout, run `bash scripts/test-tier0.sh`.
- [ ] Update `SAT-ci-remote.md` §1 wording if needed (SKIPPED only when no origin).
- [ ] Update `tests/test_ci_remote_skip.sh`: no origin → no workflows; **has origin** → workflow exists + STATUS not claiming SKIPPED forever.
- [ ] Update `STATUS.md` P7: origin present; workflow on-tree; Proven-green only after Actions pass (or honest “pending first green”).
- [ ] Push; wait for Actions; record result.

### Task 4: Stranger clone smoke (optional same day)

- [ ] Fresh clone elsewhere → install → `test-tier0.sh` → `TIER0_OK`.
- [ ] Do **not** claim marketplace done unless separately listed.

---

## Out

- Marketplace plugin manifests (optional Plan-P2)
- SaaS thicken
- Widening CI beyond Tier-0

## Success

- LICENSE filled  
- `origin` exists  
- Workflow on-tree + Actions green → may claim remote CI Proven for Tier-0 mirror only  
- Dim13 meaningfully up; still ≠ SaaS  
