# vibage-skills

Shared skills for **Vibage**: help non-coder owners of fat / AI-built repos find *where* a problem lives — hub init → scan confirm → dual reports (owner brief + engineer locate), nested investigation when the host supports it, pinned [superpowers](https://github.com/obra/superpowers).

**First-wave surfaces:** Cursor, Claude Code, Codex (shared SSOT + thin adapters).  
This is a **sibling package** to SelfAutoBuz (OPC hub). Product SSOT lives here; SelfAutoBuz only keeps research + install pointers.

**Spec (live):** `docs/superpowers/specs/2026-07-23-vibage-v2-superpowers-grade-design.md`  
**Plans (live):** `docs/superpowers/plans/2026-07-23-vibage-v2-plan-index.md`  
**Local proof (this-wave ship):** `bash scripts/test-tier0.sh`

## Status / roadmap（先讀）

**Capability / phase SSOT → [`STATUS.md`](STATUS.md).**  
Agents starting a new session must read package `STATUS.md` before expanding scope from this README.

Do **not** treat README as a second phase table. Plan-index ids (e.g. `P2-tier0-entry`) live under `docs/superpowers/plans/`; they are not README phase labels. For letter C, path-to-B, letter B agent-proven, maps (Plan G–L), CI SKIPPED, and SaaS **blank**, see `STATUS.md` only.

SaaS / register is reserved blank — thin contract: `docs/superpowers/specs/satellites/SAT-saas-blank.md` (no local register CTA; ≠ SaaS shipped).

## Install (global — three surfaces)

```bash
bash /path/to/vibage-skills/scripts/install.sh
# default --surfaces=cursor,claude,codex

bash /path/to/vibage-skills/scripts/install.sh \
  --with-project-rule=/path/to/your-repo \
  --project-skills=/path/to/your-repo \
  --init-hub=/path/to/your-repo

bash /path/to/vibage-skills/scripts/install.sh \
  --surfaces=claude,codex \
  --project-skills=/path/to/your-repo --force

bash /path/to/vibage-skills/scripts/verify-pins.sh
bash /path/to/vibage-skills/scripts/resolve-pkg-root.sh
```

| Surface | Global skills | Project skills | Thin entry |
|---------|---------------|----------------|------------|
| Cursor | `~/.cursor/skills/` | `.cursor/skills/` | `.cursor/rules/vibage.mdc` + `AGENTS.md` block |
| Claude Code | `~/.claude/skills/` | `.claude/skills/` | `CLAUDE.md` block + `.claude/vibage-entry.md` |
| Codex | `$HOME/.agents/skills/` | `.agents/skills/` | `AGENTS.md` block |

- Global skill links always refresh via `ln -sfn`.
- Project skills: skip + **WARN** if stale/foreign; `--force` only replaces package-owned stale **symlinks**.
- Superpowers: one git checkout at the pin SHA; symlink into each skill home. `verify-pins.sh` probes all three.

Then paste [`prompts/NEW-CHAT.md`](prompts/NEW-CHAT.md) into a new agent chat.

## PKG_ROOT

```bash
bash /path/to/vibage-skills/scripts/resolve-pkg-root.sh
```

Probe order: `~/.cursor/skills` → `~/.claude/skills` → `~/.agents/skills`; `vibage-init` then `vibage-issue-locate` (legacy `vibage-locate` redirect for one release).

## Skill routing

1. No hub `docs/vibage/STATUS.md` → `vibage-init`
2. Hub ready, no valid CONFIRM → `vibage-orient`
3. CONFIRM OK → `vibage-issue-locate`
4. NEW-CHAT / unclear install → `vibage-bootstrap` → init
5. Optional (not required for locate DONE): `vibage-issue-fix`, `vibage-arch-review` (架構檢視)

Package capability SSOT is root `STATUS.md` (not the hub file above).

**Rename note:** skill dir is `vibage-issue-locate`. `scripts/install.sh` still symlinks legacy name `vibage-locate` → `vibage-issue-locate` for one release.

Hard stops SSOT: [`references/hard-stops.md`](references/hard-stops.md).

## Layout

| Path | Role |
|------|------|
| `skills/` + `MANIFEST.txt` | init, bootstrap, issue-locate, orient, optional fix/arch, survey, section-gate |
| `adapters/` | Cursor `.mdc`, Claude / AGENTS thin entries |
| `prompts/NEW-CHAT.md` | Owner paste dispatcher |
| `references/` | hard-stops, nested-protocol, hub templates, report templates |
| `rules/vibage-locate.mdc` | Legacy thin rule (prefer adapters/cursor) |
| `scripts/install.sh` | Multi-surface install + optional hub |
| `scripts/resolve-pkg-root.sh` | Portable PKG_ROOT |
| `scripts/verify-pins.sh` | Superpowers pin (multi-home) |
| `scripts/assert_gate.sh` / `write_confirm.sh` | Orient → locate gate |
| `DEPENDENCIES.md` | Pinned `superpowers_sha=` |
| `docs/archive/` | Retired pre-v2 docs (not live proof) |
| `STATUS.md` | Capability / phase SSOT (package) |

## Hard product locks

- Match owner language; never hardcode zh-TW.
- Nested investigators → fresh reviewers → synthesize when platform allows; else honest `Mode: degraded`.
- Dual artifacts after reports; no cloud wall on local delivery; TBD site → graceful degrade.
- No customer cloud root keys; Markdown SSOT.

## License

MIT — see `LICENSE`. Copyright holder: `[TBD — Eric to fill]`.
