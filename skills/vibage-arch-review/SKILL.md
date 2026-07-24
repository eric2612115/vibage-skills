---
name: vibage-arch-review
description: >-
  Optional 架構檢視 / Service map track. Requires a qualified map at
  docs/vibage/maps/service_map.json. Map failure blocks only this track —
  never undoes locate DONE. Script-verify via verify-service-map.sh.
  pipeline_id=service_map; not cloud Architecture Pass.
---

# Vibage 架構檢視 (Service map — optional track — usable)

**Status:** usable — map qualification gates are script-verifiable. Thick contract → `SAT-arch-review` + `SAT-map-schema`.

**Honest scope:** Usable + package Proven-green(script) means **map qualification gates are verifiable**. It does **not** mean letter **B** complete from this track alone, does **not** guarantee agent E2E arch quality, and is **not** cloud Architecture Pass.

**Track / `pipeline_id`:** exact `service_map`. Local name: 架構檢視 / Service map.

**Track independence:** Locate DONE does **not** require this track. Map missing/underqualified → block **only** 架構檢視; leave locate DONE and dual reports intact.

**Handoff:** `artifacts_ok` does **not** cross pipelines by default. Do not treat locate-wave handoff reuse as map/architecture proof.

## Hard gates (MUST)

1. Require a **qualified** service map at workspace **`docs/vibage/maps/service_map.json`** (Hybrid: `quality_bar` = **MEDIUM**; `scale` ∈ Tiny / Subset / Large; each `services[]` item has non-empty string `id`) — see `SAT-map-schema`.
2. If map is missing or underqualified: stop this track with a plain owner sentence; **do not** rewrite locate DONE / dual reports.
3. Do not edit business code here (that is `vibage-issue-fix` after dual consent).
4. Do not dig without locate/orient gates when locating is still needed; this track is not a locate substitute.
5. English IDs: `pipeline_id` = exact `service_map` — not cloud "Architecture Pass". No SaaS / register CTA.
6. **Thin-map floor (M07):** If there is no successful `verify-map-deepen.sh` / no `MAP_DEEPEN_OK` for this workspace, chat **must** say floor-only / nameplate inventory. **Forbid** “系統已懂 / Architecture Pass / 可安心改碼”. `verify-service-map` green = inventory qualification only, not understanding. This track does **not** unlock `issue-fix`. Plan-L Mermaid/Graphify prettier ≠ `vibage-map-deepen`.

## Usable procedure

1. Resolve package root:

```bash
PKG_ROOT="$(bash /path/to/vibage-skills/scripts/resolve-pkg-root.sh)"
```

2. Ensure hub map exists at `docs/vibage/maps/service_map.json`. Package shape: `$PKG_ROOT/docs/superpowers/specs/satellites/service_map.example.json`.
3. **Verify before treating the map as qualified:**

```bash
bash "$PKG_ROOT/scripts/verify-service-map.sh" <workspace_root>
```

   Exit 0 required. On FAIL → stop this track only; locate DONE unchanged.
   When the map sets `depth: "standard"`, verify also requires non-empty id-valid `edges` (see `SAT-map-schema`). Floor maps without that flag remain valid.
4. On OK → review architecture / Service map from the qualified map. If no `MAP_DEEPEN_OK`, open with anti-illusion: floor nameplate only. Do not edit business code. Do not solicit SaaS.
5. **Optional local prettier (Plan G → Plan-L local-maps deepen)** after verify exits 0 (fail-soft; never undoes map usable / locate DONE; ≠ Architecture Pass; ≠ letter B; ≠ SAT option-L platform; **≠** cost-consented `vibage-map-deepen`):
   - OPTIONAL generate: `bash "$PKG_ROOT/scripts/generate-service-map-graph.sh" <workspace_root>`
     - Always emits non-empty `docs/vibage/maps/graph.mmd` when hub map present → expect `OK:MERMAID`.
     - Auto-writes `docs/vibage/maps/COVERAGE_NOTES.md` with `services_count` / `edges_count` (**single writer**; **not** a verify field).
     - If Graphify CLI missing → exit 0 + `OK:GRAPHIFY_SKIP` + owner sentence = CLI path skipped only (≠ no graph artifact).
     - If CLI present → best-effort or honest limitation; never empty-overwrite Mermaid; never claim `OK:GRAPHIFY wrote` for a stub.
   - REQUIRED pure-local preview: `bash "$PKG_ROOT/scripts/render-service-map-preview.sh" <workspace_root>` → `vibage-preview/service_map.html` + `.svg`. Soft skip → exit 0 + `OK:RENDER_SKIP` + owner sentence.
6. Summarize for owner; do not claim letter B or agent E2E proof from this script alone. Plan-L local-maps deepen ≠终局 (deferred≠forever-ban).

### Thin coverage notes (auto; single writer)

Prefer letting `generate-service-map-graph.sh` write workspace `docs/vibage/maps/COVERAGE_NOTES.md` (not a `service_map.json` verify field):

- Includes at least `services_count` / `edges_count` from hub JSON
- Agents may append narrative below; **do not** treat absence as `verify-service-map` FAIL
- **Do not** dual-write conflicting count blocks from skill alone when the generator already ran

## When / Not

| When | Not |
|------|-----|
| Qualified map present (verify OK) | Underqualified / missing map |
| Architecture / Service map review | Block or undo locate DONE; rewrite dual reports |
| Optional after locate | Claim issue-fix unlock; edit business code |
| `pipeline_id=service_map` | Cloud Architecture Pass; SaaS CTA |

## PKG_ROOT

```bash
bash /path/to/vibage-skills/scripts/resolve-pkg-root.sh
```

Obey `$PKG_ROOT/references/hard-stops.md`. Full contracts: `$PKG_ROOT/docs/superpowers/specs/satellites/SAT-arch-review.md` and `SAT-map-schema.md`.
