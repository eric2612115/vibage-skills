# Pins (do not use floating latest)

| dep | pin | path |
|-----|-----|------|
| superpowers | 363923f74aa9cd7b470c0aaa73dee629a8bfdc90 | `~/.cursor/skills/superpowers` (also accept `~/.claude/skills/superpowers`, `$HOME/.agents/skills/superpowers`) |

# Machine-readable (verify-pins.sh parses this line):
superpowers_sha=363923f74aa9cd7b470c0aaa73dee629a8bfdc90

Nested investigation uses the host agent's subagent API when available (Cursor Task, Claude Code Agent, Codex subagents). No separate pin. If nested dispatch is unavailable → `Mode: degraded` (legitimate success).
Graphify / other tools: not required for v1.

Recommended install: one git checkout of obra/superpowers at the pin SHA, then symlink that directory into each skill home you use.
