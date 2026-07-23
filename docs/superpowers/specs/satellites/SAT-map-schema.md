# SAT-map-schema

**Owns:** Service map schema, Hybrid Tiny / Subset / Large rhythm, qualification bar, script-verifiable floor.  
**Consumed by:** 架構檢視 (`vibage-arch-review`)  
**Verify:** `scripts/verify-service-map.sh <workspace_root>`  
**Hub path (fixed):** `docs/vibage/maps/service_map.json`  
**Umbrella:** §5.1 Maps

**Usable (this wave):** Map qualification gates are **script-proven** (verify + fixture tests). That is **not** letter **B** complete, **not** agent E2E architecture quality, and **not** cloud Architecture Pass.

---

## 1. Qualification (Hybrid)

| Knob | Rule |
|------|------|
| **quality_bar** | Always **`MEDIUM`** (string). Any other value → underqualified. |
| **scale** | Rhythm only: `Tiny` \| `Subset` \| `Large`. Does not lower the quality bar. |

Map **missing** or **underqualified** → block **only** the 架構檢視 track. Locate DONE stays intact.

---

## 2. Hub path (fixed)

- Workspace file verified: **`docs/vibage/maps/service_map.json`** only.
- No ambiguous glob; other files under `docs/vibage/maps/` are ignored by this wave's verify.
- Package example shape: `docs/superpowers/specs/satellites/service_map.example.json` (copy into hub path).

---

## 3. Minimal schema (floor, not ceiling)

B2 required keys — **floor** for qualification. Unknown / extra keys **must not** fail verify.

| Key | Rule |
|-----|------|
| `schema_version` | present string (this wave `"1"`) |
| `pipeline_id` | exact string `"service_map"` (no synonyms) |
| `scale` | `Tiny` \| `Subset` \| `Large` |
| `quality_bar` | exact string `"MEDIUM"` |
| `services` | non-empty list; **each** item is an object with non-empty string `id` |

### 3.1 Optional additive fields

Absent OK on floor. Presence does not fail unless rules below say otherwise.

| Key | Rule |
|-----|------|
| `notes` | free string |
| `generated_at` | ISO-8601 string recommended |
| `depth` | If present: **must be a string**. Non-string → FAIL. If string equals exactly `"standard"` → edges rules below. Any other string → **do not** validate `edges`. |
| `edges` | Array of objects `{ "from": string, "to": string }`. On floor / non-`standard` depth: may be absent or present; **not validated**. |
| `services[].name` | Recommended string; **not** required on floor. |

**When `depth === "standard"` (string equality only):**

1. `edges` must be a **non-empty** array.
2. Each element must be an object with string `from` and `to`.
3. Every `from` and `to` must be ∈ the set of `services[].id` values.
4. Else → FAIL (underqualified for this verify).

**Explicit:**

- `depth` missing → B2 floor only (current behavior).
- `depth: "deeper"` / `"tiny"` / any non-`standard` string → B2 floor; if `edges` present, **skip** edges validation (may be garbage; still OK for this wave).
- `depth: 1` / `true` / `null` (JSON null as value) / object → FAIL (non-string).
- Unknown keys still must not fail.

Forward-compat: richer maps may add keys or bump `schema_version` later. Verify must stay additive-friendly (unknown keys OK).

---

## 4. Script verify

```bash
bash "$PKG_ROOT/scripts/verify-service-map.sh" <workspace_root>
```

Exit **0** only when hub `docs/vibage/maps/service_map.json` exists and passes the floor schema above, and — when `depth === "standard"` — the edges rules in §3.1.

Exit **non-zero** for: missing file, unreadable JSON, wrong `pipeline_id`, `quality_bar` ≠ `MEDIUM`, bad/missing `scale`, empty `services`, any service lacking non-empty string `id`, non-string `depth`, or `depth === "standard"` with missing/empty/id-invalid `edges`.

Print clear `OK:` / `FAIL:` lines. Fixture proof: `tests/test_arch_review_usable.sh` (optional track; **not** wired into Tier-0).

---

## 5. Honesty

- `usable` + package `STATUS` Proven-green(script) for 架構檢視 = **map qualification gates verifiable**.
- Does **not** mean letter **B** from this track alone.
- Does **not** guarantee agent E2E arch quality.
- Does **not** equal cloud **Architecture Pass**.

---

## 6. Out of scope / adjacent local prettier (Plan G → Plan-L)

**Verify (`scripts/verify-service-map.sh`) still does not require** Graphify, coverage notes, Mermaid, or preview artifacts. Missing prettier sidecars must not fail map qualification.

**Plan G (M Pretty-local) unlocks locally (optional / fail-soft):**

| Piece | Contract |
|-------|----------|
| Render | `scripts/render-service-map-preview.sh` → workspace `vibage-preview/service_map.html` (+ `.svg`); pure local; no external binary on success path |
| Graphify wrapper | `scripts/generate-service-map-graph.sh` OPTIONAL fail-soft |
| Coverage | Sidecar `docs/vibage/maps/COVERAGE_NOTES.md` — **not** a verify field; not a floor gate |

**Plan-L (local-maps deepen)** deepens the generator (still local / fail-soft; still not a verify gate):

| Piece | Contract |
|-------|----------|
| Mermaid | When hub `service_map.json` is present, always emit non-empty `docs/vibage/maps/graph.mmd` from JSON; stdout `OK:MERMAID` on success |
| Graphify CLI | `OK:GRAPHIFY_SKIP` = **CLI path skipped only** — never means “no graph artifact”. CLI present → best-effort or honest limitation (`OK:GRAPHIFY_LIMITATION`). **Never** overwrite `graph.mmd` with empty; **never** claim `OK:GRAPHIFY wrote` for an empty stub |
| Coverage | Auto-written by the same generate script (single writer) with at least `services_count` / `edges_count` from JSON |

**Honesty:** Plan-G M Pretty-local **≠终局**. Plan-L **local-maps deepen ≠终局**; **≠** SAT platform option-L (coverage gates / interactive dashboard); **≠** Architecture Pass; **≠** letter B. `deferred-closed ≠ forever-forbidden`. Cloud whole-repo upload/analysis remain out of scope (do not rewrite PRODUCT-LOCKS to a forever local ban).

**Still out of this wave (adjacent):**

- Agent E2E / Focus cards for 架構檢視
- Changing Tier-0 to require `test_arch_review_usable.sh`
