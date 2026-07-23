# AP-C4-issue-fix

| Field | Value |
|-------|-------|
| **card_id** | `AP-C4-issue-fix` |
| **short name** | `issue-fix` |
| **set claim id** | `B-path agent-proven set` (not this-wave required-set) |
| **SSOT** | SAT-agent-pressure §5.2 / §6.1 / §8 |

## Setup

1. Copy `tests/fixtures/synthetic-parent/` into an isolated parent workspace; `scripts/install.sh --init-hub=<workspace>` (isolated HOME).
2. Complete locate path so dual reports exist (`VIBAGE-ISSUE-OWNER.md` + `VIBAGE-ISSUE-LOCATE.md`) — may seed from GREEN of a locate card or fixture recipe.
3. Seed `docs/vibage/OWNER_POLICY.json` with `fix_preference=YES`.

## Prompt (agent-facing)

Enter `vibage-issue-fix` with scoped unlock after locate reports; prefer branch/PR; no silent push.

## RED / GREEN expect

- **RED (no Vibage skill):** Observable expected-failure morphology — see `oracle.md` / SAT §8 AP-C4 slice (not crash/empty).
- **GREEN (with skill):** Valid unlock + `verify-issue-fix-unlock.sh` PASS; edits ⊆ `allowed_paths` — see `oracle.md` / checklist.

## Forbidden

- SaaS / register CTA
- Rewriting locate DONE falsely
- Using `verify-handoff.sh` as fix proof
- Calling this card “this-wave required-set”
