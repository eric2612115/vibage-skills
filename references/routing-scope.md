# Routing scope (before Skill routing 1–N)

Always-on adapters carry a thin copy. This file is the expanded SSOT.

## When routing applies (in scope)

Apply parent Skill routing / continuum **only** when the task is one of:

1. Owner says install Vibage / `Install Vibage` / clear install or init intent
2. Owner pastes `NEW-CHAT` / asks bootstrap / unclear install on a **parent** workspace that should run Vibage entry
3. Locating an unfamiliar problem across multiple repos in a parent (locate intent)
4. Owner explicitly asks for orient / CONFIRM / locate / pile-index / graph floor / matrix full-sweep narrative

## When routing does NOT apply (out of scope)

Say so in **one line**, then proceed with the task. **Do not** run vibage-init / pile-index / orient / locate / continuum slogans.

1. **vibage-skills package work:** workspace or git root is `PKG_ROOT`, or the task paths are under the package tree (`tests/`, `scripts/`, `adapters/`, `skills/`, `docs/`, `references/`, `labs/`). Missing parent hub `docs/vibage/STATUS.md` on MindOwnBuz (or similar) **does not** force rule 1 when the work is this package.
2. Owner already named the file or single repo, and did **not** ask for cross-repo locate.
3. Research / review / Q&A / writing a plan that produces **no dig** and claims no continuum milestones.
4. Session work root is already established; task is implement / fix tests inside that root.

### Continue-memory carve-out (`WORK_CONTINUE`)

If `docs/vibage/WORK_CONTINUE.md` exists on the parent hub, `scripts/verify-work-continue.sh` prints `WORK_CONTINUE_VERIFY_OK`, and the task continues that file's `work_root`:

- One-line continuum out-of-scope disclosure (skip pile-index / orient / CONFIRM for that continue task)
- **Must** read `WORK_CONTINUE` before code edits
- **Still** run/parse freshness (`FRESHNESS_OK` or `FRESHNESS_WAIVED` + `STALE_DISCLOSED`) and disclose stale_count / incomplete matrix (env-vacancy as today)
- Side quest: bookmark in `side_quest` before leaving `work_root` (read-only; not dig auth)

Gold example: hub has verified `WORK_CONTINUE` with `work_root: apps/foo`, owner says continue the fix → read contract; do not re-run pile-index; disclose freshness.

### Gold example (CC live failure)

Workspace = `vibage-skills`. Task = review lab harness / add verify script / edit adapters.  
→ **Out of scope.** One line: `Routing scope: vibage-skills package work — skip init/orient/locate.`  
Do **not** run vibage-init because parent MindOwnBuz lacks hub STATUS.

## Unclear

Ask once. **Do not silently** pick in-scope or out-of-scope. Do not invent continuum steps.

Example ask: `Is this a Vibage install/locate job on the parent, or package/local work I should do without init/orient/locate?`

## Honesty

Scope text ≠ perfect compliance. Mechanical gates cover guarded path diffs only (`verify-review-record.sh`).
