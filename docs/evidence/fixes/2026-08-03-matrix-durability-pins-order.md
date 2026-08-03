# Fix report — matrix state durability + pin ordering (v0.9.3.1)

Source: external tester ran the full continuum on a real parent (macOS, Claude Code,
2 sibling repos) and filed three findings. Each was re-checked against the scripts
before changing anything.

## Finding 1 — inventory destroyed proven cells (CONFIRMED, data loss)

`scripts/matrix-inventory.sh` rebuilt `cells` from scratch and wrote every cell as
`unproven`, never merging with the existing `env_branch_matrix.json`. Both callers
(`freshness-refresh-repo.sh`, `c-prime-fill.sh`) invoked it unconditionally, so a
per-repo refresh silently reset every other repo's swept state.

**Fix:** terminal states are durable, but only while their evidence still resolves.

- Inventory still recomputes structure for **every** repo, so a deleted branch cannot
  linger as a ghost `proven` cell.
- A cell whose previous state was `proven`/`failed` keeps that verdict instead of being
  reset to `unproven` — provided every carried pointer still resolves **at that branch**:
  `git cat-file -e <branch_ref>:<rel>` first, and a working-tree hit only counts when
  that branch is the checked-out one (the single case where extract also reads disk, so
  untracked evidence is legitimate). Unresolvable evidence means the cell falls back to
  `unproven`, which fails the matrix gates until a re-sweep. Structural verdicts
  (`branch_cap`, `missing-env-config`) still recompute.
- `--reset` is the explicit rebuild escape hatch (prints `mode=reset`).
- Unknown flags fail closed.
- Inventory reports `mode=`, `preserved_terminal=`, `dropped_stale_evidence=`.
- `freshness-refresh-repo.sh` keeps calling plain inventory: bounded now means "only
  this repo gets **swept**", not "other repos get wiped".

**Design changes forced by review (two rounds, both blocking findings applied):**

| Round | Finding | Outcome |
|-------|---------|---------|
| 1 | Unconditional merge kept `MATRIX_SWEEP_SUBSTANTIVE_OK` green on a pointer to a renamed file | Added the evidence gate |
| 1 | `--only-repo` let a deleted branch survive as a ghost `proven` cell | Flag dropped; structure recomputes for every repo |
| 2 | The gate's working-tree shortcut ignored `branch_ref`, so a file still on disk under another branch carried a `proven` verdict that extract would reject | Git is asked first; disk only counts for the checked-out branch |

## Residual risk (disclosed, not fixed)

- **Pointer content fidelity.** The gate proves the pointer path still exists at that
  branch, not that the stored `quote` still appears in it. A file that keeps its name
  while losing the env line can carry a `proven` verdict with a quote that no longer
  matches. A re-sweep (`c-prime-fill.sh`, or a per-repo refresh of that repo) repairs it.
  Closing this needs content re-validation, which is a different change than this bugfix.
- **Sticky `failed` on inventory-only runs.** A carried `failed` cell whose pointer is the
  repo directory stays `failed` until swept — false-red, not false-green.
- **Allow-list shape.** Only `scripts/pack-health.sh` is a mechanical review trigger in
  this batch; `matrix-inventory.sh` alone would not have required a review record. That is
  the V1 allow-list, not something this change introduced.

## Finding 2 — install never checked pins (CONFIRMED, ordering)

`install.sh` printed `Pin check: …/verify-pins.sh` as a suggestion and exited. Since
`vibage-issue-locate` preflight makes `verify-pins` a hard stop, the owner could pass
the entire continuum (`PROJECT_ENTRY_OK` → `CONFIRM` → `ASSERT_GATE_OK`) before locate
refused on a missing `rg` binary or an unfetchable pinned superpowers SHA.

**Fix:** install runs `verify-pins.sh` itself and reports `PINS_OK` / `PINS_FAIL`.
`PINS_FAIL` names the exact remediation, including the shallow-clone trap
(`--depth 1` cannot check out the pin) and that a zsh function named `rg` is invisible
to bash. Default stays exit 0 (skills are still linked); `--require-pins` turns the
report into a gate. Both refusals downstream stay fail-closed — only the ordering moved.

## Finding 3 — "stale" wording for never-scanned (CONFIRMED, cosmetic)

`compute_stale()` returns `missing_freshness_json` / `missing_record` when nothing has
ever scanned the repo, but the operator only saw `stale_count` and
`STALE_BLOCKS_MOTHER`. "Stale" implies it was fresh once.

**Fix:** freshness now discloses `never_scanned_count=`, a `stale_reasons=` breakdown,
and a note naming `c-prime-fill` (a per-repo refresh cannot fix a never-scanned repo).
Blocking behaviour and the stdout token contract are unchanged — the new lines are
stderr disclosure, so existing `FRESHNESS_OK` / `STALE_BLOCKS_MOTHER` parsers are safe.

## Regression tests

| Test | Guards |
|------|--------|
| `tests/test_c_prime_matrix_durability.sh` → `MATRIX_DURABILITY_OK` | prove a cell → re-inventory → still proven; refreshing repo-b keeps repo-a proven and still sweeps repo-b; renamed evidence drops durability and fails `verify-matrix-substantive`; evidence deleted on another branch is not carried from the working tree, while checked-out-branch evidence still is; a deleted branch cell is dropped rather than carried; `--reset` rebuilds; flag misuse fails; never-scanned disclosure |
| `tests/test_install_pins_report.sh` → `INSTALL_PINS_REPORT_OK` | `PINS_FAIL` printed with actionable remediation; install stays exit 0; `--require-pins` gates; tip-only wording cannot come back; `PINS_OK` on a healthy env |

Both are wired into `scripts/pack-health.sh` so they run in CI (matrix/freshness stay
out of Tier-0 by policy; `tests/test_tier0_c_prime_thin.sh` still passes).

**Non-vacuous checks (both probes run, both reproduced the bug they guard):**

| Probe | Result |
|-------|--------|
| v0.9.3 `matrix-inventory.sh` / `freshness-refresh-repo.sh` / `freshness.py` stashed back in | fails at `re-inventory destroyed proven state (regression)` |
| merge kept but the evidence gate short-circuited to always-true | fails at `cell with vanished evidence must fall back to unproven (false-green)` |
| gate reordered to path-existence-first (the round-2 finding) | fails at `working-tree hit must not carry another branch's proven cell (false-green)` |

## Honesty

- Fixes were exercised against fixtures and local gates, not against the reporter's machine.
- `PINS_OK` at install time is a point-in-time check; a later host change can still break locate.
- The `PINS_OK` branch of the pins test is skipped and disclosed when no pinned checkout exists.
- Routing scope: this is vibage-skills package work — no hub init / orient / locate was run.
