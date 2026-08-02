# Work Continue Memory Implementation Plan

> **For agentic workers:** REQUIRED: Use TDD for every task that adds scripts or narrative gates. Prefer implementing in the mother agent for thin narrative edits (cheaper); use fresh cold subagents for review only. Steps use checkbox (`- [ ]`) syntax for tracking. Spec: `docs/superpowers/specs/2026-08-02-work-continue-memory-design.md`.

**Goal:** After locate succeeds, hub `docs/vibage/WORK_CONTINUE.md` carries work-root + dig pointers + side-quest bookmarks so new sessions resume single-repo work without rediscovering the pile.

**Architecture:** Template + locate finishing + routing-scope/adapters + hard-stops. Optional child `PROGRESS` template. Light verify/fixture tests outside Tier-0. No new methodology pins. No `assert_gate` / Tier-0 wiring.

**Tech Stack:** Markdown templates, bash test scripts, existing skill/adapter narrative surfaces.

**Process note:** This plan is the Superpowers SSOT for Build. Cursor Plan UI is not authoritative. Plan-loop reviews happen **before** Build and are recorded under `docs/evidence/reviews/` — do **not** put plan-loop todos inside this file.

---

## File map

| Path | Responsibility |
|------|----------------|
| `references/hub/WORK_CONTINUE.md` | Hub continue contract template + field docs |
| `references/PROGRESS.child.md` | Optional child execution progress template |
| `skills/vibage-issue-locate/SKILL.md` | Require write/update WORK_CONTINUE on locate success |
| `skills/using-vibage/SKILL.md` | Finishing: WORK_CONTINUE required alongside finishing options |
| `references/routing-scope.md` | Out-of-scope continue path: read contract before edit |
| `adapters/**` (thin) | Same read-before-edit duty where they mention out-of-scope |
| `references/hard-stops.md` | Forbid pretend-no-memory after locate DONE; forbid side-quest without bookmark |
| `tests/test_work_continue_memory.sh` | Structure + phrase gates |
| `tests/fixtures/work_continue/*` | Sample good/bad continue files |

---

### Task 1: Fixture + failing test (required fields)

**Files:**
- Create: `tests/fixtures/work_continue/ok.md`
- Create: `tests/fixtures/work_continue/missing_work_root.md`
- Create: `tests/test_work_continue_memory.sh`

- [ ] **Step 1: Write failing test**

`tests/test_work_continue_memory.sh` must:

1. Fail if `references/hub/WORK_CONTINUE.md` is missing  
2. Require these heading tokens (exact English identifiers) in the template:  
   `work_root`, `run_id`, `dual_report_uris`, `inherited_finding_ids`, `phase`, `side_quest`, `forbidden`, `updated_at`  
3. Require fixture `ok.md` to contain all eight; `missing_work_root.md` must fail a small checker that greps required fields  
4. Echo `WORK_CONTINUE_MEMORY_OK` on success  

```bash
# Sketch — implement fully in Task 1:
REQUIRED=(work_root run_id dual_report_uris inherited_finding_ids phase side_quest forbidden updated_at)
for k in "${REQUIRED[@]}"; do
  grep -Fq "$k" "$ROOT/references/hub/WORK_CONTINUE.md" || fail "template missing $k"
done
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
bash tests/test_work_continue_memory.sh
```

Expected: FAIL (template missing)

- [ ] **Step 3: Add template + ok fixture (minimal)**

Create `references/hub/WORK_CONTINUE.md` with all required field headings, short English comments, and a filled example block. Create `tests/fixtures/work_continue/ok.md` matching required keys; `missing_work_root.md` omits `work_root`.

- [ ] **Step 4: Run test — expect PASS**

```bash
bash tests/test_work_continue_memory.sh
# expect: WORK_CONTINUE_MEMORY_OK
```

- [ ] **Step 5: Commit**

```bash
git add references/hub/WORK_CONTINUE.md tests/test_work_continue_memory.sh tests/fixtures/work_continue/
git commit -m "$(cat <<'EOF'
test+docs(hub): WORK_CONTINUE template and memory gate

EOF
)"
```

---

### Task 2: Locate finishing requires WORK_CONTINUE

**Files:**
- Modify: `skills/vibage-issue-locate/SKILL.md`
- Modify: `skills/using-vibage/SKILL.md`
- Modify: `tests/test_work_continue_memory.sh`
- Modify: `tests/test_session_hooks.sh` (only if finishing pointer already asserted — extend, do not weaken)

- [ ] **Step 1: Extend failing assertions**

Add to `test_work_continue_memory.sh`:

- `vibage-issue-locate` SKILL must contain `WORK_CONTINUE` and a MUST/required finishing duty  
- `using-vibage` Finishing section must contain `WORK_CONTINUE` as required (not optional skip)

- [ ] **Step 2: Run — expect FAIL**

```bash
bash tests/test_work_continue_memory.sh
```

- [ ] **Step 3: Minimal skill edits**

In both skills: after locate success / finishing options, require write or update parent `docs/vibage/WORK_CONTINUE.md` from template fields. State: pointers only; ≠ full-understanding; ≠ second locate report.

- [ ] **Step 4: Run — expect PASS**

```bash
bash tests/test_work_continue_memory.sh
bash tests/test_session_hooks.sh
```

- [ ] **Step 5: Commit**

```bash
git add skills/vibage-issue-locate/SKILL.md skills/using-vibage/SKILL.md tests/test_work_continue_memory.sh
git commit -m "$(cat <<'EOF'
feat(skills): require WORK_CONTINUE on locate finishing

EOF
)"
```

---

### Task 3: Routing-scope + adapters + hard-stops

**Files:**
- Modify: `references/routing-scope.md`
- Modify: thin adapters that mention out-of-scope / routing (grep first; touch only those with out-of-scope prose)
- Modify: `references/hard-stops.md`
- Modify: `tests/test_work_continue_memory.sh`
- Create: `references/PROGRESS.child.md`

- [ ] **Step 1: Failing assertions**

- `routing-scope.md` must instruct: if `docs/vibage/WORK_CONTINUE.md` exists and task continues that work_root → read it before code edits  
- `hard-stops.md` must forbid pretending no memory after locate DONE; forbid side-quest without updating `side_quest`  
- Optional: adapters contain the same one-line pointer to `WORK_CONTINUE` / routing-scope (no long fork)

- [ ] **Step 2: Run — expect FAIL**

```bash
bash tests/test_work_continue_memory.sh
```

- [ ] **Step 3: Implement prose + child template**

Add routing + hard-stop bullets per design §5. Add `references/PROGRESS.child.md` stating child progress must not override hub `work_root` / `side_quest`.

- [ ] **Step 4: Run — expect PASS**

```bash
bash tests/test_work_continue_memory.sh
bash tests/test_entry_docs_sync.sh
```

- [ ] **Step 5: Commit**

```bash
git add references/routing-scope.md references/hard-stops.md references/PROGRESS.child.md adapters/ tests/test_work_continue_memory.sh
git commit -m "$(cat <<'EOF'
feat(routing): read WORK_CONTINUE before single-repo continue

EOF
)"
```

---

### Task 4: Firewall + pack health honesty

**Files:**
- Modify: none of `scripts/test-tier0.sh` / `scripts/pack-health.sh` unless a later owner decision says otherwise  
- Modify: `tests/test_work_continue_memory.sh` (assert not listed in tier0 if pattern exists in other firewall tests)

- [ ] **Step 1: Assert firewall**

Mirror honesty-followup style: confirm `test_work_continue_memory.sh` is **not** required by Tier-0. Document in test comment.

- [ ] **Step 2: Run suite slice**

```bash
bash tests/test_work_continue_memory.sh
bash scripts/test-tier0.sh
# expect: WORK_CONTINUE_MEMORY_OK and TIER0_OK
```

- [ ] **Step 3: Commit only if firewall assert added files**

```bash
git add tests/test_work_continue_memory.sh
git commit -m "$(cat <<'EOF'
test(work-continue): keep memory gate outside Tier-0

EOF
)"
```

---

### Task 5: Evidence note (no Build claim of full-sweep)

**Files:**
- Create: `docs/evidence/work-continue/README.md` (short: what shipped, NOT-claims)

- [ ] Document: continue memory ≠ full-sweep ≠ system-understood; depends on locate dual reports  
- [ ] Commit

```bash
git add docs/evidence/work-continue/README.md
git commit -m "$(cat <<'EOF'
docs(evidence): WORK_CONTINUE memory NOT-claims

EOF
)"
```

---

## Done when

- All checkboxes above complete  
- `WORK_CONTINUE_MEMORY_OK` + `TIER0_OK`  
- Owner can open a new chat and see agent resume from hub file without pile-index slogans  
- Impl narrative changes have looping-review records (outside this plan body)  
