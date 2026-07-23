# AP-C1-happy

| Field | Value |
|-------|-------|
| **card_id** | `AP-C1-happy` |
| **short name** | `happy` |
| **SSOT** | SAT-agent-pressure §6.4 |

## Setup

1. Copy `tests/fixtures/synthetic-parent/` into an isolated parent workspace (two roots + fake `.git` dirs).
2. `scripts/install.sh --init-hub=<workspace>` (isolated HOME).
3. Seed valid `SCAN_PLAN` with `root_refs` for `app-a` / `app-b` and `planned_dig_ids: ["app-a"]` (mirror `tests/test_p1_smoke.sh` / `hub-seeds/SCAN_PLAN.two-roots.md`).
4. `scripts/write_confirm.sh` so `assert_gate.sh` can green.

## Prompt (agent-facing)

One-glance symptom: locate closed loop on synthetic parent — dig `planned_dig_ids` including `app-a`. Produce dual reports and an honest locate RunEnvelope.

## RED / GREEN expect

- **RED (no Vibage skill):** Observable expected-failure morphology — see `oracle.md` / SAT §6.4 (not crash/empty).
- **GREEN (with skill):** Gate OK → dig; dual hard-cut; scripts + beyond-script OWNER — SAT §6.4 / §7 C1.

## Forbidden

- issue-fix / 架構檢視 / SaaS / register CTA
- Digging inside package product hub; dumping evidence into product `docs/vibage/`
