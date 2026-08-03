# Fix report — evidence fidelity + hub-writer review triggers (v0.9.3.2)

Closes two residual risks that v0.9.3.1 disclosed instead of fixing.

## Part 1 — hub-state writers are now review triggers

v0.9.3.1's own review noted that only `scripts/pack-health.sh` was a mechanical trigger for
that batch: a solo edit to `scripts/matrix-inventory.sh` — the script whose silent state
reset was the v0.9.3 bug — produced `REVIEW_RECORD_SKIP`. The high-blast behaviour was
reviewed only because a gate script happened to be in the same diff.

`TRIGGER_GATE_HUB_WRITERS` (gate class) now covers the scripts that write the owner's
`docs/vibage/**` or mint the cell / freshness / evidence values gate tokens are computed
from: `matrix-inventory`, `matrix-sweep-cell`, `matrix-extract-evidence`, `c-prime-fill`,
`freshness-refresh-repo`, `freshness-mark`, `graph-floor`, `pile-index`, `scene-brief`,
`ledger-append`, `dimension-synth-repo`, `env-vacancy-apply-point`, `install.sh`, and the
`scripts/lib/` modules behind them (`freshness`, `env_discovery`, `env_vacancy`,
`dimension_fill`). 17 paths.

Deliberately excluded: presentation-only writers (`generate-service-map-graph.sh`,
`render-service-map-preview.sh`) mint no verdict, and read-only `verify-*.sh` wrappers stay
outside the gate as before (`tests/test_review_record.sh` still freezes that).

**Drift guard.** `tests/test_review_record.sh` partitions every `scripts/**` file that
mentions `docs/vibage`: it is a trigger, or it is named in `NON_WRITER_EXEMPT` with a
reason (17 presentation / read-only-gate / read-only-classifier entries). A new hub writer
therefore fails the suite until a human classifies it.

The first version of this guard grepped for write verbs (`write_text(`, `json.dump(`, …)
and a reviewer showed it was evadable with `open().write`, `tee`, `cp`, or a plain
redirect — so it was replaced with the exhaustive partition above. The frozen 17-path
enumeration remains the actual control; the partition is what stops silent growth.

Cost accepted: every future edit to those 17 paths needs a review record (N=2).

## Part 2 — carried evidence must still prove its env, and its quote is refreshed

v0.9.3.1 gated durability on pointer **path** existence at the branch. A file that kept its
name while losing the line that backed the verdict could still carry `proven` with a quote
that no longer matched.

Three analysts examined the options. Two recommended comparing the stored `quote` against
the file text; the third measured that on a realistic fixture **only 9 of 13 real proven
quotes are literal substrings of their file** — `dir:` pointers, the synthetic `dir:` quote
for an empty named compose, and presence-local text (`env example present; no named
APP_ENV …`) are produced by `discover_envs` / `quote_for_env` and are not file content at
all. String comparison would therefore have false-red about 31% of healthy cells: a fresh
false-red traded for a narrow false-green.

Implemented instead:

- Carrying re-derives evidence with the same `quote_for_env` the sweep uses. No env quote
  derivable at that branch → refuse the carry, cell stays `unproven`, counted in
  `dropped_stale_evidence`.
- Tree/directory evidence keeps existence as the whole test — there is no text to re-derive.
- A pointer naming a real secret dotenv (`.env`, `.env.production`, …) refuses the carry.
  Extract never emits those, so such a pointer can only come from a hand-edited or foreign
  matrix; a reviewer showed that carrying it on existence alone would launder a `proven`
  verdict citing content nothing is allowed to read.
- When the re-derived quote differs from the stored one, a stale `evidence_hash` is
  dropped rather than paired with a fresh citation.
- **The carried quote is rewritten to the re-derived value.** This is the part no analyst
  proposed and it closes their shared regret case: when a weaker rule still proves the env
  after the original line is gone, the cell keeps its verdict but stops citing text it can
  no longer produce.

Cost: one extra `git show` per carried non-directory pointer, the same order as the path
check already paid.

## Regression tests

`tests/test_c_prime_matrix_durability.sh` (`MATRIX_DURABILITY_OK`) gains:

| Case | Asserts |
|------|---------|
| Content drift | compose keeps its name and `deploy/production/` keeps the env in the inventory, but the `APP_ENV` line is gone → cell falls back to `unproven` with `dropped_stale_evidence>=1` |
| Repair | a re-sweep re-proves that cell from the surviving `deploy/` evidence, and the stale `APP_ENV: production` quote is not what comes back |
| Non-substring shapes | a fixture with directory and presence-only evidence keeps its proven cells across re-inventory, and the test refuses to run if the fixture stops containing a non-substring quote |

`tests/test_review_record.sh` gains `TRIGGER_HUB_WRITERS_OK` (frozen membership,
presentation-writer exclusion, and the drift guard).

**Non-vacuous check:** with `scripts/matrix-inventory.sh` stashed back to v0.9.3.1, the
suite fails at `content drift must not be carried (residual false-green)`.

## Honesty

- Exercised against fixtures and local gates; no live multi-repo parent was mutated.
- Re-derivation asks "is this env still provable here", not "is this the same evidence a
  human would pick". A weaker surviving rule can keep a cell green with a weaker quote —
  now visibly, because the quote is refreshed rather than preserved.
- `MATRIX_DURABILITY_OK` and `TRIGGER_HUB_WRITERS_OK` are script outcomes, not full-sweep
  or Proven-green claims.
- The measured 9/13 substring survival rate came from one fixture shape; it demonstrates
  that string comparison is unsafe, not that 31% is the population rate.
