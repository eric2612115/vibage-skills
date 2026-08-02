# WORK_CONTINUE (hub continue contract)

<!--
Seed / package template. init_hub copies this file.
MUST contain FILL_AFTER_LOCATE markers and phase: blocked so
verify-work-continue.sh FAILS until locate finishing overwrites with a live contract.

Path resolution: paths are relative to the parent hub workspace root
(the directory that contains docs/vibage/). Prefer hub-relative over machine-absolute.
-->

## MUST-NOT

- ≠ CONFIRM / ≠ assert_gate / ≠ dig authorization
- ≠ full-sweep without tokens / ≠ full-understanding / ≠ system-understood
- ≠ second locate report (pointers + bookmarks only)
- New ticket → re-orient; do not treat this file as dig auth

## Fields

work_root: FILL_AFTER_LOCATE
run_id: FILL_AFTER_LOCATE
dual_report_uris:
  - FILL_AFTER_LOCATE/VIBAGE-ISSUE-OWNER.md
  - FILL_AFTER_LOCATE/VIBAGE-ISSUE-LOCATE.md
inherited_finding_ids:
  - FILL_AFTER_LOCATE | FILL_AFTER_LOCATE | FILL_AFTER_LOCATE
next_step: FILL_AFTER_LOCATE
phase: blocked
side_quest: none
forbidden: |
  ≠ full-understanding; ≠ full-sweep without tokens; ≠ CONFIRM; ≠ assert_gate; ≠ dig auth
updated_at: FILL_AFTER_LOCATE
