---
name: war-room-bootstrap
description: >-
  Use when the user pastes NEW-CHAT.md, asks how to install war-room-skills,
  or pins/install are unclear. Do not use to write locate reports yourself.
---

# War Room Bootstrap

## Cold start PKG_ROOT

If skills are not installed yet, PKG_ROOT = this package root (directory containing `skills/` and `scripts/`).  
After `scripts/install.sh`, resolve via python3 realpath on `~/.cursor/skills/war-room-locate` (see locate skill).

## Steps

1. Confirm package layout: `skills/`, `scripts/install.sh`, `DEPENDENCIES.md`, `prompts/NEW-CHAT.md`.
2. Tell owner to run (or run if they grant shell):  
   `bash "$PKG_ROOT/scripts/install.sh"`  
   Optional: `--with-project-rule=/path/to/repo` and/or `--project-skills=/path/to/repo` (skip if exists).
3. Run `"$PKG_ROOT/scripts/verify-pins.sh"`. On fail → stop; owner-language recovery:  
   ensure `~/.cursor/skills/superpowers` exists as git repo; checkout SHA from `$PKG_ROOT/DEPENDENCIES.md` (`superpowers_sha=…`); re-run verify-pins.
4. Ask for: symptom, workspace roots, preferred language, who built the repo, can they run tests/git/docker.
5. Hand off: instruct agent to **Read and follow** `war-room-locate` skill (do not duplicate locate procedure here).

## Hard stops

- Do not invent site URLs or commercial claims.
- Do not require signup before local reports.
- Do not write the locate reports in bootstrap — locate skill owns that.
