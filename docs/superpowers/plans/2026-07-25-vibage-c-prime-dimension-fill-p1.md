# C′ W3a Dimension Fill — P1 Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** P1 orchestrator + repo synthesizer + consent/probe wiring per W3a design §4–§5 / §10 P1.

**Architecture:** `dimension-fill.sh` loads freeze, probes floor/matrix/vacancy, for each scope repo runs `dimension-synth-repo.sh` then for each class either uses provided claim JSON dir or `--claims-dir` / fails incomplete → verify. Synth writes dossier stub citing planned claim classes. Extend `test_dimension_fill_w3a.sh` with P1 cases; print `DIMENSION_FILL_W3A_P1_OK`.

**Spec:** `docs/superpowers/specs/2026-07-25-vibage-c-prime-dimension-fill-design.md`

**Out of P1:** deepen migrate / STATUS scrub (P2).

---

### Task 1: `dimension-synth-repo.sh`

**Files:** Create: `scripts/dimension-synth-repo.sh`

- [x] Write `docs/vibage/dossiers/<repo_id>.md` stub with planned `dimension_*` classes + note that stub ≠ depth without ledger ids
- [x] Exit 0 on write

### Task 2: `dimension-fill.sh` orchestrator

**Files:** Create: `scripts/dimension-fill.sh`; extend `scripts/lib/dimension_fill.py` if needed

- [x] Require consent freeze (`dimension_yes`); reject legacy `deepen_yes` alone
- [x] Probe GRAPH_FLOOR / matrix / vacancy (reuse P0 tally probes)
- [x] For each scope repo: synth → for each required class, if `--claims-dir/<repo>/<class>.json` exists run dimension-search else leave incomplete
- [x] End by running verify-dimension-fill; never print MAP_DEEPEN_OK
- [x] Usage: `dimension-fill.sh <mother> [--claims-dir=<path>]`

### Task 3: Tests

**Files:** Modify: `tests/test_dimension_fill_w3a.sh`

- [x] Legacy deepen freeze only → BLOCKED via fill.sh
- [x] Orchestrator happy path with claims-dir → OK
- [x] Synth creates dossier stub
- [x] Print `DIMENSION_FILL_W3A_P1_OK` (keep P0 cases)
