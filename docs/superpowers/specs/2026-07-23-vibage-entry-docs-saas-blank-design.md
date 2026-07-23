# Vibage — Entry docs sync + SAT-saas-blank (Design)

**Date:** 2026-07-23  
**Status:** Design absorbed eng/ext must_fix; Approach **A** locked; ready for plan  
**Package SSOT:** `/Users/eric.fang/MindOwnBuz/vibage-skills`  
**Umbrella:** `docs/superpowers/specs/2026-07-23-vibage-v2-superpowers-grade-design.md` (§4.4, D4, §11.1)  
**Plan index:** `docs/superpowers/plans/2026-07-23-vibage-v2-plan-index.md` (satellite row already lists `SAT-saas-blank`)  
**Package STATUS:** `STATUS.md` (capability SSOT — firewall applies)

This file is the **thin design** for entry-doc honesty + reserved SaaS blank. Implementation follows a later small plan. **Do not** treat this design alone as SaaS shipped or score-slogan complete.

---

## 1. Problem

Entry surfaces (`README.md`, `prompts/NEW-CHAT.md`) drift from package `STATUS.md` and the live plan index:

1. **README Phase table** still frames **P2** as “Graphify-class map… Later,” colliding with plan-index id **`P2-tier0-entry`** (already shipped) and understating C / path-to-B / letter B / Plan G–L map reality.
2. **Phantom `docs-hygiene` routing** in README skill routing looks like a vibage product skill; it is SelfAutoBuz-only if kept.
3. **`NEW-CHAT.md`** is a thin dispatcher but does not force reading package `STATUS.md` first; risk of agents expanding scope from stale README phases.
4. **Plan index** promises satellite **`SAT-saas-blank`**, but the file is missing on tree — empty commitment vs umbrella §11.1 reserved seams.
5. Soft risk: readers infer register / cloud / Architecture Pass from local copy, contradicting **no register CTA** (umbrella §4.4 / D4).

---

## 2. Goals

**Approach A (locked):** thin `SAT-saas-blank` + sync README + NEW-CHAT to STATUS.

1. Entry docs tell the **same story** as `STATUS.md` (or explicitly defer with “see STATUS.md”).
2. On-tree thin satellite `docs/superpowers/specs/satellites/SAT-saas-blank.md` matching the plan-index row (already named).
3. No local register / pairing / API-keys CTA in entry paths.
4. Keep `bash scripts/test-tier0.sh` → `TIER0_OK` (no Tier-0 body change required for success).
5. Optional regression: `tests/test_entry_docs_sync.sh` (rg / presence checks) — **not** wired into Tier-0.

---

## 3. Non-goals (Out)

| Out | Why |
|-----|-----|
| Cloud / register / pairing / API keys / upload implementation | Next phase only |
| Tier-0 or verify script body changes | Ship gate already green; this wave is docs + blank SAT |
| Agent-pressure re-runs; Focus / letter B evidence rewrite | STATUS firewall |
| Dual-track commercial long docs / brand rewrite | Scope creep (Approach C rejected) |
| Flipping SaaS Designed / On-tree / Proven to YES | Thin SAT ≠ SaaS green |
| Claiming publish-ready, remote CI, or “score ≥ 9” slogans | Honesty |

**Deferred ≠ forever-ban:** next-phase may thicken `SAT-saas-blank` and cloud product; stubs must not freeze future cloud shape.

---

## 4. Design

### 4.1 STATUS firewall (normative)

Entry sync **only aligns or points to** package `STATUS.md`.

| Allowed | Forbidden |
|---------|-----------|
| Point readers to STATUS for capability / phase truth | Rewrite Proven-green cells |
| Add one STATUS pointer line to `SAT-saas-blank` (optional, thin) | Rewrite letter B / path-to-B / Focus evidence packs |
| Keep SaaS / register row **`blank` / `—`** | Set SaaS Designed/On-tree/Proven=YES because SAT file exists |

**Rule:** Thin SAT on tree **≠** SaaS Designed / On-tree / Proven = YES.

### 4.2 SAT-saas-blank — minimum contract

New file: `docs/superpowers/specs/satellites/SAT-saas-blank.md` (thin; English).

Absorb umbrella **§11.1**, **D4**, **§4.4**:

| Requirement | Detail |
|-------------|--------|
| No local CTA | No register / pairing / API keys copy in local happy path, errors, or entry docs |
| UploadManifest stub | Schema stub only (`docs/vibage/UploadManifest.stub.json` / hub copy) — **no upload** |
| Name boundary | Cloud **Architecture Pass** ≠ local **架構檢視 / Service map** (`service_map`) |
| Thicken later | Next-phase may expand this SAT; this wave stays blank/reserve |
| Deferred ≠ forever-ban | Explicit; blanks are intentional seams |
| No shape freeze | Stub must **not** lock future cloud product APIs, pricing, or UX |

Plan-index satellite table already has: `| SAT-saas-blank | Anytime; no local CTA |` — keep; do not invent a second SSOT.

### 4.3 Entry drift fix list

#### README.md

1. **Phase table:** Resolve collision with plan-index **`P2-tier0-entry`**.
   - Prefer: rename/relabel README phases so **P2** is not “maps Later,” **or** replace the Phase table with a short “Capability / phase → see STATUS.md” pointer aligned to C / path-to-B / letter B / maps (Plan G–L).
   - Do not leave readers thinking Tier-0 entry or path-to-B work is “all Later.”
2. **`docs-hygiene`:** Remove from vibage skill routing, **or** relabel **SelfAutoBuz-only** (not a vibage locate skill).
3. Keep hard locks: no register CTA; Tier-0 as local proof entry; link STATUS first.

#### prompts/NEW-CHAT.md

1. Stay a **thin dispatcher** (no nested locate procedure paste).
2. **Read package `STATUS.md` first** (capability SSOT at package root) after PKG_ROOT resolve / pins — **before** expanding scope from README phases.
3. **Dual-STATUS rule (normative):** package `STATUS.md` = capability / phase truth; hub `docs/vibage/STATUS.md` = init/orient hub only. Do not mix names in dispatcher copy.
4. Routing consistent with README (init → orient → issue-locate; optional fix/arch).
5. **No CTA** (register / cloud / pairing).

#### STATUS.md (pointer only)

Optional one-liner under SaaS blank row pointing at `SAT-saas-blank` — **without** flipping blank cells to YES.

#### Adapters (`docs-hygiene` scope)

Same wave: fix thin adapter entry surfaces that repeat phantom `docs-hygiene` (e.g. `AGENTS.md` / Claude / Codex adapter stubs if present), **or** document residual phantom as explicit Non-goal. Prefer fix in-wave so README-only edit is not a false closed loop.

### 4.4 Optional test (not Tier-0)

`tests/test_entry_docs_sync.sh` (optional):

- Assert `SAT-saas-blank.md` exists.
- Assert README / NEW-CHAT point at package `STATUS.md`.
- **Anti-fake-green:** must **fail** current README `P2` = Graphify/Later collision (or equivalent), not merely “links STATUS” (README already links STATUS).
- CTA denylist on entry set: **at least** `README.md` + `prompts/NEW-CHAT.md` (adapters in/out must be explicit in the plan). Allow **negative / deferred** phrasing (“no register CTA”, “deferred”) — do not kill honesty seams.
- Prefer README “see STATUS.md” / drop inventing new README `P*` ids that re-collide with plan-index.
- **Must not** be added to `scripts/test-tier0.sh`.

Success of this design wave still requires existing `TIER0_OK` after doc edits (untouched Tier-0 semantics).

### 4.6 SAT later-thicken contract (normative structure)

Thin `SAT-saas-blank.md` MUST separate:

| Block | Role |
|-------|------|
| **Normative locks** | No local CTA; Architecture Pass ≠ 架構檢視 / `service_map`; UploadManifest stub ≠ upload; STATUS SaaS stays blank; thin SAT ≠ SaaS YES |
| **Non-normative blanks** | Next-phase may thicken cloud product, APIs, UX — intentionally empty now |

**UploadManifest stub SSOT chain (locked):** package `references/hub/UploadManifest.stub.json` → install → hub `docs/vibage/UploadManifest.stub.json`. This wave **documents** that chain only — no second stub schema / path.

**README Phase preference (locked):** prefer “Capability / phase → see STATUS.md” over permanently aligning README phase numbers to plan-index `P*` (avoids future plan renumber drag).

### 4.5 Approach comparison (locked choice)

| Approach | Summary | Decision |
|----------|---------|----------|
| **A** | Thin design + `SAT-saas-blank` + README/NEW-CHAT sync; optional entry sync test | **Locked** |
| B | Entry edits only, no SAT | Rejected — plan-index empty promise remains |
| C | Brand / whole-docs rewrite | Rejected — out of scope |

---

## 5. Files

| Path | Action |
|------|--------|
| `docs/superpowers/specs/2026-07-23-vibage-entry-docs-saas-blank-design.md` | This design (create) |
| `docs/superpowers/specs/satellites/SAT-saas-blank.md` | Create (thin contract) |
| `README.md` | Edit Phase table + docs-hygiene + STATUS alignment |
| `prompts/NEW-CHAT.md` | Edit: STATUS-first; no CTA; thin dispatcher |
| `STATUS.md` | Optional pointer only; **firewall** |
| `tests/test_entry_docs_sync.sh` | Optional create; **not** Tier-0 |
| `docs/superpowers/plans/2026-07-23-vibage-v2-plan-index.md` | No change required for satellite **name** (already lists `SAT-saas-blank`); later plan may add an ordered plan row if needed |

**Out of file touch for this wave:** cloud app code, `scripts/test-tier0.sh` body, verify scripts, Focus evidence, agent-pressure packs.

---

## 6. Success criteria (auditable)

1. Entry docs (`README`, `NEW-CHAT`) **do not contradict** `STATUS.md` on shipped vs Later / blank SaaS.
2. Thin `SAT-saas-blank.md` **on tree**; plan-index reference remains valid.
3. **No** local register / pairing / API-keys CTA in entry paths.
4. `bash scripts/test-tier0.sh` still ends with **`TIER0_OK`**.
5. Optional `test_entry_docs_sync.sh` green if present — still **≠** Tier-0 membership.

**Explicitly not success:**

- ≠ average-score / “pull past 9” slogan complete  
- ≠ publish-ready / remote CI  
- ≠ SaaS shipped  

---

## 7. Honesty

- Package STATUS remains SSOT for Designed / On-tree / Proven-green.
- Thin SaaS satellite = **reserved seam**, not product delivery.
- Local **架構檢視 / service_map** remains distinct from cloud **Architecture Pass**.
- UploadManifest stub presence ≠ upload capability.
- `deferred ≠ forever-ban`; stub ≠ freeze of future cloud shape.
- This design does **not** change letter B, Focus Proven-green, or Tier-0 meaning.

---

## 8. Frozen §1 locks (index)

| ID | Lock |
|----|------|
| A0 | Approach A |
| A1 | STATUS firewall — align/point only; no Proven / B / Focus rewrite |
| A2 | SaaS row stays blank; thin SAT ≠ SaaS YES |
| A3 | SAT minimum: no CTA; UploadManifest stub SSOT chain only; Architecture Pass ≠ 架構檢視; thicken OK; deferred≠forever-ban; no shape freeze |
| A4 | README prefer “see STATUS.md”; do not permanently bind README `P*` to plan-index |
| A5 | `docs-hygiene` remove/SelfAutoBuz-only in README **and** adapters same wave (or explicit Non-goal residual) |
| A6 | NEW-CHAT thin dispatcher; **package** STATUS first; dual-STATUS rule; no CTA |
| A7 | Optional `test_entry_docs_sync.sh` ∉ Tier-0; anti-fake-green on P2 collision; denylist allows negative CTA phrasing |
| A8 | Out: cloud impl, Tier-0/verify body, agent-pressure re-runs, dual-track long docs |
| A9 | Success ≠ score slogan ≠ publish-ready ≠ SaaS shipped |
| A10 | SAT later-thicken: normative locks vs non-normative blanks (structure required) |
| A11 | CTA entry set: README + NEW-CHAT minimum; adapters scope explicit in plan |
