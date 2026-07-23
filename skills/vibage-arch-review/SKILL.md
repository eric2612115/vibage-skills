---
name: vibage-arch-review
description: >-
  Optional 架構檢視 / Service map track. Requires a qualified map. Map failure
  blocks only this track — never undoes locate DONE.
---

# Vibage 架構檢視 (Service map — optional track stub)

**Status:** stub — map-qualified hard gate only. Thick behavior → `SAT-arch-review` + `SAT-map-schema`.

**Track independence:** Locate DONE does **not** require this track. Map underqualified → block **only** 架構檢視; leave locate DONE intact.

**Handoff:** `artifacts_ok` does **not** cross pipelines by default. Do not treat locate-wave handoff reuse as map/architecture proof.

## Hard gates (MUST)

1. Require a **qualified** service map under `docs/vibage/maps/` per Hybrid bar (MEDIUM quality; Tiny / Subset / Large rhythm) — see `SAT-map-schema`.
2. If map is missing or underqualified: stop this track with a plain owner sentence; **do not** rewrite locate DONE / dual reports.
3. Do not edit business code here (that is `vibage-issue-fix` after dual consent).
4. Do not dig without locate/orient gates when locating is still needed; this track is not a locate substitute.
5. English IDs: `pipeline_id` / track ≈ `service_map` / 架構檢視 — not cloud "Architecture Pass".

## When / Not

| When | Not |
|------|-----|
| Qualified map present | Underqualified / missing map |
| Architecture / Service map review | Block or undo locate DONE |
| Optional after locate | Claim issue-fix unlock |

## PKG_ROOT

```bash
bash /path/to/vibage-skills/scripts/resolve-pkg-root.sh
```

Obey `$PKG_ROOT/references/hard-stops.md`.
