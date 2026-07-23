# Survey matrix (research-survey-review)

**Default SKIP.** MUST iff one of:

1. Unknown deploy topology that would change hypotheses
2. Critical RootRef `presence` is `missing` or `external_ref` on SCAN_PLAN hot path (`hot_path_ids`)
3. Owner explicitly asks for prior art
4. Fresh nested reviewer escalates

Rules:

- Session = `run_id`; ≤1 short survey; optional second only on reviewer escalate
- Timing: after CONFIRM, after first hypotheses — not a 30-question intake
- Cache fingerprint (same hub + plan/symptom) → SKIP
- User says "skip web" → SKIP
