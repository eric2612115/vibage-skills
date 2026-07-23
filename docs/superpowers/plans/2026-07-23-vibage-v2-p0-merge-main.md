# P0 — Merge p1 → single clean trunk Implementation Plan

> **For agentic workers:** REQUIRED: Use `@superpowers:subagent-driven-development` (if subagents available) or `@superpowers:executing-plans` to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Land `scan_plan_hash` + tests from `feature/vibage-os-p1` onto one clean trunk with live SSOT only under `docs/vibage/` / `vibage-*`, archive conflicting docs, and stop soft-CTA happy-path links.

**Architecture:** Merge recipe from umbrella §7.1 — vibage wins on conflict; rewrite any `docs/war-room/` leftovers; Plan 0 DoD includes archive + thin STATUS (Designed/On-tree/Proven-green with scope). No product feature work beyond unblock gates.

**Tech Stack:** git, bash, Python 3, pytest

**Spec:** `@docs/superpowers/specs/2026-07-23-vibage-v2-superpowers-grade-design.md` (§7.1, D9, D10)

**Index:** `@docs/superpowers/plans/2026-07-23-vibage-v2-plan-index.md`

---

## File map

| Path | Responsibility |
|------|----------------|
| `scripts/lib/scan_plan_hash.py` | Canonical SCAN_PLAN hash (from p1) |
| `scripts/lib/__init__.py` | Package marker |
| `scripts/assert_gate.sh` | Dig gate (already on trunk; must find lib) |
| `scripts/write_confirm.sh` | Writes CONFIRM.json |
| `tests/**` | Pytest + bash gate/smoke from p1 |
| `docs/archive/2026-07-23/**` | Retired conflicting docs |
| `STATUS.md` | Thin package STATUS three-state |
| `README.md`, `prompts/NEW-CHAT.md` | Unlink archived / soft CTA |
| `references/feature-call.md` | Archive or banner; not happy-path |

---

## Chunk 1: Merge and path rewrite

### Task 1: Preflight and merge

**Files:**
- Merge from: `feature/vibage-os-p1` (worktree may be `.worktrees/vibage-os-p1`)
- Modify: conflicted paths as needed
- Verify: `scripts/lib/scan_plan_hash.py` exists on current branch after merge

- [x] **Step 1: Record tips**

```bash
cd /Users/eric.fang/MindOwnBuz/vibage-skills
git status -sb
git rev-parse HEAD feature/vibage-os-p1
test -f .worktrees/vibage-os-p1/scripts/lib/scan_plan_hash.py && echo "p1 has hash"
test ! -f scripts/lib/scan_plan_hash.py && echo "trunk missing hash (expected before merge)"
```

Expected: trunk missing `scripts/lib/scan_plan_hash.py`; p1 has it.

- [x] **Step 2: If p1 worktree has uncommitted vibage renames, commit them on p1 first**

Only if `git -C .worktrees/vibage-os-p1 status` shows relevant changes. Commit on that branch with message:

```bash
git -C .worktrees/vibage-os-p1 add -A
git -C .worktrees/vibage-os-p1 commit -m "$(cat <<'EOF'
chore: commit vibage path renames before merge into v2 trunk

EOF
)"
```

If clean, skip.

- [x] **Step 3: Merge p1 into current branch**

```bash
git checkout feature/vibage-v2-superpowers-grade
git merge feature/vibage-os-p1 -m "$(cat <<'EOF'
merge: land vibage-os-p1 gates and tests onto v2 trunk

EOF
)"
```

On conflict: **keep vibage live paths** (`docs/vibage/`, `vibage-*` skills). Discard resurrecting live `war-room-*` skills/rules as SSOT. Prefer p1 for `scripts/lib/**` and `tests/**` if trunk lacks them.

- [x] **Step 4: Path rewrite sweep**

Rewrite map (live paths only; never under `docs/archive/`):

| From | To / action |
|------|-------------|
| `docs/war-room/` | `docs/vibage/` |
| `war-room-preview` / `assets/war-room-preview` | `vibage-preview` / `assets/vibage-preview` |
| `skills/war-room-*` | discard live dir if present; SSOT is `skills/vibage-*` |
| `rules/war-room-*.mdc` | discard or replace with `rules/vibage-*.mdc` |
| `WAR-ROOM-*` report names in live scripts/tests | leave for P1 hard-cut if only report names; hub paths must already be vibage |

```bash
rg -n "docs/war-room|war-room-preview|skills/war-room|rules/war-room" \
  scripts tests references skills assets prompts README.md STATUS.md MANIFEST.txt rules \
  -g '!docs/archive/**' || true
```

Apply rewrites/deletes for each hit, then verify clean:

```bash
if rg -n "docs/war-room|war-room-preview|skills/war-room|rules/war-room" \
  scripts tests skills assets prompts README.md MANIFEST.txt rules \
  -g '!docs/archive/**'; then
  echo "FAIL: live war-room paths remain"; exit 1
fi
echo "PATH_REWRITE_OK"
```

Expected: `PATH_REWRITE_OK`

High-risk conflict winners: keep trunk vibage wording in `scripts/assert_gate.sh` / `scripts/write_confirm.sh` hub paths (`docs/vibage`); take p1 `scripts/lib/**` and `tests/**` if trunk lacks them.

- [x] **Step 5: Prove hash import works**

```bash
python3 scripts/lib/scan_plan_hash.py --help 2>/dev/null || python3 -c "import runpy; runpy.run_path('scripts/lib/scan_plan_hash.py')" 
# Prefer:
python3 - <<'PY'
from pathlib import Path
import sys
sys.path.insert(0, "scripts/lib")
from scan_plan_hash import hash_scan_plan_file
print("import_ok")
PY
```

Expected: `import_ok` (or module runs as CLI per p1 `__main__`).

- [x] **Step 6: Commit merge resolution if needed**

```bash
git add -A
git status
git commit -m "$(cat <<'EOF'
fix: resolve p1 merge with vibage-only live SSOT

EOF
)" || true
```

Skip empty commit if merge commit already clean.

---

### Task 2: Gate red/green smoke after merge

**Files:**
- Test: `tests/test_assert_gate.sh`, `tests/test_scan_plan_hash.py`
- Modify: only if paths still wrong

- [x] **Step 1: Run hash unit tests**

```bash
cd /Users/eric.fang/MindOwnBuz/vibage-skills
python3 -m pytest tests/test_scan_plan_hash.py -v
```

Expected: PASS (all tests).

- [x] **Step 2: Run assert_gate bash test**

```bash
bash tests/test_assert_gate.sh
```

Expected: exit 0; includes mismatch FAIL path inside script.

- [x] **Step 3: Manual RED check (dig forbidden signal)**

```bash
TMP=$(mktemp -d)
mkdir -p "$TMP/docs/vibage"
cp tests/fixtures/sample_SCAN_PLAN.md "$TMP/docs/vibage/SCAN_PLAN.md"
echo '{"schema_version":"1","payload_hash":"deadbeef","hash_alg":"sha256"}' > "$TMP/docs/vibage/CONFIRM.json"
set +e
OUT=$(bash scripts/assert_gate.sh "$TMP" 2>&1)
RC=$?
set -e
rm -rf "$TMP"
test "$RC" -ne 0 || { echo "FAIL: expected non-zero"; exit 1; }
echo "$OUT" | grep -q 'ASSERT_GATE_FAIL' || { echo "FAIL: missing ASSERT_GATE_FAIL in output"; exit 1; }
echo "RED_OK"
```

Expected: `RED_OK` (non-zero exit **and** output contains `ASSERT_GATE_FAIL`).

- [x] **Step 4: Commit any test path fixes**

```bash
git add tests scripts
git commit -m "$(cat <<'EOF'
test: ensure gate RED/GREEN after p1 merge

EOF
)" || true
```

---

## Chunk 2: Archive, unlink CTA, thin STATUS

### Task 3: Archive conflicting docs

**Files:**
- Create: `docs/archive/2026-07-23/INDEX.md`
- Move: `coverage/**`, `docs/superpowers/plans/2026-07-22-vibage-os-p1.md`, `docs/superpowers/specs/2026-07-22-vibage-os-p1-design.md` (banner or move), conflicting coverage reviews
- Modify: `references/feature-call.md` → move or add banner then unlink

- [ ] **Step 1: Create archive root + INDEX**

```bash
mkdir -p docs/archive/2026-07-23
```

Create `docs/archive/2026-07-23/INDEX.md`:

```markdown
# Archive 2026-07-23 — DO NOT USE FOR DEV

Moved conflicting pre-v2 docs. Live SSOT:
- Spec: `docs/superpowers/specs/2026-07-23-vibage-v2-superpowers-grade-design.md`
- Plans: `docs/superpowers/plans/2026-07-23-vibage-v2-*.md`

| Source | Reason |
|--------|--------|
| `coverage/*` | Hand-written PASS / false green |
| `STATUS.md.pre-v2.md` | Snapshot before thin rewrite |
| `docs/superpowers/plans/2026-07-22-vibage-os-p1.md` | Superseded by v2 plan index |
| `docs/superpowers/specs/2026-07-22-vibage-os-p1-design.md` | Superseded by v2 umbrella |
| `references/feature-call.md` | Soft CTA / register path — not this-wave happy path |
```

- [ ] **Step 2: Snapshot old STATUS then move files**

```bash
mkdir -p docs/archive/2026-07-23/coverage
cp STATUS.md docs/archive/2026-07-23/STATUS.md.pre-v2.md
# banner on snapshot:
printf '%s\n\n' '> **DO NOT USE FOR DEV** — Archived 2026-07-23. See v2 umbrella spec.' | cat - docs/archive/2026-07-23/STATUS.md.pre-v2.md > /tmp/st.md && mv /tmp/st.md docs/archive/2026-07-23/STATUS.md.pre-v2.md

mkdir -p docs/archive/2026-07-23/coverage
if [[ -d coverage ]] && ls coverage/* >/dev/null 2>&1; then
  git mv coverage/* docs/archive/2026-07-23/coverage/
  rmdir coverage 2>/dev/null || true
fi
[[ -f docs/superpowers/plans/2026-07-22-vibage-os-p1.md ]] && git mv docs/superpowers/plans/2026-07-22-vibage-os-p1.md docs/archive/2026-07-23/
[[ -f docs/superpowers/specs/2026-07-22-vibage-os-p1-design.md ]] && git mv docs/superpowers/specs/2026-07-22-vibage-os-p1-design.md docs/archive/2026-07-23/
[[ -f references/feature-call.md ]] && git mv references/feature-call.md docs/archive/2026-07-23/
```

Add INDEX rows for `STATUS.md.pre-v2.md`. Banner every moved `*.md`:

```bash
while IFS= read -r f; do
  grep -q 'DO NOT USE FOR DEV' "$f" && continue
  tmp=$(mktemp)
  printf '%s\n\n' '> **DO NOT USE FOR DEV** — Archived 2026-07-23. See v2 umbrella spec.' | cat - "$f" > "$tmp"
  mv "$tmp" "$f"
done < <(find docs/archive/2026-07-23 -type f -name '*.md')
```

- [ ] **Step 3: Unlink from entrypoints (do not rewrite STATUS body here — Task 4)**

**`prompts/NEW-CHAT.md`:** remove any line linking `references/feature-call.md` or register/soft CTA; point cold-start to v2 umbrella + plan index.

**`README.md`:** remove `coverage/` as live proof; remove soft CTA / register sections; add:

```markdown
**Spec (live):** `docs/superpowers/specs/2026-07-23-vibage-v2-superpowers-grade-design.md`  
**Plans (live):** `docs/superpowers/plans/2026-07-23-vibage-v2-plan-index.md`  
**Local proof (after P2):** `bash scripts/test-tier0.sh`
```

**`skills/vibage-locate/SKILL.md`:** delete soft CTA / feature-call / signup paragraphs; replace with exactly:

```markdown
Local delivery ends at dual Markdown reports + optional preview. Cloud deepening is out of scope this phase.
```

**`prompts/NEW-CHAT.md`:** delete any bullet/line that mentions `feature-call`, soft CTA, or signup. Ensure cold-start points only to v2 umbrella + plan index (no archived paths as live SSOT).

Leave full `STATUS.md` rewrite to Task 4.

- [ ] **Step 4: Verify no live happy-path CTA**

```bash
# Ban live signup/CTA pointers (do not ban the word "SaaS" alone)
if rg -n "feature-call|soft CTA|soft-cta|註冊|sign up|signup" \
  README.md prompts/NEW-CHAT.md skills/vibage-locate/SKILL.md \
  -g '!docs/archive/**'; then
  echo "FAIL: CTA/feature-call still live"; exit 1
fi
echo "CTA_UNLINK_OK"
```

Expected: `CTA_UNLINK_OK`

- [ ] **Step 5: Commit archive**

```bash
git add docs/archive README.md prompts/NEW-CHAT.md skills/vibage-locate/SKILL.md references
git commit -m "$(cat <<'EOF'
docs: archive conflicting pre-v2 docs and unlink soft CTA

EOF
)"
```

---

### Task 4: Thin package STATUS (three-state)

**Files:**
- Modify: `STATUS.md` (package root)

- [ ] **Step 1: Rewrite STATUS.md to thin SSOT**

Replace progress claims with a table like:

```markdown
# Vibage Skills — STATUS

> Package progress SSOT (not hub runtime STATUS). Hub runtime lives under owner workspace `docs/vibage/STATUS.md`.

**Spec:** `docs/superpowers/specs/2026-07-23-vibage-v2-superpowers-grade-design.md`  
**Plans:** `docs/superpowers/plans/2026-07-23-vibage-v2-plan-index.md`

## Capability (this wave)

| Capability | Designed | On-tree | Proven-green | Scope |
|------------|----------|---------|--------------|-------|
| scan_plan_hash + assert_gate | YES | YES/NO | YES/NO | script |
| Tier-0 `scripts/test-tier0.sh` | YES | NO | NO | script |
| Report hard-cut VIBAGE-ISSUE-* | YES | NO | NO | script |
| Handoff dual-write | YES | NO | NO | script |
| Focus: agent-pressure | YES | NO | NO | agent (deferred meta row — not a pipeline_id) |
| SaaS / register | blank | — | — | — |

Update On-tree / Proven-green only when scripts say so. Never YES without proof.
```

Fill On-tree/Proven for gate from Task 2 results.

- [ ] **Step 2: Commit STATUS**

```bash
git add STATUS.md
git commit -m "$(cat <<'EOF'
docs: thin package STATUS with Designed/On-tree/Proven scope

EOF
)"
```

---

### Task 5: P0 DoD gate

**Files:** none (verification only)

- [ ] **Step 1: P0 acceptance checklist**

```bash
test -f scripts/lib/scan_plan_hash.py
test -d docs/archive/2026-07-23
test -f docs/archive/2026-07-23/INDEX.md
test -f docs/archive/2026-07-23/STATUS.md.pre-v2.md
python3 -m pytest tests/test_scan_plan_hash.py -q
bash tests/test_assert_gate.sh
test ! -d skills/war-room-locate
if rg -n "docs/war-room|war-room-preview|skills/war-room" scripts tests skills -g '!docs/archive/**'; then exit 1; fi
if rg -n "feature-call|soft CTA|soft-cta|註冊|sign up|signup" README.md prompts/NEW-CHAT.md skills/vibage-locate/SKILL.md -g '!docs/archive/**'; then exit 1; fi
grep -q 'Designed' STATUS.md
grep -q 'On-tree' STATUS.md
grep -q 'Proven-green' STATUS.md
grep -q 'Focus: agent-pressure' STATUS.md
echo "P0_DOD_OK"
```

Expected: `P0_DOD_OK`; re-run Task 2 Step 3 RED check once.

- [ ] **Step 2: Final P0 commit only if dirty**

```bash
git status -sb
```

- [ ] **Step 3: Hand off**

Announce P0 complete. Next: `@docs/superpowers/plans/2026-07-23-vibage-v2-p1-report-hardcut.md`
