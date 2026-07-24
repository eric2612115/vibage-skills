> **ARCHIVED · DO NOT EXECUTE as live SSOT.**
> Live C′ plan: `docs/superpowers/plans/2026-07-25-vibage-c-prime-graph-brief-ledger.md`

# Vibage Map Depth (`depth:standard` + `edges`) Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend local Service map qualification so that `depth === "standard"` (string) requires a non-empty, id-valid `edges` array, while floor (absent / non-`standard` depth) stays B2-compatible — without wiring into Tier-0 or claiming letter B.

**Architecture:** Approach 1 thin: additive optional fields in `SAT-map-schema` + conditional branch in `scripts/verify-service-map.sh`; fixture proof via `tests/test_arch_review_usable.sh`. No FSM. No Graphify binary. Unknown keys still must not fail floor. Local deeper map work (Graphify / coverage / render) is **deferred this wave**, not forever-forbidden; cloud whole-repo analysis stays out of scope (do not rewrite PRODUCT-LOCKS here).

**Tech Stack:** Bash, Python 3 (inline in verify), JSON fixtures, Markdown satellites/skills

**Spec SSOT:** `@docs/superpowers/specs/satellites/SAT-map-schema.md`  
**Consumers:** `@docs/superpowers/specs/satellites/SAT-arch-review.md`, `skills/vibage-arch-review/SKILL.md`  
**Depends on:** path-to-B script-usable already green (optional tracks Proven-green script)  
**Index:** `2026-07-23-vibage-v2-plan-index.md` row **Plan-M**  
**Order lock:** Plan M **before** Plan F (`2026-07-23-vibage-focus-b-path-agent-pressure.md`). AP-C5 GREEN depends on this contract.  
**Package convention:** Commit steps are optional — **only commit when human asks**. Do **not** push. Do **not** enter new usable tests into `scripts/test-tier0.sh`.

**Honesty locks (absorb must_fix):**

- Completing Plan M alone **must not** claim letter B / `B-path agent-proven`.
- Do **not** redefine Focus locate Proven-green (`AP-C1`…`C3`).
- `path-to-B script-usable` STATUS sentence stays; Plan M only deepens map gates under script scope.
- Graphify / coverage / render = **deferred this wave** for local deeper maps — **not** “forever ban local edges.” Do not invent PRODUCT-LOCKS rewrites.

---

## File map

| Path | Responsibility |
|------|----------------|
| `docs/superpowers/specs/satellites/SAT-map-schema.md` | Normative depth/`edges` / `services[].name` rules |
| `docs/superpowers/specs/satellites/service_map.example.json` | Example may show optional `depth`+`edges` (still floor-valid without them) |
| `scripts/verify-service-map.sh` | Floor + conditional `depth==="standard"` edges validation |
| `tests/fixtures/service-map/qualified.json` | Keep floor PASS (edges may exist; without `depth:standard` edges are **not** validated) |
| `tests/fixtures/service-map/standard-depth-ok.json` | `depth:"standard"` + valid non-empty edges → PASS |
| `tests/fixtures/service-map/standard-depth-missing-edges.json` | `depth:"standard"` without edges → FAIL |
| `tests/fixtures/service-map/standard-depth-empty-edges.json` | `depth:"standard"` + `edges:[]` → FAIL |
| `tests/fixtures/service-map/standard-depth-bad-edge-id.json` | `from`/`to` not in `services[].id` → FAIL |
| `tests/fixtures/service-map/depth-non-string.json` | `depth` non-string (e.g. number/bool) → FAIL |
| `tests/fixtures/service-map/depth-deeper-with-edges.json` | non-`standard` string depth + edges present → floor PASS; edges **not** validated |
| `tests/test_arch_review_usable.sh` | Exercise new fixtures; stay out of Tier-0 |
| `docs/superpowers/specs/satellites/SAT-arch-review.md` | Honesty + point at standard-depth contract |
| `skills/vibage-arch-review/SKILL.md` | Short honesty / verify note for `depth:standard` |
| `STATUS.md` | Optional one-line under 架構檢視 honesty if needed — **no** letter B agent-proven claim |

**Hard bans:**

- Do not modify `scripts/test-tier0.sh` to call verify/usable/agent tests
- Do not call `verify-service-map.sh` from `tests/test_optional_track_gates.sh`
- Do not wire Graphify binary, coverage gates, or map render
- Do not claim SaaS / Architecture Pass / letter B agent-proven

---

## Chunk 1: Spec lock (`SAT-map-schema`)

### Task 1: Document additive depth / edges rules

**Files:**
- Modify: `docs/superpowers/specs/satellites/SAT-map-schema.md`

- [ ] **Step 1: Replace deferred `edges` row with normative optional + standard rules**

In §3 (or new §3.1), lock:

**Optional additive fields (absent OK on floor):**

| Key | Rule |
|-----|------|
| `depth` | If present: **must be a string**. Non-string → FAIL. If string equals exactly `"standard"` → edges rules below. Any other string (including absent meaning) → **do not** validate `edges`. |
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

Also update §6 Out of scope wording:

> Graphify wiring, coverage gates, map rendering = **deferred this wave** for local deeper maps — **not** forever-forbidden. Cloud whole-repo upload/analysis remains out of this plan’s job (do not rewrite PRODUCT-LOCKS).

Remove any phrasing that reads as “edges forever deferred” if it conflicts with standard-depth rules.

- [ ] **Step 2: Grep lock phrases**

```bash
cd /Users/eric.fang/MindOwnBuz/vibage-skills
rg -n 'depth|edges|standard|forever' docs/superpowers/specs/satellites/SAT-map-schema.md
```

Expected: `standard` rules present; “deferred this wave” for Graphify/coverage/render; no “forever ban local edges.”

- [ ] **Commit (only if human requested)**

```bash
git add docs/superpowers/specs/satellites/SAT-map-schema.md
git commit -m "$(cat <<'EOF'
docs: lock service_map depth=standard edges rules

EOF
)"
```

---

## Chunk 2: Verify script (TDD)

### Task 2: Write failing usable cases for standard depth first

**Files:**
- Create: `tests/fixtures/service-map/standard-depth-ok.json`
- Create: `tests/fixtures/service-map/standard-depth-missing-edges.json`
- Create: `tests/fixtures/service-map/standard-depth-empty-edges.json`
- Create: `tests/fixtures/service-map/standard-depth-bad-edge-id.json`
- Create: `tests/fixtures/service-map/depth-non-string.json`
- Create: `tests/fixtures/service-map/depth-deeper-with-edges.json`
- Modify: `tests/test_arch_review_usable.sh`

- [ ] **Step 1: Create PASS fixture `standard-depth-ok.json`**

```json
{
  "schema_version": "1",
  "pipeline_id": "service_map",
  "scale": "Subset",
  "quality_bar": "MEDIUM",
  "depth": "standard",
  "services": [
    {"id": "web", "name": "Web frontend"},
    {"id": "billing", "name": "Billing service"}
  ],
  "edges": [
    {"from": "web", "to": "billing"}
  ]
}
```

- [ ] **Step 2: Create FAIL fixtures**

`standard-depth-missing-edges.json` — same as ok but omit `edges`.  
`standard-depth-empty-edges.json` — `"edges": []`.  
`standard-depth-bad-edge-id.json` — `"edges": [{"from": "web", "to": "nope"}]`.  
`depth-non-string.json` — `"depth": 1` (keep floor keys valid otherwise).

- [ ] **Step 3: Create non-standard still-PASS fixture**

`depth-deeper-with-edges.json`:

```json
{
  "schema_version": "1",
  "pipeline_id": "service_map",
  "scale": "Tiny",
  "quality_bar": "MEDIUM",
  "depth": "deeper",
  "services": [{"id": "api"}],
  "edges": [{"from": "api", "to": "MISSING_OK_ON_NON_STANDARD"}]
}
```

Edges reference a missing id on purpose — must still **PASS** because depth ≠ `"standard"`.

- [ ] **Step 4: Extend `test_arch_review_usable.sh` with new expect_rc cases (before implement)**

Add cases after existing floor cases:

```bash
# standard depth PASS
expect_rc "standard depth ok" 0 "$TMP/std_ok"
# (install_map from standard-depth-ok.json)

# standard missing edges FAIL
expect_rc "standard missing edges" 1 "$TMP/std_miss"

# standard empty edges FAIL
expect_rc "standard empty edges" 1 "$TMP/std_empty"

# standard bad edge id FAIL
expect_rc "standard bad edge id" 1 "$TMP/std_bad"

# non-string depth FAIL
expect_rc "non-string depth" 1 "$TMP/depth_ns"

# non-standard depth: edges not validated → PASS
expect_rc "non-standard depth edges ignored" 0 "$TMP/deeper"
```

Wire `install_map` for each temp workspace from the new fixtures.

- [ ] **Step 5: Run usable test — expect FAIL on standard cases until verify lands**

```bash
bash tests/test_arch_review_usable.sh
```

Expected (before Task 3): FAIL on at least `standard missing edges` / `standard depth ok` (verify still ignores `depth`). Floor cases should still pass.

- [ ] **Commit (only if human requested)**

```bash
git add tests/fixtures/service-map tests/test_arch_review_usable.sh
git commit -m "$(cat <<'EOF'
test: add service_map depth=standard fixture cases

EOF
)"
```

---

### Task 3: Implement conditional edges validation in verify

**Files:**
- Modify: `scripts/verify-service-map.sh`

- [ ] **Step 1: After floor `services` loop, add depth / edges branch**

Inside the existing `python3` block, after validating services ids, implement exactly:

```python
depth = obj.get("depth", None)
if depth is not None and not isinstance(depth, str):
    die("depth must be a string when present")

service_ids = {
    item["id"].strip()
    for item in services
    if isinstance(item, dict)
    and isinstance(item.get("id"), str)
    and item["id"].strip()
}

if depth == "standard":
    edges = obj.get("edges")
    if not isinstance(edges, list) or len(edges) < 1:
        die('depth="standard" requires non-empty edges array')
    for i, edge in enumerate(edges):
        if not isinstance(edge, dict):
            die(f"edges[{i}] must be an object")
        frm = edge.get("from")
        to = edge.get("to")
        if not isinstance(frm, str) or not frm.strip():
            die(f"edges[{i}].from must be a non-empty string")
        if not isinstance(to, str) or not to.strip():
            die(f"edges[{i}].to must be a non-empty string")
        if frm not in service_ids:
            die(f"edges[{i}].from {frm!r} not in services[].id")
        if to not in service_ids:
            die(f"edges[{i}].to {to!r} not in services[].id")
    print('OK: depth=standard edges valid')
# else: non-standard / absent depth → do NOT validate edges (even if present)
```

Keep unknown-key friendliness. Keep existing OK print lines.

- [ ] **Step 2: Re-run usable tests**

```bash
bash tests/test_arch_review_usable.sh
```

Expected: ends with `ALL arch_review_usable tests passed`.

- [ ] **Step 3: Manual spot-checks**

```bash
TMP=$(mktemp -d)
mkdir -p "$TMP/docs/vibage/maps"
cp tests/fixtures/service-map/standard-depth-ok.json "$TMP/docs/vibage/maps/service_map.json"
bash scripts/verify-service-map.sh "$TMP"; echo rc_ok=$?
cp tests/fixtures/service-map/depth-non-string.json "$TMP/docs/vibage/maps/service_map.json"
bash scripts/verify-service-map.sh "$TMP"; echo rc_ns=$?
cp tests/fixtures/service-map/depth-deeper-with-edges.json "$TMP/docs/vibage/maps/service_map.json"
bash scripts/verify-service-map.sh "$TMP"; echo rc_deeper=$?
rm -rf "$TMP"
```

Expected: `rc_ok=0`, `rc_ns≠0`, `rc_deeper=0`.

- [ ] **Step 4: Tier-0 unchanged**

```bash
grep -n 'arch_review_usable\|verify-service-map\|agent_pressure' scripts/test-tier0.sh || echo "TIER0_UNTOUCHED_OK"
bash scripts/test-tier0.sh
```

Expected: `TIER0_UNTOUCHED_OK` then `TIER0_OK`.

- [ ] **Commit (only if human requested)**

```bash
git add scripts/verify-service-map.sh
git commit -m "$(cat <<'EOF'
feat: verify depth=standard requires valid edges

EOF
)"
```

---

## Chunk 3: Example + honesty docs

### Task 4: Refresh example map (optional additive)

**Files:**
- Modify: `docs/superpowers/specs/satellites/service_map.example.json`

- [ ] **Step 1: Prefer showing `depth` + `edges` on the example**

Add `"depth": "standard"` and a valid `edges` list between the two example services (`api` ↔ `worker`). Keep floor keys. `services[].name` remains recommended.

- [ ] **Step 2: Confirm example still qualifies**

```bash
TMP=$(mktemp -d)
mkdir -p "$TMP/docs/vibage/maps"
cp docs/superpowers/specs/satellites/service_map.example.json \
  "$TMP/docs/vibage/maps/service_map.json"
bash scripts/verify-service-map.sh "$TMP"
rm -rf "$TMP"
```

Expected: exit 0 + `OK: depth=standard edges valid`.

- [ ] **Commit (only if human requested)**

```bash
git add docs/superpowers/specs/satellites/service_map.example.json
git commit -m "$(cat <<'EOF'
docs: show depth=standard edges on service_map example

EOF
)"
```

---

### Task 5: Arch-review SAT + skill honesty (no letter B claim)

**Files:**
- Modify: `docs/superpowers/specs/satellites/SAT-arch-review.md`
- Modify: `skills/vibage-arch-review/SKILL.md`
- Modify (optional one line only): `STATUS.md`

- [ ] **Step 1: Point SAT-arch-review at standard-depth contract**

Add a short bullet under script verify / usable procedure:

> When hub map sets `depth: "standard"`, `verify-service-map.sh` requires non-empty id-valid `edges` (see `SAT-map-schema`). Floor maps without `depth` remain valid.

Keep §6 Letter B / path-to-B: script-usable unchanged; this track alone never completes letter B; ≠ Architecture Pass.

Update §7 OOS: Graphify/coverage/render deferred this wave — not forever-forbidden for local deeper maps.

- [ ] **Step 2: Skill one-liner**

In `skills/vibage-arch-review/SKILL.md`, note that verify enforces `depth:standard` edges when that flag is set. Do **not** claim letter B agent-proven.

- [ ] **Step 3: STATUS guard**

Do **not** add `letter B agent-proven` here. Optionally append under 架構檢視 honesty:

> Map verify may enforce `depth:standard` edges; still ≠ letter B agent-proven / ≠ Architecture Pass.

Leave `path-to-B script-usable` sentence intact.

- [ ] **Step 4: Re-run proofs**

```bash
bash tests/test_arch_review_usable.sh
bash scripts/test-tier0.sh
```

Expected: both green (`ALL arch_review_usable tests passed`, `TIER0_OK`).

- [ ] **Commit (only if human requested)**

```bash
git add docs/superpowers/specs/satellites/SAT-arch-review.md \
  skills/vibage-arch-review/SKILL.md STATUS.md
git commit -m "$(cat <<'EOF'
docs: honesty for standard-depth map verify

EOF
)"
```

---

## Definition of Done (Plan M)

- [ ] `SAT-map-schema` documents: string `depth` only; `depth==="standard"` ⇒ non-empty id-valid `edges`; non-standard ⇒ edges not validated; non-string depth FAIL; `services[].name` recommended-only
- [ ] `verify-service-map.sh` implements the above; floor fixtures still PASS
- [ ] Fixtures cover: standard PASS, missing/empty/bad-id FAIL, non-string FAIL, non-standard+bad-edges PASS
- [ ] `test_arch_review_usable.sh` green; **not** in Tier-0; `test-tier0.sh` → `TIER0_OK`
- [ ] Graphify/coverage/render remain deferred (local later OK); no forever-ban-local-edges wording
- [ ] No letter B / SaaS / Architecture Pass / Focus Proven-green claims from Plan M alone

---

## Out of scope

- Plan F Focus cards / dual-phase agents
- PRODUCT-LOCKS rewrite
- Graphify binary wiring, coverage deep gates, map rendering UI
- Cloud whole-repo analysis / upload
- Tier-0 / remote CI / SaaS CTA
- Claiming `B-path agent-proven` (Plan F + dual-PHASE only, after Plan M)
