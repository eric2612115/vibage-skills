# Round 3 lab status (host only · LAB_NO_DELETE)

Not Tier-0. Staging under `/tmp/vibage-lab/` when present — owner cleans `/tmp`.

## Authoritative vs pre-generator

| File | Status |
|------|--------|
| `artifacts/ROUND3-20260725T211958Z-SUMMARY.json` | **pre-generator / non-authoritative** — do not treat `live_untouched` / dual counts as dig-after proof |
| `artifacts/ROUND3-DIG-TABLE.md` | **pre-generator / non-authoritative** — hand-era table; ignore `live_untouched: True` |
| Future `ROUND3-*-SUMMARY.json` / DIG-TABLE from `summarize-round3.sh` / `finalize-round3.sh` | Script-derived; see field honesty in README |

## Historical observe (20260725T211958Z run — dispatch era)

| Metric | Then-observed (not script-authoritative) |
|--------|------------------------------------------|
| Prepare | 32/32 ok; SKIP empty mothers AI-Project / AI_Game ×4 |
| DIG_STATUS DONE | 24 (agent sessions) |
| Dual report files | claimed present in hand SUMMARY |
| Live untouched | **prepare-only** check existed; **no dig-after after snap** in that era |

## Current harness

Flow: `run-round3-prepare.sh` → L1 digs → **`finalize-round3.sh`** (after snap + summarize).

- Write gate: `scripts/lab/assert-write-gate.sh`
- Static no-delete: `scripts/lab/lab-no-delete-check.sh` → `lab_no_delete_static_scan`
- Summary: `scripts/lab/summarize-round3.sh`
- Finalize: `scripts/lab/finalize-round3.sh`

## Honesty

`LAB_L1_DONE` ≠ live mutated ≠ `TIER0_OK` ≠ full-sweep ≠ letter B.
Filesystem SUMMARY ≠ true dig proof.
