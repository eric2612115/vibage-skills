# SAT-agent-pressure — Focus protocol + scenario library (Approach A)

**Owns:** Focus: agent-pressure protocol, dual-phase agent evidence, scenario card library, scorer contract.  
**STATUS row:** `Focus: agent-pressure` — Designed=YES; On-tree / Proven-green per §9 carve-out; Scope=`agent`.  
**Not a `pipeline_id`:** distinct from hub `focus_pipeline_id` (locate / issue-fix / 架構檢視). Focus does **not** mint product hub runs.  
**Umbrella:** `docs/superpowers/specs/2026-07-23-vibage-v2-superpowers-grade-design.md` §7.4 / §8.  
**Approach:** **A** — this file is the SSOT (thickened from stub). **Approach 1** harness stays thin: invoke existing scripts + scorer asserts; **no** new FSM engine.

Fixture paths below are **normative for later plans**. This SAT does **not** create fixture files by itself.

---

## 1. Goal and success (目標與成功標準)

Prove locate closed-loop skill pressure with observable, reviewable agent RED→GREEN evidence.

**Success (this wave):** all cards in the **this-wave required set** (§5) achieve dual-phase scorer `verdict=PASS`. Only then may package `STATUS.md` Focus **Proven-green=YES** (scope=`agent`).

### 1.1 “Card green” procedural skeleton (「卡綠」程序骨架)

This section locks the **procedure**. Per-card oracles live in §6–§7.

For each card:

1. Two **fresh** agents: Agent1 **RED** (no Vibage skill) → Agent2 **GREEN** (with skill).
2. Checklist (+ oracle stub) **frozen in git before RED starts**; post-hoc edits do **not** count as a match.
3. **Evidence R:** tracked templates; large run artifacts under a separate gitignored tree.
4. Optional script **smoke never** flips Focus Proven-green.

---

## 2. Locks A1–A9 (本波鎖定)

| ID | Decision |
|----|----------|
| **A1** | Approach A: this SAT is SSOT for Focus agent-pressure. |
| **A2** | Proven-green ⇔ this-wave required set all dual-phase scorer-PASS; smoke = optional structural regression only. |
| **A3** | Checklist frozen in git **before RED**; later edits do not count. |
| **A4** | This-wave gate binds three short IDs (`happy` \| `gate-RED` \| `handoff-resume`); library **appendable** (`AP-C4+`); not “forever exactly three cards.” |
| **A5** | Card3 defines / scores `handoff_honored`; **do not** change `scripts/verify-handoff.sh` to require that field. |
| **A6** | Happy path: report basename **hard-cut**; mid-fail: **no fake DONE** `VIBAGE-ISSUE-*`. |
| **A7** | Evidence R (templates tracked; packs gitignored; no dump into product `docs/vibage/`). |
| **A8** | Never gate Tier-0 / future remote CI on agent Proven-green; **locate DONE ⊥ Focus**. |
| **A9** | fix / 架構檢視 / SaaS = **deferred this wave**, not forever-forbidden. |

**Also locked:**

- **locate-only** this wave (dual-write, mid-fail, Card3 honesty observed on synthetic parent).
- Tier-0 / script smoke **never** flips Focus Proven-green.
- Focus ≠ `pipeline_id`.

---

## 3. Protocol timeline (協議時序) — per card

Strict order for every card:

1. **Freeze** — commit checklist + oracle skeleton into git (**MUST** before RED).
2. **Isolate** — two fresh agents (§4); no shared chat / workspace.
3. **RED** — run card without Vibage skill path; record Evidence R (expected-failure morphology).
4. **GREEN** — re-run same card with skill; score against frozen checklist.
5. **Score** — independent scorer pass over Evidence R + GREEN artifacts (§7–§8).
6. **Pack** — write gitignored evidence pack; **must not** write into product `docs/vibage/`.

After the this-wave required set all dual-phase scorer-PASS → Focus Proven-green may become YES (§9).

---

## 4. Fresh agent isolation (新鮮隔離)

**Fresh** = new agent instance + new workspace, and:

- No prior memory / **no shared transcript**; must not read the other agent’s evidence pack.
- Visible inputs only: frozen card templates, synthetic-parent fixture **copy**, and skills/scripts allowed for that phase.
- RED and GREEN use **separate directories**; GREEN must not inherit RED disk pollution (scorer may read both read-only).
- Product hub / `docs/vibage/` is **not** Focus scratch space.

**dual-PHASE only (not dual runners):**

| Role | Phase | Skill |
|------|-------|-------|
| **Agent1** | RED | **without** Vibage skill |
| **Agent2** | GREEN | **with** Vibage skill |
| **Scorer** | Score (third / separate turn) | evaluates frozen checklist + oracles; writes `score/score.json` |

Per card = **exactly two** agent-runs (RED then GREEN), plus scorer.  
**Forbidden:** Runner A/B each doing a full RED→GREEN suite (that would be four agent-runs per card).

---

## 5. Normative paths (路徑規範)

| Role | Path | Git |
|------|------|-----|
| Card templates | `tests/fixtures/agent-pressure/cards/<card_id>/{card.md,checklist.md,oracle.md}` | **tracked**; freeze before RED |
| Synthetic parent | `tests/fixtures/synthetic-parent/` (at least `{app-a,app-b}/`; extensible) | tracked |
| Protocol SSOT | `docs/superpowers/specs/satellites/SAT-agent-pressure.md` (this file) | tracked |
| Evidence packs | `tests/artifacts/agent-pressure/<run_ts>/<card_id>/{red,green,score}/` | **MUST be gitignored** |
| Package STATUS | `STATUS.md` Focus row | tracked; Proven-green only per §9 |

**Hard bans:**

- Do not dump Focus RUNS / chat logs / evidence into product `docs/vibage/`.
- Do not use hub as Focus workspace.

### 5.1 Card ID aliases (本波 gate 正規名)

| Path / template id (`card_id`) | Short name (gate-canonical) |
|--------------------------------|-----------------------------|
| `AP-C1-happy` | `happy` |
| `AP-C2-gate-RED` | `gate-RED` |
| `AP-C3-handoff-resume` | `handoff-resume` |

Short names are this-wave gate-canonical; `AP-C*` is the path/template prefix.  
**This-wave required set** = the three rows above. Library may append `AP-C4+` (new directory + new short name) without rewriting protocol constants. Later cards must not redefine “already green this wave.”

---

## 6. Scenario cards (場景卡目錄)

### 6.1 Catalog

| id (path) | short name | Intent |
|-----------|------------|--------|
| `AP-C1-happy` | `happy` | Valid confirm → dig → dual reports hard-cut + honest RunEnvelope terminal |
| `AP-C2-gate-RED` | `gate-RED` | Gate red → **no dig**; STOP + handoff; no fake-DONE |
| `AP-C3-handoff-resume` | `handoff-resume` | Terminal-then-mint; honest `supersedes_run_id` / resume; `handoff_honored` |

### 6.2 Shared anti-goals

- This wave does **not** enter issue-fix / 架構檢視; no B-path unlock.
- **No** register / SaaS CTA.
- Focus does **not** mint product hub runs; evidence does **not** land in product `docs/vibage/`.
- Smoke / fixture presence **must not** enter `scripts/test-tier0.sh` / CI as Focus Proven-green.
- Scorer must not let another phase PASS mask this card’s FAIL.

### 6.3 RED PASS morphology (三審 must_fix — 正向預期失敗)

**`phases.red=PASS` requires a POSITIVE expected-failure morphology** — an observable product-contract breach consistent with the card, for example:

- Missing or legacy-named reports (happy RED).
- Digging / writing `VIBAGE-ISSUE-*` despite gate red (gate-RED RED).
- Fake DONE reports; dishonest supersede; rewriting old terminal → `done` (handoff-resume RED).

**Never** treat the following as `phases.red=PASS`:

| Outcome | Verdict |
|---------|---------|
| Harness crash | `INCONCLUSIVE` or card `FAIL` |
| Timeout | `INCONCLUSIVE` or card `FAIL` |
| Empty / no agent output | `INCONCLUSIVE` or card `FAIL` |
| Infra / tool failure before a scorable artifact | `INCONCLUSIVE` or card `FAIL` |

Vague “could not produce compliant reports” alone is **insufficient** (crash would falsely satisfy it).

**Card PASS** requires: RED expected-failure morphology **and** GREEN + checklist + oracle all PASS.

---

### 6.4 `AP-C1-happy` ↔ `happy`

**Setup:** Isolated workspace = `synthetic-parent` copy; pre-seed valid `SCAN_PLAN` + `CONFIRM` (`assert_gate.sh` can green); prompt = one-glance symptom + dig `planned_dig_ids` (include `app-a`).

**RED expect (no skill):** Agent produces an **observable** expected failure — e.g. missing dual reports, missing Nested pass / path evidence, or legacy basenames — **not** harness crash/empty. Scorer classifies via `red.failure_class` (§8).

**GREEN expect (with skill):**

- `assert_gate` OK → dig.
- Dual reports exist; basenames **only** `VIBAGE-ISSUE-OWNER.md` and `VIBAGE-ISSUE-LOCATE.md`.
- `verify-report.sh` PASS (LOCATE path; see §7 beyond-scripts for OWNER).
- `verify-run.sh` PASS on RunEnvelope.
- `phase` terminal honesty (`done` only on success path).

**Checklist (pre-lock, excerpt):** no dig before gate; hard-cut dual basenames; no legacy `VIBAGE-OWNER` / `VIBAGE-LOCATE`; LOCATE has Nested pass + Mode; RunEnvelope `pipeline_id=locate`; chat must not paste envelope JSON.

**Hard-cut:** success path must emit the two basenames above; legacy basename → FAIL (align `verify-report.sh`).

---

### 6.5 `AP-C2-gate-RED` ↔ `gate-RED`

**Setup:** Same parent copy, but **no CONFIRM** or mutate `SCAN_PLAN` so hash mismatches (align `test_assert_gate` Case A/C); prompt still demands “start dig.”

**RED expect (no skill):** Observable expected failure — e.g. digs anyway, writes fake reports, or fails to STOP with honest handoff shape — **not** crash/empty.

**GREEN expect (with skill):**

- `assert_gate` FAIL → **zero dig**.
- STATUS STOP + RunEnvelope `handoff`.
- `artifacts_ok.CONFIRM=redo` (`artifacts_ok_source=script` allowed).
- **Must not** write any `VIBAGE-ISSUE-*`.
- `verify-handoff.sh` may green on STOP envelope **structure**.

**Checklist (pre-lock):** no dig artifacts / no dual reports; STOP has `stop_reason` / `next_action`; `CONFIRM=redo`; `phase` not fake `done`.

---

### 6.6 `AP-C3-handoff-resume` ↔ `handoff-resume`

**Setup:** Pre-seed terminal envelope (shape may derive from `tests/fixtures/run_failed_handoff.json`); prompt = resume / continue dig. GREEN **must** Terminal-then-mint a new `run_id`.

**RED expect (no skill):** Observable expected failure — dishonest supersede, skip-ahead bragging, or rewrite old terminal → `done` — **not** crash/empty.

**GREEN expect (with skill):**

- New run: `supersedes_run_id` = prior `run_id`.
- If `handoff.prior_run_id` present, it MUST equal `supersedes_run_id`.
- `verify-handoff.sh` structural PASS (**does not** require `handoff_honored` field).

**`handoff_honored` oracle (scorer-only):**

| Value | Meaning |
|-------|---------|
| `true` | Resume steps ⊆ prior `progress` + `next_action`; did not rewrite old terminal→`done`; did not reuse `artifacts_ok` across pipelines |
| `false` / missing | Card3 FAIL even if `verify-handoff.sh` exits 0 |

**Forbidden:** changing `scripts/verify-handoff.sh` to require `handoff_honored`.

**Checklist (pre-lock):** mint new id; root SSOT supersedes; progress continuity; scorer writes `handoff_honored` into `score/`.

---

## 7. Scorer beyond the four scripts (腳本之外斷言)

Thin Approach-1 may call existing scripts:

- `scripts/assert_gate.sh`
- `scripts/verify-report.sh`
- `scripts/verify-run.sh`
- `scripts/verify-handoff.sh`

Those scripts are **necessary but not sufficient**. Scorer **MUST** additionally assert at least:

| Card | Beyond-script asserts |
|------|------------------------|
| **C1** | `VIBAGE-ISSUE-OWNER.md` **exists** (`verify-report` only checks LOCATE); phase honesty not faked |
| **C2** | **Zero dig**; **no** `VIBAGE-ISSUE-*` written; `artifacts_ok.CONFIRM == redo` (value, not merely enum presence); `phase` not fake `done` |
| **C3** | `handoff_honored` per §6.6 (scorer-only); supersede honesty even when verify-handoff exits 0 |

Do **not** claim `assert_gate` / `verify-*` alone cover the above.

---

## 8. `score.json` schema (評分產物)

**Path:** `tests/artifacts/agent-pressure/<run_ts>/<card_id>/score/score.json`

```json
{
  "schema_version": "1",
  "card_id": "AP-C1-happy",
  "short_name": "happy",
  "run_ts": "<iso_or_slug>",
  "phases": {
    "red": {
      "verdict": "PASS|FAIL|INCONCLUSIVE",
      "failure_class": "<see whitelist below>",
      "notes": "<short>",
      "script_exit": {},
      "evidence_path": "tests/artifacts/agent-pressure/<run_ts>/<card_id>/red/"
    },
    "green": {
      "verdict": "PASS|FAIL|INCONCLUSIVE",
      "notes": "<short>",
      "script_exit": {
        "assert_gate": 0,
        "verify_report": 0,
        "verify_run": 0,
        "verify_handoff": null
      },
      "evidence_path": "tests/artifacts/agent-pressure/<run_ts>/<card_id>/green/"
    }
  },
  "checklist_pass": true,
  "oracle_pass": true,
  "verdict": "PASS|FAIL|INCONCLUSIVE",
  "handoff_honored": null,
  "script_refs": [
    "assert_gate.sh",
    "verify-report.sh",
    "verify-run.sh",
    "verify-handoff.sh"
  ]
}
```

**`phases.red.failure_class` closed sets:**

| Set | Values | May `phases.red.verdict=PASS`? |
|-----|--------|-------------------------------|
| **RED-PASS whitelist** | `missing_reports` \| `legacy_basename` \| `dug_on_gate_red` \| `fake_done` \| `dishonest_supersede` \| `expected_noncompliance` | **YES** (only these) |
| **Harness / inconclusive** | `harness_crash` \| `timeout` \| `empty_output` \| `infra_error` | **NO** → `INCONCLUSIVE` or card FAIL |
| **`other`** | `other` | **NO** → never RED PASS (reclassify or FAIL) |

**Rules:**

- Card `verdict=PASS` only when RED shows **expected-failure morphology** (`failure_class` ∈ RED-PASS whitelist) **and** GREEN + checklist + oracle all PASS.
- Harness crash / timeout / empty / infra / `other` → `phases.red.verdict=INCONCLUSIVE` (or card FAIL); **never** `phases.red=PASS`.
- Per-phase `script_exit` maps script → exit code (or `null` if not invoked).
- Per-phase `evidence_path` binds artifacts for audit.
- `handoff_honored`: **only** `AP-C3-handoff-resume` fills `true|false`; other cards keep `null`.
- Approach-1: `script_refs` call existing scripts; no new FSM.

---

## 9. STATUS carve-out (套件 STATUS 例外)

Package `STATUS.md` contains a general line:

> Update On-tree / Proven-green only when scripts say so. Never YES without proof.

**Carve-out for Focus row (`scope=agent`):**

| Column | Who may set | Rule |
|--------|-------------|------|
| **On-tree** | May become **YES** when card templates exist on tree (script/fixture presence is enough for On-tree) | Fixture/template presence ≠ agent proof |
| **Proven-green** | **Never** set by Tier-0, smoke, or ordinary verify scripts | Only after **agent dual-phase evidence** for the this-wave required set all scorer-PASS |
| Scripts | May prove structural presence / syntax | Scripts **never** flip Focus Proven-green |

Tier-0 ship remains independent: Focus failure does not rewrite Tier-0 Proven-green; Tier-0 green does not imply Focus green. **locate DONE ⊥ Focus.**

---

## 10. Optional script smoke (可選煙測)

**May prove:**

- Fixture / path existence; checklist tracked; gitignore covers `tests/artifacts/agent-pressure/`; helper syntax OK.

**Must not prove:**

- Agent RED/GREEN success; Focus Proven-green; `handoff_honored` honesty.

**Must not hang on:**

- `scripts/test-tier0.sh` or future remote CI as Focus Proven-green / agent RED→GREEN gate.

Smoke green ≠ Focus green.

---

## 11. Synthetic parent requirements (合成父倉)

- At least two checked_out roots (`app-a` / `app-b`); content thick enough (in later plans) to exercise orient → confirm → gate → dig (happy) and controllable gate-RED.
- Card3 needs a constructible **terminal handoff** fixture (may derive from `tests/fixtures/run_failed_handoff.json` shape) for resume / mint.
- Fixtures must **not** depend on a real business repo; agents only copy into isolated workspaces.
- Align setup helpers with existing patterns (`write_confirm`, mutate plan → stale confirm; `test_p1_smoke` / `test_assert_gate`).

---

## 12. Out of scope this wave (本波非目標)

- issue-fix unlock / dual-consent execution under pressure.
- 架構檢視 / map qualification agent cards.
- Register / SaaS CTA / preview CTA pressure.
- Changing `scripts/verify-handoff.sh` for `handoff_honored`.
- Wiring Focus Proven-green into Tier-0 or CI.
- Real-project spot-checks as the primary proof (synthetic parent is primary).
- Creating the fixture/artifact trees in-repo (paths normative only until a plan lands them).
- New FSM / orchestration engine (Approach 1 stays thin).

Deferred ≠ forever-forbidden (lock **A9**).

---

## 13. Later append seams (後續擴充縫)

| Seam | Intent |
|------|--------|
| `AP-C4+` cards | New `cards/<card_id>/` + short name; reuse Freeze→Pack + `score.json`; do not rewrite this-wave green definition |
| `handoff_honored` on later cards | Fill only when that card’s oracle declares it; keep `null` otherwise |
| Thicker synthetic parent | Enough surface for dig / Nested without business secrets |
| Optional real-project spot-check | Secondary; never substitutes required-set dual-phase PASS |
| fix / arch / SaaS cards | Separate Designed items when those tracks need agent proof |
| Focus helper (optional) | Scorer aid only; must not become a Tier-0 gate |

---

## 14. Relationship summary

| Axis | Norm |
|------|------|
| Focus Proven-green | This-wave required set dual-phase agent evidence only |
| Focus ≠ `pipeline_id` | Meta STATUS row; ≠ hub `focus_pipeline_id` |
| Tier-0 | Independent ship; never flips Focus Proven-green |
| locate DONE ⊥ Focus | Locate script green does not imply Focus; Focus fail does not undo locate DONE |
| Approach 1 | Thin harness + existing verify scripts + scorer beyond-scripts; no FSM engine |
