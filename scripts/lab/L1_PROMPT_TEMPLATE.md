# L1 mother-trial agent prompt (lab Round 3)

Copy this into each L1 subagent. Fill every `{{...}}` field. One agent = one staging.

## Identity

- `STAGING_PARENT={{STAGING_PARENT}}`  ← absolute path under `/tmp/vibage-lab/.../parent` only
- `MODEL={{MODEL}}` (`composer` or `grok`)
- `SLOT={{SLOT}}` (`a` or `b`)
- `MOTHER_NAME={{MOTHER_NAME}}`
- `PKG_ROOT={{PKG_ROOT}}`
- `RESULTS_DIR={{RESULTS_DIR}}`
- `MAX_DIG_IDS={{MAX_DIG_IDS}}` (Termmax → 2; others → 3)

## Hard bans

1. **Do not delete** any file or directory (`rm`, `rm -rf`, `docker rm`, trash, cleanup staging). Owner cleans `/tmp` later.
2. **Do not write** under live allowlist roots:
   - `/Users/eric.fang/Projects`
   - `/Users/eric.fang/MindOwnBuz`
   - `/Users/eric.fang/Rust`
3. Before any write, run:
   `bash $PKG_ROOT/scripts/lab/assert-write-gate.sh <path> --staging="$STAGING_PARENT"`
   Must print `LAB_WRITE_GATE_OK`.
4. All install / hub / CONFIRM / dig / reports must use `STAGING_PARENT` as workspace root / cwd.
5. Set `HOME={{FAKE_HOME}}` for any `install.sh` / skill link commands (already used by continuum if pre-run).
6. Do not share this staging with another agent. Do not read other slots' parents.
7. Do not claim 掃透 / letter B / SaaS / `TIER0_OK` from lab success.
8. If `planned_dig_ids` is empty → print `LAB_L1_SKIP_DIG empty_mother` and stop (still no deletes).

## Steps

1. Confirm `STAGING_PARENT` exists and starts with `/tmp/vibage-lab` (or `VIBAGE_LAB_ROOT`).
2. If continuum not yet green:  
   `bash $PKG_ROOT/scripts/lab/continuum.sh "$STAGING_PARENT" "$PKG_ROOT" "{{OUT_DIR}}"`
3. Ensure `docs/vibage/SCAN_PLAN.md` has `planned_dig_ids` with **≤ MAX_DIG_IDS** entries (edit only inside staging). Prefer small/hot repos.
4. Mint lab CONFIRM (orchestrator substitute — staging only):  
   `bash $PKG_ROOT/scripts/lab/mint-lab-confirm.sh "$STAGING_PARENT" "lab-{{MODEL}}-{{SLOT}}"`
5. `bash $PKG_ROOT/scripts/assert_gate.sh "$STAGING_PARENT"`
6. Run locate nested dig **only** ⊆ `planned_dig_ids` (L2 investigators/reviewers). Workspace = `STAGING_PARENT`.
7. Write dual reports under staging; run  
   `bash $PKG_ROOT/scripts/verify-report.sh` (paths as skill requires) / coverage-box verify as applicable.
8. Copy SCOREBOARD notes + report paths into `RESULTS_DIR` (create files; do not delete others).
9. Stop. Leave staging in place. Print `LAB_L1_DONE staging=... model=... slot=...`

## Done means

- `assert_gate` green on staging  
- dual reports present on staging  
- no writes to live mothers  
- no deletes anywhere  
