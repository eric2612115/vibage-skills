# Service map — AI-first (humans optional)

**Who cares:** agents doing 架構檢視 / locate context. Humans rarely stare at big graphs.

| Artifact | Role |
|----------|------|
| `docs/vibage/maps/service_map.json` | **Truth for gates** — `verify-service-map.sh` (inventory; ≠ understood) |
| `docs/vibage/dossiers/<id>.md` | Optional nested deepen output — `verify-map-deepen.sh` → `MAP_DEEPEN_OK` (≠ Plan-L Graphify; ≠ CONFIRM) |
| `docs/vibage/maps/graph.mmd` | Compact graph for agents — `generate-service-map-graph.sh` → `OK:MERMAID` |
| `docs/vibage/maps/COVERAGE_NOTES.md` | Counts sidecar (not a verify field) |
| `vibage-preview/service_map.{html,svg}` | Optional human glance — `render-service-map-preview.sh` |

**One-command (agent):** from a workspace that already has a qualified `service_map.json`:

```bash
bash "$PKG_ROOT/scripts/generate-service-map-graph.sh" "$WORKSPACE"
# optional: bash "$PKG_ROOT/scripts/render-service-map-preview.sh" "$WORKSPACE"
```

**Honesty:** Graphify CLI is fail-soft (`OK:GRAPHIFY_SKIP`). Map qualify ≠ Architecture Pass ≠ letter B alone. Plan-L Mermaid/Graphify ≠ cost-consented `vibage-map-deepen` / `MAP_DEEPEN_OK`.
