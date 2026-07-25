# Pins (do not use floating latest)

| dep | pin | path |
|-----|-----|------|
| superpowers | 363923f74aa9cd7b470c0aaa73dee629a8bfdc90 | `~/.cursor/skills/superpowers` (also accept `~/.claude/skills/superpowers`, `$HOME/.agents/skills/superpowers`) |
| ripgrep | **required on PATH** as `rg` (presence; not SHA-pinned) | system package / Homebrew / CI image — **not** a zsh shell-function-only shim |

# Machine-readable (verify-pins.sh parses these lines):
superpowers_sha=363923f74aa9cd7b470c0aaa73dee629a8bfdc90
ripgrep=required

Nested investigation uses the host agent's subagent API when available (Cursor Task, Claude Code Agent, Codex subagents). No separate pin. If nested dispatch is unavailable → `Mode: degraded` (legitimate success).
Graphify / other tools: not required for v1.

**ripgrep honesty:** tests that call `rg` source `scripts/lib/require_rg.sh` (fail-closed). A missing `rg` must exit 1 — never treat empty stdout as “no slogan hits.” Presence check ≠ semantic coverage of slogans.

Recommended install: one git checkout of obra/superpowers at the pin SHA, then symlink that directory into each skill home you use.
