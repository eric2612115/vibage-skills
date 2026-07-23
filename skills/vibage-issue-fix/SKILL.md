---
name: vibage-issue-fix
description: >-
  Optional track: scoped business-code edits only after dual consent
  (OWNER_POLICY YES + unlock file). Prefer branch/PR. Do not dig without a
  locate report. Preference NO must not block locate DONE.
---

# Vibage Issue Fix (optional track stub)

**Status:** stub — hard gates only. Thick unlock behavior → `SAT-issue-fix-unlock`.

**Track independence:** Locate may still DONE when preference is NO (default). This track never gates locate DONE.

**Handoff:** `artifacts_ok` does **not** cross pipelines by default. Do not reuse a locate-wave `artifacts_ok` / `verify-handoff.sh` verdict for fix runs.

## Hard gates (MUST)

1. **Dual consent** (umbrella §4.1):
   - `docs/vibage/OWNER_POLICY.json` preference for fix = **YES** (default is NO).
   - File-backed **unlock** after a locate report (scope confirm). See unlock example under satellites.
2. Preference ≠ unlock. Unlock without YES is forbidden. YES without unlock is forbidden.
3. If preference is **NO**: do **not** enter this skill or solicit unlock.
4. **No dig without locate report:** require workspace `VIBAGE-ISSUE-OWNER.md` + `VIBAGE-ISSUE-LOCATE.md` (or prior locate run DONE) before unlock/edits.
5. Prefer **branch/PR** for edits; no silent push; no deploy.
6. Do not redefine model routing; do not claim 架構檢視 DONE.

## When / Not

| When | Not |
|------|-----|
| OWNER_POLICY YES + unlock file present | Preference NO / missing unlock |
| After dual locate reports | Dig / orient / init |
| Scoped edits on confirmed paths | Whole-repo rewrite; secret reads |

## PKG_ROOT

```bash
bash /path/to/vibage-skills/scripts/resolve-pkg-root.sh
```

Obey `$PKG_ROOT/references/hard-stops.md`. Full unlock schema: `$PKG_ROOT/docs/superpowers/specs/satellites/SAT-issue-fix-unlock.md`.
