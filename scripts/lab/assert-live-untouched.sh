#!/usr/bin/env bash
# Compare fingerprint of live allowlist mothers before/after a lab run.
# Usage:
#   bash assert-live-untouched.sh --snapshot=/path/to/before.json
#   bash assert-live-untouched.sh --check=/path/to/before.json
# Does not delete anything.
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=allowlist.sh
source "$LAB_DIR/allowlist.sh"

MODE=""
FILE=""
for arg in "$@"; do
  case "$arg" in
    --snapshot=*) MODE=snap; FILE="${arg#*=}" ;;
    --check=*) MODE=check; FILE="${arg#*=}" ;;
    *) echo "FAIL: unknown arg $arg" >&2; exit 1 ;;
  esac
done
[[ -n "$MODE" && -n "$FILE" ]] || {
  echo "Usage: $0 --snapshot=FILE | --check=FILE" >&2
  exit 2
}

fingerprint() {
  python3 - <<'PY'
import hashlib, json, os, sys

mothers = [
  "/Users/eric.fang/Projects/AI-Project",
  "/Users/eric.fang/Projects/AI_Game",
  "/Users/eric.fang/Projects/LangSight",
  "/Users/eric.fang/Projects/OmRate_Phalanx",
  "/Users/eric.fang/Projects/Termmax",
  "/Users/eric.fang/Projects/Trading",
  "/Users/eric.fang/MindOwnBuz",
  "/Users/eric.fang/Rust",
]
# Paths that lab must never change on live trees
watch = [
  "docs/vibage",
  ".cursor/rules/vibage.mdc",
  "CLAUDE.md",
  "AGENTS.md",
  ".claude/vibage-entry.md",
]

def digests(root):
  out = {}
  if not os.path.isdir(root):
    return {"missing": True}
  for rel in watch:
    p = os.path.join(root, rel)
    if os.path.isfile(p):
      h = hashlib.sha256(open(p, "rb").read()).hexdigest()
      out[rel] = {"type": "file", "sha256": h, "mtime": os.path.getmtime(p)}
    elif os.path.isdir(p):
      # directory: hash of sorted (relpath, size, mtime) for files one level deep + recursive vibage
      entries = []
      for dirpath, _, files in os.walk(p):
        for fn in files:
          fp = os.path.join(dirpath, fn)
          try:
            st = os.stat(fp)
            entries.append(f"{os.path.relpath(fp, p)}:{st.st_size}:{int(st.st_mtime)}")
          except OSError:
            continue
      blob = "\n".join(sorted(entries)).encode()
      out[rel] = {"type": "dir", "sha256": hashlib.sha256(blob).hexdigest(), "n": len(entries)}
    else:
      out[rel] = {"type": "absent"}
  return out

report = {m: digests(m) for m in mothers}
print(json.dumps(report, indent=2, sort_keys=True))
PY
}

if [[ "$MODE" == "snap" ]]; then
  mkdir -p "$(dirname "$FILE")"
  fingerprint >"$FILE"
  echo "LAB_LIVE_SNAPSHOT_OK path=$FILE"
  exit 0
fi

[[ -f "$FILE" ]] || { echo "FAIL: missing snapshot $FILE" >&2; exit 1; }
TMP="$(mktemp)"
# mktemp file only — we overwrite contents; do not rm (owner policy). Leave in /tmp.
fingerprint >"$TMP"
python3 - "$FILE" "$TMP" <<'PY'
import json, sys
before = json.load(open(sys.argv[1], encoding="utf-8"))
after = json.load(open(sys.argv[2], encoding="utf-8"))
bad = []
for k in sorted(set(before) | set(after)):
    if before.get(k) != after.get(k):
        bad.append(k)
if bad:
    print("LAB_LIVE_TOUCHED FAIL mothers:", ", ".join(bad), file=sys.stderr)
    sys.exit(1)
print("LAB_LIVE_UNTOUCHED_OK")
PY
