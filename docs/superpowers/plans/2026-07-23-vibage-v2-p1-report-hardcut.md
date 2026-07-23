# P1 — Report hard-cut `VIBAGE-ISSUE-*` Implementation Plan

> **For agentic workers:** REQUIRED: Use `@superpowers:subagent-driven-development` or `@superpowers:executing-plans`. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Hard-cut deliverable report names to `VIBAGE-ISSUE-OWNER.md` and `VIBAGE-ISSUE-LOCATE.md` with no legacy compat.

**Architecture:** Update templates, skills, verify scripts, and fixtures so any old `VIBAGE-OWNER.md` / `VIBAGE-LOCATE.md` / `WAR-ROOM-*` references fail tests.

**Tech Stack:** Markdown templates, bash verify scripts, fixtures

**Spec:** umbrella §3.2 / §5.2 / D5  
**Depends on:** P0 complete  
**Index:** `2026-07-23-vibage-v2-plan-index.md`

---

## File map

| Path | Responsibility |
|------|----------------|
| `references/owner-report-template.md` | OWNER template |
| `references/locate-report-template.md` | LOCATE template (+ assumption-challenge section) |
| `skills/vibage-locate/SKILL.md` | Instruct new filenames |
| `scripts/verify-report.sh` | Assert hard-cut names / reject legacy |
| `tests/fixtures/sample_*.md` | Fixtures renamed or content updated |
| `assets/vibage-preview/**` | Preview copy if it names reports |

---

## Chunk 1: Templates and skill copy

### Task 1: Failing test for hard-cut names

**Files:**
- Create: `tests/test_report_names.sh`
- Modify: `scripts/verify-report.sh` (later)

- [x] **Step 1: Write failing test**

Create `tests/test_report_names.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# Legacy names must NOT be the instructed deliverable in skill/templates
if rg -n 'VIBAGE-OWNER\.md|VIBAGE-LOCATE\.md|WAR-ROOM-OWNER|WAR-ROOM-LOCATE' \
  "$ROOT/skills/vibage-locate/SKILL.md" \
  "$ROOT/references/owner-report-template.md" \
  "$ROOT/references/locate-report-template.md"; then
  echo "FAIL: legacy report names still present in live templates/skill"
  exit 1
fi
rg -n 'VIBAGE-ISSUE-OWNER\.md' "$ROOT/skills/vibage-locate/SKILL.md" \
  "$ROOT/references/owner-report-template.md"
rg -n 'VIBAGE-ISSUE-LOCATE\.md' "$ROOT/skills/vibage-locate/SKILL.md" \
  "$ROOT/references/locate-report-template.md"
echo "OK: hard-cut names present; legacy absent"
```

- [x] **Step 2: Run test — expect FAIL**

```bash
chmod +x tests/test_report_names.sh
bash tests/test_report_names.sh
```

Expected: FAIL (legacy names still present or new names missing).

- [x] **Step 3: Update templates + skill**

In `references/owner-report-template.md`, `references/locate-report-template.md`, `skills/vibage-locate/SKILL.md`:

- Use only `VIBAGE-ISSUE-OWNER.md` / `VIBAGE-ISSUE-LOCATE.md`
- Ensure LOCATE template has **Assumption-challenge** section (2–5 bullet slots)
- Header notes two status lines: 找問題 / 架構檢視

- [x] **Step 4: Re-run test — expect PASS**

```bash
bash tests/test_report_names.sh
```

Expected: `OK: hard-cut names present; legacy absent`

- [x] **Step 5: Commit**

```bash
git add tests/test_report_names.sh references/owner-report-template.md references/locate-report-template.md skills/vibage-locate/SKILL.md
git commit -m "$(cat <<'EOF'
feat: hard-cut report names to VIBAGE-ISSUE-*

EOF
)"
```

---

### Task 2: verify-report + fixtures

**Files:**
- Modify: `scripts/verify-report.sh`
- Modify: `tests/fixtures/*LOCATE*`, `tests/fixtures/*OWNER*` if named legacy
- Modify: `assets/vibage-preview/index.html` if it labels files

- [x] **Step 1: Add verify check for filename args**

In `scripts/verify-report.sh`, when paths are passed, if basename is `VIBAGE-OWNER.md` or `VIBAGE-LOCATE.md`, exit non-zero with plain message preferring `VIBAGE-ISSUE-*`.

- [x] **Step 2: Update fixtures / smoke callers**

Rename or retarget fixture filenames in tests that pass report paths into `verify-report.sh`.

- [x] **Step 3: Run related tests**

```bash
bash tests/test_verify_run.sh
bash tests/test_p1_smoke.sh
bash tests/test_report_names.sh
```

Expected: all exit 0.

- [x] **Step 4: Commit**

```bash
git add scripts/verify-report.sh tests assets
git commit -m "$(cat <<'EOF'
test: align verify-report and fixtures with VIBAGE-ISSUE-*

EOF
)"
```

---

### Task 3: P1 DoD

- [x] **Step 1: Acceptance**

```bash
bash tests/test_report_names.sh
rg -n 'VIBAGE-OWNER\.md|VIBAGE-LOCATE\.md' skills references scripts tests assets \
  -g '!docs/archive/**' && exit 1 || echo "legacy_clear"
```

Expected: `legacy_clear` and name test OK.

- [x] **Step 2: Hand off to P2**
