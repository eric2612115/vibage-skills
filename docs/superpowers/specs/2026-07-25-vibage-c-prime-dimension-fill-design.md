# C′ Wave-3a — Dimension Fill Design

**Date:** 2026-07-25  
**Status:** Design-FULL for W3a — **On-tree=YES** after P0–P2 (`DIMENSION_FILL_W3A_P2_OK`; `MAP_DEEPEN_OK` brand retired)  
**Roadmap:** `docs/superpowers/specs/2026-07-25-vibage-c-prime-next-waves-roadmap.md`  
**Parent:** `docs/superpowers/specs/2026-07-24-vibage-c-prime-graph-brief-ledger-design.md` (§1 workers, §2.1–2.4)  
**Prereq:** W2 env-vacancy On-tree (`ENV_VACANCY_W2_OK`) for **implement**; design may land now  

**Phrase locks:**

- Dimension fill ≠ full-sweep ≠ “understood” ≠ dig-ready ≠ letter B ≠ Gate B  
- `exit 0 ≠ DIMENSION_FILL_OK` (`PARTIAL` also exits 0 — skills **must** parse exact tokens)  
- `dimension_*` claims **never** satisfy `UNDERSTANDING_ROLLUP_OK` / floor rollup slices  
- Vacancy `ENV_VACANCY_ASK` anywhere in discovery set ⇒ forbid `DIMENSION_FILL_OK`  
- **Retire** `MAP_DEEPEN_OK` as understood brand; new scripts **never print it**; old verify **never emits it** after migrate  
- W1–W3 **MUST NOT** touch `scripts/test-tier0.sh` / pack-health  

---

## 1. Goal

Fill non-matrix understanding dimensions via **repo synthesizer → dimension searchers → ledger `dimension_*` claims**, so agents have evidence-backed notes without treating deepen dossiers as Gate A or dig auth.

**Owner one-liner (value):** ledger evidence notes for behavior/tests/security/ops — **≠** understanding the whole pile.

## 2. Deepen migration (locked)

| Legacy | W3a fate |
|--------|----------|
| Skill `vibage-map-deepen` | Thin pointer to dimension-fill; **must not** narrate “system understood” |
| Token `MAP_DEEPEN_OK` | **Retired as brand** (P2 scrub STATUS/adapters/skills). New scripts **never print** it. Old `verify-map-deepen.sh` after migrate: **never emit `MAP_DEEPEN_OK`** — hard-fail migrate text, **or** wrap that prints only `DIMENSION_FILL_OK` / `PARTIAL` / `BLOCKED` |
| Envelope `pipeline_id=map_deepen` / `deepen_*` freeze | **Do not authorize** dimension-fill. Owner must re-consent with `dimension_*` keys (§4). No silent dual-read. |
| `docs/vibage/dossiers/` | Optional human notes; **must** cite ledger claim ids; agents must not cite stub alone as depth |

**Forbidden dual-track:** old deepen “understood” narrative and dimension-fill as two competing substrates in one session.

**STATUS scrub (P2):** remove `MAP_DEEPEN_OK` from proof-layer advertising once On-tree.

## 3. Frozen dimension set (W3a v1)

| claim_class | Intent |
|-------------|--------|
| `dimension_behavior` | Primary runtime / API / CLI behavior entrypoints |
| `dimension_tests` | How the repo is tested |
| `dimension_security` | Authz / secrets / trust-boundary hints (no real `.env` reads) |
| `dimension_ops` | Deploy / runbook / ops surface beyond matrix env cells |

`OWNER_POLICY.dimension_classes` may **narrow** to a subset. Expanding requires design amendment.

**Precedence:** DECISIONS freeze `dimension_classes` (if present) ∩ policy subset ∩ §3 default = required set. Freeze `dimension_scope_ids` selects repos; classes come from above.

## 4. Consent freeze (owner-facing)

Before any synthesizer/searcher:

1. Anti-illusion already said (nameplate ≠ understood; ≠ dig-ready; ≠ full-sweep).  
2. Cost band for N repos already said.  
3. Owner **yes** to dimension-fill (ticket paste alone = implicit **no**).  

**Frozen ask (English; agent may translate):**

```text
VIBAGE_DIMENSION_ASK: Run optional dimension-fill (behavior/tests/security/ops ledger notes) for N repos?
This is NOT full-sweep / NOT system-understood / NOT dig-ready. [yes/no + model tier]
```

**Forbidden slogans in the ask or success path:** understood, dig-ready, install→ready, full-sweep, Architecture Pass.

Append DECISIONS fence **before** work:

```json
{
  "dimension_yes": true,
  "model_tier": "balanced",
  "dimension_scope_ids": ["svc-a"],
  "dimension_classes": ["dimension_behavior", "dimension_tests", "dimension_security", "dimension_ops"],
  "dimension_scope_hash": "<sha256 of sorted ids>",
  "dimension_frozen_at": "2026-07-25T00:00:00Z",
  "source": "human",
  "run_id": "dimension-fill-1"
}
```

Legacy `deepen_yes` / `deepen_scope_*` / `pipeline_id=map_deepen` **do not** satisfy this freeze.

## 5. Workers & orchestration

```text
Orchestrator (dimension-fill.sh)
  → probe matrix honesty + vacancy (machine: verify-env-vacancy.sh + verify-env-branch-matrix)
  → for each dimension_scope_ids repo
      → Repo synthesizer (dossier stub citing claim ids to-be)
          → Dimension searcher × each required claim_class
              → ledger-append (proven|failed) OR refuse append
```

### 5.1 Searcher mode (P0 locked)

`dimension-search.sh` is a **validator + appender**, not a silent invent-engine:

- Input: claim JSON from agent nested search (production continuum).  
- `--heuristic` **fixture/test only** — refuse unless `VIBAGE_DIMENSION_HEURISTIC=1` **and** path under `tests/` / tmp fixture; production continuum must hard-refuse heuristic minting.  
- Agent supplies pointers/quote; script validates schema/classes/secrets then `ledger-append`.  
- Reject unknown `claim_class`, non-terminal state, empty pointers, secret dotenv basename → **do not append**; orchestrator may count as blocked class (not terminal failed-that-greens-OK).

### 5.2 Matrix / vacancy probes (machine)

Before `DIMENSION_FILL_OK`:

1. Hub + real `GRAPH_FLOOR_OK` from `verify-graph-floor.sh` (map-present alone is **not** enough).  
2. Matrix honesty: `ENV_BRANCH_MATRIX_OK` **OR** (disclosed incomplete **and** vacancy token is `CLEAR`|`ANSWERED`|`ASK` from `verify-env-vacancy.sh`).  
3. If vacancy primary token is `ENV_VACANCY_ASK` for the mother (any unanswered missing in discovery set) → **forbid** `DIMENSION_FILL_OK`; max `DIMENSION_FILL_PARTIAL`.  
4. If neither matrix OK nor disclosed vacancy path → `DIMENSION_FILL_BLOCKED`.

Scope narrowing **must not** hide pile-level `ENV_VACANCY_ASK`.

## 6. Ledger claim shape

Reuse `ledger-append.sh`. W3a norms:

- `subject_type`: `repo`; `subject_id`: repo_id  
- `claim_class`: ∈ §3 (enforced by searcher/verify — append today does not enum-check)  
- `state`: `proven` | `failed` only after searcher accepts  
- pointers: non-empty; `path` under repo; basename ∉ `SECRET_DOTENV_NAMES`  
- Secret dotenv attempt → **refuse append** + contribute to `DIMENSION_FILL_BLOCKED` or keep class unfinished (not a terminal `failed` that still allows OK)

Latest claim per `(subject_id, claim_class)` wins.

## 7. Scripts / tokens

| Script | Role |
|--------|------|
| `scripts/dimension-fill.sh` | Orchestrator |
| `scripts/dimension-synth-repo.sh` | Dossier stub |
| `scripts/dimension-search.sh` | Validate+append one class |
| `scripts/verify-dimension-fill.sh` | Scope verify → tokens |
| `scripts/verify-map-deepen.sh` | Post-On-tree: **never emit `MAP_DEEPEN_OK`**. Hard-fail migrate message, **or** wrap printing only `DIMENSION_FILL_*` (OK/PARTIAL/BLOCKED). |

### Tokens (exactly one primary)

```text
DIMENSION_FILL_OK tally=proven:<p>,failed:<f>
DIMENSION_FILL_PARTIAL reason=<vacancy_ask|incomplete_scope|...>
DIMENSION_FILL_BLOCKED reason=<no_consent|no_floor|matrix_opaque|secret_dotenv|...>
```

**OK semantics:** every in-scope repo × required class has a **terminal accepted** ledger claim (`proven|failed`). Print **mandatory** `tally=proven:<p>,failed:<f>` so all-failed cannot look like silent success. Skills: OK ≠ understood; all-failed ⇒ disclose “no proven depth.”

### Exit-code matrix

| Token | Exit | Skill rule |
|-------|------|------------|
| `DIMENSION_FILL_OK` | 0 | Parse token + tally; exit 0 ≠ OK alone as understood |
| `DIMENSION_FILL_PARTIAL` | 0 | **Forbidden:** treat as filled/understood; must disclose |
| `DIMENSION_FILL_BLOCKED` | ≠ 0 | Fix consent / probes / secrets |

**Compat:** new scripts never print `MAP_DEEPEN_OK`. Old `verify-map-deepen.sh` **never** emits `MAP_DEEPEN_OK` after migrate (hard-fail or `DIMENSION_FILL_*` only).

## 8. Skill / adapter surface

- Continuum: optional after freshness + env-vacancy.  
- Exact-token parse; `exit 0 ≠ DIMENSION_FILL_OK`.  
- `vibage-map-deepen`: migrated banner → call dimension-fill path.  
- Locate/orient: ignore dimension/deepen as dig auth.

## 9. Testing (`tests/test_dimension_fill_w3a.sh`)

Outside suite glob; grep-firewall ∉ Tier-0 / pack-health.

| Case | Expect |
|------|--------|
| No consent | `BLOCKED` |
| Happy path | `OK` + tally; four terminal claims |
| Vacancy ASK on discovery set | `PARTIAL`; not OK |
| Matrix opaque | `BLOCKED` |
| Secret dotenv pointer | refuse append; not OK via fake failed |
| All-failed classes | `OK` only with tally failed>0; skills copy forbids understood |
| Legacy deepen freeze only | `BLOCKED` (no silent auth) |
| `verify-map-deepen` after migrate | no PARTIAL→deepen OK |

## 10. Split plans

| Chunk | Delivers |
|-------|----------|
| **P0** | `dimension-search.sh` validate+append + `verify-dimension-fill.sh` + tests |
| **P1** | synth + `dimension-fill.sh` + consent + vacancy/matrix probes |
| **P2** | migrate deepen/verify + STATUS/adapters scrub `MAP_DEEPEN_OK` brand |

## 11. Out of scope

W1b; W3b cards; W4 Tier-0; vector/RAG; silent class expansion; auto-fill on install; real `.env` reads; dimension satisfying rollup/full-sweep/dig-ready.

## 12. Freeze-lift note

Until green: **W3a dimension-fill design exists; On-tree=NO**.  
After green: **W3a dimension-fill On-tree ≠ full-sweep ≠ understood ≠ letter B**; `MAP_DEEPEN_OK` brand retired.
