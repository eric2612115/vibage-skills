---
name: vibage-init
description: >-
  Use when Vibage is not installed, hub STATUS missing, user pastes NEW-CHAT,
  or asks to install/init Vibage on the parent-folder workspace.
  Do not write VIBAGE-OWNER/LOCATE or deep-dig.
---

# Vibage Init

Goal: install package skills, create `docs/vibage/` hub skeleton, verify pins, hand off to orient.

## When / Not

| When | Not |
|------|-----|
| No hub `docs/vibage/STATUS.md` | Write locate dual reports |
| Install unclear / NEW-CHAT cold start | Deep dig or nested investigation |
| User asks "install Vibage" | Claim survey or Mode full nested |

## PKG_ROOT (mandatory — portable)

Prefer init symlink (P1):

```bash
python3 -c 'import os; print(os.path.dirname(os.path.dirname(os.path.realpath(os.path.expanduser("~/.cursor/skills/vibage-init")))))'
```

Fallback if init not linked yet (V0 installs):

```bash
python3 -c 'import os; print(os.path.dirname(os.path.dirname(os.path.realpath(os.path.expanduser("~/.cursor/skills/vibage-locate")))))'
```

If neither exists, PKG_ROOT = this package checkout (directory containing `skills/` and `scripts/`).

Never hardcode `/Users/...`.

## Language

Match the owner's language. Never assume Traditional Chinese. Paths and identifiers stay English.

## Procedure

1. Confirm package layout exists: `skills/MANIFEST.txt`, `scripts/install.sh`, `DEPENDENCIES.md`, `prompts/NEW-CHAT.md`, `references/hub/`.
2. Install (no silent `--force`):
   - Global: `bash "$PKG_ROOT/scripts/install.sh"`
   - Optional project rule: `--with-project-rule="$WORKSPACE"`
   - Optional project skills: `--project-skills="$WORKSPACE"`
   - Hub: `bash "$PKG_ROOT/scripts/install.sh" --init-hub="$WORKSPACE"`
3. **`--force` policy:** `--force` only replaces **package-owned stale** project skill **symlinks** (resolved under `$PKG_ROOT/skills`). It never deletes real (non-symlink) skill directories, and never replaces foreign symlinks. For foreign symlinks or real skill dirs: tell the owner to manually `rm` that path, then re-run install with `--project-skills` (no `--force`). Do not pass `--force` unless the user explicitly approved replacing a package-owned stale link; record that approval in `docs/vibage/DECISIONS.md` (`source: human`).
4. Run `"$PKG_ROOT/scripts/verify-pins.sh"`. On failure → stop; owner-language recovery:
   1) Ensure `~/.cursor/skills/superpowers` is a git checkout of obra/superpowers (or their pin path).  
   2) `git -C ~/.cursor/skills/superpowers fetch && git -C ~/.cursor/skills/superpowers checkout <superpowers_sha from DEPENDENCIES.md>`.  
   3) Re-run verify-pins.
5. Create or continue a run footprint:
   - Pick `run_id` = `locate-YYYYMMDD-HHMMSS` (UTC).
   - Write `docs/vibage/RUNS/<run_id>.json` with phase `installed`, mode `degraded`, empty artifacts.
   - Update `docs/vibage/STATUS.md`: `hub_ready: true`, `focus_run_id`, `focus_pipeline_id: locate`, `phase: installed`.
6. **Resume (S12):** If STATUS/CONFIRM already exist, do **not** wipe CONFIRM via re-init. Prefer `--init-hub` skip-existing behavior. Hand off based on phase.
7. Hand off: instruct agent to **Read and follow** `vibage-orient` (do not dig; do not write OWNER/LOCATE here).

## RunEnvelope seed (write this JSON)

```json
{
  "schema_version": "1",
  "pipeline_id": "locate",
  "run_id": "<run_id>",
  "phase": "installed",
  "mode": "degraded",
  "artifact_uris": [],
  "survey_refs": [],
  "gap_ids": []
}
```

## Hard stops

- Do not invent site URLs or commercial claims.
- Do not require signup before local reports.
- Do not write `VIBAGE-OWNER.md` / `VIBAGE-LOCATE.md` in init.
- Do not deep-dig or claim nested Mode.
- Do not use `--force` without recorded human approval.
- Do not `rm -rf` real project skill directories to “help” install; only the owner may remove them.
