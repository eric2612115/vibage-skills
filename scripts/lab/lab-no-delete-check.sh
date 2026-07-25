#!/usr/bin/env bash
# Static scan: scripts/lab/*.sh must not contain executable delete commands.
# Prints JSON: lab_no_delete_static_scan, hits[], method.
# Static pass ≠ runtime proof that agents never deleted.
# Usage: bash lab-no-delete-check.sh
# Exit 0 if scan clean; exit 1 if hits found (still prints JSON on stdout).
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"

python3 - "$LAB_DIR" <<'PY'
import json, re, sys
from pathlib import Path

lab = Path(sys.argv[1])
# Executable-line patterns (comments stripped). Static only.
pat = re.compile(r"(rm\s+-r(?:f)?\b|rm\s+-fr\b|docker\s+rm\b)")
hits = []
for path in sorted(lab.glob("*.sh")):
    try:
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    except OSError as e:
        hits.append({"file": str(path), "line": 0, "text": f"read_error:{e}"})
        continue
    for i, raw in enumerate(lines, 1):
        # Strip full-line and trailing comments (naive; good enough for lab scripts)
        code = raw.split("#", 1)[0]
        if not code.strip():
            continue
        if pat.search(code):
            hits.append({"file": path.name, "line": i, "text": raw.rstrip()[:200]})

ok = len(hits) == 0
obj = {
    "lab_no_delete_static_scan": ok,
    "hits": hits,
    "method": "static_script_scan",
    "scope": "scripts/lab/*.sh",
    "honesty": "static_scan ≠ runtime zero-delete",
}
print(json.dumps(obj, indent=2, ensure_ascii=False))
sys.exit(0 if ok else 1)
PY
