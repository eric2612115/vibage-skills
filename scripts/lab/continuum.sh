#!/usr/bin/env bash
# Run script continuum against an already-copied sandbox parent (never a live allowlist path).
# Usage: bash continuum.sh <sandbox_parent> <pkg_root> <out_dir>
set -euo pipefail

PARENT="${1:-}"
PKG_ROOT="${2:-}"
OUT="${3:-}"

fail() { echo "FAIL: $*" >&2; exit 1; }
[[ -d "$PARENT" ]] || fail "parent missing: $PARENT"
[[ -d "$PKG_ROOT/scripts" ]] || fail "pkg_root missing: $PKG_ROOT"
mkdir -p "$OUT"
PARENT="$(cd "$PARENT" && pwd)"
PKG_ROOT="$(cd "$PKG_ROOT" && pwd)"
OUT="$(cd "$OUT" && pwd)"

export HOME="${LAB_FAKE_HOME:-$OUT/fake-home}"
mkdir -p "$HOME"

LOG="$OUT/continuum.log"
echo "LAB_CONTINUUM_START parent=$PARENT home=$HOME" | tee "$LOG"
echo "Honesty: LAB_OK ≠ live parent mutated ≠ TIER0_OK ≠ 掃透 ≠ letter B" | tee -a "$LOG"

echo "== install pins + project rule ==" | tee -a "$LOG"
bash "$PKG_ROOT/scripts/install.sh" --with-project-rule="$PARENT" 2>&1 | tee -a "$LOG"

echo "== verify-project-entry ==" | tee -a "$LOG"
bash "$PKG_ROOT/scripts/verify-project-entry.sh" "$PARENT" 2>&1 | tee -a "$OUT/entry.out" | tee -a "$LOG"

echo "== init-hub ==" | tee -a "$LOG"
bash "$PKG_ROOT/scripts/install.sh" --init-hub="$PARENT" 2>&1 | tee -a "$LOG"

echo "== graph-floor / pile-index ==" | tee -a "$LOG"
set +e
bash "$PKG_ROOT/scripts/pile-index.sh" "$PARENT" 2>&1 | tee "$OUT/pile-index.out" | tee -a "$LOG"
PI_EC=${PIPESTATUS[0]}
set -e

echo "== c-prime-fill (matrix sweep; may be incomplete) ==" | tee -a "$LOG"
set +e
bash "$PKG_ROOT/scripts/c-prime-fill.sh" "$PARENT" 2>&1 | tee "$OUT/c-prime-fill.out" | tee -a "$LOG"
CF_EC=${PIPESTATUS[0]}
set -e

echo "== freshness ==" | tee -a "$LOG"
set +e
bash "$PKG_ROOT/scripts/verify-freshness.sh" "$PARENT" 2>&1 | tee "$OUT/freshness.out" | tee -a "$LOG"
FR_EC=${PIPESTATUS[0]}
set -e

py_bool() {
  local f="$1" pat="$2"
  if [[ -f "$f" ]] && grep -Fq "$pat" "$f"; then echo true; else echo false; fi
}

python3 - "$OUT" "$PARENT" "$PI_EC" "$CF_EC" "$FR_EC" <<'PY'
import json, sys
out, parent, pi, cf, fr = sys.argv[1:6]

import re

def has_line_token(name, token):
    """True only if token appears as its own token line (not inside a NOTE denying it)."""
    path = f"{out}/{name}"
    try:
        text = open(path, encoding="utf-8", errors="replace").read()
    except OSError:
        return False
    return re.search(rf"(?m)^{re.escape(token)}\b", text) is not None

no_git = False
try:
    no_git = "no git repos discovered" in open(f"{out}/pile-index.out", encoding="utf-8", errors="replace").read()
except OSError:
    pass
entry_ok = has_line_token("entry.out", "PROJECT_ENTRY_OK")
pile_ok = has_line_token("pile-index.out", "PILE_INDEX_OK")
# Empty mothers (0 git children) are honest LAB_CASE_OK when entry works.
empty_ok = entry_ok and no_git and not pile_ok
sb = {
    "parent": parent,
    "project_entry_ok": entry_ok,
    "pile_index_ok": pile_ok,
    "empty_mother_no_git": no_git,
    "env_branch_matrix_ok": has_line_token("c-prime-fill.out", "ENV_BRANCH_MATRIX_OK"),
    "matrix_incomplete": has_line_token("c-prime-fill.out", "MATRIX_INCOMPLETE"),
    "matrix_sweep_substantive_ok": has_line_token("c-prime-fill.out", "MATRIX_SWEEP_SUBSTANTIVE_OK"),
    "freshness_ok": has_line_token("freshness.out", "FRESHNESS_OK"),
    "freshness_waived": has_line_token("freshness.out", "FRESHNESS_WAIVED"),
    "stale_disclosed": has_line_token("freshness.out", "STALE_DISCLOSED"),
    "pile_index_exit": int(pi),
    "c_prime_fill_exit": int(cf),
    "freshness_exit": int(fr),
    "honesty": "LAB_OK ≠ live mutated ≠ TIER0_OK ≠ 掃透 ≠ letter B",
}
open(f"{out}/SCOREBOARD.json", "w", encoding="utf-8").write(json.dumps(sb, indent=2) + "\n")
print(json.dumps(sb, indent=2))
sys.exit(0 if (entry_ok and pile_ok) or empty_ok else 1)
PY
EC=$?
if [[ "$EC" -eq 0 ]]; then
  echo "LAB_CASE_OK continuum parent=$PARENT" | tee -a "$LOG"
else
  echo "LAB_CASE_FAIL continuum parent=$PARENT (see $OUT)" | tee -a "$LOG" >&2
fi
exit "$EC"
