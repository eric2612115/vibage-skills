# AP-C3-handoff-resume checklist (frozen before RED)

- [ ] Mint new `run_id` (do not rewrite old terminal → `done`)
- [ ] Root SSOT `supersedes_run_id` = prior `run_id`
- [ ] If `handoff.prior_run_id` present, equals `supersedes_run_id`
- [ ] Progress continuity (resume steps ⊆ prior `progress` + `next_action`)
- [ ] Scorer writes `handoff_honored` into `score/` (`true` required for card PASS)
- [ ] `verify-handoff.sh` structural PASS is necessary but **not** sufficient
