<!-- vibage:start -->
# Vibage (Claude Code entry)

Product SSOT lives in the vibage-skills package. Skills are linked under `~/.claude/skills/` and optionally `.claude/skills/`.
Package capability SSOT: package root `STATUS.md` (hub `docs/vibage/STATUS.md` is init/orient only).
Thin entry only — do not paste nested locate procedure.
Owner: do not type bash; agent runs install/verify/pins scripts. no register CTA.

## Routing scope (applies before rules 1–N)

Apply Skill routing / continuum **only** when in scope (install / NEW-CHAT-bootstrap / cross-repo locate / explicit orient·CONFIRM·locate·pile-index·掃透). Details: `$PKG_ROOT/references/routing-scope.md`.

**Out of scope** (one-line disclosure, then proceed — **do not** init/orient/locate): vibage-skills package work; owner named file/repo without cross-repo locate; research/review/Q&A/plan with no dig; established single work root.

When unclear: ask. **Do not silently** pick either side.

When **in scope** only: Session routing follows **using-vibage** (pointer skill). Parent routers remain SSOT — no second state machine.
If owner says **幫我裝 Vibage** / install Vibage → follow using-vibage § Install continuum:
`PROJECT_ENTRY_OK` → hub → `GRAPH_FLOOR_OK` (via **vibage-pile-index**) → matrix sweep → freshness → env-vacancy → optional deferred dimension fill → ticket or scene → `SCENE_BRIEF_OK` when scene set → orient → CONFIRM → locate.
Freshness: parse stdout tokens (`FRESHNESS_OK` or WAIVED+DISCLOSED); exit 0 ≠ `FRESHNESS_OK`. Session start: disclose stale_count + incomplete_matrix (+ escalate).
Env vacancy: ANSWERED ≠ CLEAR ≠ 掃透; exit 0 ≠ 掃透.
Do not claim installed without verify. Do not dig yet. Cursor hook files are **not** required for Claude success.
掃透 only with `MATRIX_SWEEP_SUBSTANTIVE_OK`. Scene cover via `verify-scene-cover`. `PILE_INDEX_OK` / `DIMENSION_FILL_*` (legacy `MAP_DEEPEN_OK` brand retired) ≠ full-understanding.
After `PILE_INDEX_OK` / `GRAPH_FLOOR_OK`: nameplate only; cost/deepen ask (ticket paste = skip deepen).

## Looping review (guarded paths / plans)

Writing a plan or changing guarded paths requires Plan/Impl **looping review** until freeze — see `$PKG_ROOT/references/looping-review.md`. **Plan loop finishes before Build** — do not put plan-loop todos inside the plan body. Qualified = formatted `docs/evidence/reviews/<diff_id>.md` (any host/chat/human/model). **Not** “must use Cursor Task × 3”. Model diversity is disclosure (`diversity: ok|waived`), not a host-tool hard gate. Verify: `verify-review-record.sh` (exit 0 ≠ `REVIEW_RECORD_OK`).

## Skill routing

1. No `docs/vibage/STATUS.md` → Read/follow **vibage-init**.
2. Hub ready, no graph floor / qualified map (unless MAP_SKIP) → **vibage-pile-index** (`GRAPH_FLOOR_OK`; then matrix sweep / `c-prime-fill`).
3. Scene set / switch → scene-brief → `SCENE_BRIEF_OK`; claiming 多領域立體場景切換 also requires `verify-scene-cover.sh` exit 0 (BRIEF alone ≠ cover).
4. Map/graph ready, no valid CONFIRM (= owner OK on the scan plan) → **vibage-orient** (stop until owner confirms).
5. CONFIRM OK → **vibage-issue-locate** (consume briefs/ledger; ignore deepen-as-auth; gate then dig ⊆ planned_dig_ids; legacy `vibage-locate` OK).
6. NEW-CHAT / install unclear → **vibage-bootstrap** or **vibage-init** (then using-vibage).
7. Optional (not required for locate DONE): **vibage-map-deepen** (deferred dimension path; ≠ Gate A), **vibage-issue-fix**, **vibage-arch-review**.

Read package `STATUS.md` first (capability SSOT) before expanding scope.
After locate DONE → finishing options in **using-vibage** (required).

Best-available on Claude: this always-on block (Cursor-only hook files are **not** required). See `references/host-best-session-entry.md`.

## PKG_ROOT

Prefer: `bash <vibage-skills>/scripts/resolve-pkg-root.sh`  
Fallback: realpath `~/.claude/skills/vibage-init` (then `vibage-issue-locate`) → dirname/dirname.

## Nested / browser

Use Claude Code Agent/subagents when available; else `Mode: degraded`. Preview is fail-soft — no register CTA.

## Hard stops

`$PKG_ROOT/references/hard-stops.md`
<!-- vibage:end -->
