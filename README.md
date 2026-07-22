# war-room-skills

Shared Cursor skills for **War Room Locate**: help non-coder owners of fat / AI-built repos find *where* a problem lives — dual reports (owner brief + engineer locate), nested investigation, pinned [superpowers](https://github.com/obra/superpowers).

This is a **sibling package** to SelfAutoBuz (OPC hub). Product SSOT lives here; SelfAutoBuz only keeps research + install pointers.

## Status / roadmap（先讀）

**接續進度、Phase 邊界、能力對照表 → [`STATUS.md`](STATUS.md)。**  
Agents starting a new session should read `STATUS.md` before expanding scope.

| Phase | Meaning | Now |
|-------|---------|-----|
| **V0** | Single-/few-root locate + dual reports | **Shipped** (this package) |
| **P1** | Parent-folder OS: init → scan plan → confirm → locate; footprints; local preview; survey + section-gate skills | **Designing** |
| **P2** | Graphify-class map, coverage gates, long-task + AUTO_DECIDED | Later |
| **P3** | Cloud Pro / richer results after signup (`war-room-app`) | Later |

Do not treat Harden-2 bullets below as the full roadmap — Phase table in `STATUS.md` supersedes when they conflict.

## Install (global)

```bash
bash /path/to/war-room-skills/scripts/install.sh
bash /path/to/war-room-skills/scripts/install.sh \
  --with-project-rule=/path/to/your-repo \
  --project-skills=/path/to/your-repo
# If project skill dirs already exist but are NOT symlinks to this package:
bash /path/to/war-room-skills/scripts/install.sh \
  --project-skills=/path/to/your-repo --force
bash /path/to/war-room-skills/scripts/verify-pins.sh
```

- Global `~/.cursor/skills/war-room-*` always refreshes via `ln -sfn`.
- Project skills: skip + **WARN** if stale/foreign; use `--force` to replace with package symlink.

Then paste [`prompts/NEW-CHAT.md`](prompts/NEW-CHAT.md) into a new Agent chat.

## PKG_ROOT

After install, agents resolve the package root via:

```bash
python3 -c 'import os; print(os.path.dirname(os.path.dirname(os.path.realpath(os.path.expanduser("~/.cursor/skills/war-room-locate")))))'
```

## Layout

| Path | Role |
|------|------|
| `skills/war-room-locate/` | Main locate skill |
| `skills/war-room-bootstrap/` | Cold-start / install handoff |
| `prompts/NEW-CHAT.md` | Owner paste prompt |
| `references/` | Nested protocol, templates, no-docs cold start, vibe-debt smells, `feature-call.md` (Soft CTA → web) |
| `examples/` | Synthetic golden `WAR-ROOM-*.md` (not real customer data) |
| `rules/war-room-locate.mdc` | Thin hard-stops rule |
| `scripts/install.sh` | Global (+ optional project) install |
| `scripts/verify-pins.sh` | Superpowers pin check |
| `scripts/verify-report.sh` | Report checklist (not proof of nested) |
| `DEPENDENCIES.md` | Pinned `superpowers_sha=` |
| `coverage/` | Blind-test / coverage logs |
| `STATUS.md` | Phase map, capability matrix, design locks, next steps |
| `docs/superpowers/specs/2026-07-22-war-room-os-p1-design.md` | P1 OS + locate pipeline design (approved draft → spec-review) |

### Done in Harden / V1 must-fix（= V0）

- Capability branching in locate + owner template + NEW-CHAT
- No-docs cold start, vibe-debt smells, verify-report, golden examples
- Pin recovery owner-language; honest `Mode: full nested` vs degraded

### Harden-2 (later)

- Deeper multi-root service-map template
- Stronger nested audit than checklist (still cannot fully prove subagent dispatch)
- Pin UX polish inside `verify-pins.sh` messages

## Hard product locks

- Match owner language; never hardcode zh-TW.
- Nested investigators → fresh reviewers → synthesize (MUST).
- Dual artifacts; soft CTA after reports; no signup wall; TBD site → graceful degrade.
- No customer cloud root keys; Markdown SSOT; HTML optional later.

## P1 parent hub (quick)

```bash
bash scripts/install.sh --init-hub="/abs/path/to/parent-folder"
# then in Cursor: paste prompts/NEW-CHAT.md — init → orient → confirm → locate
# preview: bash scripts/serve-preview.sh "/abs/path/to/parent-folder"
```

## License

MIT — see `LICENSE`. Copyright holder: `[TBD — Eric to fill]`.
