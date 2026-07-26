# C′ Wave-1 — Sync / Freshness Design

**Date:** 2026-07-25  
**Status:** Design-FULL for W1 — **On-tree=YES** (`FRESHNESS_W1_OK`); phrase: `W1 freshness On-tree (HEAD+TTL subset) ≠ Sync contract DONE`  
**Roadmap:** `docs/superpowers/specs/2026-07-25-vibage-c-prime-next-waves-roadmap.md`  
**Parent §2.5:** `docs/superpowers/specs/2026-07-24-vibage-c-prime-graph-brief-ledger-design.md` §2.5  

**Phrase lock:** After implement: say only `W1 freshness On-tree (HEAD+TTL subset) ≠ Sync contract DONE`. Never “Sync On-tree” alone. W1 ≠ letter B ≠ Gate B.

### §2.5 trigger coverage (W1 vs deferred)

| §2.5 trigger | W1 | Deferred (W1b+) |
|--------------|----|-----------------|
| Child HEAD change → mark slice stale | YES | — |
| TTL / time freshness | YES (default 7d) | — |
| Invalidate dependent edges + refresh brief on HEAD change | NO | YES |
| New/removed branch or env config path | NO | YES |
| Compose / deploy / package manifest change | NO | YES |
| Scene registry edit | NO | YES |
| Ledger pointer missing / hash mismatch | NO | YES |
| Session start: report stale + incomplete; auto-continue incomplete sweep | Report YES; auto-continue NO | auto-continue YES |

Worktree dirty-bit optional later; not required in W1.

---

## 1. Goal

Mother-dir graph / matrix / ledger must not pretend to be fresh. Child repos stay developer-friendly (git not hard-blocked) but **must warn** and **must ask** whether to refresh the mother hub after push; refusal cannot stay silent forever.

## 2. Policies (frozen names — never call these A/B)

| Policy | When | Behavior |
|--------|------|----------|
| **HARD_MOTHER** | Dir contains `docs/vibage/STATUS.md` | Blocking stale without valid waiver → reject listed gates. |
| **SOFT_CHILD** | Sibling git under mother | Allow commit/push; required warn + ask; refuse keeps stale + disclose + escalate. |

Mother detection SSOT: **`docs/vibage/STATUS.md` exists** (not merely `docs/vibage/`).

### 2.1 HARD_MOTHER block surface

Hard block = script exit + skill/adapter obedience. **Not** git-hook-only. Parent often has no `.git`.

**Blocked when mother check is hard-fail** (see §6 exit table):

1. Claiming continuum / hub ready / understood / full-sweep without stale disclosure  
2. Orient presenting hot-path as authoritative without stale disclosure  
3. Any path that would print `FRESHNESS_OK`  
4. Narrating dig-ready / install→ready  

**Always allowed when stale (resweep exception):**

- `scripts/freshness-check.sh`  
- `scripts/freshness-mark.sh`  
- `scripts/freshness-refresh-repo.sh`  
- `scripts/graph-floor.sh`, `matrix-inventory.sh`, `matrix-sweep-cell.sh`, bounded wrappers  

Optional: parent `.git` hook on `docs/vibage/**` calls check — add-on only; missing hook ≠ bypass.

### 2.2 `freshness_skip_waiver`

SSOT: object in `docs/vibage/OWNER_POLICY.json` under key `freshness_skip_waiver`.

**Required:** `reason` (non-empty string), `at` (ISO UTC), `scope` (list of repo_id or `["*"]`), `review_by` (ISO UTC date).

**Invalid waiver** (treat as absent → hard-block if stale): missing fields, empty reason, `now > review_by`.

**Coverage rule:** Waiver is **valid for mother waive** only if structurally valid **and** `scope` is `["*"]` **or** `scope` covers **every** currently stale in-scope repo id. If any stale in-scope repo is outside `scope`, check is hard-fail (`STALE_BLOCKS_MOTHER` exit 1) for those uncovered repos (whole mother check fails).

**Never grants / never prints:** `FRESHNESS_OK`, `MATRIX_SWEEP_SUBSTANTIVE_OK`, dig-ready, matrix/rollup “fresh” slogans.

**Valid waiver + stale:** mother check exit **0**, print exactly:

```text
FRESHNESS_WAIVED
STALE_DISCLOSED count=<n>
```

Do **not** print `FRESHNESS_OK`. Skills may proceed past hard-block only with disclosure.

**Skill gate rule:** Continuum / claim gates MUST match **exact stdout tokens**. **Forbidden:** treating exit code 0 as `FRESHNESS_OK` (waived-stale is also exit 0).

Separate from `env_vacancy_waiver`.

### 2.3 SOFT_CHILD ask / refuse

Frozen ask (English for hooks; agent may translate for owner):

```text
VIBAGE_FRESHNESS_ASK: Mother hub may be stale for this repo. Update docs/vibage map/matrix/progress now? [yes/no]
```

- **yes** → `freshness-refresh-repo.sh <mother> <repo_id>`  
- **no** → `freshness-mark.sh --refuse <mother> <repo_id>` (increments `refuse_count`, keeps `stale=true`)

Frozen escalate when `refuse_count >= 3`:

```text
VIBAGE_FRESHNESS_ESCALATE: repo=<id> refused hub update N>=3; mother session must disclose before continuum slogans
```

## 3. Parent resolution (SSOT order)

1. `VIBAGE_PARENT` if set and has `docs/vibage/STATUS.md`  
2. Else walk ancestors from cwd for `docs/vibage/STATUS.md`  
3. Else: soft message `VIBAGE_PARENT_UNRESOLVED`; skip hub update ask; do not invent mother

## 4. Data: `docs/vibage/maps/freshness.json`

```json
{
  "schema_version": "1",
  "ttl_days": 7,
  "updated_at": "2026-07-25T00:00:00Z",
  "repos": {
    "svc-a": {
      "head": "<git rev-parse HEAD>",
      "scanned_at": "2026-07-25T00:00:00Z",
      "stale": false,
      "refuse_count": 0
    }
  }
}
```

- Default TTL 7 days; override `OWNER_POLICY.json` → `freshness_ttl_days` if present.  
- **In-scope repos:** ids from mother `service_map.json` `repos[].path` (or `repo_id`), excluding tooling excludes already applied by graph-floor.  
- **Missing `freshness.json`:** treat every in-scope repo as stale (mother hard-fail unless waived).  
- **Map repo missing from freshness.json:** stale.  
- **Freshness entry with no checkout:** ignore for HEAD compare; still TTL-stale if `scanned_at` old; do not crash check.

### Stale computation

`stale=true` if HEAD ≠ stored `head` OR age > ttl_days OR missing record.

### Mark rules (anti-greenwash)

`freshness-mark.sh --success` is **fail-closed**:

1. Read matrix; every cell with that `repo_id` must be terminal (`proven`|`failed`), not `unproven`.  
2. Else exit ≠ 0 and **do not** write `stale=false`.  
3. On success only: set `stale=false`, update `head`/`scanned_at`, reset `refuse_count`.  

`freshness-refresh-repo.sh` must not call `--success` if any step failed.  

**Forbidden:** mark `stale=false` after graph-floor alone; mark when cells missing/unproven.

## 5. Bounded refresh (W1 locked path)

Script: `scripts/freshness-refresh-repo.sh <mother> <repo_id>`

**Required steps:**

1. Resolve mother; verify `repo_id` in service_map (else run `graph-floor.sh` once, print `FULL_MOTHER_FLOOR_REFRESH`, then continue)  
2. For cells in `env_branch_matrix.json` with that `repo_id`: re-run inventory for mother **or** patch-inventory minimal — W1 **locked minimum:** run `matrix-inventory.sh` (mother-wide inventory OK) then sweep **only** that repo’s cells via `matrix-sweep-cell.sh`  
3. `freshness-mark.sh` that repo success path  

**Forbidden:** unannounced full `c-prime-fill.sh`.  

If operator intentionally runs full mother fill: must print `FULL_MOTHER_FILL_REFRESH` and may mark all repos that completed cells.

## 6. Scripts / tokens / exit codes

| Script | Role |
|--------|------|
| `freshness-check.sh --mode=mother\|child [--json]` | Compute stale set |
| `freshness-mark.sh` | `--success` / `--refuse` |
| `freshness-refresh-repo.sh` | Bounded refresh |
| `verify-freshness.sh` | Wrapper → mother mode; skills MUST parse tokens (exit 0 ≠ `FRESHNESS_OK`) |

### Mother exit / stdout contract

| Situation | Exit | Must print |
|-----------|------|------------|
| No in-scope stale | 0 | `FRESHNESS_OK` |
| In-scope stale, no valid waiver | 1 | `STALE_BLOCKS_MOTHER` (+ count) |
| In-scope stale, valid waiver | 0 | `FRESHNESS_WAIVED` and `STALE_DISCLOSED count=<n>` — **never** `FRESHNESS_OK` |

### Child exit / stdout

Always exit 0. If stale for this repo (or unresolved parent): `FRESHNESS_CHILD_WARN`. If escalate: also `VIBAGE_FRESHNESS_ESCALATE` line.

**Tokens:** `FRESHNESS_OK`, `STALE_BLOCKS_MOTHER`, `FRESHNESS_WAIVED`, `STALE_DISCLOSED`, `FRESHNESS_CHILD_WARN`, `FULL_MOTHER_FLOOR_REFRESH`, `FULL_MOTHER_FILL_REFRESH`.  

All ∉ Tier-0 / pack-health / required `test_c_prime_suite` path until W4 owner decision (freshness default excluded from thin Tier-0).

## 7. Skill / adapter surface

- Mother session start: run mother check; report stale_count + incomplete matrix; no auto full rewrite; if escalate lines present, show them.  
- Continuum slogans require `FRESHNESS_OK` **or** (`FRESHNESS_WAIVED` + disclosure).  
- Child post-commit/push: emit `VIBAGE_FRESHNESS_ASK`.  
- Optional install helper for soft hook templates only.

## 8. Testing (`tests/test_freshness_w1.sh` — not in suite glob / not Tier-0)

| Case | Expect |
|------|--------|
| Change child HEAD after success mark | mother → `STALE_BLOCKS_MOTHER` exit 1 |
| Same | child → `FRESHNESS_CHILD_WARN` exit 0 |
| TTL expired | stale without HEAD change |
| Valid waiver | exit 0, `FRESHNESS_WAIVED`+`STALE_DISCLOSED`, no `FRESHNESS_OK` |
| Expired / empty waiver | treated absent → hard-fail if stale |
| Missing freshness.json | hard-fail if map has repos |
| Refuse 3× | escalate line on mother check |
| Parent unresolved | soft skip ask |
| Mark after floor-only | must NOT clear stale (test) |
| Mark `--success` with zero cells for repo | exit ≠ 0; stale unchanged |
| Partial waiver scope (stale a,b; scope [a]) | mother exit 1 `STALE_BLOCKS_MOTHER` |
| Waiver ≠ substantive | substantive verify unchanged |
| Skill gate | document: exit 0 ≠ `FRESHNESS_OK` |

## 9. Out of scope

W2 vacancy product; dimension; letter B; Tier-0; full §2.5 remainder (W1b); real `.env`; silent full fill.

## 10. Freeze-lift note

**W1 freshness On-tree (HEAD+TTL subset) ≠ Sync contract DONE** — see freeze-lift + `docs/evidence/c-prime/FRESHNESS-W1-SUMMARY.md`.
