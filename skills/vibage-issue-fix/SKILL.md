---
name: vibage-issue-fix
description: >-
  Optional track: scoped business-code edits only after dual consent
  (OWNER_POLICY YES + unlock file). Prefer branch/PR. Do not dig without a
  locate report. Preference NO must not block locate DONE. Script-verify via
  verify-issue-fix-unlock.sh before edits.
---

# Vibage Issue Fix (optional track — usable)

**Status:** usable — dual-consent + unlock gates are script-verifiable. Thick contract → `SAT-issue-fix-unlock`.

**Honest scope:** Usable + package Proven-green(script) means gates are verifiable. It does **not** mean letter **B** complete, and does **not** guarantee agent fix E2E / quality.

**Track independence:** Locate may still DONE when preference is NO (default). This track never gates locate DONE.

**Handoff:** `artifacts_ok` does **not** cross pipelines by default. Do not reuse a locate-wave `artifacts_ok` / `verify-handoff.sh` verdict for fix runs.

## Hard gates (MUST)

1. **Dual consent** (umbrella §4.1):
   - Hub preference: `docs/vibage/OWNER_POLICY.json` with `fix_preference` = **YES** (default / example is NO). Package shape: `$PKG_ROOT/docs/superpowers/specs/satellites/OWNER_POLICY.example.json`.
   - Hub unlock: `docs/vibage/ISSUE_FIX_UNLOCK.json` after locate reports (scope confirm). Package shape: `$PKG_ROOT/docs/superpowers/specs/satellites/unlock.example.json`.
2. Preference ≠ unlock. Unlock without YES is forbidden. YES without unlock is forbidden.
3. If preference is **NO**: do **not** enter this skill or solicit unlock.
4. **No dig without locate report:** require workspace `VIBAGE-ISSUE-OWNER.md` + `VIBAGE-ISSUE-LOCATE.md` (or prior locate run DONE) before unlock/edits.
5. Prefer **branch/PR** for edits; no silent push; no deploy.
6. Stay inside unlock `allowed_paths`. Do not redefine model routing; do not claim 架構檢視 DONE.
7. **Thin map alone never unlocks fix (M01):** `PILE_INDEX_OK` / folder-name match / thin `service_map` is **not** permission to edit business code. Never “map says checkout so patch checkout” without locate dual reports + dual consent + `verify-issue-fix-unlock.sh` green.

## Usable procedure

1. Resolve package root:

```bash
PKG_ROOT="$(bash /path/to/vibage-skills/scripts/resolve-pkg-root.sh)"
```

2. Confirm locate reports exist (OWNER + LOCATE) or prior locate DONE. If missing → stop; run locate first.
3. If owner has not set preference YES: ask plainly in chat; write `docs/vibage/OWNER_POLICY.json` with `"fix_preference": "YES"` only on clear consent. If answer is NO → stop (locate DONE unchanged).
4. After YES **and** locate reports: write `docs/vibage/ISSUE_FIX_UNLOCK.json` with required keys (`schema_version`, `locate_run_id`, `allowed_paths`, `confirmed_at`, `confirmed_by`). `allowed_paths` and `locate_run_id` must be non-empty.
5. **Verify before any business edit:**

```bash
bash "$PKG_ROOT/scripts/verify-issue-fix-unlock.sh" <workspace_root>
```

   Exit 0 required. On FAIL → do not edit.
6. Create/use a feature branch; apply scoped edits only under `allowed_paths`; prefer PR; no silent push.
7. Summarize for owner; do not claim letter B or agent E2E proof from this script alone.

## When / Not

| When | Not |
|------|-----|
| OWNER_POLICY YES + valid unlock (verify OK) | Preference NO / missing unlock / bad schema |
| After dual locate reports | Dig / orient / init / **thin pile-index map alone** as substitute |
| Scoped edits on confirmed paths | Whole-repo rewrite; secret reads; Focus agent cards |
| Optional after locate | Undo locate DONE; cross-pipeline `artifacts_ok`; fix-from-map-name |

## PKG_ROOT

```bash
bash /path/to/vibage-skills/scripts/resolve-pkg-root.sh
```

Obey `$PKG_ROOT/references/hard-stops.md`. Full unlock schema: `$PKG_ROOT/docs/superpowers/specs/satellites/SAT-issue-fix-unlock.md`.
