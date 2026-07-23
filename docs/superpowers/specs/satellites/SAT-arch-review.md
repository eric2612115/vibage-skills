# SAT-arch-review

**Owns:** 架構檢視 track behavior given a qualified map.  
**Skill:** `skills/vibage-arch-review/SKILL.md`  
**Verify:** `scripts/verify-service-map.sh <workspace_root>`  
**Map schema:** `SAT-map-schema.md`  
**Umbrella:** §5.1 Maps; local name ≠ cloud Architecture Pass

**Usable (this wave):** Map qualification gates are **script-proven**. That is **not** letter **B** complete, **not** agent E2E architecture quality, and **not** cloud Architecture Pass.

**Track / `pipeline_id`:** `service_map` (exact). Local name: **架構檢視** / Service map.

---

## 1. Hard rules

1. Require a **qualified** map at workspace `docs/vibage/maps/service_map.json` (Hybrid: `quality_bar=MEDIUM`; `scale` ∈ Tiny/Subset/Large; floor schema per `SAT-map-schema`).
2. Map **missing** or **underqualified** → stop **only** this track with a plain owner sentence; **do not** rewrite locate DONE / dual reports (`VIBAGE-ISSUE-OWNER.md` / `VIBAGE-ISSUE-LOCATE.md`).
3. Locate DONE does **not** require 架構檢視 (bidirectional independence).
4. Do **not** edit business code here (that is `vibage-issue-fix` after dual consent).
5. Do **not** claim cloud Architecture Pass; English IDs stay `service_map` / 架構檢視.
6. No SaaS / register CTA.

---

## 2. Script verify (usable proof)

```bash
bash "$PKG_ROOT/scripts/verify-service-map.sh" <workspace_root>
```

Exit **0** = map present and qualified. Exit **non-zero** = block this track only.

When hub map sets `depth: "standard"`, `verify-service-map.sh` requires non-empty id-valid `edges` (see `SAT-map-schema`). Floor maps without `depth` remain valid.

Fixture proof: `tests/test_arch_review_usable.sh` (optional; **not** in Tier-0). Do **not** call verify from `test_optional_track_gates.sh` / `test-tier0.sh` (thin rg contracts OK in optional gates).

**Honesty:** Proven-green(script) = gates verifiable. ≠ letter B alone; ≠ agent E2E; ≠ Architecture Pass.

---

## 3. Usable procedure (agent)

1. Resolve `PKG_ROOT` via `scripts/resolve-pkg-root.sh`.
2. Ensure hub map exists at `docs/vibage/maps/service_map.json` (copy shape from package `service_map.example.json` if owner wants this track).
3. Run `verify-service-map.sh <workspace_root>`. On FAIL → stop this track; leave locate DONE intact.
4. On OK → perform architecture / Service map review from the qualified map. Do not edit business code. Do not solicit SaaS.
5. Summarize for owner; do not claim letter B or agent E2E from this script alone.

---

## Optional local prettier (Plan G → Plan-L local-maps deepen)

After `verify-service-map.sh` exits 0, agents **may**:

1. OPTIONAL: `bash "$PKG_ROOT/scripts/generate-service-map-graph.sh" <workspace_root>`
   - When hub map present → expect non-empty `docs/vibage/maps/graph.mmd` and stdout `OK:MERMAID`.
   - Auto-writes `docs/vibage/maps/COVERAGE_NOTES.md` counts (`services_count` / `edges_count`) — **single writer**; **not** a verify field.
   - If Graphify CLI missing → exit 0 + `OK:GRAPHIFY_SKIP` + owner sentence = **CLI path skipped only** (Mermaid artifact still present). **Not** a qualification failure.
   - If CLI present → best-effort or honest limitation; never empty-overwrite of `graph.mmd`; never claim `OK:GRAPHIFY wrote` for a stub.
2. REQUIRED local preview (pure local, no external binary):  
   `bash "$PKG_ROOT/scripts/render-service-map-preview.sh" <workspace_root>`  
   → `vibage-preview/service_map.html` + `vibage-preview/service_map.svg`.  
   On soft skip/failure → exit 0 + `OK:RENDER_SKIP` + owner sentence; does not undo map usable / locate DONE.

Still ≠ cloud Architecture Pass. Still ≠ letter B upgrade. Plan-L local-maps deepen ≠终局 ≠ SAT option-L platform (deferred≠forever-ban).

---

## 4. Locate independence

| Case | Behavior |
|------|----------|
| Locate DONE, no map | Locate stays DONE; 架構檢視 blocked |
| Map underqualified | 架構檢視 blocked; locate DONE unchanged; dual reports untouched |
| Map qualified (verify OK) | May proceed with this track |
| This track fails mid-flight | Still must not rewrite locate DONE / dual reports |

---

## 5. Handoff / `artifacts_ok` (non-cross)

- `artifacts_ok` does **not** cross pipelines by default (umbrella §8.4).
- Do **not** reuse a locate-wave `artifacts_ok` / `verify-handoff.sh` verdict as map/architecture proof.
- Do **not** modify `scripts/verify-handoff.sh` or `scripts/verify-issue-fix-unlock.sh` for this track.
- Arch usable proof is `verify-service-map.sh` + optional `tests/test_arch_review_usable.sh` only.

---

## 6. Letter B / path-to-B

- Letter **B** needs issue-fix **usable** **and** 架構檢視 **usable**.
- When both are script-green: STATUS may note **path-to-B script-usable** (≠ agent-proven B).
- This track alone never completes letter B.

---

## 7. Out of scope (this wave / deferred — not forever-forbidden)

- Agent E2E / Focus agent-pressure cards for 架構檢視
- Option **L** deeper Graphify-class platform / coverage gates / interactive dashboard (M Pretty-local ≠终局; `deferred-closed ≠ forever-forbidden`). Cloud whole-repo upload/analysis remains out of this track’s job.
- Wiring `test_arch_review_usable.sh` or `test_prettier_maps.sh` into Tier-0
- SaaS / register CTA
