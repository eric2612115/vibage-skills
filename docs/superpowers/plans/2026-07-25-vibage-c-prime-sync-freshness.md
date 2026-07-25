# C′ W1 Sync / Freshness Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Implement W1 freshness (HEAD+TTL stale, HARD_MOTHER / SOFT_CHILD, fail-closed mark, waiver tokens) per `docs/superpowers/specs/2026-07-25-vibage-c-prime-sync-freshness-design.md`.

**Architecture:** Hub file `docs/vibage/maps/freshness.json` stores per-repo fingerprints. `freshness-check.sh` computes stale and prints frozen tokens (**exit 0 ≠ `FRESHNESS_OK`**). `freshness-refresh-repo.sh` inventories mother then sweeps one repo’s cells then fail-closed marks. Skills parse stdout tokens only. Tests live in `tests/test_freshness_w1.sh` (avoids `test_c_prime_*.sh` suite glob; not Tier-0).

**Tech Stack:** bash + python3 JSON; existing graph-floor / matrix-inventory / matrix-sweep-cell; no new deps.

**Spec:** `docs/superpowers/specs/2026-07-25-vibage-c-prime-sync-freshness-design.md`  
**Roadmap:** `docs/superpowers/specs/2026-07-25-vibage-c-prime-next-waves-roadmap.md`

---

## File map

| File | Responsibility |
|------|----------------|
| Create: `scripts/lib/freshness.py` | Resolve mother; load/save freshness.json; TTL from policy; compute stale; waiver validate+coverage |
| Create: `scripts/freshness-check.sh` | CLI mother/child modes + tokens (+ escalate on mother) |
| Create: `scripts/freshness-mark.sh` | `--success` / `--refuse` fail-closed (all cells terminal) |
| Create: `scripts/freshness-refresh-repo.sh` | Bounded refresh one repo |
| Create: `scripts/verify-freshness.sh` | Thin wrap → mother check |
| Create: `tests/test_freshness_w1.sh` | Spec §8 cases + Tier-0 firewall grep |
| Create: `scripts/hooks/vibage-child-post-commit.sample` | Soft ask text |
| Modify: `scripts/c-prime-fill.sh` | Print `FULL_MOTHER_FILL_REFRESH`; mark repos with all cells terminal |
| Modify: `skills/using-vibage/SKILL.md` | Session stale_count + incomplete matrix; token gates; child ask |
| Modify: `adapters/cursor/vibage.mdc` (and shared AGENTS if needed) | Continuum: parse tokens; exit0≠OK |
| Modify: `docs/superpowers/specs/2026-07-25-vibage-c-prime-freeze-lift.md` | After green: W1 freshness On-tree phrase |
| Modify: `STATUS.md` | One-line W1 On-tree when green (not before) |
| Do **not** modify: `scripts/test-tier0.sh`, pack-health, `tests/test_c_prime_suite.sh` required list |

---

### Task 1: Failing freshness test skeleton

**Files:**
- Create: `tests/test_freshness_w1.sh`

- [x] **Step 1: Write test that expects `freshness-check.sh` and fails if missing**

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }
[[ -x "$ROOT/scripts/freshness-check.sh" ]] || fail "missing freshness-check.sh"
# Firewall: this test and freshness scripts must not be wired into Tier-0 / pack-health
! grep -q 'test_freshness_w1\|freshness-check\|verify-freshness' "$ROOT/scripts/test-tier0.sh" \
  || fail "freshness wired into test-tier0.sh"
```

- [x] **Step 2: Run test — expect FAIL missing script**

Run: `bash tests/test_freshness_w1.sh`  
Expected: FAIL missing freshness-check.sh

- [x] **Step 3: Keep uncommitted until scripts land with later tasks**

---

### Task 2: `scripts/lib/freshness.py`

**Files:**
- Create: `scripts/lib/freshness.py`

- [x] **Step 1: Implement helpers**

Behavior locked:

- `resolve_mother(start: Path) -> Path | None` — (1) `VIBAGE_PARENT` if has `docs/vibage/STATUS.md`, else (2) walk ancestors for `STATUS.md`, else None
- `load_freshness(mother) / save_freshness(mother, obj)`
- `ttl_days(mother) -> int` — `OWNER_POLICY.json` → `freshness_ttl_days` if present, else `freshness.json` `ttl_days`, else 7
- `in_scope_repo_ids(mother) -> list` from `service_map.json` (same excludes as graph-floor)
- `compute_stale(mother) -> dict[repo_id, reason]` — missing freshness.json ⇒ all in-scope stale; HEAD mismatch; TTL; missing record
- `waiver_valid(pol, stale_ids) -> bool` — required fields + `now <= review_by` + (`scope` is `["*"]` or covers **every** stale id)
- `git_head(repo_root) -> str | None` — missing checkout → None (no crash; TTL still applies)
- `cells_all_terminal(mother, repo_id) -> bool` — every matrix cell for repo is `proven`|`failed`; **false** if zero cells

- [x] **Step 2: Unit-smoke via `python3 -c` import from scripts path**

Expected: import OK

---

### Task 3: `freshness-check.sh`

**Files:**
- Create: `scripts/freshness-check.sh`

- [x] **Step 1: Implement CLI**

```bash
# Usage: freshness-check.sh --mode=mother|child [--repo=<id>] [--json] <mother-or-cwd>
```

**Mother stdout / exit (exact):**

| Situation | Exit | Print |
|-----------|------|-------|
| No in-scope stale | 0 | `FRESHNESS_OK` |
| Stale, no valid waiver | 1 | `STALE_BLOCKS_MOTHER count=<n>` |
| Stale, valid waiver | 0 | `FRESHNESS_WAIVED` + `STALE_DISCLOSED count=<n>` — never `FRESHNESS_OK` |
| Any repo `refuse_count >= 3` | (with above) | also `VIBAGE_FRESHNESS_ESCALATE: repo=<id> refused hub update N>=3; mother session must disclose before continuum slogans` |

**Child:** always exit 0. If parent unresolved → print `VIBAGE_PARENT_UNRESOLVED` + `FRESHNESS_CHILD_WARN` (skip ask). If stale for `--repo` → `FRESHNESS_CHILD_WARN`. If escalate → also escalate line.

- [x] **Step 2: Extend `tests/test_freshness_w1.sh` — HEAD change → mother fail (+count), child warn; unresolved parent token**

- [x] **Step 3: Run those cases — PASS**

---

### Task 4: `freshness-mark.sh` fail-closed

**Files:**
- Create: `scripts/freshness-mark.sh`

- [x] **Step 1: `--success` requires `cells_all_terminal` (every cell for `repo_id` is `proven`|`failed`; **zero cells ⇒ fail**); else exit ≠ 0 and do not write `stale=false`**
- [x] **Step 2: `--refuse` increments `refuse_count`, forces `stale=true`**
- [x] **Step 3: Tests: floor-only mark fails; zero cells fails; refuse×3 → escalate on **mother** check**

---

### Task 5: `freshness-refresh-repo.sh`

**Files:**
- Create: `scripts/freshness-refresh-repo.sh`

- [x] **Step 1: If repo not in map → `graph-floor.sh` once + echo `FULL_MOTHER_FLOOR_REFRESH`**
- [x] **Step 2: `matrix-inventory.sh` then sweep each cell for `repo_id` only**
- [x] **Step 3: Call mark `--success` only if all steps OK; never on partial failure**
- [x] **Step 4: Test happy path on tiny 1-repo fixture with compose env**

---

### Task 6: `verify-freshness.sh` + skill/adapter copy

**Files:**
- Create: `scripts/verify-freshness.sh`
- Modify: `skills/using-vibage/SKILL.md`
- Modify: `adapters/cursor/vibage.mdc`
- Modify: `adapters/shared/AGENTS.vibage.md` (and claude block if same continuum lines)
- Create: `scripts/hooks/vibage-child-post-commit.sample`

- [x] **Step 1: verify wraps mother check (same tokens)**
- [x] **Step 2: Document HARD_MOTHER session start: run mother check; report `stale_count` **+ incomplete matrix**; show escalate lines; continuum requires `FRESHNESS_OK` **or** (`FRESHNESS_WAIVED` + disclosure); **forbidden** treating exit 0 as OK**
- [x] **Step 3: Child ask frozen string `VIBAGE_FRESHNESS_ASK: ...`; sample hook emits it**

---

### Task 7: Full `tests/test_freshness_w1.sh` + suite/Tier-0 firewall

**Files:**
- Modify: `tests/test_freshness_w1.sh`

**Locked name:** `tests/test_freshness_w1.sh` (outside suite glob).

Must cover Spec §8:

| Case | Expect |
|------|--------|
| HEAD change after success mark | mother `STALE_BLOCKS_MOTHER count=` exit 1 |
| Same | child `FRESHNESS_CHILD_WARN` exit 0 |
| TTL expired | stale without HEAD change |
| Valid waiver | exit 0, waived+disclosed, no `FRESHNESS_OK` |
| Expired / empty waiver | hard-fail if stale |
| Missing freshness.json | hard-fail if map has repos |
| Refuse 3× | escalate on **mother** check |
| Parent unresolved | `VIBAGE_PARENT_UNRESOLVED`; soft skip ask |
| Mark after floor-only | must NOT clear stale |
| Mark `--success` zero cells | exit ≠ 0; stale unchanged |
| Partial waiver scope | mother exit 1 `STALE_BLOCKS_MOTHER` |
| Waiver ≠ substantive | substantive verify unchanged |
| Tier-0 firewall | grep: freshness ∉ `test-tier0.sh` / pack-health |
| Suite firewall | `test_c_prime_suite` does not run this file |

- [x] **Step 1: Implement all cases above**
- [x] **Step 2: `bash tests/test_freshness_w1.sh` → all PASS**
- [x] **Step 3: `bash tests/test_c_prime_suite.sh` still `C_PRIME_SUITE_OK` without freshness**

---

### Task 8: Wire mark after successful `c-prime-fill` (not graph-floor)

**Files:**
- Modify: `scripts/c-prime-fill.sh`
- Do **not** mark from `scripts/graph-floor.sh`

- [x] **Step 1: On intentional full fill success: print `FULL_MOTHER_FILL_REFRESH`**
- [x] **Step 2: For each in-scope repo with all cells terminal, call mark `--success`**
- [x] **Step 3: graph-floor must NOT call mark `--success` (test already in Task 7)**
- [x] **Step 4: Test fill → `FRESHNESS_OK` on fresh fixture; stdout includes `FULL_MOTHER_FILL_REFRESH`**

---

### Task 9: Docs STATUS / freeze after green

**Files:**
- Modify: `docs/superpowers/specs/2026-07-25-vibage-c-prime-freeze-lift.md`
- Modify: `STATUS.md` continuum one-liner

- [x] **Step 1: Only after Task 7 green — freeze-lift: `W1 freshness On-tree (HEAD+TTL subset) ≠ Sync contract DONE`**
- [x] **Step 2: STATUS note W1 freshness On-tree; still ≠ letter B / 掃透 / Tier-0**

---

## Execution handoff

Do **not** start Tasks until owner says execute implementation.  
After green: optional live pressure on DefiStrategy/MindOwnBuz freshness check only (not new Proven-green flip unless owner asks).
