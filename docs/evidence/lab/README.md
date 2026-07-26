# Lab harness (isolated multi-parent · host only)

Script continuum + depth-C locate prep against **copies** of allowlisted parents.
Never mutates live trees. **Never deletes** staging — owner cleans `/tmp` later.
Not Tier-0.

## Allowlist (named; no HOME scan)

- `/Users/eric.fang/Projects/AI-Project`
- `/Users/eric.fang/Projects/AI_Game`
- `/Users/eric.fang/Projects/LangSight`
- `/Users/eric.fang/Projects/OmRate_Phalanx`
- `/Users/eric.fang/Projects/Termmax`
- `/Users/eric.fang/Projects/Trading`
- `/Users/eric.fang/MindOwnBuz`
- `/Users/eric.fang/Rust`

## Copy excludes

See `scripts/lab/rsync-excludes.txt` (`.venv`, `node_modules`, Trading `_reference` /
data / `.worktrees`, etc.). rsync uses `--safe-links`.

## Commands

```bash
# smoke (leaves artifacts under /tmp/vibage-lab/smoke-*)
bash tests/test_lab_harness_smoke.sh

# one mother (staging kept)
bash scripts/lab/run-trial.sh --source=/Users/eric.fang/MindOwnBuz

# Round 1 then Round 2 script matrix
bash scripts/lab/run-round12.sh

# Round 3 prepare → L1 digs (Cursor) → finalize (script SUMMARY + after live snap)
bash scripts/lab/run-round3-prepare.sh
bash scripts/lab/run-round3-prepare.sh --mothers=MindOwnBuz,LangSight   # subset
# … dispatch L1 agents from prompts/ …
bash scripts/lab/finalize-round3.sh --base=/tmp/vibage-lab/<run>-round3 \
  --before=/tmp/vibage-lab/live-snapshots/before-<run>.json

# Script-derived SUMMARY only (filesystem scan ≠ dig quality proof)
bash scripts/lab/summarize-round3.sh /tmp/vibage-lab/<run>-round3 \
  --before=... --after=...
```

Docker mode is **rejected** (`LAB_NO_DELETE`). L1 agents must not delete; owner cleans `/tmp`.

## Evidence honesty

| Artifact | Authority |
|----------|-----------|
| `artifacts/ROUND3-20260725T211958Z-SUMMARY.json` | **pre-generator / non-authoritative** (hand era) |
| `artifacts/ROUND3-DIG-TABLE.md` | **pre-generator / non-authoritative** (hand era; superseded by finalize DIG-TABLE) |
| SUMMARY / DIG-TABLE from `summarize-round3.sh` / `finalize-round3.sh` | Script-derived filesystem counts + optional before/after live check |
| Prepare `assert-live-untouched --check` | **prepare_only** — not dig-after proof |

Field meanings:

- `dig_status_counts` / `dual_report_files_present` = files/tokens on disk (**≠** true dig quality)
- `trials_order` = `lexicographic_by_results_dirname` (**≠** dig execution order)
- `lab_no_delete_static_scan` = static scan of `scripts/lab/*.sh` (**≠** runtime zero-delete)
- `live_untouched` = true only when before+after snaps equal (finalize also forces false if `--check` fails)

## Honesty

`LAB_CASE_OK` ≠ live mutated ≠ `TIER0_OK` ≠ full-sweep ≠ letter B.
