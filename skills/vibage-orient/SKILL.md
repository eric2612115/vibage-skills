---
name: vibage-orient
description: >-
  Use when hub is ready (docs/vibage/STATUS.md), there is no valid CONFIRM,
  or SCAN_PLAN must be (re)drafted before dig. Do not deep-dig or write
  VIBAGE-OWNER/LOCATE dual reports.
---

# Vibage Orient

Goal: discover RootRefs, write SCAN_PLAN, stop at `awaiting_confirm`.

## When / Not

| When | Not |
|------|-----|
| Hub ready, no valid CONFIRM | Deep dig / nested locate |
| Plan rejected or stale_confirm | Write OWNER/LOCATE |
| S1 empty parent / S1b repos added | Claim Mode full nested |

## PKG_ROOT

```bash
python3 -c 'import os; print(os.path.dirname(os.path.dirname(os.path.realpath(os.path.expanduser("~/.cursor/skills/vibage-init")))))'
```

Fallback: realpath on `~/.cursor/skills/vibage-locate` then dirname/dirname.

## RootRef schema (write into scan_plan_v1.root_refs[])

Each object:

- `id` (string)
- `path` or `uri` (string)
- `presence`: `checked_out` | `missing` | `external_ref` | `submodule`
- `kind`: `app` | `deploy` | `lib` | `data` | `unknown`
- `evidence` (string[])
- optional `hot_path` (bool)

ServiceRef = same schema when kind is app|deploy|lib|data.

## Procedure

1. Require hub: if `docs/vibage/STATUS.md` missing → hand off to `vibage-init`.
2. Discover roots (shallow):
   - One-level children of workspace with `.git` → `presence: checked_out`
   - Note suspected missing/external units as RootRef with `missing`/`external_ref` — do not invent checkouts
   - Vibing single-repo workspace (S3): still emit light SCAN_PLAN with that root
3. Write `docs/vibage/SCAN_PLAN.md`:
   - Human summary: list visible roots + time estimate + "confirming visible subset, not whole system"
   - Fenced JSON `scan_plan_v1` with required keys: `schema_version`, `root_refs`, `budgets`, `hot_path_ids`, `known_incompleteness`, `planned_dig_ids`
   - Default budgets if unspecified: `max_wall_min=25`, `max_files=40`, `max_depth=3`
   - `known_incompleteness` is required (never empty string without meaning)
4. Update RUNS + STATUS:
   - phase `plan_drafted` then `awaiting_confirm`
   - Do **not** enter `analyzing`
5. **Stop** and ask plain-language confirm (owner language). List roots + estimate. Do not dig.
6. On user confirm (chat OK is only a trigger):
   - Run `"$PKG_ROOT/scripts/write_confirm.sh" "$WORKSPACE"`
   - Remind: signed the **visible subset**
   - Hand off to `vibage-locate` (locate runs assert_gate)
7. On reject/change plan (S13): edit SCAN_PLAN; clear or overwrite CONFIRM only after new confirm; hash mismatch must block dig.
8. Stale (S14): if plan changed under an old CONFIRM → treat as `stale_confirm`; clear CONFIRM → re-orient (no `--force` required).

## Hard stops

- No deep dig, no dual reports, no nested investigators.
- No silent `--force` on install.
- Empty parent (S1): stay at awaiting_confirm; do not invent roots to dig.
