# Vibage Hub STATUS

schema_version: 1
hub_ready: true
focus_run_id: ""
focus_pipeline_id: "locate"
phase: installed
notes: "OS pointer only — not global done. Update focus_run_id when a run is active."

<!--
STOP card = pointer + prose. No dual FSM.
RunEnvelope.handoff is machine SSOT; this card is owner-facing.
Keys (English): stop_reason / where / steps_done / blockers / next_action /
artifacts_ok / known_incompleteness
Chat: plain language only — never paste RunEnvelope JSON.
-->

## STOP (interrupt card — fill only on failed|aborted|stale_confirm)

| Field | Content |
|------|------|
| Why stopped | <!-- stop_reason --> |
| Where | <!-- phase / progress cursor --> |
| Done so far | <!-- progress.steps_done / dig_ids_done --> |
| Blocked on | <!-- blockers --> |
| Next | <!-- next_action.summary + steps --> |
| Reusable | <!-- artifacts_ok → reuse --> |
| Do not fake done | <!-- known_incompleteness — mid-fail: no dual reports --> |

### Fill rules

- Mid-fail / abort: write STOP + `RUNS/<run_id>.json` `handoff`; **do not** write `VIBAGE-ISSUE-*`.
- Terminal-then-mint: new `run_id` must set root `supersedes_run_id` (SSOT); `handoff.prior_run_id` is optional mirror and must match if present.
- Happy path: do not dump hub chores on the owner; chat uses plain-language progress.
