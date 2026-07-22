# GapQuestion template

Write unanswered gaps after analysis (and optionally during orient as known_incompleteness). Machine fields:

```json
{
  "schema_version": "1",
  "id": "gap-001",
  "kind": "missing_repo|observability|owner|deploy|contract",
  "why_blocks_hot_path": "<string>",
  "owner_action": "<string>",
  "unanswered": true,
  "root_ref_id": "<optional RootRef.id>"
}
```

Owner-facing: one short bullet per gap in `WAR-ROOM-OWNER.md` without dumping JSON.
