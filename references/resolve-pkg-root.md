# Resolve PKG_ROOT (portable)

Never hardcode `/Users/...`. Prefer the script:

```bash
bash "$PKG_ROOT_HINT/scripts/resolve-pkg-root.sh"
# or, after install:
bash "$(dirname "$(realpath "$(command -v resolve-pkg-root.sh 2>/dev/null || true)")" )"  # prefer:
```

Agents should run:

```bash
# From any cwd once skills are installed:
python3 - <<'PY'
import os, sys
homes = [
    os.path.expanduser("~/.cursor/skills"),
    os.path.expanduser("~/.claude/skills"),
    os.path.expanduser("~/.agents/skills"),
]
names = ("vibage-init", "vibage-locate")
for home in homes:
    for name in names:
        p = os.path.join(home, name)
        if os.path.lexists(p):
            root = os.path.dirname(os.path.dirname(os.path.realpath(p)))
            print(root)
            sys.exit(0)
sys.exit("PKG_ROOT not found — run vibage-skills/scripts/install.sh")
PY
```

Or: `"$KNOWN_CHECKOUT/scripts/resolve-pkg-root.sh"` which prints PKG_ROOT and exits 0/1.

Probe order: Cursor → Claude → Codex skill homes; within each home `vibage-init` then `vibage-locate`.
