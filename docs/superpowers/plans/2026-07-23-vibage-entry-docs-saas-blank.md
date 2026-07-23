# Plan-E — Entry docs sync + SAT-saas-blank

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align README / NEW-CHAT / adapters with package `STATUS.md`, add thin `SAT-saas-blank` on tree, keep Tier-0 green — without flipping SaaS YES or adding CTAs.

**Architecture:** Approach A from `docs/superpowers/specs/2026-07-23-vibage-entry-docs-saas-blank-design.md`. STATUS firewall; dual-STATUS naming; UploadManifest stub SSOT chain documented only; optional sync test ∉ Tier-0.

**Tech Stack:** Markdown, Bash (rg), existing Tier-0.

**Design SSOT:** `docs/superpowers/specs/2026-07-23-vibage-entry-docs-saas-blank-design.md`

---

## Files

| Path | Action |
|------|--------|
| `docs/superpowers/specs/satellites/SAT-saas-blank.md` | Create |
| `README.md` | Replace Phase table with STATUS pointer; fix docs-hygiene; no CTA |
| `prompts/NEW-CHAT.md` | Package STATUS first; dual-STATUS; no CTA |
| `adapters/cursor/vibage.mdc` | docs-hygiene SelfAutoBuz-only or remove; drop soft CTA |
| `adapters/claude/CLAUDE.vibage.md` | same |
| `adapters/codex/AGENTS.vibage.md` | same |
| `adapters/shared/AGENTS.vibage.md` | same |
| `STATUS.md` | Optional one-liner pointer to SAT-saas-blank; SaaS row stays blank |
| `tests/test_entry_docs_sync.sh` | Create; **not** in Tier-0 |
| `docs/superpowers/plans/2026-07-23-vibage-v2-plan-index.md` | Add Plan-E row |

---

### Task 1: Optional failing sync test

**Files:**
- Create: `tests/test_entry_docs_sync.sh`

- [x] **Step 1: Write test that fails on current tree**

Assert (PKG_ROOT = repo root):

1. `docs/superpowers/specs/satellites/SAT-saas-blank.md` exists.
2. `README.md` and `prompts/NEW-CHAT.md` mention package `STATUS.md`.
3. README must **not** contain a Phase row claiming **P2** Graphify/Later (anti-fake-green) — e.g. fail if `rg -n '^\| \*\*P2\*\*.*Graphify|^\| \*\*P2\*\*.*Later' README.md` matches, OR require README Capability section with “see STATUS.md” and no colliding P2 Graphify Later table.
4. Entry CTA denylist on `README.md` + `prompts/NEW-CHAT.md` + four adapter files: fail on positive register/pairing/API-key CTA phrases; **allow** “no register CTA”, “blank”, “deferred”.
5. Phantom: fail if any of those files still route SelfAutoBuz hygiene to bare `` `docs-hygiene` `` / `**docs-hygiene**` without “SelfAutoBuz-only” / “not a vibage skill” qualifier — prefer **remove** the routing line entirely.
6. Must print `ENTRY_DOCS_SYNC_OK` on success.
7. Confirm `scripts/test-tier0.sh` does **not** invoke this test.

- [x] **Step 2: Run test — expect FAIL before edits**

```bash
bash tests/test_entry_docs_sync.sh; echo exit:$?
```

---

### Task 2: SAT-saas-blank

**Files:**
- Create: `docs/superpowers/specs/satellites/SAT-saas-blank.md`

- [x] **Step 1: Write thin SAT** with sections:

1. This-wave rule (reserved blank; no local CTA)
2. Normative locks vs non-normative blanks (later-thicken)
3. UploadManifest stub SSOT: `references/hub/UploadManifest.stub.json` → install → hub `docs/vibage/UploadManifest.stub.json` (document only; stub ≠ upload)
4. Architecture Pass ≠ local 架構檢視 / `service_map`
5. STATUS firewall: SaaS row stays blank; thin SAT ≠ YES
6. Out of scope / deferred≠forever-ban / no shape freeze

Mirror tone of `SAT-ci-remote.md` (short).

---

### Task 3: Entry + adapter edits

**Files:** README, NEW-CHAT, four adapters, optional STATUS pointer

- [x] **Step 1: README** — Replace Phase table with short “Capability / phase → see STATUS.md” (mention letter C / path-to-B / letter B / maps G–L only as “see STATUS”, not invent new README `P*` SSOT). Remove `docs-hygiene` routing line (or SelfAutoBuz-only one-liner). Keep Tier-0 / Spec / Plans links. No register CTA. Soften or remove “P3 Cloud Pro Later” inventing product — point SaaS to STATUS blank + SAT-saas-blank.

- [x] **Step 2: NEW-CHAT** — After cold-start Spec/Plans, add: read package `STATUS.md` (capability SSOT) before expanding scope; note hub `docs/vibage/STATUS.md` is init/orient only. No CTA. Stay thin dispatcher.

- [x] **Step 3: Adapters** — Remove docs-hygiene phantom routing; remove “Soft CTA after dual reports…” lines that imply product CTA. Keep skill routing 1–4 + optional fix/arch if listed.

- [x] **Step 4: STATUS.md** — One optional line under SaaS row: pointer to `SAT-saas-blank`; cells stay blank / —.

- [x] **Step 5: Re-run sync test → ENTRY_DOCS_SYNC_OK**

- [x] **Step 6: `bash scripts/test-tier0.sh` → TIER0_OK**

---

### Task 4: Plan index + commit

- [x] **Step 1:** Add ordered plan row `Plan-E` after Plan-L in plan-index.
- [ ] **Step 2:** Commit with message focused on entry honesty + reserved SaaS blank (no push). *(awaiting user ask)*

---

## DoD

1. `SAT-saas-blank.md` on tree; STATUS SaaS still blank.
2. README/NEW-CHAT/adapters aligned; no phantom docs-hygiene; no register CTA.
3. `tests/test_entry_docs_sync.sh` → `ENTRY_DOCS_SYNC_OK` and **not** in Tier-0.
4. `bash scripts/test-tier0.sh` → `TIER0_OK`.
5. ≠ SaaS shipped ≠ publish-ready ≠ score slogan.

## Honesty

STATUS firewall; dual-STATUS; UploadManifest stub chain only; Architecture Pass ≠ 架構檢視; deferred≠forever-ban.
