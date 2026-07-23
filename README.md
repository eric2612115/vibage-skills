# vibage-skills

Shared skills for **Vibage**: help non-coder owners of fat / AI-built repos find *where* a problem lives — hub init → scan confirm → dual reports (owner brief + engineer locate), nested investigation when the host supports it, pinned [superpowers](https://github.com/obra/superpowers).

**First-wave surfaces:** Cursor, Claude Code, Codex (shared SSOT + thin adapters).  
This is a **sibling package** to SelfAutoBuz (OPC hub). Product SSOT lives here; SelfAutoBuz only keeps research + install pointers.

**Spec (live):** `docs/superpowers/specs/2026-07-23-vibage-v2-superpowers-grade-design.md`  
**Plans (live):** `docs/superpowers/plans/2026-07-23-vibage-v2-plan-index.md`  
**Local proof (this-wave ship):** `bash scripts/test-tier0.sh`

## Status / roadmap（先讀）

**接續進度、Phase 邊界、能力對照表 → [`STATUS.md`](STATUS.md)。**  
Agents starting a new session should read `STATUS.md` before expanding scope.

| Phase | Meaning | Now |
|-------|---------|-----|
| **V0** | Single-/few-root locate + dual reports | **Shipped** |
| **P1** | Parent-folder OS: init → orient → confirm → locate; footprints; preview; survey + section-gate | **Skills on MAIN** + multi-IDE install |
| **P2** | Graphify-class map, coverage gates, long-task + AUTO_DECIDED | Later |
| **P3** | Cloud Pro / richer results (`vibage-app`) | Later |

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

Probe order: `~/.cursor/skills` → `~/.claude/skills` → `~/.agents/skills`; `vibage-init` then `vibage-locate`.

## Skill routing

1. No `docs/vibage/STATUS.md` → `vibage-init`
2. Hub ready, no valid CONFIRM → `vibage-orient`
3. CONFIRM OK → `vibage-locate`
4. NEW-CHAT / unclear install → `vibage-bootstrap` → init
5. SelfAutoBuz doc hygiene → `docs-hygiene` (not locate)

Hard stops SSOT: [`references/hard-stops.md`](references/hard-stops.md).

## Layout

| Path | Role |
|------|------|
| `skills/` + `MANIFEST.txt` | init, bootstrap, locate, orient, survey, section-gate |
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
| `STATUS.md` | Phase map |

## Hard product locks

- Match owner language; never hardcode zh-TW.
- Nested investigators → fresh reviewers → synthesize when platform allows; else honest `Mode: degraded`.
- Dual artifacts after reports; no cloud wall on local delivery; TBD site → graceful degrade.
- No customer cloud root keys; Markdown SSOT.

## License

MIT — see `LICENSE`. Copyright holder: `[TBD — Eric to fill]`.
