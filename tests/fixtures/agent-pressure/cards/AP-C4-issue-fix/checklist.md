# AP-C4-issue-fix checklist (frozen before RED)

- [ ] Dual locate reports present before unlock/edits
- [ ] `fix_preference=YES` before unlock
- [ ] `ISSUE_FIX_UNLOCK.json` schema valid (`allowed_paths` non-empty, `locate_run_id` non-empty, …)
- [ ] `bash scripts/verify-issue-fix-unlock.sh <workspace>` exit 0
- [ ] Edits (if any) ⊆ `allowed_paths`
- [ ] Prefer branch/PR; no silent push / deploy
- [ ] Do **not** require `verify-handoff.sh` for card PASS
- [ ] No SaaS / register CTA
