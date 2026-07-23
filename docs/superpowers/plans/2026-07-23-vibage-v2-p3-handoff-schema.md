# P3 — Handoff schema + milestone dual-write Implementation Plan

> **For agentic workers:** REQUIRED: Use `@superpowers:subagent-driven-development` or `@superpowers:executing-plans`. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Machine-readable `RunEnvelope.handoff` + STATUS STOP card template + skill milestone dual-write hooks (chat plain + disk), with Terminal-then-mint and `supersedes_run_id` SSOT.

**Architecture:** Thin Approach 1 — JSON schema/fixture + verify helpers + skill MD obligations. No daemon. Chat never pastes JSON to owner.

**Tech Stack:** JSON fixtures, bash/python verify, Markdown skills/hub templates

**Spec:** umbrella §8  
**Depends on:** P2 (ship can precede; P3 is script-proven UX)  
**Index:** `2026-07-23-vibage-v2-plan-index.md`

---

## File map

| Path | Responsibility |
|------|----------------|
| `references/hub/STATUS.md` | STOP card template |
| `references/hub/RunEnvelope.example.json` | Example envelope + handoff |
| `scripts/lib/handoff_check.py` or `scripts/verify-handoff.sh` | Structural checks |
| `tests/fixtures/run_failed_handoff.json` | Failed mid-run fixture |
| `tests/test_handoff.sh` | Contract tests |
| `skills/vibage-locate/SKILL.md`, `skills/vibage-orient/SKILL.md` | Milestone dual-write steps |

---

## Chunk 1: Schema + verify

### Task 1: Failing handoff contract test

- [x] **Step 1: Add fixture `tests/fixtures/run_failed_handoff.json`**

Minimal envelope:

```json
{
  "schema_version": "1",
  "pipeline_id": "locate",
  "run_id": "locate-test-failed-1",
  "phase": "failed",
  "mode": "degraded",
  "supersedes_run_id": null,
  "stopped_at": "2026-07-23T00:00:00Z",
  "handoff": {
    "stop_reason": "gate_failed",
    "progress": {
      "steps_done": ["orient", "confirm"],
      "dig_ids_done": [],
      "dig_ids_pending": ["app-a"],
      "confirm_payload_hash": "abc"
    },
    "blockers": [{"kind": "stale_confirm", "detail": "hash mismatch"}],
    "next_action": {"summary": "Re-confirm SCAN_PLAN", "steps": ["re-confirm", "assert_gate"]},
    "artifacts_ok": {
      "SCAN_PLAN": "reuse",
      "CONFIRM": "redo",
      "OWNER_POLICY": "reuse"
    },
    "artifacts_ok_source": "script",
    "known_incompleteness": ["no dual reports"]
  }
}
```

- [x] **Step 2: Write `tests/test_handoff.sh` that fails until verifier exists**

Checks: `phase`/`pipeline_id` not inside `handoff`; required handoff keys present; mint example with `supersedes_run_id` set and optional `handoff.prior_run_id` equal or absent.

- [x] **Step 3: Implement `scripts/verify-handoff.sh`** (or small Python) to enforce §8.3 rules

- [x] **Step 4: RED→GREEN**

```bash
bash tests/test_handoff.sh
```

Expected: PASS

- [x] **Step 5: Commit**

```bash
git add tests/fixtures/run_failed_handoff.json tests/test_handoff.sh scripts/verify-handoff.sh references/hub
git commit -m "$(cat <<'EOF'
feat: RunEnvelope handoff contract + verify-handoff

EOF
)"
```

---

## Chunk 2: STATUS STOP + skill milestones

### Task 2: Hub STATUS STOP template

- [x] **Step 1: Update `references/hub/STATUS.md`** with STOP card fields (为何停 / 停在哪 / 已做完 / 卡住 / 下一步 / 可沿用 / 不可装做完) in Traditional Chinese labels + English keys in comments if needed

- [x] **Step 2: Skill hooks** — in orient/locate SKILL.md, list milestones that MUST dual-write (orient done, confirm, gate, locate start/end, success/stop). Explicit: chat = plain; disk = STATUS + RunEnvelope; no JSON dump to owner; no hub homework on happy path

- [x] **Step 3: Add handoff test to Tier-0 optionally**

Either extend `scripts/test-tier0.sh` with `bash tests/test_handoff.sh` or document as Tier-0+ ; prefer include once stable.

- [x] **Step 4: Commit + STATUS row Proven-green(script) for handoff when tests green**

---

### Task 3: P3 DoD

- [x] **Step 1:** `bash tests/test_handoff.sh` exit 0  
- [x] **Step 2:** No mid-fail path writes `VIBAGE-ISSUE-*` in skills (rg skill text for prohibition)  
- [x] **Step 3:** Hand off to P4–P7 follow-ons

This-wave **script ship** complete for P3. Do **not** start P4 in this commit wave unless separately dispatched.
