#!/usr/bin/env bash
# Proven-green lock gate. MUST NOT enter scripts/test-tier0.sh (STATUS lints stay
# out of the ship gate, same policy as test_status_capability_table).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "FAIL: $*"; exit 1; }
pass() { echo "PASS: $*"; }

if grep -qE 'test_proven_lock|verify-proven-lock' scripts/test-tier0.sh 2>/dev/null; then
  fail "proven lock must not enter scripts/test-tier0.sh"
fi
pass "not wired into Tier-0"

[[ -x scripts/verify-proven-lock.sh ]] || fail "verify-proven-lock.sh not executable"
[[ -f docs/PROVEN-LOCK.json ]] || fail "missing docs/PROVEN-LOCK.json"

# 1. Live tree must be signed and every YES must resolve.
out="$(bash scripts/verify-proven-lock.sh 2>/dev/null)" || fail "live check failed: $out"
echo "$out" | grep -qx 'PROVEN_LOCK_OK' || fail "expect PROVEN_LOCK_OK, got: $out"
pass "live tree PROVEN_LOCK_OK"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
WS="$TMP/pkg"
mkdir -p "$WS/docs" "$WS/scripts/lib" "$WS/tests"
cp scripts/lib/proven_lock.py "$WS/scripts/lib/"
cp scripts/verify-proven-lock.sh "$WS/scripts/"
cp STATUS.md "$WS/"
cp docs/PROVEN-LOCK.json "$WS/docs/"
# Evidence targets referenced by the real lock must exist in the sandbox too.
while IFS= read -r rel; do
  mkdir -p "$WS/$(dirname "$rel")"
  printf '20260724T205853Z 20260724T171248Z 20260723T101530Z\n' >"$WS/$rel"
done < <(python3 -c '
import json
o = json.load(open("docs/PROVEN-LOCK.json", encoding="utf-8"))
for r in o["rows"]:
    for p in r.get("evidence_paths") or []:
        print(p)
')

run() { bash "$WS/scripts/verify-proven-lock.sh" "$WS" 2>/dev/null; }

out="$(run)" || fail "sandbox baseline should pass: $out"
echo "$out" | grep -qx 'PROVEN_LOCK_OK' || fail "sandbox baseline token: $out"
pass "sandbox baseline PROVEN_LOCK_OK"

# 2. Silent Proven-green flip must be caught (the whole point).
python3 - "$WS/STATUS.md" <<'PY'
import re, sys
p = sys.argv[1]
t = open(p, encoding="utf-8").read()
t2 = t.replace(
    "| **C′ W2 env-vacancy** | YES | YES | YES |",
    "| **C′ W2 env-vacancy** | YES | YES | YES |",
)
# flip a Proven-green cell without touching the lock
t2 = re.sub(
    r"(\| \*\*C′ W4 Tier-0 thin\*\* \| YES \| YES \| )YES( \|)",
    r"\1NO\2",
    t2,
)
assert t2 != t, "fixture edit did not apply"
open(p, "w", encoding="utf-8").write(t2)
PY
set +e
out="$(run)"
rc=$?
set -e
[[ "$rc" -ne 0 ]] || fail "flipped Proven-green must exit != 0"
echo "$out" | grep -qx 'PROVEN_LOCK_MISMATCH' || fail "expect PROVEN_LOCK_MISMATCH, got: $out"
pass "silent Proven-green flip → PROVEN_LOCK_MISMATCH"

cp STATUS.md "$WS/STATUS.md"
out="$(run)" || fail "restore should pass: $out"
echo "$out" | grep -qx 'PROVEN_LOCK_OK' || fail "restore token: $out"
pass "restore → PROVEN_LOCK_OK"

# 3. Scope upgrade script -> script+live-pressure must be caught.
python3 - "$WS/STATUS.md" <<'PY'
import re, sys
p = sys.argv[1]
t = open(p, encoding="utf-8").read()
t2 = re.sub(
    r"(\| \*\*C′ W2 env-vacancy\*\* \| YES \| YES \| YES \| )script \(",
    r"\1script+live-pressure (",
    t,
)
assert t2 != t, "scope fixture edit did not apply"
open(p, "w", encoding="utf-8").write(t2)
PY
set +e
out="$(run)"
rc=$?
set -e
[[ "$rc" -ne 0 ]] || fail "scope upgrade must exit != 0"
echo "$out" | grep -qx 'PROVEN_LOCK_MISMATCH' || fail "expect MISMATCH on scope upgrade, got: $out"
pass "silent scope upgrade → PROVEN_LOCK_MISMATCH"

cp STATUS.md "$WS/STATUS.md"

# 4. Signed YES whose evidence vanished must be caught.
victim="$(python3 -c '
import json
o = json.load(open("docs/PROVEN-LOCK.json", encoding="utf-8"))
for r in o["rows"]:
    if r["proven_green"] == "YES" and r.get("evidence_paths"):
        print(r["evidence_paths"][0]); break
')"
[[ -n "$victim" ]] || fail "no evidence path to remove"
rm -f "$WS/$victim"
set +e
out="$(run)"
rc=$?
set -e
[[ "$rc" -ne 0 ]] || fail "missing evidence must exit != 0"
echo "$out" | grep -qx 'PROVEN_LOCK_NO_EVIDENCE' || fail "expect NO_EVIDENCE, got: $out"
pass "vanished evidence → PROVEN_LOCK_NO_EVIDENCE"

printf '20260724T205853Z 20260724T171248Z 20260723T101530Z\n' >"$WS/$victim"

# 5. run-kind evidence whose run_ts no longer appears must be caught.
run_row="$(python3 -c '
import json
o = json.load(open("docs/PROVEN-LOCK.json", encoding="utf-8"))
for r in o["rows"]:
    if r.get("evidence_kind") == "run":
        print(r["evidence_paths"][0]); break
')"
[[ -n "$run_row" ]] || fail "no run-kind evidence row"
printf 'no timestamp here\n' >"$WS/$run_row"
set +e
out="$(run)"
rc=$?
set -e
[[ "$rc" -ne 0 ]] || fail "stale run_ts must exit != 0"
echo "$out" | grep -qx 'PROVEN_LOCK_NO_EVIDENCE' || fail "expect NO_EVIDENCE on run_ts, got: $out"
pass "run_ts not in evidence → PROVEN_LOCK_NO_EVIDENCE"

# 6. Re-signing after a flip is allowed but must be explicit (lock content changes).
printf '20260724T205853Z 20260724T171248Z 20260723T101530Z\n' >"$WS/$run_row"
before="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1],encoding="utf-8"))["payload_hash"])' "$WS/docs/PROVEN-LOCK.json")"
python3 - "$WS/STATUS.md" <<'PY'
import re, sys
p = sys.argv[1]
t = open(p, encoding="utf-8").read()
open(p, "w", encoding="utf-8").write(
    re.sub(r"(\| \*\*C′ W4 Tier-0 thin\*\* \| YES \| YES \| )YES( \|)", r"\1NO\2", t)
)
PY
bash "$WS/scripts/verify-proven-lock.sh" --sign "$WS" >/dev/null 2>&1 \
  || fail "re-sign should succeed"
after="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1],encoding="utf-8"))["payload_hash"])' "$WS/docs/PROVEN-LOCK.json")"
[[ "$before" != "$after" ]] || fail "re-sign must change payload_hash (visible in diff)"
pass "re-sign is possible but changes the lock (reviewable act)"

# --- regression: bypasses found in adversarial review (must stay closed) ---

expect_fail() { # <label> <expected token>
  local label="$1" want="$2" out rc
  set +e
  out="$(run)"
  rc=$?
  set -e
  [[ "$rc" -ne 0 ]] || fail "$label must exit != 0 (got rc=0, out: $out)"
  echo "$out" | grep -qx "$want" || fail "$label expect $want, got: $out"
  pass "$label → $want"
  cp STATUS.md "$WS/STATUS.md"
  cp docs/PROVEN-LOCK.json "$WS/docs/PROVEN-LOCK.json"
}

lock_edit() { python3 - "$WS/docs/PROVEN-LOCK.json" "$@"; }
# Edit the lock and RE-SIGN it, so the signature matches and the check has to
# reject the content on its merits rather than on the hash.
lock_edit_signed() {
  python3 - "$WS/docs/PROVEN-LOCK.json" "$@"
  python3 "$WS/scripts/lib/proven_lock.py" sign "$WS" >/dev/null 2>&1 || true
}

# 7. Lock-side proven_green flip must not disable the evidence check.
#    (The SSOT for the claim is STATUS.md, never the lock's own copy of it.)
#    7a: flip ONLY the lock's proven_green (evidence fields untouched, so the
#        signature still matches) — the STATUS-vs-lock disagreement must catch it.
lock_edit <<'PY'
import json, sys
p = sys.argv[1]
o = json.load(open(p, encoding="utf-8"))
for r in o["rows"]:
    if r["proven_green"] == "YES":
        r["proven_green"] = "NO"
json.dump(o, open(p, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
PY
expect_fail "lock-side proven_green flip only" "PROVEN_LOCK_NO_EVIDENCE"

#    7b: flip proven_green AND strip the evidence — now the signature catches it
#        first, before the disagreement check is even reached.
lock_edit <<'PY'
import json, sys
p = sys.argv[1]
o = json.load(open(p, encoding="utf-8"))
for r in o["rows"]:
    if r["proven_green"] == "YES":
        r["proven_green"] = "NO"
        r["evidence_kind"] = "none"
        r["evidence_paths"] = []
        r["evidence_run_ts"] = ""
json.dump(o, open(p, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
PY
expect_fail "lock-side flip + evidence strip" "PROVEN_LOCK_MISMATCH"

# 8. An indented row still renders as a table row on GitHub — it must not be
#    invisible to the parser.
printf ' | **Letter B: full-pile full-sweep** | YES | YES | YES | script+live-pressure (proven) |\n' \
  >>"$WS/STATUS.md"
expect_fail "indented appended capability row" "PROVEN_LOCK_MISMATCH"

# 9. A second `## Capability` heading must not shadow the governed table.
cat >>"$WS/STATUS.md" <<'EOF'

## Capability (archived)

| Capability | Designed | On-tree | Proven-green | Scope |
|------------|----------|---------|--------------|-------|
| **Letter B: full-pile full-sweep** | YES | YES | YES | script (proven) |
EOF
expect_fail "second ## Capability heading" "PROVEN_LOCK_BLOCKED"

# 10. On-tree is a governed claim too (STATUS: "Update On-tree / Proven-green
#     only when scripts say so").
python3 - "$WS/STATUS.md" <<'PY'
import re, sys
p = sys.argv[1]
t = open(p, encoding="utf-8").read()
t2 = t.replace("| SaaS / register | blank | — | — | — |",
               "| SaaS / register | YES | YES | — | — |")
assert t2 != t, "on-tree fixture did not apply"
open(p, "w", encoding="utf-8").write(t2)
PY
expect_fail "silent On-tree flip" "PROVEN_LOCK_MISMATCH"

# 11. Evidence paths must stay inside the package: no absolute, no `..`, no symlink.
for bad in '/etc/hosts' '../../../etc/hosts'; do
  lock_edit_signed "$bad" <<'PY'
import json, sys
p, bad = sys.argv[1], sys.argv[2]
o = json.load(open(p, encoding="utf-8"))
for r in o["rows"]:
    if r["proven_green"] == "YES" and r["evidence_kind"] == "script":
        r["evidence_paths"] = [bad]
        break
json.dump(o, open(p, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
PY
  expect_fail "evidence_path $bad" "PROVEN_LOCK_NO_EVIDENCE"
done

victim2="$(python3 -c '
import json
o = json.load(open("docs/PROVEN-LOCK.json", encoding="utf-8"))
for r in o["rows"]:
    if r["proven_green"] == "YES" and r["evidence_kind"] == "script":
        print(r["evidence_paths"][0]); break
')"
rm -f "$WS/$victim2"
ln -s /etc/hosts "$WS/$victim2"
expect_fail "symlinked evidence_path" "PROVEN_LOCK_NO_EVIDENCE"
rm -f "$WS/$victim2"
printf '20260724T205853Z 20260724T171248Z 20260723T101530Z\n' >"$WS/$victim2"

# 12. A degenerate run_ts must not substring-match everything.
lock_edit_signed <<'PY'
import json, sys
p = sys.argv[1]
o = json.load(open(p, encoding="utf-8"))
for r in o["rows"]:
    if r["evidence_kind"] == "run":
        r["evidence_run_ts"] = "2"
        break
json.dump(o, open(p, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
PY
expect_fail "degenerate evidence_run_ts" "PROVEN_LOCK_NO_EVIDENCE"

# 13. Malformed lock must still emit a token (consumers parse tokens, not rc).
lock_edit <<'PY'
import json, sys
p = sys.argv[1]
o = json.load(open(p, encoding="utf-8"))
o["rows"] = "oops"
json.dump(o, open(p, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
PY
expect_fail "malformed lock.rows" "PROVEN_LOCK_BLOCKED"

rm -f "$WS/docs/PROVEN-LOCK.json"
expect_fail "missing lock file" "PROVEN_LOCK_BLOCKED"

# --- round 2: bypasses found by the cross-model review ---

# 14. Evidence pointers are signed too — silently re-aiming a YES at some other
#     file that happens to exist must fail.
lock_edit <<'PY'
import json, sys
p = sys.argv[1]
o = json.load(open(p, encoding="utf-8"))
for r in o["rows"]:
    if r["capability"] == "Handoff dual-write":
        r["evidence_paths"] = ["docs/HONESTY-SURFACES.md"]
json.dump(o, open(p, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
PY
expect_fail "silent evidence_paths swap" "PROVEN_LOCK_MISMATCH"

# 15. Same for downgrading evidence_kind run -> script to shed the run_ts check.
lock_edit <<'PY'
import json, sys
p = sys.argv[1]
o = json.load(open(p, encoding="utf-8"))
for r in o["rows"]:
    if r.get("evidence_kind") == "run":
        r["evidence_kind"] = "script"
        r["evidence_run_ts"] = ""
        break
json.dump(o, open(p, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
PY
expect_fail "silent evidence_kind run->script" "PROVEN_LOCK_MISMATCH"

# 16. A run-kind row must cite its run_ts in STATUS, not only inside the lock.
python3 - "$WS/STATUS.md" <<'PY'
import sys
p = sys.argv[1]
t = open(p, encoding="utf-8").read()
t2 = t.replace("`run_ts=20260723T101530Z`; meta row", "meta row")
assert t2 != t, "focus run_ts fixture did not apply"
open(p, "w", encoding="utf-8").write(t2)
PY
expect_fail "run-kind row with no STATUS run_ts citation" "PROVEN_LOCK_MISMATCH"

# 17. A stored projection that disagrees with STATUS misleads readers even when
#     the gate itself reads STATUS — reject it.
lock_edit <<'PY'
import json, sys
p = sys.argv[1]
o = json.load(open(p, encoding="utf-8"))
for r in o.get("projection") or []:
    if r["proven_green"] == "YES":
        r["proven_green"] = "NO"
        break
json.dump(o, open(p, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
PY
expect_fail "stale lock.projection vs STATUS" "PROVEN_LOCK_MISMATCH"

# 18. --since must actually exercise the change branch, not only the empty one.
if git rev-parse --git-dir >/dev/null 2>&1; then
  set +e
  dout="$(bash scripts/verify-proven-lock.sh --since b022819 2>/dev/null)"
  drc=$?
  set -e
  [[ "$drc" -eq 0 ]] || fail "--since should exit 0, got $drc"
  echo "$dout" | grep -qE '^PROVEN_DIFF rows_changed=[1-9]' \
    || fail "--since against a ref with a known Proven move must report changes, got: $dout"
  echo "$dout" | grep -q 'C′ W3a dimension fill' \
    || fail "--since must name the capability that moved, got: $dout"
  pass "--since exercises the change branch and names the row"

  set +e
  dout2="$(bash scripts/verify-proven-lock.sh --since HEAD 2>/dev/null)"
  set -e
  echo "$dout2" | grep -qE '^PROVEN_DIFF(_NONE)? ' || fail "expect token, got: $dout2"
  pass "--since HEAD emits a PROVEN_DIFF token"
else
  pass "--since skipped (not a git checkout)"
fi

echo "PROVEN_LOCK_TEST_OK"
