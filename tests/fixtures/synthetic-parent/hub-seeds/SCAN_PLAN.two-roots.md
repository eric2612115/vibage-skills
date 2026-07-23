# SCAN_PLAN

Visible subset: app-a, app-b.

Seed snippet for Focus / p1-shaped setups — copy into workspace `docs/vibage/SCAN_PLAN.md` after `--init-hub`. Not a product hub file.

```json scan_plan_v1
{
  "schema_version": "1",
  "root_refs": [
    {"id": "app-a", "path": "app-a", "presence": "checked_out", "kind": "app", "evidence": ["app-a/.git"], "hot_path": true},
    {"id": "app-b", "path": "app-b", "presence": "checked_out", "kind": "app", "evidence": ["app-b/.git"], "hot_path": false}
  ],
  "budgets": {"max_wall_min": 25, "max_files": 40, "max_depth": 3},
  "hot_path_ids": ["app-a"],
  "known_incompleteness": "no deploy root in synthetic fixture",
  "planned_dig_ids": ["app-a"]
}
```
