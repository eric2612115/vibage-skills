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

Optional (may be absent; presence does not fail):

| Key | Notes |
|-----|-------|
| `notes` | free string |
| `generated_at` | ISO-8601 string recommended |
| `edges` / Graphify / coverage / render fields | **deferred** this wave — additive later; **not** forever-forbidden |

Forward-compat: richer maps may add keys or bump `schema_version` later. Verify must stay additive-friendly (unknown keys OK).

---

## 4. Script verify

```bash
bash "$PKG_ROOT/scripts/verify-service-map.sh" <workspace_root>
```

Exit **0** only when hub `docs/vibage/maps/service_map.json` exists and passes the floor schema above.

Exit **non-zero** for: missing file, unreadable JSON, wrong `pipeline_id`, `quality_bar` ≠ `MEDIUM`, bad/missing `scale`, empty `services`, any service lacking non-empty string `id`.

Print clear `OK:` / `FAIL:` lines. Fixture proof: `tests/test_arch_review_usable.sh` (optional track; **not** wired into Tier-0).

---

## 5. Honesty

- `usable` + package `STATUS` Proven-green(script) for 架構檢視 = **map qualification gates verifiable**.
- Does **not** mean letter **B** from this track alone.
- Does **not** guarantee agent E2E arch quality.
- Does **not** equal cloud **Architecture Pass**.

---

## 6. Out of scope (this wave / deferred — not forever-forbidden)

- Graphify wiring, edge graphs, coverage gates, map rendering, cloud upload
- Agent E2E / Focus cards for 架構檢視
- Changing Tier-0 to require `test_arch_review_usable.sh`
