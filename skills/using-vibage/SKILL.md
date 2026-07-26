---
name: using-vibage
description: >-
  Use for in-scope Vibage conversations only: install Vibage / Install Vibage,
  NEW-CHAT/bootstrap, cross-repo locate on a parent, or explicit
  orient/CONFIRM/locate/pile-index/full-sweep. Not for vibage-skills package work,
  single-repo named-file tasks, or research/review/Q&A/plan with no dig.
  When unclear, ask — do not silently pick. Must run before dig when in scope.
  Do not paste nested locate procedure here. See references/routing-scope.md.
---

<EXTREMELY-IMPORTANT>
Routing scope first (`references/routing-scope.md`). Out of scope → one-line
disclosure and proceed without init/orient/locate continuum.
In scope only: if the owner asks install, parent workspace routing, or
locate/where a problem lives — invoke this skill before improvising shell or dig.
Never claim install success without PROJECT_ENTRY_OK on the PARENT workspace.
Do not silently pick in-scope vs out-of-scope.
</EXTREMELY-IMPORTANT>

# Using Vibage

Thin router only. **Parent project entry** (`.cursor/rules/vibage.mdc` / `CLAUDE.md` / `AGENTS.md`) is the routing table SSOT. This skill does **not** invent a second state machine.

## Routing scope (before continuum / S08)

**Vibage conversation (in scope)** = install / NEW-CHAT-bootstrap / cross-repo locate / explicit orient·CONFIRM·locate·pile-index·full-sweep.

**Out of scope** examples: work inside **vibage-skills** `PKG_ROOT`; owner named file/repo without cross-repo locate; research/review/Q&A/plan with no dig. Gold example: workspace=`vibage-skills`, edit lab/tests/adapters → skip init even if parent lacks hub STATUS.

When out of scope: one line, then do the task. When unclear: ask. **Do not silently** pick either side.

Full text: `$PKG_ROOT/references/routing-scope.md`.

## Looping review

Plans and guarded-path edits → Plan/Impl looping review until freeze. Qualified path = `docs/evidence/reviews/<diff_id>.md` (any host). Not Cursor-Task-only. See `$PKG_ROOT/references/looping-review.md`. `verify-review-record.sh`: exit 0 ≠ `REVIEW_RECORD_OK`.

**Plan loop ∉ plan todos:** freeze the plan **before** Build. Do not put `plan-loop-converge` (or “run 3 plan reviews”) inside the implementation todo list of the same plan.

## Plain milestones (F11 — owner chat)

Say these in owner language (no jargon):

| Done | Means | Not yet |
|------|-------|---------|
| Entry OK | Parent routers on disk (`PROJECT_ENTRY_OK`) | Hub / graph / dig |
| Hub ready | Checklist folder `docs/vibage/` exists | Graph / dig |
| Graph floor | Structural index (`GRAPH_FLOOR_OK`; `PILE_INDEX_OK` = wrapper echo) | Matrix / dig |
| Matrix sweep | Env×branch cells terminal; full-sweep only if `MATRIX_SWEEP_SUBSTANTIVE_OK` | Dig |
| Scene brief | When a scene is set: `SCENE_BRIEF_OK` (+ cover via `verify-scene-cover`) | Confirm / dig |
| Confirm | Owner OK on this ticket’s hot path | Dig reports |

Optional dimension-fill (`DIMENSION_FILL_*`; legacy `MAP_DEEPEN_OK` brand retired) — never Gate A “understood” / never “ready after install alone.”

## Gate A slogans (narrative honesty — ≠ dig auth)

| Claim language | Requires |
|----------------|----------|
| Floor / qualified map narrative | `UNDERSTANDING_ROLLUP_OK` (matrix not required) |
| matrix-terminal-state／no-missed-scan | `ENV_BRANCH_MATRIX_OK` |
| full-environment full-branch full-sweep | **`MATRIX_SWEEP_SUBSTANTIVE_OK` only** |
| multi-domain scene cover | `SCENE_BRIEF_OK` + `verify-scene-cover.sh` exit 0 |

Gate A ≠ Gate B (orient → CONFIRM → `assert_gate` → dig).  
`PILE_INDEX_OK` / `DIMENSION_FILL_*` (retired `MAP_DEEPEN_OK`) must **not** be narrated as full-understanding or dig-ready by themselves.

## Install phrase / continuum (C′)

**Only when in scope.** Trigger examples: `Install Vibage` · `Please install Vibage` · Vibage intent on a parent with missing entry.

**Authoritative continuum:**

`PROJECT_ENTRY_OK` → hub → `GRAPH_FLOOR_OK` → matrix sweep → **freshness gate** → **env-vacancy gate** → **optional deferred dimension fill** → ticket **or** scene switch → **`SCENE_BRIEF_OK` when scene set** → orient → CONFIRM → locate.

**Freshness (W1 — HARD_MOTHER / SOFT_CHILD):**

- Mother: `bash "$PKG_ROOT/scripts/verify-freshness.sh" "$PARENT"` (or `freshness-check.sh --mode=mother`).
- Continuum / hub-ready / full-sweep / dig-ready slogans require stdout **`FRESHNESS_OK`** **or** (`FRESHNESS_WAIVED` + `STALE_DISCLOSED`).
- **Forbidden:** treating exit code 0 as `FRESHNESS_OK` (waived-stale also exits 0).
- Hard-fail stdout: `STALE_BLOCKS_MOTHER count=<n>` — do not claim continuum ready; may still run refresh / graph-floor / matrix sweep.
- Child: after commit/push emit `VIBAGE_FRESHNESS_ASK: Mother hub may be stale for this repo. Update docs/vibage map/matrix/progress now? [yes/no]`. yes → `freshness-refresh-repo.sh`; no → `freshness-mark.sh --refuse`. Refusal cannot stay silent (`VIBAGE_FRESHNESS_ESCALATE` at refuse_count≥3).

**Env vacancy (W2):**

- Mother: `bash "$PKG_ROOT/scripts/verify-env-vacancy.sh" "$PARENT"` after matrix fill / session start.
- Tokens (exactly one): `ENV_VACANCY_CLEAR` | `ENV_VACANCY_ASK count=<n>` | `ENV_VACANCY_ANSWERED count=<n>` | `ENV_VACANCY_BLOCKED`.
- **ANSWERED ≠ CLEAR ≠ full-sweep.** Exit 0 on CLEAR/ANSWERED still requires token parse; ASK/BLOCKED exit ≠ 0.
- Unanswered missing → emit `VIBAGE_ENV_VACANCY_ASK` and record skip|point|classify via `env-vacancy-answer.sh` (point-pending stays ASK until `env-vacancy-apply-point.sh`).
- skip/classify/binary `env_vacancy_waiver` **never** grant `MATRIX_SWEEP_SUBSTANTIVE_OK`.

Agent **must** (owner: do not type bash):

1. Resolve `PKG_ROOT`.
2. If workspace looks like a **child** repo (parent missing entry, skills global only) → explain honestly; **do not** install rules into the child; ask to open the **parent** folder (S03).
3. `bash "$PKG_ROOT/scripts/install.sh"`
4. `bash "$PKG_ROOT/scripts/install.sh" --with-project-rule="$PARENT"` — **required**, not optional. Refuses fake-green without it (S02).
5. `bash "$PKG_ROOT/scripts/verify-project-entry.sh" "$PARENT"` → must print `PROJECT_ENTRY_OK` (includes `alwaysApply: true` on Cursor mdc). **Do not** say “installed” until this passes.
6. `bash "$PKG_ROOT/scripts/verify-pins.sh"`; on fail use `DEPENDENCIES.md` recovery.
7. Plain explain (owner language):
   - init = “set up a small checklist folder here”
   - graph / pile-index = “list every app folder and how they seem linked — not read every file”
   - matrix = “check env/branch evidence cells (full-sweep only when substantive OK)”
   - orient = “for this ticket, which hot path on the map?”
   - Explicitly: **not** SaaS signup; **not** Graphify-first; **not** embedding pipelines as memory
8. If hub missing → prefer one-shot glue when owner wants continuum fill:
   `bash "$PKG_ROOT/scripts/install.sh" --init-hub="$PARENT" --c-prime-fill="$PARENT"`
   (or `--init-hub` then hand to **`vibage-pile-index`** / `c-prime-fill`). `--c-prime-fill` default off.
9. Hand to **`vibage-pile-index`** → expect `GRAPH_FLOOR_OK` (script also echoes `PILE_INDEX_OK` for freeze compat). Continuum exit ≠ “intent only” (F15).
10. After graph floor / `PILE_INDEX_OK`: nameplate only; **cost/deepen ask** (`ticket paste = skip deepen`; optional **`vibage-map-deepen`** / dimension-fill only if owner says yes). Then matrix path (`c-prime-fill` prints `ENV_BRANCH_MATRIX_OK` **or** `MATRIX_INCOMPLETE`, and `MATRIX_SWEEP_SUBSTANTIVE_OK` only when full-sweep). May accept ticket with honest incomplete disclosure; **never** claim full-sweep without `MATRIX_SWEEP_SUBSTANTIVE_OK`. Dimension fill stays optional/deferred unless owner yes. Success to CONFIRM-ready ≠ full-sweep.
11. Ticket / pain **or** scene switch: if scene set → `scene-brief` + expect `SCENE_BRIEF_OK`; stereoscopic cover via `verify-scene-cover.sh` (independent of matrix).
12. Hand to **`vibage-orient`** → CONFIRM → **`vibage-issue-locate`**. **No dig / no dual reports** until CONFIRM. Optional `DIMENSION_FILL_*` / retired `MAP_DEEPEN_OK` ≠ CONFIRM ≠ dig-all ≠ Gate A understood.

Canonical paste: `prompts/SAY-INSTALL-VIBAGE.md`.  
Re-run: `bash tests/test_install_phrase_e2e.sh` → `INSTALL_PHRASE_E2E_OK`.

## On session start / unclear intent (S08)

0. **Routing scope gate** — if out of scope (e.g. vibage-skills package work): one-line disclosure; **stop continuum**; do not run steps 3–4 init/orient/locate. If unclear: ask; **do not silently** pick.
1. Resolve `PKG_ROOT`; verify-pins (agent).
2. Read package `STATUS.md`.
3. If hub present (`docs/vibage/STATUS.md`): run mother freshness check; report **`stale_count` + incomplete matrix** (stderr `stale_count=` / `incomplete_matrix=`); show any `VIBAGE_FRESHNESS_ESCALATE` lines; **do not** auto full rewrite. Continuum slogans need `FRESHNESS_OK` or waived+disclosed (exit 0 ≠ `FRESHNESS_OK`).
4. **In scope only** — follow **parent** routing (mdc/CLAUDE/AGENTS — hooks may drop; alwaysApply mdc is reliable):
   - No hub → **vibage-init**
   - Hub ready, no graph floor (and no owner `MAP_SKIP`) → **vibage-pile-index** → then matrix sweep (`c-prime-fill` path)
   - Scene set / switch → scene-brief → `SCENE_BRIEF_OK`; multi-domain scene cover also needs `verify-scene-cover.sh` exit 0
   - Map/graph ready, no valid CONFIRM → **vibage-orient** (only if freshness allows or stale disclosed)
   - CONFIRM OK → **vibage-issue-locate**
5. Dual-STATUS: package `STATUS.md` ≠ hub `docs/vibage/STATUS.md`.
6. Thin entry — no nested locate paste; no register CTA.

## Lifecycle

`PROJECT_ENTRY_OK → hub → GRAPH_FLOOR_OK → matrix sweep → freshness (exit 0 ≠ FRESHNESS_OK) → env-vacancy (ANSWERED ≠ CLEAR ≠ full-sweep) → (optional deferred dimension fill) → ticket or scene → SCENE_BRIEF_OK when scene set → orient → CONFIRM → locate → finish`

## Finishing (required after locate success)

Deliverable `verify-report` token lint (Held + Token evidence) ≠ chat-level honesty; ≠ replace C′ live panel.

Owner-language only (no soft CTA / no register / no pairing / no API-key / no Architecture Pass upsell):

1. Optional localhost preview — fail-soft  
2. Handoff / STOP if mid-fail  
3. Stop — local delivery complete  
4. Optional issue-fix / architecture review **only if owner asks**

### Cost / deepen talk (any time)

After `PILE_INDEX_OK`: say nameplate index; **cost/deepen ask**; **ticket paste = skip deepen** (implicit no to optional `vibage-map-deepen` / dimension-fill).  
Stay **local**: skip optional deepen/dimension fill, thin graph + hot path, shrink `planned_dig_ids`, `Mode: degraded`.  
Do **not** push register / cloud / “Architecture Pass is cheaper.” SaaS stays blank in package `STATUS.md`.

## Maps / extending

- Map context for agents: `docs/maps/AI-FIRST.md`
- Extending the pack: `docs/EXTENDING.md`
- C′ freeze-lift: `docs/superpowers/specs/2026-07-25-vibage-c-prime-freeze-lift.md`

## Hard stops

Obey `$PKG_ROOT/references/hard-stops.md`.
