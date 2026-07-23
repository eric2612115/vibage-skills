---
name: vibage-init
description: >-
  Use when Vibage is not installed, hub STATUS missing, user pastes NEW-CHAT,
  or asks to install/init Vibage on the parent-folder workspace.
  Do not write VIBAGE-ISSUE-OWNER/LOCATE or deep-dig.
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

```bash
bash /path/to/vibage-skills/scripts/resolve-pkg-root.sh
```

Probes `~/.cursor/skills` → `~/.claude/skills` → `~/.agents/skills` for `vibage-init` then `vibage-locate`.
See `$PKG_ROOT/references/resolve-pkg-root.md`. If unresolved, PKG_ROOT = this package checkout
(directory containing `skills/` and `scripts/`). Never hardcode `/Users/...`.

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
   1) Ensure a git checkout of obra/superpowers exists (Cursor / Claude / Codex skill home — see DEPENDENCIES.md).  
   2) `git -C <superpowers_path> fetch && git -C <superpowers_path> checkout <superpowers_sha from DEPENDENCIES.md>`.  
   3) Symlink that checkout into each skill home you use; re-run verify-pins.
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

Also obey `$PKG_ROOT/references/hard-stops.md`.

- Do not invent site URLs or commercial claims.
- Do not require signup before local reports.
- Do not write `VIBAGE-ISSUE-OWNER.md` / `VIBAGE-ISSUE-LOCATE.md` in init.
- Do not deep-dig or claim nested Mode.
- Do not use `--force` without recorded human approval.
- Do not `rm -rf` real project skill directories to “help” install; only the owner may remove them.
