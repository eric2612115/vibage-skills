#!/usr/bin/env bash
# Machine-filled coverage box. MUST NOT enter scripts/test-tier0.sh.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "FAIL: $*"; exit 1; }
pass() { echo "PASS: $*"; }

if grep -qE 'test_coverage_box|coverage-box' scripts/test-tier0.sh 2>/dev/null; then
  fail "coverage box must not enter scripts/test-tier0.sh"
fi
pass "not wired into Tier-0"

[[ -x scripts/coverage-box.sh ]] || fail "coverage-box.sh not executable"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mk_repo() { # <dir> <with_env>
  mkdir -p "$1"
  (
    cd "$1"
    git init -q .
    echo "# $(basename "$1")" >README.md
    if [[ "$2" == "env" ]]; then
      printf 'services:\n  web:\n    image: x\n' >docker-compose.yml
    fi
    git add -A
    git -c user.email=t@t -c user.name=t commit -qm init
  )
}

mk_hub() { # <parent>
  bash scripts/install.sh --init-hub="$1" >/dev/null 2>&1 || true
  bash scripts/c-prime-fill.sh "$1" >/dev/null 2>&1 || true
  mkdir -p "$1/docs/vibage/RUNS"
  cat >"$1/docs/vibage/RUNS/r1.json" <<'EOF'
{"schema_version":"1","run_id":"r1","pipeline_id":"locate","phase":"done","mode":"degraded","investigators":[],"reviewers":[]}
EOF
}

# --- Parent A: everything proven (full-sweep YES) ---
A="$TMP/A"
mk_repo "$A/svc-a" env
mk_repo "$A/svc-b" env
mk_hub "$A"

# --- Parent B: one repo with no env config (full-sweep NO) ---
B="$TMP/B"
mk_repo "$B/app-a" env
mk_repo "$B/app-b" env
mk_repo "$B/app-c" noenv
mk_hub "$B"

write_report() { # <parent> <findings-block> <held-line>
  local p="$1" findings="$2" heldline="$3" f="$1/VIBAGE-ISSUE-LOCATE.md"
  {
    echo "# Locate"
    echo
    bash scripts/coverage-box.sh emit "$p" --run="$p/docs/vibage/RUNS/r1.json"
    echo
    echo "## Call"
    echo "$findings"
    echo
    echo "## Nested pass"
    echo "Investigators: none"
    echo "Reviewers: none"
    echo "Mode: degraded"
    echo
    echo "## Held tokens"
    echo "$heldline"
  } >"$f"
  echo "$f"
}

verify() { # <report> <parent>
  bash scripts/verify-report.sh "$1" "$2/docs/vibage/RUNS/r1.json" 2>&1
}

# 1. Honest report round-trips.
R="$(write_report "$A" 'Suspect `svc-a/docker-compose.yml` wiring.' '`GRAPH_FLOOR_OK`')"
out="$(verify "$R" "$A")" || fail "honest report should verify: $out"
echo "$out" | grep -qx 'COVERAGE_BOX_OK' || fail "expect COVERAGE_BOX_OK, got: $out"
pass "honest report → COVERAGE_BOX_OK"

# 2. Hand-editing ANY number in the box fails (it is machine-generated).
for probe in 's/repos_discovered: 2/repos_discovered: 99/' \
             's/full-sweep (MATRIX_SWEEP_SUBSTANTIVE_OK): YES/full-sweep (MATRIX_SWEEP_SUBSTANTIVE_OK): NO/' \
             's/freshness: FRESHNESS_OK/freshness: STALE_BLOCKS_MOTHER/'; do
  cp "$R" "$R.bak"
  python3 - "$R" "$probe" <<'PY'
import re, sys
p, expr = sys.argv[1], sys.argv[2]
m = re.match(r"s/(.*)/(.*)/$", expr)
t = open(p, encoding="utf-8").read()
open(p, "w", encoding="utf-8").write(t.replace(m.group(1), m.group(2)))
PY
  set +e
  out="$(verify "$R" "$A")"
  rc=$?
  set -e
  [[ "$rc" -ne 0 ]] || fail "tampered box must fail: $probe"
  echo "$out" | grep -q 'COVERAGE_BOX_FAIL' || fail "expect COVERAGE_BOX_FAIL for $probe, got: $out"
  mv "$R.bak" "$R"
done
pass "hand-edited coverage box → COVERAGE_BOX_FAIL (3 fields)"

# 2b. INVOCATION INDEPENDENCE: the verdict must not depend on whether --run was
#     passed. An earlier version carried a RUNS-derived field, so omitting --run
#     re-derived it as "unknown" and produced a FAIL that accused the author of
#     hand-editing. A gate that cries wolf when you forget a flag gets ignored.
with_run="$(bash scripts/coverage-box.sh check "$R" --run="$A/docs/vibage/RUNS/r1.json" 2>&1 | tail -1)"
no_run="$(bash scripts/coverage-box.sh check "$R" --workspace="$A" 2>&1 | tail -1)"
[[ "$with_run" == "$no_run" ]] \
  || fail "verdict must not depend on --run: with=$with_run no=$no_run"
[[ "$with_run" == "COVERAGE_BOX_OK" ]] || fail "expect OK both ways, got: $with_run"
pass "verdict identical with and without --run (no invocation-dependent fields)"

# 3. Claiming a token the workspace does not hold fails.
R2="$(write_report "$A" 'Suspect `svc-a/docker-compose.yml` wiring.' '`GRAPH_FLOOR_OK` `SCENE_COVER_OK` `ASSERT_GATE_OK`')"
set +e
out="$(verify "$R2" "$A")"
rc=$?
set -e
[[ "$rc" -ne 0 ]] || fail "unheld token claim must fail"
echo "$out" | grep -q 'does not hold' || fail "expect unheld-token error, got: $out"
pass "Held tokens claiming unheld tokens → COVERAGE_BOX_FAIL"

# 4. A derivable hub with no box at all fails (box is required, not optional).
R3="$A/VIBAGE-ISSUE-LOCATE.md"
cat >"$R3" <<'EOF'
# Locate

## Call
Suspect `svc-a/docker-compose.yml` wiring.

## Nested pass
Investigators: none
Reviewers: none
Mode: degraded
EOF
set +e
out="$(verify "$R3" "$A")"
rc=$?
set -e
[[ "$rc" -ne 0 ]] || fail "missing box on a derivable hub must fail"
echo "$out" | grep -q 'missing `vibage_coverage_v1`' || fail "expect missing-box error, got: $out"
pass "missing coverage box on derivable hub → COVERAGE_BOX_FAIL"

# 5. No derivable hub → SKIPPED, and the token says so rather than implying a pass.
LONE="$TMP/lone.md"
cp "$R3" "$LONE"
out="$(bash scripts/coverage-box.sh check "$LONE" 2>&1)" || fail "no-hub check should exit 0"
echo "$out" | grep -qx 'COVERAGE_BOX_SKIPPED reason=no-derivable-hub' \
  || fail "expect explicit SKIPPED token, got: $out"
pass "no derivable hub → COVERAGE_BOX_SKIPPED (not a silent pass)"

# 6. The point of the whole mechanism: on a parent where nothing was dug and
#    full-sweep is NO, a second-order paraphrase still passes the phrase lint — but it
#    now sits under machine-authored numbers that contradict it. Assert BOTH:
#    the prose is not blocked, AND the box states the refuting facts.
PARA='Every repo and every branch has been checked; nothing slipped through.
I have fully mastered this system'\''s architecture.
Evidence: `app-a/docker-compose.yml`'
R4="$(write_report "$B" "$PARA" '`GRAPH_FLOOR_OK`')"
out="$(verify "$R4" "$B")" || fail "paraphrase report should still verify: $out"
echo "$out" | grep -qx 'COVERAGE_BOX_OK' || fail "expect COVERAGE_BOX_OK on B, got: $out"
grep -q 'full-sweep (MATRIX_SWEEP_SUBSTANTIVE_OK): NO' "$R4" \
  || fail "box must state full-sweep NO on parent B"
grep -qE 'repos_dug: 0 / 3' "$R4" || fail "box must state repos_dug 0 / 3"
grep -q 'missing-env-config 1' "$R4" || fail "box must state the missing env cell"
pass "paraphrase passes the lint but the box contradicts it (bounded, not blocked)"

# 7. The coverage FENCE is exempt from the phrase lint (it legitimately contains
#    full-sweep), but prose under the `## Coverage` heading is NOT exempt — that heading
#    must not become a hiding place.
R5="$(write_report "$A" 'Suspect `svc-a/docker-compose.yml` wiring.' '`GRAPH_FLOOR_OK`')"
python3 - "$R5" <<'PY'
import sys
p = sys.argv[1]
t = open(p, encoding="utf-8").read()
marker = "## Coverage (machine-filled)\n"
i = t.index(marker) + len(marker)
open(p, "w", encoding="utf-8").write(
    t[:i] + "\nfull-environment full-branch full-sweep.\n" + t[i:]
)
PY
set +e
out="$(verify "$R5" "$A")"
rc=$?
set -e
[[ "$rc" -ne 0 ]] || fail "prose under ## Coverage must still be linted"
echo "$out" | grep -q 'MATRIX_SWEEP_SUBSTANTIVE_OK' || fail "expect slogan lint, got: $out"
pass "fence exempt, prose under ## Coverage still linted"

# 8. A box from an older renderer must be told apart from a tampered one. Never
#    accuse when the evidence is ambiguous — a wrong accusation trains people to
#    ignore the gate just as effectively as a false pass does.
R6="$(write_report "$A" 'Suspect `svc-a/docker-compose.yml` wiring.' '`GRAPH_FLOOR_OK`')"
python3 - "$R6" <<'PY2'
import sys
p = sys.argv[1]
t = open(p, encoding="utf-8").read()
open(p, "w", encoding="utf-8").write(
    t.replace("freshness:", "nested_dispatch: degraded\nfreshness:", 1)
)
PY2
set +e
out="$(verify "$R6" "$A")"
rc=$?
set -e
[[ "$rc" -ne 0 ]] || fail "stale-format box must fail"
echo "$out" | grep -q 'different renderer version' \
  || fail "expect renderer-version message, got: $out"
echo "$out" | grep -q 'must not be hand-edited' \
  && fail "must NOT accuse hand-editing when the field set differs"
pass "older renderer box → version message, not a tampering accusation"

echo "COVERAGE_BOX_TEST_OK"
