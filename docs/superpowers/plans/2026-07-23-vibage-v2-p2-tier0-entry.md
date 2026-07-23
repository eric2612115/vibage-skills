# P2 — Tier-0 entry `scripts/test-tier0.sh` Implementation Plan

> **For agentic workers:** REQUIRED: Use `@superpowers:subagent-driven-development` or `@superpowers:executing-plans`. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Single local ship command `bash scripts/test-tier0.sh` that proves gate RED→GREEN, verify green, and hard-cut report names — this-wave **ship** (SHIP_MEANS_TIER0_ONLY).

**Architecture:** Wrapper over existing pytest + bash tests from P0/P1; no CI remote required. Update package STATUS Proven-green(script) only after this passes.

**Tech Stack:** bash, pytest

**Spec:** umbrella §7.2 / D8  
**Depends on:** P0 + P1  
**Index:** `2026-07-23-vibage-v2-plan-index.md`

---

## File map

| Path | Responsibility |
|------|----------------|
| `scripts/test-tier0.sh` | Single entry — ship gate |
| `tests/test_tier0_entry.sh` | Meta: entry exists; fail-closed |
| `tests/test_*.sh`, `tests/test_*.py` | Covered suites |
| `STATUS.md`, `README.md` | Mark Tier-0 Proven-green(script); document entry |

---

## Chunk 1: Entry script + RED→GREEN coverage

### Task 1: Entry contract + wrapper

**Files:**
- Create: `scripts/test-tier0.sh`
- Create: `tests/test_tier0_entry.sh`

- [ ] **Step 1: Write meta test first (fails until wrapper exists)**

Create `tests/test_tier0_entry.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENTRY="$ROOT/scripts/test-tier0.sh"
[[ -x "$ENTRY" || -f "$ENTRY" ]] || { echo "FAIL: missing $ENTRY"; exit 1; }
# fail-closed: entry must not swallow child failures
grep -q 'set -euo pipefail' "$ENTRY"
grep -q 'test_p1_smoke.sh' "$ENTRY"
grep -q 'test_report_names.sh' "$ENTRY"
grep -q 'TIER0_OK' "$ENTRY"
# must NOT ignore smoke/report failures
if grep -E 'test_p1_smoke\.sh.*\|\| true|test_report_names\.sh.*\|\| true' "$ENTRY"; then
  echo "FAIL: entry ignores child failures"; exit 1
fi
echo "ENTRY_CONTRACT_OK"
```

```bash
chmod +x tests/test_tier0_entry.sh
bash tests/test_tier0_entry.sh
```

Expected: FAIL (`missing …/test-tier0.sh`).

- [ ] **Step 2: Create wrapper**

Create `scripts/test-tier0.sh` with exact body:

```bash
#!/usr/bin/env bash
# Tier-0 ship entry — local complete script truth
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "== tier0: pytest hash =="
python3 -m pytest tests/test_scan_plan_hash.py -q

echo "== tier0: assert_gate =="
bash tests/test_assert_gate.sh

echo "== tier0: verify-run =="
bash tests/test_verify_run.sh

echo "== tier0: report names =="
bash tests/test_report_names.sh

echo "== tier0: p1 smoke (gate RED after mutate) =="
bash tests/test_p1_smoke.sh

echo "== tier0: install safety (if present) =="
if [[ -f tests/test_install_force_safety.sh ]]; then
  bash tests/test_install_force_safety.sh
fi
if [[ -f tests/test_install_manifest.sh ]]; then
  bash tests/test_install_manifest.sh
fi

echo "TIER0_OK"
```

```bash
chmod +x scripts/test-tier0.sh
```

- [ ] **Step 3: Verify smoke contains mutate→gate RED**

```bash
grep -q 'MUTATED_SMOKE\|assert_gate' tests/test_p1_smoke.sh
# Must show non-zero check after mutate — require these patterns:
grep -q 'assert_gate.sh' tests/test_p1_smoke.sh
grep -Eq 'RC|exit 1' tests/test_p1_smoke.sh || { echo "FAIL: smoke missing RED assert"; exit 1; }
echo "SMOKE_RED_SEGMENT_OK"
```

Expected: `SMOKE_RED_SEGMENT_OK`. If FAIL: stop and restore mutate block from `.worktrees/vibage-os-p1/tests/test_p1_smoke.sh` lines covering “mutate plan → stale confirm” through non-zero `assert_gate` (do not invent a weaker check).

- [ ] **Step 4: Run meta + entry — expect PASS**

```bash
bash tests/test_tier0_entry.sh
bash scripts/test-tier0.sh
```

Expected: `ENTRY_CONTRACT_OK` then `TIER0_OK`, exit 0. Fix child suites until green; never `|| true` around ship suites.

- [ ] **Step 5: Commit**

```bash
git add scripts/test-tier0.sh tests/test_tier0_entry.sh tests
git commit -m "$(cat <<'EOF'
test: add Tier-0 ship entry scripts/test-tier0.sh

EOF
)"
```

---

### Task 2: STATUS + README ship wording

**Files:**
- Modify: `STATUS.md`, `README.md`

- [ ] **Step 1: Update STATUS capability row**

Set Tier-0 row: Designed=YES, On-tree=YES, Proven-green=YES, Scope=`script`.

Add plain sentence:

> This-wave 可交貨 = Plan0 + Tier-0 green. ≠ agent E2E. ≠ publish-ready.

- [ ] **Step 2: README one-liner**

Document: `bash scripts/test-tier0.sh` as the local proof command.

- [ ] **Step 3: Commit**

```bash
git add STATUS.md README.md
git commit -m "$(cat <<'EOF'
docs: mark Tier-0 script-proven as this-wave ship

EOF
)"
```

---

### Task 3: P2 DoD (ship)

- [ ] **Step 1: Final ship check**

```bash
bash scripts/test-tier0.sh
```

Expected: `TIER0_OK`

- [ ] **Step 2: Hand off**

This-wave **script ship** complete. Next optional: P3 handoff dual-write. Do **not** mark Focus agent-pressure Proven-green.
