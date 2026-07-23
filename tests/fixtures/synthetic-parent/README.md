# Synthetic parent — Focus / locate closed-loop fixture

Tracked fixture for **copy into an isolated workspace**. Never dig inside the package tree’s product hub (`docs/vibage/` on this repo). Agents and smoke copy this tree, then init a fresh hub under the copy.

## Copy recipe

1. **Copy tree** into a temp parent workspace with two roots:
   - `app-a/` and `app-b/` (include their `src/` diggable surface).
   - Create fake git dirs as smoke does: `mkdir -p <ws>/app-a/.git <ws>/app-b/.git`.
2. **Init hub** (isolated `HOME` recommended):
   - `scripts/install.sh --init-hub=<workspace>`
3. **Seed** `docs/vibage/SCAN_PLAN.md` with `root_refs` for both apps and `planned_dig_ids: ["app-a"]` (mirror `tests/test_p1_smoke.sh` plan shape). Optional snippets live under `hub-seeds/` (not product hub files).
4. **Happy path:** `scripts/write_confirm.sh <workspace> <owner>` then `scripts/assert_gate.sh <workspace>` → OK → dig `planned_dig_ids`.
5. **Gate-RED path:** omit CONFIRM **or** mutate plan after confirm (hash mismatch) — align `tests/test_assert_gate.sh` Case A/C.
6. **Card3 (handoff-resume):** seed a terminal RunEnvelope from `tests/fixtures/run_failed_handoff.json` shape into the workspace RUNS. Do **not** rewrite package fixtures in place during a run.

## Diggable surface (minimum)

| Path | Role |
|------|------|
| `app-a/README.md` | Purpose + entry hint |
| `app-a/src/app.py` | Tiny placeholder module |
| `app-a/src/__init__.py` | Package marker |
| `app-b/README.md` | Second root identity |
| `app-b/src/service.py` | Tiny placeholder |

Content is Focus-fixture only — no business secrets. Thick enough for Nested / Mode evidence on a synthetic dig.
