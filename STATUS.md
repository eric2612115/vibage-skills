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

**SaaS blank pointer:** reserved seam only — `docs/superpowers/specs/satellites/SAT-saas-blank.md`. Thin SAT on tree ≠ Designed/On-tree/Proven YES; no local register CTA; ≠ SaaS shipped.

**Parent session entry (Plan-R + Plan-S):** Global skills ≠ project routing. Owner one-liner: **幫我裝 Vibage** (`prompts/SAY-INSTALL-VIBAGE.md`) → agent runs install + `--with-project-rule` + `verify-project-entry` → `PROJECT_ENTRY_OK` (parent only). Cursor `sessionStart` + Claude/Codex always-on (host-best). Skill: `using-vibage` (must-invoke + finishing). Maps for agents: `docs/maps/AI-FIRST.md`. Extend locally: `docs/EXTENDING.md`. **Public GitHub** (owner visibility flip) ≠ marketplace listing ≠ publish-ready ≠ SaaS. Marketplace submit/review is a separate wave; SaaS stays blank. `PROJECT_ENTRY_OK` ≠ CONFIRM / locate DONE.

**Proof layers (do not confuse):** `TIER0_OK` (ship gate) · `PACK_HEALTH_OK` via `scripts/pack-health.sh <parent>` (pins + parent entry + entry-docs + `OWNER_ZERO_BASH_OK` + `INSTALL_PHRASE_OK` + `INSTALL_PHRASE_E2E_OK`; **≠** Tier-0 ≠ remote CI ≠ letter B) · `PROJECT_ENTRY_OK` (parent routers). Capability SSOT remains this file. Optional proof table: `docs/superpowers/specs/satellites/SAT-optional-proof.md`. Local complete checklist: `docs/LOCAL-COMPLETE-CHECKLIST.md`. Focus/B summary index: `docs/evidence/focus/SUMMARY.md`.

This-wave 可交貨 = Plan0 + Tier-0 green. ≠ agent E2E. ≠ publish-ready. Public git clone ≠ marketplace ≠ SaaS.

**Optional issue-fix honesty:** On-tree=YES + Proven-green=YES (scope=`script`) means dual-consent + unlock gates are verifiable via `scripts/verify-issue-fix-unlock.sh` and `tests/test_issue_fix_usable.sh`. That is **not** letter **B** complete, and **not** an agent fix E2E / quality guarantee. `test_issue_fix_usable.sh` is **not** wired into Tier-0.

**Optional 架構檢視 honesty:** On-tree=YES + Proven-green=YES (scope=`script`) means map qualification gates are verifiable via `scripts/verify-service-map.sh` and `tests/test_arch_review_usable.sh` against hub `docs/vibage/maps/service_map.json` (`pipeline_id=service_map`). That is **not** letter **B** from this track alone, **not** agent E2E arch quality, and **not** cloud Architecture Pass. `test_arch_review_usable.sh` is **not** wired into Tier-0. Map verify may enforce `depth:standard` edges; still ≠ letter B agent-proven / ≠ Architecture Pass. Local prettier maps (Plan G / M Pretty-local → Plan-L local-maps deepen): Mermaid `graph.mmd` + auto `COVERAGE_NOTES.md` counts + optional Graphify CLI fail-soft (`OK:GRAPHIFY_SKIP` = CLI skipped only) + `vibage-preview/service_map` render are fail-soft / non-verify; ≠ Architecture Pass; ≠ SAT option-L platform; ≠ letter B rewrite; Plan-L ≠终局 (deferred≠forever-ban).

**path-to-B (script-usable):** issue-fix and 架構檢視 are both Proven-green(script) → **path-to-B script-usable**. That is **≠** agent-proven letter **B**.

**letter B agent-proven** ⇔ `AP-C4-issue-fix` + `AP-C5-service-map` both dual-PHASE scorer-PASS (pack `run_ts=20260723T105500Z`, artifacts gitignored). That is ≠ fix quality guarantee ≠ SaaS ≠ Architecture Pass. Does NOT redefine Focus locate Proven-green (AP-C1…C3 / 20260723T101530Z). path-to-B script-usable remains.

**Handoff note:** `verify-handoff.sh` is locate-wave shaped only (not pipeline-agnostic). `artifacts_ok` does **not** cross pipelines by default (umbrella §8.4).

**Focus:** Designed=YES, On-tree=YES (frozen cards + RUNBOOK + structural smoke), Proven-green=YES via dual-phase pack `run_ts=20260723T101530Z` (artifacts gitignored under `tests/artifacts/agent-pressure/`; evidence not required in git). Not a `pipeline_id`.

**Focus carve-out (scope=agent):** On-tree may become YES when card templates exist; Proven-green is never set by Tier-0, smoke, or ordinary verify scripts — only after this-wave required-set dual-phase agent scorer-PASS. Fixture/smoke presence ≠ agent proof. locate DONE ⊥ Focus.

**P7 / CI:** `origin` present (`https://github.com/eric2612115/vibage-skills`). Workflow on-tree: `.github/workflows/tier0.yml` (runs **only** `bash scripts/test-tier0.sh`). Contract: `docs/superpowers/specs/satellites/SAT-ci-remote.md`. Remote CI Proven-green = **YES** (Actions green after ripgrep+pytest setup; mirrors local Tier-0). Local `TIER0_OK` alone was never enough; remote green is. Still ≠ publish-ready / ≠ SaaS. (Historical no-origin state was SKIPPED.)

Update On-tree / Proven-green only when scripts say so — **except** Focus row (`scope=agent`): see Focus carve-out above. Never YES without proof.
