> **ARCHIVED · DO NOT EXECUTE as live SSOT.**
> Live C′ plan: `docs/superpowers/plans/2026-07-25-vibage-c-prime-graph-brief-ledger.md`

# Vibage Local Maps Deepen (`Plan-L` / local-maps deepen) Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deepen **local** Graphify-class maps beyond Plan-G M Pretty-local: always emit a useful Mermaid `graph.mmd` from hub JSON, auto-write `COVERAGE_NOTES.md` counts from the same script, keep Graphify CLI optional/fail-soft — without claiming SAT option-L platform, Architecture Pass, or letter B.

**Architecture:** **local-maps deepen (depth M)** on Approach 1 thin runtime. Single writer `scripts/generate-service-map-graph.sh` parses `docs/vibage/maps/service_map.json` → non-empty `docs/vibage/maps/graph.mmd` (`flowchart`/`graph LR`, nodes + `A-->B` edges) + `COVERAGE_NOTES.md` (`services_count` / `edges_count`). Stdout `OK:MERMAID` on Mermaid success. `OK:GRAPHIFY_SKIP` means **CLI path skipped only** — never “no graph artifact”. Graphify CLI present → best-effort `--help`/noop **or** honest limitation; **never** overwrite `graph.mmd` with empty; **never** claim `OK:GRAPHIFY wrote` for an empty stub. Optional layered SVG in `render-service-map-preview.sh` is non-blocking. Proofs only in `tests/test_prettier_maps_l.sh` (or extended prettier harness) — **not** Tier-0 / optional-track gates. `verify-service-map.sh` zero behavior change.

**Tech Stack:** Bash, Python 3 (stdlib), Markdown SAT/skills, fixtures under `tests/fixtures/service-map/`.

**Spec SSOT (consumers):** `@docs/superpowers/specs/satellites/SAT-map-schema.md`, `@docs/superpowers/specs/satellites/SAT-arch-review.md`, `skills/vibage-arch-review/SKILL.md`  
**Depends on:** Plan-G (M Pretty-local) green.  
**Index:** `2026-07-23-vibage-v2-plan-index.md` row **Plan-L** (order 13) — name **local-maps deepen** (NOT “option L platform done”).  
**Package convention:** Commit steps optional — **only commit when human/orchestrator asks**. Do **not** push. Do **not** wire new tests into `scripts/test-tier0.sh` or `tests/test_optional_track_gates.sh`.

**Honesty locks (absorb must_fixes from DoD tri-review):**

1. Always emit non-empty `docs/vibage/maps/graph.mmd` from JSON when map is present/usable for prettier; stdout `OK:MERMAID` on success.
2. `OK:GRAPHIFY_SKIP` **only** means CLI path skipped — NEVER imply no graph artifact; never claim `OK:GRAPHIFY wrote` for empty stub.
3. If Graphify CLI present: best-effort **or** honest limitation; never overwrite `graph.mmd` with empty.
4. Auto-write `COVERAGE_NOTES.md` from JSON counts via generate script (**single writer**).
5. Optional layered SVG improvement in `render-service-map-preview.sh` OK but **not blocking**.
6. Tests: extend `test_prettier_maps.sh` **or** new `test_prettier_maps_l.sh` — **NOT** Tier-0 / optional gates.
7. `verify-service-map.sh` zero diff.
8. **Plan-L ≠终局; ≠ Architecture Pass; ≠ SAT platform option-L; deferred≠forever-ban.**
9. Do **not** commit unless orchestrator/human asks.

---

## File map

| Path | Responsibility |
|------|----------------|
| `scripts/generate-service-map-graph.sh` | Mermaid emit + auto COVERAGE_NOTES + optional Graphify fail-soft |
| `tests/test_prettier_maps_l.sh` | Sole Plan-L proof harness (Plan-G harness remains) |
| `docs/superpowers/specs/satellites/SAT-map-schema.md` | §6 Plan-L deepen contracts + honesty |
| `docs/superpowers/specs/satellites/SAT-arch-review.md` | Procedure: Mermaid always; GRAPHIFY_SKIP ≠ no artifact |
| `skills/vibage-arch-review/SKILL.md` | Agent steps; single-writer coverage notes |
| `STATUS.md` | One honesty line for Plan-L local-maps deepen |
| `docs/superpowers/plans/2026-07-23-vibage-v2-plan-index.md` | Row 13 Plan-L + keep Plan-M wording fix |
| **Do not modify behavior:** `scripts/verify-service-map.sh` | Zero behavior change |
| **Do not wire:** `scripts/test-tier0.sh`, `tests/test_optional_track_gates.sh` | Must remain unaware of prettier L tests |
| Optional non-blocking: `scripts/render-service-map-preview.sh` | Layered SVG polish |

**Hard bans:**

- Do not modify `verify-service-map.sh` logic/output contracts
- Do not wire prettier L tests into Tier-0 or optional-track gates
- Do not claim SAT option-L platform / coverage gates / interactive dashboard done
- Do not claim SaaS / cloud Architecture Pass / letter B / Focus rewrite
- Do not invent forever-ban of further local deepen
- Do not claim `OK:GRAPHIFY wrote` for empty/narrative stubs

---

## Chunk 1: Index + plan honesty

### Task 1: Index row 13 + keep Plan-M wording

**Files:**
- Modify: `docs/superpowers/plans/2026-07-23-vibage-v2-plan-index.md`

- [x] **Step 1: Ensure Plan-M Ship? text** says Graphify/coverage/render **unlocked by Plan-G** (M Pretty-local ≠终局; deeper L later OK) — not “deferred local (not forever-ban)” alone.
- [x] **Step 2: Add order 13** `Plan-L` (local-maps deepen) pointing at this file. Name carefully: **local-maps deepen** — NOT “option L platform done”.

---

## Chunk 2: Generator rewrite (TDD)

### Task 2: Write failing Plan-L tests

**Files:**
- Create: `tests/test_prettier_maps_l.sh`

- [x] **Step 1: Assert Mermaid always + GRAPHIFY_SKIP semantics + auto coverage + isolation**

Cases:
1. Missing CLI → exit 0, `OK:GRAPHIFY_SKIP` + owner sentence, **and** non-empty `graph.mmd` with service ids + `-->`, plus `OK:MERMAID`
2. Fake CLI on PATH (non-zero) → soft; Mermaid retained; verify PASS
3. Auto `COVERAGE_NOTES.md` with `services_count` / `edges_count` matching fixture
4. Isolation: `test_prettier_maps_l` not in tier0 / optional gates
5. `verify-service-map` still PASS on fixture workspace

- [x] **Step 2: Run to fail before rewrite (or pass after)**

```bash
bash tests/test_prettier_maps_l.sh
```

---

### Task 3: Rewrite `generate-service-map-graph.sh`

**Files:**
- Modify: `scripts/generate-service-map-graph.sh`

- [x] **Step 1: Implement**

Order when map present:
1. Parse JSON → write non-empty `graph.mmd` + `COVERAGE_NOTES.md`
2. Print `OK:MERMAID wrote …`
3. If Graphify CLI missing → `OK:GRAPHIFY_SKIP` + owner sentence (CLI skipped; Mermaid already written)
4. If CLI present → `--help`/noop best-effort; on failure soft; on “usable but unknown emit contract” → honest limitation; **never** replace `graph.mmd` with empty; **never** `OK:GRAPHIFY wrote` for stub

Missing map → exit 0 + `OK:GRAPHIFY_SKIP` + owner sentence (no Mermaid claim).

- [x] **Step 2: Run Plan-L + Plan-G prettier tests**

```bash
bash tests/test_prettier_maps.sh
bash tests/test_prettier_maps_l.sh
```

Expected: both ALL-pass.

---

## Chunk 3: Docs honesty

### Task 4: SAT / skill / STATUS

**Files:**
- Modify: `SAT-map-schema.md` §6, `SAT-arch-review.md`, `skills/vibage-arch-review/SKILL.md`, `STATUS.md`

- [x] **Step 1:** Document Plan-L deepen: always Mermaid + auto counts; `GRAPHIFY_SKIP` ≠ no artifact; Plan-L ≠终局 ≠ SAT option-L platform ≠ Architecture Pass; deferred≠forever-ban.
- [x] **Step 2:** Skill: generate script is **single writer** for `COVERAGE_NOTES.md` counts.

---

## Chunk 4: Regression

### Task 5: Verify zero diff + Tier-0

```bash
git diff -- scripts/verify-service-map.sh
bash tests/test_prettier_maps.sh
bash tests/test_prettier_maps_l.sh
bash scripts/test-tier0.sh
```

Expected: verify diff empty; prettier ALL-pass; `TIER0_OK`.

---

## Definition of Done (Plan-L)

- [x] Non-empty `docs/vibage/maps/graph.mmd` from JSON when map present; stdout `OK:MERMAID`
- [x] `OK:GRAPHIFY_SKIP` = CLI skipped only; never implies no graph; no `OK:GRAPHIFY wrote` empty stub
- [x] CLI present → best-effort or honest limitation; never empty-overwrite of `graph.mmd`
- [x] Auto `COVERAGE_NOTES.md` via generate script (single writer) with counts
- [x] `tests/test_prettier_maps_l.sh` green; not in Tier-0 / optional gates
- [x] `git diff -- scripts/verify-service-map.sh` empty; `test-tier0.sh` → `TIER0_OK`
- [x] Honesty: Plan-L ≠终局 ≠ Architecture Pass ≠ SAT option-L platform; deferred≠forever-ban
- [x] No commit unless orchestrator asks

---

## Out of scope

- SAT option-L platform / coverage gates / interactive dashboard
- Cloud Architecture Pass / SaaS / letter B / Focus rewrite
- Changing `verify-service-map.sh` or Tier-0 wiring
- Forced Graphify install
- Claiming Plan-L =终局
