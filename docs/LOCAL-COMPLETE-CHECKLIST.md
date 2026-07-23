# Local complete checklist (C + path-to-B)

Grep-able OK tokens only. Capability SSOT remains [`STATUS.md`](../STATUS.md).

| Step | Command / path | Token / evidence |
|------|----------------|------------------|
| 0 Owner chat path | README **Owner path** + `tests/fixtures/owner-zero-bash-path.md` | no owner-typed bash (`OWNER_ZERO_BASH_OK`) |
| 0b Install phrase | `prompts/SAY-INSTALL-VIBAGE.md` + fixtures | `INSTALL_PHRASE_OK` |
| 0b2 Install e2e | `tests/test_install_phrase_e2e.sh` (agent-equivalent steps) | `INSTALL_PHRASE_E2E_OK` |
| 0c Map AI-first | `docs/maps/AI-FIRST.md` | agents use JSON + `graph.mmd` |
| 0d Extending | `docs/EXTENDING.md` | add optional skill without marketplace |
| 0e Plugin manifests | `tests/test_plugin_manifests.sh` | `PLUGIN_MANIFESTS_OK` (≠ store listing) |
| 0f Pile index | `bash scripts/pile-index.sh <parent>` | `PILE_INDEX_OK` (≠ Architecture Pass) |
| 1 Ship gate | `bash scripts/test-tier0.sh` | `TIER0_OK` |
| 2 Pack health | `bash scripts/pack-health.sh <parent>` | `PACK_HEALTH_OK` |
| 3 Parent entry | (included in pack-health) | `PROJECT_ENTRY_OK` |
| 4 Optional fix usable | `bash tests/test_issue_fix_usable.sh` | script exit 0 (∉ Tier-0) |
| 5 Optional arch usable | `bash tests/test_arch_review_usable.sh` | script exit 0 (∉ Tier-0) |
| 6 Focus / B index | `docs/evidence/focus/SUMMARY.md` | committed summary present |
| 7 Map AI path | `verify-service-map.sh` + `generate-service-map-graph.sh` | qualify + `graph.mmd` when hub map exists |

**Honesty**

- This checklist ≠ publish-ready ≠ remote CI ≠ SaaS shipped ≠ Architecture Pass  
- `PACK_HEALTH_OK` ≠ `TIER0_OK` ≠ letter B agent-proven  
- path-to-B script-usable ≠ letter B agent-proven (see STATUS)
