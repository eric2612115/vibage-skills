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

## STOP（中斷卡 — 僅在 failed|aborted|stale_confirm 時填）

| 欄位 | 內容 |
|------|------|
| 為何停 | <!-- stop_reason --> |
| 停在哪 | <!-- phase / progress cursor --> |
| 已做完 | <!-- progress.steps_done / dig_ids_done --> |
| 卡住 | <!-- blockers --> |
| 下一步 | <!-- next_action.summary + steps --> |
| 可沿用 | <!-- artifacts_ok → reuse --> |
| 不可假裝做完 | <!-- known_incompleteness — mid-fail: no dual reports --> |

### 填寫規則

- Mid-fail / abort：寫 STOP + `RUNS/<run_id>.json` `handoff`；**不要**寫 `VIBAGE-ISSUE-*`。
- Terminal-then-mint：新 `run_id` 必須設 root `supersedes_run_id`（SSOT）；`handoff.prior_run_id` 可選鏡像，若有必須相等。
- Happy path：不把 hub 作業丟給 owner；chat 用白話進度。
