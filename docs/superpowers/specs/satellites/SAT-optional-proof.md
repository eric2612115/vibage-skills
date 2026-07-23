# SAT-optional-proof

**Owns:** How to prove optional tracks / Focus claims without lying that Tier-0 covers them.  
**Not:** Capability SSOT (that remains package `STATUS.md`).

## Command → YES means → not

| Command / artifact | YES means | Not |
|--------------------|-----------|-----|
| `bash scripts/test-tier0.sh` → `TIER0_OK` | Core locate ship gate green | pin · parent entry · letter B · remote CI |
| `bash scripts/pack-health.sh <parent>` → `PACK_HEALTH_OK` | pins + parent entry + entry-docs + owner/install phrase checks | Tier-0 · letter B · remote CI |
| `bash tests/test_install_phrase.sh` → `INSTALL_PHRASE_OK` | 「幫我裝 Vibage」path documented + wired | agent E2E video · dig |
| `bash scripts/verify-project-entry.sh <parent>` → `PROJECT_ENTRY_OK` | Parent Cursor/Claude/Codex routers on disk | CONFIRM · locate DONE |
| `bash tests/test_issue_fix_usable.sh` | issue-fix unlock gates script-usable | letter B · fix quality |
| `bash tests/test_arch_review_usable.sh` | service_map qualification script-usable | Architecture Pass · letter B alone |
| `docs/evidence/focus/SUMMARY.md` | Committed index of Focus / B-path packs | Full artifacts in git · Tier-0 proof |

## Map (AI-first)

- Qualification: `scripts/verify-service-map.sh` against hub `docs/vibage/maps/service_map.json`
- Graph for agents: `docs/vibage/maps/graph.mmd` via `scripts/generate-service-map-graph.sh`
- Human preview optional: `scripts/render-service-map-preview.sh`
- Graphify CLI is fail-soft optional — humans rarely stare at it; AI/script usefulness is the bar

## Handoff

`verify-handoff.sh` is **locate-wave shaped**. Map/fix have their own verify scripts. Do not assume cross-pipeline `artifacts_ok`.
