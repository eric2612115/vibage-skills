# Vibage

**Find where a problem lives** in a fat / AI-built multi-repo folder — without drowning the owner in tickets.

For non-coder owners and agents on **Cursor**, **Claude Code**, and **Codex**.

## Owner path (no bash)

1. Open a chat on your **parent** folder (after someone ran one-time setup below — that someone can be the agent).  
2. Say what hurts in plain language.  
3. The agent follows **using-vibage**, runs pins/verify scripts, and routes init → orient → locate.  
4. You only answer confirm questions (CONFIRM = your OK on the scan plan).  
5. When dual reports exist, the agent offers finishing options (preview / stop) — still no register CTA.

Evidence contract: [`tests/fixtures/owner-zero-bash-path.md`](tests/fixtures/owner-zero-bash-path.md) · checklist: [`docs/LOCAL-COMPLETE-CHECKLIST.md`](docs/LOCAL-COMPLETE-CHECKLIST.md)

## 60-second start (operator / agent)

One-time setup commands — **not** what the owner must type. Replace paths with your checkout and **parent** workspace (not each child repo):

```bash
# 1) Install skills (Cursor + Claude + Codex)
bash /path/to/vibage-skills/scripts/install.sh

# 2) Parent session routers (required — global skills alone are not enough)
bash /path/to/vibage-skills/scripts/install.sh \
  --with-project-rule=/path/to/parent-workspace

# 3) Prove routers are on disk
bash /path/to/vibage-skills/scripts/verify-project-entry.sh \
  /path/to/parent-workspace
# expect: PROJECT_ENTRY_OK
```

Optional paste for agents: [`prompts/NEW-CHAT.md`](prompts/NEW-CHAT.md).

Per-surface notes: [`docs/install/CURSOR.md`](docs/install/CURSOR.md) · [`docs/install/CLAUDE.md`](docs/install/CLAUDE.md) · [`docs/install/CODEX.md`](docs/install/CODEX.md)

### What you get

1. Scan plan you can confirm in plain language  
2. Dual reports: owner brief + engineer locate (paths / evidence)  
3. Optional later: issue-fix / 架構檢視 (not required for locate done)

### Honesty (short)

- Local proof ship gate: `bash scripts/test-tier0.sh` → `TIER0_OK`  
- Pack health (pins + parent entry + entry docs): `bash scripts/pack-health.sh /path/to/parent` → `PACK_HEALTH_OK` (**≠** Tier-0)  
- Capability truth: [`STATUS.md`](STATUS.md) (not this README)  
- Checklist: [`docs/LOCAL-COMPLETE-CHECKLIST.md`](docs/LOCAL-COMPLETE-CHECKLIST.md) · optional proof: [`SAT-optional-proof`](docs/superpowers/specs/satellites/SAT-optional-proof.md)  
- SaaS / register: **blank** — [`SAT-saas-blank`](docs/superpowers/specs/satellites/SAT-saas-blank.md) · ≠ SaaS shipped  
- No git remote here → remote CI **SKIPPED** · ≠ publish-ready  
- `PROJECT_ENTRY_OK` ≠ “scan confirmed” ≠ “locate finished”

---

## Status / deeper docs

**Capability / phase SSOT → [`STATUS.md`](STATUS.md).**  
Agents must read package `STATUS.md` before expanding scope from this README.

Do **not** treat README as a second phase table. Plan-index ids live under `docs/superpowers/plans/`. For letter C, path-to-B, letter B, maps, CI SKIPPED, SaaS blank — see `STATUS.md` only.

**Spec:** `docs/superpowers/specs/2026-07-23-vibage-v2-superpowers-grade-design.md`  
**Plans:** `docs/superpowers/plans/2026-07-23-vibage-v2-plan-index.md`

This package is a **sibling** to SelfAutoBuz (OPC hub). Product SSOT lives here.

## Install (details)

```bash
bash /path/to/vibage-skills/scripts/install.sh
# default --surfaces=cursor,claude,codex

bash /path/to/vibage-skills/scripts/install.sh \
  --with-project-rule=/path/to/parent-workspace \
  --project-skills=/path/to/parent-workspace \
  --init-hub=/path/to/parent-workspace

bash /path/to/vibage-skills/scripts/verify-pins.sh
bash /path/to/vibage-skills/scripts/resolve-pkg-root.sh
```

| Surface | Global skills | Thin parent entry |
|---------|---------------|-------------------|
| Cursor | `~/.cursor/skills/` | `.cursor/rules/vibage.mdc` + sessionStart hooks + `AGENTS.md` block |
| Claude Code | `~/.claude/skills/` | `CLAUDE.md` block + `.claude/vibage-entry.md` |
| Codex | `$HOME/.agents/skills/` | `AGENTS.md` block |

- Global skill links refresh via `ln -sfn`.
- Project skills: skip + **WARN** if stale/foreign; `--force` only replaces package-owned stale **symlinks**.
- Superpowers: one git checkout at pin SHA; `verify-pins.sh` probes all three homes.
- Host-best session injection: [`references/host-best-session-entry.md`](references/host-best-session-entry.md).

## Skill routing (agents)

1. No hub `docs/vibage/STATUS.md` → `vibage-init`  
2. Hub ready, no valid CONFIRM (= owner OK on the scan plan) → `vibage-orient`  
3. CONFIRM OK → `vibage-issue-locate`  
4. Unclear install → `vibage-bootstrap` → init · session pointer → `using-vibage`  
5. Optional: `vibage-issue-fix`, `vibage-arch-review`

Package capability SSOT is root `STATUS.md` (not the hub file).

**Rename note:** skill dir is `vibage-issue-locate`. Legacy symlink `vibage-locate` remains for one release.

Hard stops: [`references/hard-stops.md`](references/hard-stops.md).

## Layout

| Path | Role |
|------|------|
| `skills/` + `MANIFEST.txt` | using-vibage, init, bootstrap, issue-locate, orient, optional fix/arch, survey, section-gate |
| `adapters/` | Cursor `.mdc` + hooks, Claude / AGENTS thin entries |
| `prompts/NEW-CHAT.md` | Optional owner paste dispatcher |
| `docs/install/` | Per-surface short install |
| `references/` | hard-stops, host-best, hub templates, report templates |
| `scripts/install.sh` | Multi-surface install + parent entry |
| `scripts/verify-project-entry.sh` | Parent routers green |
| `scripts/test-tier0.sh` | Local ship gate |
| `STATUS.md` | Capability / phase SSOT (package) |
| `DEPENDENCIES.md` | Pinned `superpowers_sha=` |

## Hard product locks

- Match owner language; never hardcode zh-TW.
- Nested investigators → reviewers when platform allows; else honest `Mode: degraded`.
- Dual artifacts after reports; no register CTA on local happy path.
- No customer cloud root keys; Markdown SSOT.

## License

MIT — see `LICENSE`. Copyright holder: Eric Fang.
