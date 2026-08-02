# WORK_CONTINUE fixture (dual paths that will not exist)

## Fields

work_root: apps/demo-child
run_id: run_fixture_nodual_001
dual_report_uris:
  - DOES-NOT-EXIST-OWNER.md
  - DOES-NOT-EXIST-LOCATE.md
inherited_finding_ids:
  - f1 | apps/demo-child/src/main.ts | claim
next_step: Implement fix
phase: implement_in_work_root
side_quest: none
forbidden: |
  ≠ full-understanding; ≠ full-sweep without tokens; ≠ CONFIRM; ≠ assert_gate; ≠ dig auth
updated_at: 2026-08-02T00:00:00Z
