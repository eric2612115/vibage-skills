---
name: vibage-orient
description: >-
  Use when hub is ready (docs/vibage/STATUS.md), there is no valid CONFIRM,
  or SCAN_PLAN must be (re)drafted before dig. Do not deep-dig or write
  VIBAGE-ISSUE-OWNER/LOCATE dual reports.
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
bash /path/to/vibage-skills/scripts/resolve-pkg-root.sh
```

See `$PKG_ROOT/references/resolve-pkg-root.md`.

## RootRef schema (write into scan_plan_v1.root_refs[])

Each object:

- `id` (string)
- `path` or `uri` (string)
- `presence`: `checked_out` | `missing` | `external_ref` | `submodule`
- `kind`: `app` | `deploy` | `lib` | `data` | `unknown`
- `evidence` (string[])
- optional `hot_path` (bool)

ServiceRef = same schema when kind is app|deploy|lib|data.

## Milestone dual-write (MUST)

On these milestones — not every tool call — write **both**:

| Milestone | Chat (owner) | Disk |
|-----------|--------------|------|
| orient done / plan drafted | Plain: roots + estimate; ask confirm | STATUS pointer + RunEnvelope phase `plan_drafted`→`awaiting_confirm` |
| confirm | Plain: signed visible subset | `CONFIRM.json` via `write_confirm.sh`; RunEnvelope progress |
| stop / stale_confirm | Plain STOP + next step | STATUS STOP card + `handoff` (§8); **no** `VIBAGE-ISSUE-*` |

Rules:

- Chat = plain language only. **Never** paste RunEnvelope JSON / hashes / internal fields to the owner.
- Disk = `docs/vibage/STATUS.md` + `RUNS/<run_id>.json` (+ SCAN_PLAN / CONFIRM as procedure says).
- No hub homework on the happy path.
- Mid-fail / abort: STOP + handoff only — do **not** write dual reports (`VIBAGE-ISSUE-OWNER.md` / `VIBAGE-ISSUE-LOCATE.md`).
- See `$PKG_ROOT/references/hub/STATUS.md` STOP template and `RunEnvelope.example.json`.

## Intake (first-class — before drafting)

Consider **before** writing SCAN_PLAN:

1. Ticket text in chat (if only a URL / empty body → say plainly “I cannot read the ticket body”; ask for a short symptom summary — S07; never invent ticket fields; never freeze waiting for Jira API).
2. Qualified map at `docs/vibage/maps/service_map.json` — if missing/underqualified and owner did **not** say `MAP_SKIP` → hand to **`vibage-pile-index`** first (S05).
3. Owner-stated repos / deps = **hot-path correction only** (F10). Never shrink the full child index to “the two they named.” Named-but-missing checkouts → `missing` / `external_ref` still listed.
4. Owner-stated DB / log / container → `external_ref` + `known_incompleteness` + later OWNER gaps (S06).

## Procedure

1. Require hub: if `docs/vibage/STATUS.md` missing → hand off to `vibage-init`.
2. Require map (F16): run `bash "$PKG_ROOT/scripts/verify-service-map.sh" "$WORKSPACE"` or hand to pile-index — unless owner explicit `MAP_SKIP` (record in `docs/vibage/DECISIONS.md`).
3. Discover roots (shallow) **and** merge map services:
   - One-level children with `.git` → `presence: checked_out`
   - Map service ids/paths feed `root_refs` / candidates for `planned_dig_ids`
   - Note missing/external units — do not invent checkouts
4. Propose hot path = **map × ticket keywords × owner corrections** (not random two repos).
5. Write `docs/vibage/SCAN_PLAN.md`:
   - Human summary: hot-path apps + external gaps + time estimate + “map covered N apps; digging this hot path, not all N unless you say so”
   - Fenced JSON `scan_plan_v1` with required keys: `schema_version`, `root_refs`, `budgets`, `hot_path_ids`, `known_incompleteness`, `planned_dig_ids`
   - Budgets (wide owner / large map):

| Dig targets N | max_wall_min | max_files |
|---------------|--------------|-----------|
| 1–2 | 25 | 40 |
| 3–6 | 40 | 80 |
| 7+ | 55 | 120 |

   - Budget ↑ does **not** authorize dropping owner externals or map services from incompleteness notes.
   - `known_incompleteness` is required (never empty string without meaning)
6. Update RUNS + STATUS (**orient done** milestone dual-write):
   - phase `plan_drafted` then `awaiting_confirm`
   - Do **not** enter `analyzing`
7. **Stop** and ask plain-language confirm. List dig targets + DB/log/container gaps. Do not dig. No jargon (no SCAN_PLAN/RootRef/hash in owner sentences).
8. On user confirm (chat OK is only a trigger) — **confirm** milestone dual-write:
   - Run `"$PKG_ROOT/scripts/write_confirm.sh" "$WORKSPACE"`
   - Hand off to `vibage-issue-locate` (locate runs assert_gate + map check)
9. On reject/change plan (S13): edit SCAN_PLAN; clear or overwrite CONFIRM only after new confirm; hash mismatch must block dig.
10. Stale (S14): if plan changed under an old CONFIRM → treat as `stale_confirm`; clear CONFIRM → re-orient (no `--force` required). Dual-write STOP + handoff; no dual reports.

## Hard stops

Also obey `$PKG_ROOT/references/hard-stops.md`.

- No deep dig, no dual reports, no nested investigators.
- Mid-fail / abort / stale: never write `VIBAGE-ISSUE-*` (STOP + handoff only).
- No silent `--force` on install.
- Empty parent (S1): stay at awaiting_confirm; do not invent roots to dig.
- Never dump RunEnvelope JSON to chat.
