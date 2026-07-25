# Honesty surfaces (what "covered" can and cannot mean)

Vibage spends most of its design budget on one problem: **an agent claiming more
than it proved.** That problem does not live on one surface, and the surfaces do
not have the same ceiling. Scoring them with a single "fully covered?" question
produces a permanent **NO** that says nothing useful — the same mistake as
collapsing `script` and `agent` scope into one Proven-green column.

So: name the surfaces, name the inequality.

## The three surfaces

| Surface | What can go wrong | Instrument | Ceiling |
|---------|-------------------|------------|---------|
| **Capability SSOT** | `STATUS.md` says Proven-green=YES for something that was never proven, or drifts silently across repair waves | `verify-proven-lock.sh` (`PROVEN_LOCK_OK`), `test_status_capability_table.sh` (`STATUS_CAPABILITY_TABLE_OK`) | **Reachable for the signed fields** — tri-state cells, scope kind, cited tokens and cited `run_ts`. Scope caveat prose stays unsigned |
| **Deliverable** | `VIBAGE-ISSUE-OWNER/LOCATE.md` narrate 掃透 / 立體場景 / dig-ready without holding the token | `verify-report.sh` → `REPORT_TOKEN_LINT_OK` + `COVERAGE_BOX_OK`, `verify-run.sh` mode honesty | **Partial — Wave-2 closed.** Dig coverage reader-proven (Q1). Second-order paraphrase still passes the lint by design (bounded by the box, not blocked). Per-finding script gate = **WONT_BUILD** (see below) |
| **Chat** | The agent tells the owner something truer-sounding than the artifacts support | optional milestone paste of script stdout (no receipt product) | **CLOSED — accepted ceiling.** Not reachable; no future wave. Do not reopen as a backlog item |

## The inequality

```
CAPABILITY_SSOT_HONESTY  ≠  DELIVERABLE_HONESTY  ≠  CHAT_HONESTY
```

- **Capability SSOT honesty** — enforceable today for the signed fields. Drift is
  not *impossible* — anyone with write access can re-sign — but **unsigned** drift
  fails the gate, and re-signing is an explicit act that shows up in review and
  must name an evidence path that resolves inside the package. See
  `docs/PROVEN-LOCK.json`. What the gate cannot see: whether that evidence file's
  content actually supports the claim, and any caveat deleted from Scope prose.
- **Deliverable honesty** — enforceable in principle, **partial today**. The lint is
  literal / phrase matching. Second-order paraphrase passes; this is measured and
  disclosed, not assumed away. See the residual section below.
- **Chat honesty** — **CLOSED (accepted ceiling).** Not provable; no future wave.
  Chat has no verifiable side effect. Soft practice (paste script stdout at
  milestones) may raise the cost of a false claim; it is **not** a product gate
  and must not appear as open work.

**Therefore:** "Is Vibage fully covered?" is not answerable as one question.
Answer it per surface, and never let a reachable surface borrow credibility from
an unreachable one — or the reverse.

## Measured residual (deliverable surface)

The deliverable lint blocks exact slogans plus a closed set of universal-completion
and env-vacancy phrases. Rewording outside those patterns passes. This is measured,
not estimated — probes that pass today:

- 「每一個 repo 的每一條 branch 都檢查完畢，沒有漏網之魚。」(「檢查」∉ 掃/scan)
- 「環境變數的疑慮都已排除。」(「排除」∉ 確認/釐清/clear)
- "I have completed a full sweep of every environment and branch." (`sweep` ∉ scanned/mapped)
- 「這個系統的架構我已經完全掌握了。」(「掌握」∉ understood/全懂)
- 「可以直接開挖了。」(「開挖」∉ dig-ready/ready to dig)

**Do not close this with more regex.** Every added pattern enumerates one more bad
sentence out of an infinite set while adding a surface that *looks* covered — using
the fake-green technique to fight fake green. The structural fix is to stop
detecting the lie and start bounding it:

1. **Machine-filled coverage box** — **DONE** (`scripts/coverage-box.sh`,
   `COVERAGE_BOX_OK`). Required in both reports; re-derived from the hub at verify
   time. Hand-edited boxes fail. Paraphrase claiming full coverage sits under
   machine numbers and is **contradicted**, not blocked. `## Held tokens` ⊆ box
   `held:`.
2. **Per-finding citation (script gate)** — **WONT_BUILD / CLOSED.** Soft rule
   already exists in `references/hard-stops.md` (kill findings without `path` +
   quote). A structural verify for “every line cites a path” was considered and
   **rejected after reader-exp Q3**: both arms scored 100% on gap detection from
   prose alone — adding a script force would be a zero-baseline experiment and
   must not stay listed as open work. Soft skill guidance remains; no new gate.

Wave-2 deliverable track is **closed**. Remaining paraphrase pass-through is
disclosed residual, not a backlog item. Note what the box does **not** do: it
does not judge whether a finding is correct, and `COVERAGE_BOX_SKIPPED` (no
derivable hub) is not a pass.

### What the coverage box has and has not been shown to do

**Script-proven:** tamper detection, unheld-token detection, required-when-derivable,
invocation independence, renderer-version vs tampering — `tests/test_coverage_box.sh`
(`COVERAGE_BOX_TEST_OK`).

**Reader-proven (one dimension).** Evidence:
`docs/evidence/coverage-box/READER-EXP-1785002313.md`. Same report content, box
present vs removed, prose otherwise byte-identical; 8 bad-news hubs, 24 clean
judges with no hub access:

| | with box | without |
|---|---|---|
| "how many repos were dug" — accuracy | **100%** | **0%** |
| answered "cannot tell" | 0% | **100%** |

Holds within each model separately (grok 8/8 vs 0/4; composer 4/4 vs 0/8), so it
is not a model artifact. The null "box makes no difference ⇒ A ≈ B" is falsified
on that question. **The mechanism is bounded reading, not blocked writing.**

**Explicitly NOT shown, and not to be implied:**

- **Not** that authors overclaim less. A separate 12-agent writer panel scored
  with-box 1/6 vs without-box 0/6 — which measures nothing, because the control
  arm had a **zero baseline** (both arms ran the full skills + hard-stops
  apparatus, which already instructs honest disclosure). No dynamic range, no
  result, in either direction.
- **Not** that the box improves 掃透 or gap judgement: Q2/Q3 were 100% in *both*
  arms. The prose already carried enough. There is no increment to claim here.
- **Not** that it reduces overconfidence: both arms were 0%. Nothing to reduce.
- **Not** validated on the live 17-repo DefiStrategy — synthetic hubs only.
- **Not** semantic understanding, and **not** a chat firewall.

The one thing it demonstrably does: it turns "how much was actually dug" from
unreadable into readable. Everything else about it remains unmeasured.

## What each token does and does not mean

| Token | Means | Does **not** mean |
|-------|-------|-------------------|
| `PROVEN_LOCK_OK` | The rows the parser sees in the single `## Capability` table match the last signature; each Proven-green=YES names an in-package path that exists (run-kind: containing the declared `run_ts`) | The evidence supports the claim; the claims are true; letter B; a live-panel re-run happened; that unsigned Scope prose is intact |
| `STATUS_CAPABILITY_TABLE_OK` | Table shape is well-formed; no scope words leaked into tri-state columns | Any claim in the table is proven |
| `REPORT_TOKEN_LINT_OK` | No listed slogan appears without the required Held token + evidence fence | Semantic coverage; paraphrase caught; chat honesty |
| `COVERAGE_BOX_OK` | The report's coverage numbers match the hub on disk right now, and `## Held tokens` claims nothing the workspace does not hold | The findings are correct; the dig was complete; the prose above/below is true |
| `COVERAGE_BOX_SKIPPED` | The check could **not** run (no derivable hub) | A pass |
| `VERIFY_REPORT_OK` | Report passes the structural checklist | Nested subagents actually ran (see `verify-report.sh` header) |

## Known limits of the capability-SSOT gate (measured, not assumed)

An adversarial pass tried to move a Proven-green claim without tripping
`verify-proven-lock.sh`. Five bypasses were reproduced and are now closed, each
with a regression test in `tests/test_proven_lock.sh`:

| Bypass | Now |
|--------|-----|
| Flip the **lock's own** `proven_green` to `NO` → evidence check disarms itself | Closed — the claim is read from STATUS.md; a lock row disagreeing with STATUS fails |
| Append a row indented 1–3 spaces (GitHub still renders it as a table row) | Closed — every pipe-line in the section is a row, indented or not |
| Add a second `## Capability` heading to shadow the governed table | Closed — exactly one heading required |
| Flip `Designed` / `On-tree` (outside the old projection) | Closed — both are signed |
| `evidence_paths` pointing at `/etc/hosts`, `../` escapes, symlinks, or a `run_ts` of `"2"` | Closed — package-relative, no `..`, no symlink, resolved inside root, strict `run_ts` format |

A second, cross-model pass then found four more. All closed, all with tests:

| Bypass | Now |
|--------|-----|
| Re-aim `evidence_paths` at any other file that happens to exist — the pointers were outside the hash | Closed — the signature covers **both** halves: the STATUS projection AND the evidence pointers |
| Downgrade `evidence_kind` `run` → `script` to shed the `run_ts` check | Closed — same signature |
| A run-kind row whose `run_ts` is named only inside the lock, never in STATUS | Closed — run-kind rows must cite `run_ts=` in the Scope cell, so the timestamp is a public claim |
| A stale `lock.projection` that disagrees with STATUS — no bypass, but it misleads anyone reading the lock instead of running it | Closed — stored projection must equal the recomputed one |

**Still open, deliberately:** Scope **prose** is unsigned. Deleting a `≠` caveat
from a Scope cell — which is where much of this table's honesty content lives —
does not trip the gate. Signing free text would make every wording fix a
re-signature event; the trade was made knowingly, and it is a real hole, not an
oversight. A forged `run_ts=` citation *is* caught, because that is a fact rather
than prose.

**Also open:** the gate proves an evidence file exists and carries the declared
`run_ts`. It cannot judge whether that file's content supports the claim.

## Where this runs

`PROVEN_LOCK_OK` is checked in remote CI (its own job `status-lints`) and in
`pack-health.sh`. It is deliberately **∉ Tier-0** — `TIER0_OK` semantics stay
exactly what they were, consistent with the existing policy that STATUS lints
stay out of the ship gate. Whether that job is a required check on GitHub is a
repo-settings question — the workflow alone does not make merge “unbypassable.”
