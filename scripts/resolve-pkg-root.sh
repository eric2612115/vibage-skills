#!/usr/bin/env bash
# Print vibage-skills PKG_ROOT by resolving installed skill symlinks across surfaces.
set -euo pipefail
python3 - <<'PY'
import os
import sys

homes = [
    os.path.expanduser("~/.cursor/skills"),
    os.path.expanduser("~/.claude/skills"),
    os.path.expanduser("~/.agents/skills"),
]
names = ("vibage-init", "vibage-locate")
for home in homes:
    for name in names:
        path = os.path.join(home, name)
        if os.path.lexists(path):
            root = os.path.dirname(os.path.dirname(os.path.realpath(path)))
            print(root)
            sys.exit(0)
print(
    "ERROR: PKG_ROOT not found. Run vibage-skills/scripts/install.sh "
    "(surfaces: cursor, claude, codex).",
    file=sys.stderr,
)
sys.exit(1)
PY
