# Vibage Skills — STATUS

> Package progress SSOT (not hub runtime STATUS). Hub runtime lives under owner workspace `docs/vibage/STATUS.md`.

**Spec:** `docs/superpowers/specs/2026-07-23-vibage-v2-superpowers-grade-design.md`  
**Plans:** `docs/superpowers/plans/2026-07-23-vibage-v2-plan-index.md`

## Capability (this wave)

| Capability | Designed | On-tree | Proven-green | Scope |
|------------|----------|---------|--------------|-------|
| scan_plan_hash + assert_gate | YES | YES | YES | script |
| Tier-0 `scripts/test-tier0.sh` | YES | YES | YES | script |
| Report hard-cut VIBAGE-ISSUE-* | YES | YES | YES | script |
| Handoff dual-write | YES | YES | YES | script |
| Optional: issue-fix | YES | YES | YES | script (dual-consent+unlock gates; locate DONE independent) |
| Optional: 架構檢視 | YES | YES | YES | script (map qualification gates; locate DONE independent) |
| Focus: agent-pressure | YES | YES | YES | agent (meta row — **not** a pipeline_id; see SAT-agent-pressure) |
| SaaS / register | blank | — | — | — |

This-wave 可交貨 = Plan0 + Tier-0 green. ≠ agent E2E. ≠ publish-ready.

**Optional issue-fix honesty:** On-tree=YES + Proven-green=YES (scope=`script`) means dual-consent + unlock gates are verifiable via `scripts/verify-issue-fix-unlock.sh` and `tests/test_issue_fix_usable.sh`. That is **not** letter **B** complete, and **not** an agent fix E2E / quality guarantee. `test_issue_fix_usable.sh` is **not** wired into Tier-0.

**Optional 架構檢視 honesty:** On-tree=YES + Proven-green=YES (scope=`script`) means map qualification gates are verifiable via `scripts/verify-service-map.sh` and `tests/test_arch_review_usable.sh` against hub `docs/vibage/maps/service_map.json` (`pipeline_id=service_map`). That is **not** letter **B** from this track alone, **not** agent E2E arch quality, and **not** cloud Architecture Pass. `test_arch_review_usable.sh` is **not** wired into Tier-0. Map verify may enforce `depth:standard` edges; still ≠ letter B agent-proven / ≠ Architecture Pass. Local prettier maps (Plan G / M Pretty-local): optional Graphify sidecar + `COVERAGE_NOTES.md` + `vibage-preview/service_map` render are fail-soft / non-verify; ≠ Architecture Pass; ≠ letter B rewrite; M ≠终局.

**path-to-B (script-usable):** issue-fix and 架構檢視 are both Proven-green(script) → **path-to-B script-usable**. That is **≠** agent-proven letter **B**.

**letter B agent-proven** ⇔ `AP-C4-issue-fix` + `AP-C5-service-map` both dual-PHASE scorer-PASS (pack `run_ts=20260723T105500Z`, artifacts gitignored). That is ≠ fix quality guarantee ≠ SaaS ≠ Architecture Pass. Does NOT redefine Focus locate Proven-green (AP-C1…C3 / 20260723T101530Z). path-to-B script-usable remains.

**Handoff note:** `verify-handoff.sh` is locate-wave shaped only (not pipeline-agnostic). `artifacts_ok` does **not** cross pipelines by default (umbrella §8.4).

**Focus:** Designed=YES, On-tree=YES (frozen cards + RUNBOOK + structural smoke), Proven-green=YES via dual-phase pack `run_ts=20260723T101530Z` (artifacts gitignored under `tests/artifacts/agent-pressure/`; evidence not required in git). Not a `pipeline_id`.

**Focus carve-out (scope=agent):** On-tree may become YES when card templates exist; Proven-green is never set by Tier-0, smoke, or ordinary verify scripts — only after this-wave required-set dual-phase agent scorer-PASS. Fixture/smoke presence ≠ agent proof. locate DONE ⊥ Focus.

**P7 / CI (SKIPPED):** `git remote -v` has **no origin** on this checkout → remote CI workflow **skipped** / **SKIPPED** (no `.github/workflows/*.yml` this wave). Contract: `docs/superpowers/specs/satellites/SAT-ci-remote.md`. Local Tier-0 green (`bash scripts/test-tier0.sh`) is allowed and is **≠** remote CI success. No remote ≠ publish-ready.

Update On-tree / Proven-green only when scripts say so — **except** Focus row (`scope=agent`): see Focus carve-out above. Never YES without proof.
