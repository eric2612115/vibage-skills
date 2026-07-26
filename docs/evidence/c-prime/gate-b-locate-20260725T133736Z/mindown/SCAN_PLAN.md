# SCAN_PLAN — Gate B pressure (degraded)

```json scan_plan_v1
{
  "schema_version": "1",
  "root_refs": [
    {"id": "SelfAutoBuz", "path": "SelfAutoBuz", "presence": "checked_out", "kind": "app", "evidence": ["SelfAutoBuz/.git"], "hot_path": true},
    {"id": "vibage-app", "path": "vibage-app", "presence": "checked_out", "kind": "app", "evidence": ["vibage-app/.git"], "hot_path": false},
    {"id": "vibage-web", "path": "vibage-web", "presence": "checked_out", "kind": "app", "evidence": ["vibage-web/.git"], "hot_path": false}
  ],
  "budgets": {"max_wall_min": 25, "max_files": 40, "max_depth": 3},
  "hot_path_ids": ["SelfAutoBuz"],
  "known_incompleteness": "Gate-B live evidence; matrix may be incomplete; dig SelfAutoBuz only; ≠ full-sweep",
  "planned_dig_ids": ["SelfAutoBuz"]
}
```
