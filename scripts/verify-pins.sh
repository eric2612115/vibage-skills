#!/usr/bin/env bash
set -euo pipefail
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SUPERPOWERS_ROOT="${SUPERPOWERS_ROOT:-$HOME/.cursor/skills/superpowers}"
expected="$(grep -E '^superpowers_sha=' "$PKG_ROOT/DEPENDENCIES.md" | head -1 | cut -d= -f2 | tr -d '[:space:]')"
if [[ -z "$expected" || ${#expected} -lt 40 ]]; then
  echo "ERROR: superpowers_sha missing/invalid in DEPENDENCIES.md" >&2
  exit 1
fi
actual="$(git -C "$SUPERPOWERS_ROOT" rev-parse HEAD)"
if [[ "$actual" != "$expected" ]]; then
  echo "ERROR: superpowers pin mismatch expected=$expected actual=$actual" >&2
  exit 1
fi
echo "OK: superpowers@$actual"
exit 0
