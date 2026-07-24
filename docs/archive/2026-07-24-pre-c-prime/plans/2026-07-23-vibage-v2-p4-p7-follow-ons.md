> **ARCHIVED · DO NOT EXECUTE as live SSOT.**
> Live C′ plan: `docs/superpowers/plans/2026-07-25-vibage-c-prime-graph-brief-ledger.md`

# P4–P7 — Follow-on plans (optional / deferred)

> **For agentic workers:** REQUIRED: Use `@superpowers:subagent-driven-development` or `@superpowers:executing-plans`. Do **not** block this-wave ship (P2) on these. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Wire optional B-path tracks thinly, finish skill rename, stub Focus meta row, add CI only when remote exists.

**Architecture:** Keep Approach 1. Thick behavior lives in satellites under `docs/superpowers/specs/satellites/` when a plan starts.

**Tech Stack:** Markdown MANIFEST/skills, git remotes, GitHub Actions optional

**Spec:** umbrella §9.2 P4–P7  
**Depends on:** P2 for ship; P3 recommended before heavy dual-write UX claims  
**Index:** `2026-07-23-vibage-v2-plan-index.md`

---

## P4 — Optional tracks (issue-fix / 架構檢視)

### Task P4.1: Thin MANIFEST + skill stubs

**Files:**
- Modify: `MANIFEST.txt` / install allowlist
- Create (if missing): `skills/vibage-issue-fix/SKILL.md` stub
- Create: `docs/superpowers/specs/satellites/SAT-issue-fix-unlock.md` (short) before deep unlock behavior
- Create: `docs/superpowers/specs/satellites/SAT-arch-review.md` + `SAT-map-schema.md` before map depth

- [x] **Step 1: Mark tracks optional in MANIFEST / STATUS**

Locate DONE independent. Preference NO blocks fix (umbrella §4.1).

- [x] **Step 2: Stub skills with hard gates only**

issue-fix SKILL must state: require OWNER_POLICY YES + unlock file; prefer branch/PR; no dig without locate report.

架構檢視 SKILL must state: require qualified map; failure does not undo locate DONE.

- [x] **Step 3: Contract tests (no full agent)**

Add `tests/test_optional_track_gates.sh` asserting skill text / tiny JSON unlock schema exists.

- [x] **Step 4: Commit**

```bash
git commit -m "$(cat <<'EOF'
feat: optional issue-fix and 架構檢視 track stubs

EOF
)"
```

---

## P5 — Skill rename cleanup

### Task P5.1: `vibage-locate` → `vibage-issue-locate`

**Files:**
- Move: `skills/vibage-locate` → `skills/vibage-issue-locate`
- Modify: `scripts/install.sh`, `MANIFEST.txt`, `rules/vibage-locate.mdc`, `prompts/NEW-CHAT.md`

- [x] **Step 1: git mv skill dir**

- [x] **Step 2: Keep install redirect** from old name for one release (document in README)

- [x] **Step 3: Update rules + NEW-CHAT triggers**

- [x] **Step 4: Run `bash scripts/test-tier0.sh`**

Expected: `TIER0_OK`

- [x] **Step 5: Commit**

```bash
git commit -m "$(cat <<'EOF'
refactor: rename skill dir to vibage-issue-locate

EOF
)"
```

---

## P6 — Focus: agent-pressure stub

### Task P6.1: STATUS meta row only

**Files:**
- Modify: `STATUS.md`
- Create: `docs/superpowers/specs/satellites/SAT-agent-pressure.md` outline (protocol pointer; no scenarios yet)

- [x] **Step 1: Ensure STATUS lists Focus: agent-pressure** with Designed=YES, On-tree=stub, Proven-green=NO, Scope=`agent`, note **not a pipeline_id**

- [x] **Step 2: Do not run agent RED→GREEN in this plan**

- [x] **Step 3: Commit**

```bash
git commit -m "$(cat <<'EOF'
docs: stub Focus agent-pressure meta row

EOF
)"
```

---

## P7 — CI when remote exists

### Task P7.1: Mirror Tier-0

**Files:**
- Create: `.github/workflows/tier0.yml` (only if `git remote -v` shows origin)

- [x] **Step 1: Check remote**

```bash
git remote -v
```

If empty: **stop** — document “no remote ≠ publish-ready” in STATUS; do not invent CI green.

**Result (this checkout):** no `origin` → **SKIPPED** creating `.github/workflows/tier0.yml`. Documented in `STATUS.md`.

- [ ] **Step 2: Workflow runs** — N/A (no remote)

```yaml
# .github/workflows/tier0.yml
name: tier0
on: [push, pull_request]
jobs:
  tier0:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: bash scripts/test-tier0.sh
```

- [ ] **Step 3: Commit only with remote present** — N/A (skipped)

---

## Follow-on DoD

- [x] P4 stubs do not make locate DONE depend on fix/架構  
- [x] P5 Tier-0 still green  
- [x] P6 Focus not marked agent Proven-green  
- [x] P7 skipped honestly if no remote  
