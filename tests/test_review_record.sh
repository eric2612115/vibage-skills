#!/usr/bin/env bash
# Review-record gate smoke. ∉ Tier-0 / must not enter test-tier0.sh.
# --paths-file=/--base= are TEST-ONLY via direct library invocation (not a production acceptance path).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "FAIL: $*"; exit 1; }

CLEANUP_RECS=()
cleanup() {
  local p
  for p in "${CLEANUP_RECS[@]:-}"; do
    rm -f "$p"
  done
}
trap cleanup EXIT

write_rec() {
  local id="$1"
  local body="$2"
  local path="$ROOT/docs/evidence/reviews/${id}.md"
  printf '%s\n' "$body" >"$path"
  CLEANUP_RECS+=("$path")
}

if grep -qE 'test_review_record|verify-review-record|review-budget' scripts/test-tier0.sh 2>/dev/null; then
  fail "review-budget/record must not enter scripts/test-tier0.sh"
fi

[[ -f scripts/verify-review-record.sh ]] || fail "missing verify-review-record.sh"
[[ -f scripts/lib/review_record.py ]] || fail "missing review_record.py"
[[ -f references/looping-review.md ]] || fail "missing looping-review.md"
[[ -f references/review-budget.md ]] || fail "missing review-budget.md"

FIX="$ROOT/docs/evidence/reviews/_fixture_work"
mkdir -p "$FIX" "$ROOT/docs/evidence/reviews"

python3 - <<'PY' || fail "assert_gate.sh must be_trigger"
import sys
sys.path.insert(0, "scripts/lib")
from review_record import is_trigger
assert is_trigger("scripts/assert_gate.sh"), "assert_gate not trigger"
assert is_trigger("tests/test_assert_gate.sh"), "tests/test_assert_gate.sh must be trigger"
assert not is_trigger("docs/evidence/reviews/x.md")
print("TRIGGER_ASSERT_OK")
PY

python3 - <<'PY' || fail "skills/ prefix must be trigger (G2)"
import sys
sys.path.insert(0, "scripts/lib")
from review_record import is_trigger
assert is_trigger("skills/vibage-orient/SKILL.md"), "skills/ not only using-vibage"
assert is_trigger("skills/using-vibage/SKILL.md")
assert is_trigger("references/review-budget.md"), "review-budget must be TRIGGER_NARRATIVE_EXACT"
print("TRIGGER_SKILLS_G2_OK")
PY

python3 - <<'PY' || fail "Batch 3 E4 allow-list membership"
import sys
sys.path.insert(0, "scripts/lib")
from review_record import is_trigger, classify_path, _norm_rel

assert _norm_rel("./.github/workflows/tier0.yml") == ".github/workflows/tier0.yml"
assert is_trigger(".github/workflows/tier0.yml")
assert is_trigger("./.github/workflows/tier0.yml")
assert classify_path(".github/workflows/tier0.yml") == "gate"
# Every workflow and composite action is gated from v0.9.3.4: adding a CI job
# changes what "green" covers, so it cannot be a no-record change.
assert is_trigger(".github/workflows/other.yml")
assert classify_path(".github/workflows/other.yml") == "gate"
assert is_trigger(".github/actions/run-suite/action.yml")
assert classify_path(".github/actions/run-suite/action.yml") == "gate"
assert not is_trigger(".github/ISSUE_TEMPLATE/bug.md")
for helper in (
    "scripts/lib/scan_plan_hash.py",
    "scripts/lib/proven_lock.py",
    "scripts/lib/coverage_box.py",
):
    assert is_trigger(helper), helper
    assert classify_path(helper) == "gate", helper
# verify-*.sh moved INTO the gate in v0.9.3.3: a verify script defines what
# passing means, so editing one can turn FAIL into OK. Blanket `scripts/lib/`
# stays out — only named helpers are gated.
assert is_trigger("scripts/verify-freshness.sh")
assert classify_path("scripts/verify-freshness.sh") == "gate"
assert not is_trigger("scripts/lib/env_vacancy_unused_helper.py")
# CI-run suites joined TRIGGER_TESTS_EXACT in v0.9.3.3; blanket tests/ still does not.
assert is_trigger("tests/test_status_capability_table.sh")
assert classify_path("tests/test_status_capability_table.sh") == "tests"
assert not is_trigger("tests/test_not_wired_anywhere.sh")
assert not is_trigger("lab/x.sh")
print("TRIGGER_ALLOWLIST_E4_OK")
PY

python3 - <<'PY' || fail "hub-state writers must be gate triggers"
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, "scripts/lib")
from review_record import (
    CI_NON_TRIGGER_EXACT,
    CI_NON_TRIGGER_PREFIXES,
    TRIGGER_GATE_ACCEPTANCE_EXACT,
    TRIGGER_GATE_HUB_WRITERS,
    classify_path,
    is_trigger,
)

# Frozen enumeration: the writers that mint owner hub state.
for rel in (
    "scripts/matrix-inventory.sh",
    "scripts/matrix-sweep-cell.sh",
    "scripts/matrix-extract-evidence.py",
    "scripts/c-prime-fill.sh",
    "scripts/freshness-refresh-repo.sh",
    "scripts/freshness-mark.sh",
    "scripts/graph-floor.sh",
    "scripts/pile-index.sh",
    "scripts/scene-brief.sh",
    "scripts/ledger-append.sh",
    "scripts/dimension-fill.sh",
    "scripts/dimension-search.sh",
    "scripts/dimension-synth-repo.sh",
    "scripts/env-vacancy-answer.sh",
    "scripts/env-vacancy-apply-point.sh",
    "scripts/install.sh",
    "scripts/lib/freshness.py",
    "scripts/lib/env_discovery.py",
    "scripts/lib/env_vacancy.py",
    "scripts/lib/dimension_fill.py",
):
    assert Path(rel).is_file(), f"allow-list names a missing file: {rel}"
    assert is_trigger(rel), f"hub writer not a trigger: {rel}"
    assert classify_path(rel) == "gate", f"hub writer not gate class: {rel}"

# Presentation-only writers stay outside the gate.
for rel in (
    "scripts/generate-service-map-graph.sh",
    "scripts/render-service-map-preview.sh",
):
    assert not is_trigger(rel), f"presentation writer must not gate: {rel}"

# Total partition with NO predicate: every non-lab script under scripts/ is a
# trigger or is named here with a reason. Earlier versions keyed on a write-verb
# grep, then on mentioning `docs/vibage` — both were evadable (open().write, tee,
# cp, or simply building the hub path from variables, which the dimension /
# env-vacancy wrappers actually do). Enumerating the whole directory removes the
# predicate, so a new script cannot land without being classified.
NON_GATE_EXEMPT = {
    "scripts/generate-service-map-graph.sh": "presentation — writes graph.mmd / notes, mints no gate token",
    "scripts/render-service-map-preview.sh": "presentation — writes vibage-preview assets, mints no gate token",
    "scripts/serve-preview.sh": "presentation — copies preview assets and serves localhost; no verdict",
    "scripts/resolve-pkg-root.sh": "path resolution — reads symlinks, no hub state, no token",
    "scripts/lib/__init__.py": "package marker",
    "scripts/hooks/vibage-child-post-commit.sample": "sample hook — not installed or executed by the pack",
}
# No suffix filter: an earlier version only looked at .sh/.py, which a reviewer
# bypassed with scripts/check-matrix.mjs and an extensionless script. Every
# tracked file under scripts/ must be classified.
unclassified = []
tracked = subprocess.run(
    ["git", "ls-files", "scripts"], capture_output=True, text=True, check=True
).stdout.split()
for rel in sorted(tracked):
    if not Path(rel).is_file():
        continue
    if rel.startswith("scripts/lab/"):
        continue  # lab harness runs on copies under /tmp, never a real owner hub
    if is_trigger(rel) or rel in NON_GATE_EXEMPT:
        continue
    unclassified.append(rel)
if unclassified:
    raise SystemExit(
        "scripts that are neither review triggers nor exempt: "
        + ", ".join(unclassified)
        + " — gate it (hub writer / acceptance definer) or add it to"
        " NON_GATE_EXEMPT with a reason"
    )
for rel in NON_GATE_EXEMPT:
    assert Path(rel).is_file(), f"exempt names a missing file: {rel}"
    assert not is_trigger(rel), f"exempt path is also a trigger: {rel}"

# Acceptance surface: editing what "passing" means requires a record.
for rel in sorted(Path("scripts").glob("verify-*.sh")):
    r = rel.as_posix()
    assert is_trigger(r), f"verify script not gated: {r}"
    assert classify_path(r) == "gate", f"verify script not gate class: {r}"
for rel in (
    "scripts/freshness-check.sh",
    "scripts/env-vacancy-check.sh",
    "scripts/scene-validate.sh",
    "scripts/scene-classify.sh",
    "scripts/lib/report_token_lint.py",
    "scripts/lib/require_rg.sh",
):
    assert Path(rel).is_file(), f"acceptance allow-list names a missing file: {rel}"
    assert is_trigger(rel), f"acceptance definer not gated: {rel}"
# A verify script added tomorrow is gated by prefix, not by remembering to list it.
assert is_trigger("scripts/verify-not-yet-written.sh")
assert classify_path("scripts/verify-not-yet-written.sh") == "gate"
# The lab harness stays outside the gate.
assert not is_trigger("scripts/lab/verify-l1-done.sh")

# Every suite a CI job runs must be a trigger. Weakening or deleting one edits
# what "still locked" means, so it cannot be a no-record change. Derived from the
# runners themselves, so wiring a new suite into CI without gating it fails here.
def discover_ci_suites(root: Path) -> set:
    """Suite paths any CI runner under `root` can reach.

    One function so the simulation below exercises the shipped logic instead of
    re-implementing it — a reviewer pointed out that a private copy would stay
    green while the real scan regressed.
    """
    sources = [root / "scripts/test-tier0.sh", root / "scripts/pack-health.sh"]
    # Every workflow, not just tier0.yml, and composite actions too: a workflow
    # can call an action that runs a suite, hiding the name from a shallow scan.
    for sub in (".github/workflows", ".github/actions"):
        d = root / sub
        if d.is_dir():
            sources += sorted(d.rglob("*.y*ml"))
    found = set()
    for src in sources:
        if not src.is_file():
            continue
        found.update(
            re.findall(
                r"tests/test_[A-Za-z0-9_]+\.(?:sh|py)", src.read_text(encoding="utf-8")
            )
        )
    return found


for required in (Path("scripts/test-tier0.sh"), Path("scripts/pack-health.sh")):
    assert required.is_file(), f"missing CI runner: {required}"
ci_suites = discover_ci_suites(Path("."))
assert ci_suites, "no CI-run suites discovered — the derivation broke"
ungated_ci = sorted(s for s in ci_suites if not is_trigger(s))
if ungated_ci:
    raise SystemExit(
        "CI-run suites outside the review allow-list: "
        + ", ".join(ungated_ci)
        + " — add to TRIGGER_TESTS_EXACT"
    )

# A suite reachable only through a composite action must still be discovered.
# Simulated in a temp tree so the check does not depend on this repo owning one.
import tempfile

with tempfile.TemporaryDirectory() as td:
    sim = Path(td)
    (sim / ".github/workflows").mkdir(parents=True)
    (sim / ".github/actions/run-suite").mkdir(parents=True)
    (sim / ".github/workflows/nightly.yml").write_text(
        "jobs:\n  n:\n    steps:\n      - uses: ./.github/actions/run-suite\n",
        encoding="utf-8",
    )
    (sim / ".github/actions/run-suite/action.yml").write_text(
        "runs:\n  using: composite\n  steps:\n    - run: bash tests/test_sneaky.sh\n",
        encoding="utf-8",
    )
    sim_suites = discover_ci_suites(sim)
    assert "tests/test_sneaky.sh" in sim_suites, (
        "composite-action suites must be discovered by the CI derivation"
    )

# Same total-partition rule for .github: everything there is CI definition
# unless it is repo metadata. Naming only workflows/ and actions/ would leave
# .github/scripts/** as the next carrier.
github_unclassified = []
for rel in sorted(
    subprocess.run(
        ["git", "ls-files", ".github"], capture_output=True, text=True, check=True
    ).stdout.split()
):
    if not Path(rel).is_file():
        continue
    if is_trigger(rel):
        continue
    if rel in CI_NON_TRIGGER_EXACT or any(
        rel.startswith(p) for p in CI_NON_TRIGGER_PREFIXES
    ):
        continue
    github_unclassified.append(rel)
if github_unclassified:
    raise SystemExit(
        "tracked .github files that are neither CI-definition triggers nor known "
        "metadata: " + ", ".join(github_unclassified)
    )
for rel in (
    ".github/scripts/run-ci.sh",
    ".github/workflows/nested/deep.yml",
    # A directory carve-out without a trailing slash used to match these.
    ".github/PULL_REQUEST_TEMPLATE_x/action.yml",
    ".github/PULL_REQUEST_TEMPLATEsneaky.yml",
    ".github/ISSUE_TEMPLATE_x/run.sh",
):
    assert is_trigger(rel), f"CI carrier must be gated: {rel}"
for rel in (
    ".github/CODEOWNERS",
    ".github/dependabot.yml",
    ".github/README.md",
    ".github/PULL_REQUEST_TEMPLATE.md",
    ".github/pull_request_template.md",
    ".github/PULL_REQUEST_TEMPLATE/two.md",
    ".github/DISCUSSION_TEMPLATE/ideas.yml",
):
    assert not is_trigger(rel), f"repo metadata must not gate: {rel}"
for p in CI_NON_TRIGGER_PREFIXES:
    assert p.endswith("/"), f"directory carve-out needs a path boundary: {p}"

n_verify = len(list(Path("scripts").glob("verify-*.sh")))
print(
    f"TRIGGER_HUB_WRITERS_OK n={len(TRIGGER_GATE_HUB_WRITERS)} "
    f"acceptance={n_verify + len(TRIGGER_GATE_ACCEPTANCE_EXACT)} "
    f"exempt={len(NON_GATE_EXEMPT)}"
)
PY

python3 - <<'PY' || fail "blast class / budget"
import sys
sys.path.insert(0, "scripts/lib")
from review_record import (
    classify_path, blast_class_for, budget_for, is_trigger,
)

SAMPLES = [
    "scripts/assert_gate.sh",
    "scripts/verify-freshness.sh",
    "scripts/lib/review_record.py",
    "adapters/cursor/vibage.mdc",
    "skills/vibage-init/SKILL.md",
    "references/routing-scope.md",
    "references/review-budget.md",
    "tests/test_review_record.sh",
    "README.md",
]
for p in SAMPLES:
    assert (classify_path(p) is not None) == is_trigger(p), p

assert classify_path("scripts/assert_gate.sh") == "gate"
assert classify_path("scripts/verify-freshness.sh") == "gate"
assert classify_path("scripts/lib/review_record.py") == "gate"
assert classify_path("adapters/cursor/vibage.mdc") == "narrative"
assert classify_path("skills/vibage-init/SKILL.md") == "narrative"
assert classify_path("references/routing-scope.md") == "narrative"
assert classify_path("references/review-budget.md") == "narrative"
assert classify_path("tests/test_review_record.sh") == "tests"
assert classify_path("README.md") is None

assert blast_class_for(["tests/test_review_record.sh", "adapters/a.md"]) == "narrative"
assert blast_class_for(["tests/test_review_record.sh", "scripts/assert_gate.sh"]) == "gate"
assert blast_class_for(["tests/test_review_record.sh"]) == "tests"

for bad in ([], ["README.md"], ["tests/x.sh"]):
    try:
        blast_class_for(bad)
        raise SystemExit(f"expected raise for {bad!r}")
    except ValueError:
        pass

for cls in ("gate", "narrative", "tests"):
    b = budget_for(cls)
    assert b["min_reviewers"] == 2 and b["diversity_kind"] == "context", cls
print("BLAST_BUDGET_UNIT_OK")
PY

python3 - <<'PY' || fail "no low class"
import sys
sys.path.insert(0, "scripts/lib")
from review_record import budget_for
for cls in ("gate", "narrative", "tests"):
    assert budget_for(cls)["diversity_kind"] == "context"
try:
    budget_for("low")
    raise SystemExit("low must not be a budget class")
except ValueError:
    pass
print("NO_LOW_CLASS_OK")
PY

diff_id_for() {
  local paths_csv=""
  local p
  for p in "$@"; do
    paths_csv+="$p"$'\n'
  done
  PATHS_CSV="$paths_csv" python3 - <<'PY'
from pathlib import Path
import os, sys
sys.path.insert(0, "scripts/lib")
from review_record import compute_diff_id
paths = [ln for ln in os.environ["PATHS_CSV"].splitlines() if ln.strip()]
print(compute_diff_id(Path(".").resolve(), paths))
PY
}

# --- Fixture A: gate PASS same model, distinct contexts ---
printf '%s\n' 'scripts/assert_gate.sh' >"$FIX/a_paths.txt"
A_ID="$(diff_id_for scripts/assert_gate.sh)"
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fixture A gate same-model distinct contexts\"
---
Fixture A.
"
A_OUT="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX/a_paths.txt" --base=fixture)"
echo "$A_OUT" | grep -Fq 'REVIEW_RECORD_FIXTURE_PASS' || fail "Fixture A expected OK"
echo "$A_OUT" | grep -Fq 'blast_class=gate' || fail "Fixture A blast_class"
echo "$A_OUT" | grep -Fq 'review_budget_n=2' || fail "Fixture A review_budget_n"
echo "$A_OUT" | grep -Fq 'reviewer_selected_by: owner=2 implementer=0 host_default=0' \
  || fail "Fixture A must disclose selected_by counts (G1)"

# G1: all-implementer → highest-risk honesty line
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: implementer
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: implementer
    blocking: []
conclusion: \"fixture G1 all implementer\"
---
"
G1_OUT="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX/a_paths.txt" --base=fixture)"
echo "$G1_OUT" | grep -Fq 'REVIEW_RECORD_FIXTURE_PASS' || fail "G1 all-implementer still OK"
echo "$G1_OUT" | grep -Fq 'reviewer_selected_by: owner=0 implementer=2 host_default=0' \
  || fail "G1 counts"
echo "$G1_OUT" | grep -Fq 'all reviewers selected by the implementing agent' \
  || fail "G1 highest-risk honesty line"

# --- Fixture B: gate FAIL same context ---
B_ID="$(diff_id_for scripts/assert_gate.sh)"
write_rec "$B_ID" "---
diff_id: \"$B_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fixture B same context\"
---
"
set +e
B_OUT="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX/a_paths.txt" --base=fixture 2>&1)"
B_EC=$?
set -e
[[ "$B_EC" -ne 0 ]] || fail "Fixture B must FAIL"
echo "$B_OUT" | grep -Fq 'REVIEW_RECORD_FIXTURE_FAIL' || fail "Fixture B FAIL token"

# --- Fixture C: narrative PASS (routing-scope) ---
printf '%s\n' 'references/routing-scope.md' >"$FIX/c_paths.txt"
C_ID="$(diff_id_for references/routing-scope.md)"
write_rec "$C_ID" "---
diff_id: \"$C_ID\"
diff_base: \"fixture\"
subject_paths:
  - references/routing-scope.md
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: host-A
    reviewer_selected_by: implementer
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS_WITH_GAPS
    model: fixture-grok
    context: host-B
    reviewer_selected_by: implementer
    blocking: []
conclusion: \"fixture C narrative\"
---
"
C_OUT="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX/c_paths.txt" --base=fixture)"
echo "$C_OUT" | grep -Fq 'REVIEW_RECORD_FIXTURE_PASS' || fail "Fixture C expected OK"
echo "$C_OUT" | grep -Fq 'blast_class=narrative' || fail "Fixture C blast_class"

# --- Fixture D: narrative FAIL missing context ---
write_rec "$C_ID" "---
diff_id: \"$C_ID\"
diff_base: \"fixture\"
subject_paths:
  - references/routing-scope.md
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fixture D no context\"
---
"
set +e
D_EC="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX/c_paths.txt" --base=fixture >/dev/null 2>&1; echo $?)"
set -e
[[ "$D_EC" -ne 0 ]] || fail "Fixture D must FAIL"

# --- Fixture E: plan floor ---
write_rec "$C_ID" "---
diff_id: \"$C_ID\"
diff_base: \"fixture\"
subject_paths:
  - references/routing-scope.md
loop: plan
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: host-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: host-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fixture E plan floor\"
---
"
set +e
E_OUT="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX/c_paths.txt" --base=fixture 2>&1)"
E_EC=$?
set -e
[[ "$E_EC" -ne 0 ]] || fail "Fixture E must FAIL plan floor"
echo "$E_OUT" | grep -Eiq 'need ≥3|need >=3' || fail "Fixture E must mention ≥3 reviewers"

# --- Fixture F: field mismatch ---
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
blast_class: tests
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fixture F1\"
---
"
set +e
F1_EC="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX/a_paths.txt" --base=fixture >/dev/null 2>&1; echo $?)"
set -e
[[ "$F1_EC" -ne 0 ]] || fail "Fixture F1 blast_class mismatch must FAIL"

write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
review_budget_n: 1
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fixture F2\"
---
"
set +e
F2_EC="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX/a_paths.txt" --base=fixture >/dev/null 2>&1; echo $?)"
set -e
[[ "$F2_EC" -ne 0 ]] || fail "Fixture F2 review_budget_n mismatch must FAIL"

write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
min_reviewers: 2
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fixture F3\"
---
"
set +e
F3_EC="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX/a_paths.txt" --base=fixture >/dev/null 2>&1; echo $?)"
set -e
[[ "$F3_EC" -ne 0 ]] || fail "Fixture F3 min_reviewers declare must FAIL"

# --- Fixture H: tests class context ---
printf '%s\n' 'tests/test_review_record.sh' >"$FIX/h_paths.txt"
H_ID="$(diff_id_for tests/test_review_record.sh)"
write_rec "$H_ID" "---
diff_id: \"$H_ID\"
diff_base: \"fixture\"
subject_paths:
  - tests/test_review_record.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: t-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: t-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fixture H tests same model\"
---
"
H_OUT="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX/h_paths.txt" --base=fixture)"
echo "$H_OUT" | grep -Fq 'REVIEW_RECORD_FIXTURE_PASS' || fail "Fixture H expected OK"
echo "$H_OUT" | grep -Fq 'blast_class=tests' || fail "Fixture H blast_class"

write_rec "$H_ID" "---
diff_id: \"$H_ID\"
diff_base: \"fixture\"
subject_paths:
  - tests/test_review_record.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-a
    context: t-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-b
    context: t-A
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fixture H fail same context\"
---
"
set +e
H2_EC="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX/h_paths.txt" --base=fixture >/dev/null 2>&1; echo $?)"
set -e
[[ "$H2_EC" -ne 0 ]] || fail "Fixture H same context must FAIL"

# --- Fixture I: loop required ---
write_rec "$C_ID" "---
diff_id: \"$C_ID\"
diff_base: \"fixture\"
subject_paths:
  - references/routing-scope.md
loop: PLAN
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: host-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: host-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fixture I bad loop\"
---
"
set +e
I_EC="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX/c_paths.txt" --base=fixture >/dev/null 2>&1; echo $?)"
set -e
[[ "$I_EC" -ne 0 ]] || fail "Fixture I bad loop must FAIL"

# --- Fixture J: waived ---
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: waived
diversity_reason: \"single-primary-model owner roster\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fixture J waived\"
---
"
J_OUT="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX/a_paths.txt" --base=fixture)"
echo "$J_OUT" | grep -Fq 'REVIEW_RECORD_FIXTURE_PASS' || fail "Fixture J expected OK"

write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: waived
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fixture J no reason\"
---
"
set +e
J2_EC="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX/a_paths.txt" --base=fixture >/dev/null 2>&1; echo $?)"
set -e
[[ "$J2_EC" -ne 0 ]] || fail "Fixture J missing reason must FAIL"

write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: waived
diversity_reason: \"single-primary-model owner roster\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fixture J one reviewer\"
---
"
set +e
J3_EC="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX/a_paths.txt" --base=fixture >/dev/null 2>&1; echo $?)"
set -e
[[ "$J3_EC" -ne 0 ]] || fail "Fixture J one reviewer must FAIL"

write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: waived
diversity_reason: \"single-primary-model owner roster\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fixture J waived same context\"
---
"
set +e
J4_EC="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX/a_paths.txt" --base=fixture >/dev/null 2>&1; echo $?)"
set -e
[[ "$J4_EC" -ne 0 ]] || fail "Fixture J waived identical context must FAIL"

# --- Fixture K: reviewer_selected_by ---
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fixture K missing selected_by\"
---
"
set +e
K_EC="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX/a_paths.txt" --base=fixture >/dev/null 2>&1; echo $?)"
set -e
[[ "$K_EC" -ne 0 ]] || fail "Fixture K missing reviewer_selected_by must FAIL"

write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: agent
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fixture K bad selected_by\"
---
"
set +e
K2_EC="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX/a_paths.txt" --base=fixture >/dev/null 2>&1; echo $?)"
set -e
[[ "$K2_EC" -ne 0 ]] || fail "Fixture K invalid reviewer_selected_by must FAIL"

# --- Conclusion overclaim lint ---
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"context axis verified\"
---
"
set +e
CL_OUT="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX/a_paths.txt" --base=fixture 2>&1)"
CL_EC=$?
set -e
[[ "$CL_EC" -ne 0 ]] || fail "conclusion with 'verified' must FAIL"
echo "$CL_OUT" | grep -Fq 'verified|proven|confirmed' || fail "conclusion lint message"

write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fields disclosed; unverifiable; not verified\"
---
"
CL_OK="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX/a_paths.txt" --base=fixture)"
echo "$CL_OK" | grep -Fq 'REVIEW_RECORD_FIXTURE_PASS' || fail "unverified / not verified must PASS conclusion lint"
echo "CONCLUSION_LINT_OK"

# --- Lens A: blocking list / scalar / verdict case must not fake-green ---
python3 - <<'PY' || fail "blocking/verdict parser bypass still open"
import sys
sys.path.insert(0, "scripts/lib")
from review_record import parse_front_matter, validate_record

def fm(blocking_block: str, verdict: str = "PASS") -> dict:
    return parse_front_matter(f"""---
diff_id: "x"
diff_base: "fixture"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: ""
reviewers:
  - id: A
    lens: scope
    verdict: {verdict}
    model: m
    context: a
    reviewer_selected_by: owner
{blocking_block}
  - id: B
    lens: e
    verdict: PASS
    model: m
    context: b
    reviewer_selected_by: owner
    blocking: []
conclusion: "parser bypass check"
---
""")

# six-space YAML list under blocking
d = fm("    blocking:\n      - should-block")
assert d["reviewers"][0]["blocking"] == ["should-block"], d["reviewers"][0]
errs = validate_record(d, ["scripts/assert_gate.sh"], "x")
assert any("blocking" in e for e in errs), errs

# scalar blocking must not wipe to []
d = fm("    blocking: critical-finding")
assert d["reviewers"][0]["blocking"] == ["critical-finding"], d["reviewers"][0]
errs = validate_record(d, ["scripts/assert_gate.sh"], "x")
assert any("blocking" in e for e in errs), errs

# inline list
d = fm('    blocking: ["a", "b"]')
assert d["reviewers"][0]["blocking"] == ["a", "b"], d["reviewers"][0]

# verdict case
d = fm("    blocking: []", verdict="fail")
errs = validate_record(d, ["scripts/assert_gate.sh"], "x")
assert any("verdict FAIL" in e for e in errs), errs
print("BLOCKING_VERDICT_PARSE_OK")
PY

# empty paths → SKIP
: >"$FIX/empty.txt"
SKIP_OUT="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX/empty.txt" --base=fixture)"
echo "$SKIP_OUT" | grep -Fq 'REVIEW_RECORD_FIXTURE_SKIP' || fail "empty paths must SKIP"
if echo "$SKIP_OUT" | grep -Fq 'REVIEW_RECORD_OK'; then
  fail "SKIP must not print REVIEW_RECORD_OK"
fi

# missing record → FAIL
printf '%s\n' 'adapters/cursor/vibage.mdc' >"$FIX/bad_paths.txt"
set +e
BAD_OUT="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX/bad_paths.txt" --base=fixture 2>&1)"
BAD_EC=$?
set -e
[[ "$BAD_EC" -ne 0 ]] || fail "missing record must fail"

python3 - <<'PY' || fail "head1 mode check"
import sys
from pathlib import Path
sys.path.insert(0, "scripts/lib")
from review_record import resolve_base, git_stdout
pkg = Path(".").resolve()
base, mode = resolve_base(pkg)
assert mode in ("merge_base", "head1", "none"), mode
if mode == "none":
    raise SystemExit("unexpected none base in this repo")
print(f"RESOLVE_BASE_OK mode={mode} base={base[:8]}")
PY

LIVE="$(bash scripts/verify-review-record.sh "$ROOT" 2>&1)" || true
if echo "$LIVE" | grep -Fq 'reason=no_git_base'; then
  fail "full clone must not no_git_base"
fi

# --- Schema hardening (§5 cases 1–29); append-only — do not edit assertions above ---

assert_schema_fail() {
  local label="$1"
  local needle="$2"
  local out ec
  set +e
  out="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX/a_paths.txt" --base=fixture 2>&1)"
  ec=$?
  set -e
  [[ "$ec" -ne 0 ]] || fail "$label: expected non-zero exit"
  echo "$out" | grep -Fq 'REVIEW_RECORD_FIXTURE_FAIL' || fail "$label: missing REVIEW_RECORD_FIXTURE_FAIL"
  echo "$out" | grep -Fq 'reason=schema' || fail "$label: expected reason=schema, got: $out"
  echo "$out" | grep -Fq "$needle" || fail "$label: missing '$needle' in: $out"
}

# Case 1: every reviewer verdict: FAILED
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: FAILED
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: FAILED
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 1 FAILED spelling\"
---
"
assert_schema_fail "case1" "got 'FAILED'"

# Case 2: verdict key omitted
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 2 missing verdict\"
---
"
assert_schema_fail "case2" "missing verdict"

# Case 3: verdict: fail lower case → existing case-insensitive FAIL path
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: fail
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 3 lower-case fail\"
---
"
assert_schema_fail "case3" "verdict FAIL"

# Case 4: PASS_WITH_GAPS + empty blocking still OK
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS_WITH_GAPS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 4 PASS_WITH_GAPS policy unchanged\"
---
"
C4_OUT="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX/a_paths.txt" --base=fixture)"
echo "$C4_OUT" | grep -Fq 'REVIEW_RECORD_FIXTURE_PASS' || fail "case4: PASS_WITH_GAPS must OK"

# Case 5: --- mid-value after B's required fields; conclusion before reviewers; C FAIL
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
conclusion: \"case 5 conclusion before reviewers\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    reviewer_selected_by: owner
    blocking: []
    context: \"cross-ref --- thread\"
  - id: C
    lens: adversarial
    verdict: FAIL
    model: fixture-grok
    context: sess-C
    reviewer_selected_by: owner
    blocking:
      - gate truncation hide
---
"
assert_schema_fail "case5" "verdict FAIL"

# Case 6: indented --- between B and C; C must still be seen
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
    ---
  - id: C
    lens: adversarial
    verdict: FAIL
    model: fixture-grok
    context: sess-C
    reviewer_selected_by: owner
    blocking:
      - indented delimiter must not hide
conclusion: \"case 6 indented delimiter\"
---
"
assert_schema_fail "case6" "verdict FAIL"
set +e
C6_OUT="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX/a_paths.txt" --base=fixture 2>&1)"
set -e
echo "$C6_OUT" | grep -Fq 'not recognised' || fail "case6: indented --- must be not recognised"

# Case 7: duplicate verdict FAIL then PASS
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: FAIL
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 7 duplicate verdict\"
---
"
assert_schema_fail "case7" "duplicate key 'verdict'"

# Case 8: duplicate blocking finding then []
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking:
      - gate is broken
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 8 duplicate blocking\"
---
"
assert_schema_fail "case8" "duplicate key 'blocking'"

# Case 9: blocking at three-space indent
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
   blocking:
      - three-space finding
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 9 three-space blocking\"
---
"
assert_schema_fail "case9" "not recognised"

# Case 10: Verdict: FAIL then verdict: PASS
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    Verdict: FAIL
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 10 case-variant key\"
---
"
assert_schema_fail "case10" "not recognised"

# Case 11: list item with colon before blocking key
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
      - id: dropped-finding
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 11 orphan list item\"
---
"
assert_schema_fail "case11" "not recognised"

# Case 12: form feed before --- inside front matter; FAIL reviewer after
python3 - <<PY || fail "case12 write"
from pathlib import Path
aid = "$A_ID"
path = Path("docs/evidence/reviews") / f"{aid}.md"
body = f"""---
diff_id: "{aid}"
diff_base: "fixture"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: ""
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
\x0c---
  - id: C
    lens: adversarial
    verdict: FAIL
    model: fixture-grok
    context: sess-C
    reviewer_selected_by: owner
    blocking:
      - form-feed truncation
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: "case 12 form feed"
---
"""
path.write_text(body, encoding="utf-8")
print(path)
PY
CLEANUP_RECS+=("$ROOT/docs/evidence/reviews/${A_ID}.md")
assert_schema_fail "case12" "control character"

# Case 13: reviewer field note:
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    note: free text not allowed
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 13 note field\"
---
"
assert_schema_fail "case13" "not recognised"

# Case 14: min_reviewers declared — specific message retained
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
min_reviewers: 2
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 14 min_reviewers\"
---
"
assert_schema_fail "case14" "min_reviewers must not be declared"

# Case 15: body contains --- after front matter — still OK
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 15 body delimiter\"
---
Body may contain --- without truncating.
"
C15_OUT="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX/a_paths.txt" --base=fixture)"
echo "$C15_OUT" | grep -Fq 'REVIEW_RECORD_FIXTURE_PASS' || fail "case15: body --- must OK"

# Case 16: CRLF line endings parse same as LF
python3 - <<'PY' || fail "case16 CRLF parity"
import sys
sys.path.insert(0, "scripts/lib")
from review_record import parse_front_matter

lf = """---
diff_id: "x"
diff_base: "fixture"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: ""
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: m
    context: a
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: e
    verdict: PASS_WITH_GAPS
    model: m
    context: b
    reviewer_selected_by: owner
    blocking: []
conclusion: "crlf parity"
---
"""
crlf = lf.replace("\n", "\r\n")
d_lf = parse_front_matter(lf)
d_crlf = parse_front_matter(crlf)
assert [(r.get("id"), r.get("verdict")) for r in d_lf["reviewers"]] == [
    ("A", "PASS"),
    ("B", "PASS_WITH_GAPS"),
]
assert [(r.get("id"), r.get("verdict")) for r in d_crlf["reviewers"]] == [
    ("A", "PASS"),
    ("B", "PASS_WITH_GAPS"),
]
assert d_lf.get("_parser_errors") == []
assert d_crlf.get("_parser_errors") == []
print("CASE16_CRLF_OK")
PY

# Case 17: unterminated front matter — reason=parse unchanged
python3 - <<PY || fail "case17 write"
from pathlib import Path
aid = "$A_ID"
path = Path("docs/evidence/reviews") / f"{aid}.md"
path.write_text(f"""---
diff_id: "{aid}"
diff_base: "fixture"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
frozen: true
diversity: ok
reviewers:
  - id: A
    verdict: PASS
    model: m
    context: a
    reviewer_selected_by: owner
    blocking: []
conclusion: "unterminated"
""", encoding="utf-8")
PY
CLEANUP_RECS+=("$ROOT/docs/evidence/reviews/${A_ID}.md")
set +e
C17_OUT="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX/a_paths.txt" --base=fixture 2>&1)"
C17_EC=$?
set -e
[[ "$C17_EC" -ne 0 ]] || fail "case17: expected fail"
echo "$C17_OUT" | grep -Fq 'REVIEW_RECORD_FIXTURE_FAIL' || fail "case17: FAIL token"
echo "$C17_OUT" | grep -Fq 'reason=parse' || fail "case17: expected reason=parse"
echo "$C17_OUT" | grep -Fq 'unterminated front matter' || fail "case17: unterminated message"

# Case 18: - id: D at column zero after terminator → OK + S5 disclosure
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 18 outside reviewer\"
---
- id: D
"
C18_OUT="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX/a_paths.txt" --base=fixture)"
echo "$C18_OUT" | grep -Fq 'REVIEW_RECORD_FIXTURE_PASS' || fail "case18: must OK"
echo "$C18_OUT" | grep -Fq 'reviewers_outside_front_matter=1' \
  || fail "case18: expected reviewers_outside_front_matter=1 in: $C18_OUT"

# Case 19: reviewers: inline flow with FAIL entry
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers: [{id: Z, verdict: FAIL, model: x, context: cz, reviewer_selected_by: owner, blocking: [gate broken]}]
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 19 inline reviewers\"
---
"
assert_schema_fail "case19" "must have no inline value"

# Case 20: duplicate top-level conclusion
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"first\"
conclusion: \"second\"
---
"
assert_schema_fail "case20" "duplicate key 'conclusion'"

# Case 21: unrecognised line above FAIL reviewer — both errors
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  bogus_unrecognised: true
  - id: C
    lens: adversarial
    verdict: FAIL
    model: fixture-grok
    context: sess-C
    reviewer_selected_by: owner
    blocking:
      - must still be seen
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 21 continue past unrecognised\"
---
"
set +e
C21_OUT="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX/a_paths.txt" --base=fixture 2>&1)"
C21_EC=$?
set -e
[[ "$C21_EC" -ne 0 ]] || fail "case21: expected fail"
echo "$C21_OUT" | grep -Fq 'REVIEW_RECORD_FIXTURE_FAIL' || fail "case21: FAIL token"
echo "$C21_OUT" | grep -Fq 'reason=schema' || fail "case21: reason=schema"
echo "$C21_OUT" | grep -Fq 'not recognised' || fail "case21: missing not recognised"
echo "$C21_OUT" | grep -Fq 'verdict FAIL' || fail "case21: missing verdict FAIL (scan must continue)"

# Case 22: subject_paths inline value
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths: [scripts/assert_gate.sh]
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 22 inline subject_paths\"
---
"
assert_schema_fail "case22" "must have no inline value"

# Case 23: id line swallows FAIL fields
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: Z, verdict: FAIL, model: x, context: cz, reviewer_selected_by: owner, blocking: [gate broken]
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case 23 id token\"
---
"
assert_schema_fail "case23" "id must be a simple token"

# Case 24: U+2028 before --- on same line
python3 - <<PY || fail "case24 write"
from pathlib import Path
aid = "$A_ID"
path = Path("docs/evidence/reviews") / f"{aid}.md"
body = f"""---
diff_id: "{aid}"
diff_base: "fixture"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: ""
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
\u2028---
  - id: C
    lens: adversarial
    verdict: FAIL
    model: fixture-grok
    context: sess-C
    reviewer_selected_by: owner
    blocking:
      - u2028 truncation
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: "case 24 u2028"
---
"""
path.write_text(body, encoding="utf-8")
PY
CLEANUP_RECS+=("$ROOT/docs/evidence/reviews/${A_ID}.md")
assert_schema_fail "case24" "control character"

# Cases 25–29: frozen literal rule (case-sensitive; no .lower())
for frozen_val in False no yes 1 True; do
  write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: ${frozen_val}
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"case frozen=${frozen_val}\"
---
"
  assert_schema_fail "frozen=${frozen_val}" "frozen must be true or false"
done

echo "SCHEMA_HARDENING_CASES_OK"

# --- Invocation provenance (§4.5 / §4.5.1 / §4.5.2) — append-only ---

count_key() {
  local hay="$1" key="$2"
  printf '%s\n' "$hay" | grep -c "^${key}=" || true
}

assert_provenance_once() {
  local out="$1" label="$2"
  [[ "$(count_key "$out" review_record_mode)" == "1" ]] \
    || fail "$label: review_record_mode= must appear exactly once"
  [[ "$(count_key "$out" review_record_pkg)" == "1" ]] \
    || fail "$label: review_record_pkg= must appear exactly once"
  [[ "$(count_key "$out" review_record_toplevel)" == "1" ]] \
    || fail "$label: review_record_toplevel= must appear exactly once"
  [[ "$(count_key "$out" review_record_git_dir)" == "1" ]] \
    || fail "$label: review_record_git_dir= must appear exactly once"
}

assert_no_production_token() {
  local out="$1" label="$2"
  if printf '%s\n' "$out" | grep -Fq 'REVIEW_RECORD_OK'; then
    fail "$label: production REVIEW_RECORD_OK in flagged output"
  fi
  if printf '%s\n' "$out" | grep -Fq 'REVIEW_RECORD_SKIP'; then
    fail "$label: production REVIEW_RECORD_SKIP in flagged output"
  fi
  if printf '%s\n' "$out" | grep -Fq 'REVIEW_RECORD_FAIL'; then
    fail "$label: production REVIEW_RECORD_FAIL in flagged output"
  fi
}

samefile_py() {
  local a="$1" b="$2"
  python3 -c 'import os,sys; sys.exit(0 if os.path.samefile(sys.argv[1], sys.argv[2]) else 1)' "$a" "$b"
}

# Re-plant shared fixture A (earlier schema cases leave it invalid)
write_rec "$A_ID" "---
diff_id: \"$A_ID\"
diff_base: \"fixture\"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: \"\"
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: \"fixture A replant for provenance cases\"
---
Fixture A replant.
"

# Wrapper rejects each flag (P1)
set +e
WRAP_PF="$(bash scripts/verify-review-record.sh --paths-file=x . 2>&1)"
WRAP_PF_EC=$?
WRAP_B="$(bash scripts/verify-review-record.sh --base=x . 2>&1)"
WRAP_B_EC=$?
set -e
[[ "$WRAP_PF_EC" -eq 2 ]] || fail "wrapper --paths-file must exit 2, got $WRAP_PF_EC"
[[ "$WRAP_B_EC" -eq 2 ]] || fail "wrapper --base must exit 2, got $WRAP_B_EC"
echo "$WRAP_PF" | grep -Fq 'FAIL: unknown flag' || fail "wrapper --paths-file unknown flag message"
echo "$WRAP_B" | grep -Fq 'FAIL: unknown flag' || fail "wrapper --base unknown flag message"

# Provenance once on fixture PASS / SKIP / FAIL
PASS_OUT="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX/a_paths.txt" --base=fixture)"
echo "$PASS_OUT" | grep -Fq 'REVIEW_RECORD_FIXTURE_PASS' || fail "provenance PASS expected"
assert_provenance_once "$PASS_OUT" "fixture PASS"
echo "$PASS_OUT" | grep -Fq 'review_record_mode=fixture' || fail "PASS mode=fixture"
echo "$PASS_OUT" | grep -Fq "review_record_pkg=$(python3 -c "from pathlib import Path; print(Path('$ROOT').resolve())")" \
  || fail "PASS review_record_pkg"
assert_no_production_token "$PASS_OUT" "fixture PASS"

SKIP_P="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX/empty.txt" --base=fixture 2>&1)"
echo "$SKIP_P" | grep -Fq 'REVIEW_RECORD_FIXTURE_SKIP' || fail "provenance SKIP expected"
assert_provenance_once "$SKIP_P" "fixture SKIP"
assert_no_production_token "$SKIP_P" "fixture SKIP"

set +e
FAIL_P="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX/bad_paths.txt" --base=fixture 2>&1)"
set -e
echo "$FAIL_P" | grep -Fq 'REVIEW_RECORD_FIXTURE_FAIL' || fail "provenance FAIL expected"
assert_provenance_once "$FAIL_P" "fixture FAIL"
assert_no_production_token "$FAIL_P" "fixture FAIL"

# Empty / unreadable flag values (§4.2.1)
set +e
EMPTY_PF="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file= --base=fixture 2>&1)"
EMPTY_PF_EC=$?
EMPTY_B="$(python3 scripts/lib/review_record.py "$ROOT" --base= 2>&1)"
EMPTY_B_EC=$?
UNREAD="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX/missing_paths_no_such.txt" --base=fixture 2>&1)"
UNREAD_EC=$?
DIR_PF="$(python3 scripts/lib/review_record.py "$ROOT" --paths-file="$FIX" --base=fixture 2>&1)"
DIR_PF_EC=$?
set -e
[[ "$EMPTY_PF_EC" -ne 0 ]] || fail "empty --paths-file= must fail"
echo "$EMPTY_PF" | grep -Fq 'REVIEW_RECORD_FIXTURE_FAIL reason=empty_flag_value' \
  || fail "empty paths-file token"
echo "$EMPTY_PF" | grep -Fq 'review_record_mode=fixture' || fail "empty paths-file mode"
assert_no_production_token "$EMPTY_PF" "empty paths-file"

[[ "$EMPTY_B_EC" -ne 0 ]] || fail "empty --base= must fail"
echo "$EMPTY_B" | grep -Fq 'REVIEW_RECORD_FIXTURE_FAIL reason=empty_flag_value' \
  || fail "empty base token"
echo "$EMPTY_B" | grep -Fq 'review_record_mode=base_override' || fail "empty base mode"
assert_no_production_token "$EMPTY_B" "empty base"

[[ "$UNREAD_EC" -ne 0 ]] || fail "missing paths-file must fail"
echo "$UNREAD" | grep -Fq 'REVIEW_RECORD_FIXTURE_FAIL reason=paths_file_unreadable' \
  || fail "unreadable missing token"
assert_no_production_token "$UNREAD" "unreadable missing"

[[ "$DIR_PF_EC" -ne 0 ]] || fail "directory paths-file must fail"
echo "$DIR_PF" | grep -Fq 'REVIEW_RECORD_FIXTURE_FAIL reason=paths_file_unreadable' \
  || fail "unreadable directory token"
assert_no_production_token "$DIR_PF" "unreadable directory"

# Legacy patterns vs fixture tokens; control REVIEW_RECORD_OK_FIXTURE matches
LEGACY_CTRL="REVIEW_RECORD_OK_FIXTURE"
[[ "$(printf '%s\n' "$PASS_OUT" | grep -cF 'REVIEW_RECORD_OK' || true)" == "0" ]] \
  || fail "legacy -Fq OK must miss fixture PASS"
[[ "$(printf '%s\n' "REVIEW_RECORD_FIXTURE_SKIP" | grep -cF 'REVIEW_RECORD_SKIP' || true)" == "0" ]] \
  || fail "legacy -Fq SKIP must miss FIXTURE_SKIP"
[[ "$(printf '%s\n' "REVIEW_RECORD_FIXTURE_FAIL" | grep -cF 'REVIEW_RECORD_FAIL' || true)" == "0" ]] \
  || fail "legacy -Fq FAIL must miss FIXTURE_FAIL"
[[ "$(printf '%s\n' "$LEGACY_CTRL" | grep -cF 'REVIEW_RECORD_OK' || true)" == "1" ]] \
  || fail "control OK_FIXTURE must match -Fq OK"
[[ "$(printf '%s\n' "$LEGACY_CTRL" | grep -cE 'REVIEW_RECORD_(OK|SKIP)' || true)" == "1" ]] \
  || fail "control OK_FIXTURE must match -Eq OK|SKIP"

# --- §4.5.1 integration: real temporary git repository ---
INT_TMP="$(mktemp -d "${TMPDIR:-/tmp}/rr-int.XXXXXX")"
cleanup_int() {
  if [[ -n "${INT_TMP:-}" && -d "$INT_TMP" ]]; then
    git -C "$INT_TMP" worktree prune >/dev/null 2>&1 || true
    rm -rf "$INT_TMP"
  fi
  if [[ -n "${INT_SEP_DIR:-}" && -d "$INT_SEP_DIR" ]]; then
    rm -rf "$INT_SEP_DIR"
  fi
  if [[ -n "${INT_SUB_SRC:-}" && -d "$INT_SUB_SRC" ]]; then
    rm -rf "$INT_SUB_SRC"
  fi
  if [[ -n "${INT_WT:-}" && -d "$INT_WT" ]]; then
    rm -rf "$INT_WT"
  fi
  if [[ -n "${INT_CORE_OTHER:-}" && -d "$INT_CORE_OTHER" ]]; then
    rm -rf "$INT_CORE_OTHER"
  fi
}
trap 'cleanup; cleanup_int' EXIT

rsync -a --exclude '.git' --exclude 'docs/evidence/reviews/*.md' "$ROOT/" "$INT_TMP/"
git -C "$INT_TMP" init -q
git -C "$INT_TMP" config user.email "rr-int@example.com"
git -C "$INT_TMP" config user.name "rr-int"
git -C "$INT_TMP" add -A
git -C "$INT_TMP" commit -qm "int baseline"
# Second commit: exactly one gate-class file
echo "# rr-int gate marker $(date +%s)" >>"$INT_TMP/scripts/assert_gate.sh"
git -C "$INT_TMP" add scripts/assert_gate.sh
git -C "$INT_TMP" commit -qm "int gate change"
# Clean tree
git -C "$INT_TMP" status --porcelain | grep -q . && fail "int tree must be clean" || true

INT_RESOLVED="$(python3 -c "from pathlib import Path; print(Path('$INT_TMP').resolve())")"
INT_HEAD1="$(git -C "$INT_TMP" rev-parse HEAD~1)"
git -C "$INT_TMP" cat-file -e "$INT_HEAD1^{commit}" || fail "HEAD~1 must exist in int object store"

set +e
INT_OUT1="$(bash scripts/verify-review-record.sh "$INT_TMP" 2>&1)"
INT_EC1=$?
set -e
echo "$INT_OUT1" | grep -Fq 'review_record_mode=head1' || fail "int: mode must be head1: $INT_OUT1"
echo "$INT_OUT1" | grep -Fq "review_record_pkg=$INT_RESOLVED" || fail "int: pkg path: $INT_OUT1"
echo "$INT_OUT1" | grep -Fq 'trigger_count=1' || fail "int: trigger_count=1: $INT_OUT1"
echo "$INT_OUT1" | grep -Fq 'trigger=scripts/assert_gate.sh' || fail "int: trigger path: $INT_OUT1"
echo "$INT_OUT1" | grep -Fq "diff_base=$INT_HEAD1" || fail "int: diff_base: $INT_OUT1"
echo "$INT_OUT1" | grep -Fq 'blast_class=gate' || fail "int: blast_class=gate: $INT_OUT1"
echo "$INT_OUT1" | grep -Fq 'REVIEW_RECORD_FAIL reason=missing_record' \
  || fail "int: missing_record: $INT_OUT1"
[[ "$INT_EC1" -ne 0 ]] || fail "int: missing_record must be non-zero"

INT_DIFF_ID="$(printf '%s\n' "$INT_OUT1" | sed -n 's/^diff_id=//p' | head -1)"
[[ -n "$INT_DIFF_ID" ]] || fail "int: no diff_id"
mkdir -p "$INT_TMP/docs/evidence/reviews"
cat >"$INT_TMP/docs/evidence/reviews/${INT_DIFF_ID}.md" <<EOF
---
diff_id: "$INT_DIFF_ID"
diff_base: "$INT_HEAD1"
subject_paths:
  - scripts/assert_gate.sh
loop: impl
round: 1
frozen: true
diversity: ok
diversity_reason: ""
reviewers:
  - id: A
    lens: scope
    verdict: PASS
    model: fixture-grok
    context: sess-A
    reviewer_selected_by: owner
    blocking: []
  - id: B
    lens: evidence
    verdict: PASS
    model: fixture-grok
    context: sess-B
    reviewer_selected_by: owner
    blocking: []
conclusion: "int provenance integration planted record"
---
Int planted.
EOF

set +e
INT_OUT2="$(bash scripts/verify-review-record.sh "$INT_TMP" 2>&1)"
INT_EC2=$?
set -e
echo "$INT_OUT2" | grep -Fq 'REVIEW_RECORD_OK' || fail "int: expected OK after plant: $INT_OUT2"
[[ "$INT_EC2" -eq 0 ]] || fail "int: OK path exit 0"
echo "$INT_OUT2" | grep -Fq 'review_record_mode=head1' || fail "int OK: mode"
assert_provenance_once "$INT_OUT2" "int OK"

# --- §4.5.2 layout cases (built on INT_TMP; keep INT_TMP clean until replace-ref) ---

# linked worktree
INT_WT="$(mktemp -d "${TMPDIR:-/tmp}/rr-wt.XXXXXX")"
git -C "$INT_TMP" worktree add -q "$INT_WT" HEAD
set +e
WT_OUT="$(bash scripts/verify-review-record.sh "$INT_WT" 2>&1)"
set -e
echo "$WT_OUT" | grep -Fq 'reason=git_scope_mismatch' && fail "worktree must not scope-mismatch: $WT_OUT"
WT_TOP="$(printf '%s\n' "$WT_OUT" | sed -n 's/^review_record_toplevel=//p' | head -1)"
samefile_py "$WT_TOP" "$INT_WT" || fail "worktree toplevel samefile: top=$WT_TOP wt=$INT_WT"
git -C "$INT_TMP" worktree remove -f "$INT_WT" >/dev/null 2>&1 || rm -rf "$INT_WT"
INT_WT=""

# --separate-git-dir
INT_SEP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/rr-sep.XXXXXX")"
INT_SEP_CLONE="$(mktemp -d "${TMPDIR:-/tmp}/rr-sepclone.XXXXXX")"
git clone -q --separate-git-dir="$INT_SEP_DIR/gitdir" "$INT_TMP" "$INT_SEP_CLONE"
set +e
SEP_OUT="$(bash scripts/verify-review-record.sh "$INT_SEP_CLONE" 2>&1)"
set -e
echo "$SEP_OUT" | grep -Fq 'reason=git_scope_mismatch' && fail "separate-git-dir must not mismatch: $SEP_OUT"
SEP_GDIR="$(printf '%s\n' "$SEP_OUT" | sed -n 's/^review_record_git_dir=//p' | head -1)"
samefile_py "$SEP_GDIR" "$INT_SEP_DIR/gitdir" || fail "separate git_dir samefile: got=$SEP_GDIR"
rm -rf "$INT_SEP_CLONE"

# case-folded package root (skip if FS is case-sensitive)
CASE_ALT="$(RR_CASE_SRC="$INT_TMP" python3 - <<'PY'
import os
s = os.path.realpath(os.environ["RR_CASE_SRC"])
alt = None
for i in range(len(s) - 1, -1, -1):
    if s[i].isalpha():
        cand = s[:i] + s[i].swapcase() + s[i + 1 :]
        if cand != s and os.path.exists(cand):
            try:
                if os.path.samefile(cand, s):
                    alt = cand
                    break
            except OSError:
                pass
print(alt or "")
PY
)"
if [[ -n "$CASE_ALT" ]]; then
  set +e
  CASE_OUT="$(bash scripts/verify-review-record.sh "$CASE_ALT" 2>&1)"
  set -e
  echo "$CASE_OUT" | grep -Fq 'reason=git_scope_mismatch' && fail "case-fold must not mismatch: $CASE_OUT"
  CASE_TOP="$(printf '%s\n' "$CASE_OUT" | sed -n 's/^review_record_toplevel=//p' | head -1)"
  samefile_py "$CASE_TOP" "$INT_TMP" || fail "case-fold toplevel samefile"
else
  echo "NOTE: skip case-fold layout (filesystem does not case-fold)"
fi

# unicode normalisation (skip if other spelling does not exist)
NFC_DIR="$(mktemp -d "${TMPDIR:-/tmp}/rr-nfc.XXXXXX")"
UNI_OUT="$(RR_UNI_SRC="$INT_TMP" RR_UNI_BASE="$NFC_DIR" python3 - <<'PY'
import os, shutil, subprocess, unicodedata
from pathlib import Path
src = Path(os.environ["RR_UNI_SRC"])
base = Path(os.environ["RR_UNI_BASE"])
name_nfc = unicodedata.normalize("NFC", "café-rr")
name_nfd = unicodedata.normalize("NFD", "café-rr")
dst = base / name_nfc
if dst.exists():
    shutil.rmtree(dst)
r = subprocess.run(
    ["git", "clone", "-q", str(src), str(dst)],
    capture_output=True,
    text=True,
)
if r.returncode != 0:
    print("SKIP")
    raise SystemExit(0)
nfd_path = str(base / name_nfd)
if not os.path.exists(nfd_path):
    print("SKIP")
    raise SystemExit(0)
try:
    if not os.path.samefile(nfd_path, str(dst)):
        print("SKIP")
        raise SystemExit(0)
except OSError:
    print("SKIP")
    raise SystemExit(0)
print(nfd_path)
PY
)"
if [[ "$UNI_OUT" != "SKIP" && -n "$UNI_OUT" ]]; then
  set +e
  UNI_RUN="$(bash scripts/verify-review-record.sh "$UNI_OUT" 2>&1)"
  set -e
  echo "$UNI_RUN" | grep -Fq 'reason=git_scope_mismatch' && fail "unicode norm must not mismatch: $UNI_RUN"
  UNI_TOP="$(printf '%s\n' "$UNI_RUN" | sed -n 's/^review_record_toplevel=//p' | head -1)"
  samefile_py "$UNI_TOP" "$UNI_OUT" || fail "unicode toplevel samefile"
else
  echo "NOTE: skip unicode-normalisation layout (filesystem does not normalise)"
fi

# leftover replace ref — --no-replace-objects must keep the gate trigger visible.
# The reset is what makes this case discriminating: with a dirty tree the gate file
# differs from the replaced HEAD anyway, so an implementation that honours the
# replace ref still reports the trigger and the case passes vacuously. Aligning the
# tree with the replaced HEAD leaves the trigger visible only through the flag.
INT_TIP="$(git -C "$INT_TMP" rev-parse HEAD)"
INT_INIT="$(git -C "$INT_TMP" rev-parse HEAD~1)"
git -C "$INT_TMP" replace "$INT_TIP" "$INT_INIT"
git -C "$INT_TMP" reset -q --hard HEAD
set +e
REP_OUT="$(bash scripts/verify-review-record.sh "$INT_TMP" 2>&1)"
set -e
git -C "$INT_TMP" replace -d "$INT_TIP" >/dev/null 2>&1 || true
git -C "$INT_TMP" reset -q --hard HEAD
# Tracked content only: the planted review record is untracked by design, so
# porcelain is never empty here.
git -C "$INT_TMP" diff --quiet HEAD \
  || fail "replace-ref: INT_TMP tracked content must be restored for the later layout cases"
[[ -f "$INT_TMP/docs/evidence/reviews/${INT_DIFF_ID}.md" ]] \
  || fail "replace-ref: the reset must not remove the planted record"
echo "$REP_OUT" | grep -Fq 'trigger_count=1' || fail "replace-ref: trigger_count=1: $REP_OUT"
echo "$REP_OUT" | grep -Fq 'trigger=scripts/assert_gate.sh' || fail "replace-ref: gate trigger: $REP_OUT"
echo "$REP_OUT" | grep -Fq "diff_base=$INT_INIT" || fail "replace-ref: diff_base must be the real parent: $REP_OUT"
echo "$REP_OUT" | grep -Fq 'reason=no_trigger_paths' && fail "replace-ref must not vacuous SKIP"

# A directory that is not a git repository at all must keep the no_git_base FAIL.
# The scope check applies only when git returned a toplevel; treating "no toplevel"
# as a mismatch downgrades that FAIL to a SKIP, which pack-health accepts.
NOGIT_TMP="$(mktemp -d)"
set +e
NOGIT_OUT="$(bash scripts/verify-review-record.sh "$NOGIT_TMP" 2>&1)"
set -e
echo "$NOGIT_OUT" | grep -Fq 'REVIEW_RECORD_FAIL reason=no_git_base' \
  || fail "non-git dir must FAIL no_git_base, not downgrade: $NOGIT_OUT"
echo "$NOGIT_OUT" | grep -Fq 'reason=git_scope_mismatch' \
  && fail "non-git dir must not report scope mismatch: $NOGIT_OUT"
# An explicit --base must not rescue it either: the diff is empty without a
# repository, which would read as no_trigger_paths and hide the same FAIL.
set +e
NOGIT_BASE_OUT="$(python3 scripts/lib/review_record.py "$NOGIT_TMP" --base=HEAD 2>&1)"
set -e
echo "$NOGIT_BASE_OUT" | grep -Fq 'REVIEW_RECORD_FIXTURE_FAIL reason=no_git_base' \
  || fail "non-git dir with --base must FAIL no_git_base: $NOGIT_BASE_OUT"
echo "$NOGIT_BASE_OUT" | grep -Fq 'reason=no_trigger_paths' \
  && fail "non-git dir with --base must not report no_trigger_paths: $NOGIT_BASE_OUT"
rm -rf "$NOGIT_TMP"

# package root below toplevel → scope mismatch. Two classes share this signature
# and §4.2.2 accepts both: a vendored package root nested in an outer repository,
# which reported SKIP before and still does, and a subdirectory of the package's
# own repository, which reported FAIL reason=missing_record before. The second is
# an accepted downgrade, recorded here so it stays visible.
set +e
SUBDIR_OUT="$(bash scripts/verify-review-record.sh "$INT_TMP/scripts" 2>&1)"
set -e
echo "$SUBDIR_OUT" | grep -Fq 'REVIEW_RECORD_SKIP reason=git_scope_mismatch' \
  || fail "subdir scope mismatch: $SUBDIR_OUT"

# vendored shape: a package root nested inside an outer repository that names its
# paths under a prefix, so no trigger matched even before the scope check.
MONO_TMP="$(mktemp -d "${TMPDIR:-/tmp}/rr-mono.XXXXXX")"
mkdir -p "$MONO_TMP/vendor/vibage-skills/scripts"
git -C "$MONO_TMP" init -q
git -C "$MONO_TMP" config user.email "rr-mono@example.com"
git -C "$MONO_TMP" config user.name "rr-mono"
printf '#!/usr/bin/env bash\n' >"$MONO_TMP/vendor/vibage-skills/scripts/assert_gate.sh"
git -C "$MONO_TMP" add -A
git -C "$MONO_TMP" commit -qm "mono baseline"
printf '# marker\n' >>"$MONO_TMP/vendor/vibage-skills/scripts/assert_gate.sh"
git -C "$MONO_TMP" add -A
git -C "$MONO_TMP" commit -qm "mono gate change"
set +e
MONO_OUT="$(bash scripts/verify-review-record.sh "$MONO_TMP/vendor/vibage-skills" 2>&1)"
set -e
echo "$MONO_OUT" | grep -Fq 'REVIEW_RECORD_SKIP reason=git_scope_mismatch' \
  || fail "vendored root must report scope mismatch: $MONO_OUT"
# The negative half: no_trigger_paths is the inaccurate reason this row replaces,
# and it is what the outer repo's path prefix would otherwise produce.
echo "$MONO_OUT" | grep -Fq 'reason=no_trigger_paths' \
  && fail "vendored root must not report no_trigger_paths: $MONO_OUT"
rm -rf "$MONO_TMP"
echo "$SUBDIR_OUT" | grep -Fq 'REVIEW_RECORD_OK' && fail "subdir must not OK"
echo "$SUBDIR_OUT" | grep -Fq 'reason=no_trigger_paths' && fail "subdir must not no_trigger_paths"

# core.worktree pointing elsewhere
INT_CORE_OTHER="$(mktemp -d "${TMPDIR:-/tmp}/rr-corewt.XXXXXX")"
echo other >"$INT_CORE_OTHER/marker"
CORE_CLONE="$(mktemp -d "${TMPDIR:-/tmp}/rr-coreclone.XXXXXX")"
git clone -q "$INT_TMP" "$CORE_CLONE"
git -C "$CORE_CLONE" config core.worktree "$INT_CORE_OTHER"
set +e
CORE_OUT="$(bash scripts/verify-review-record.sh "$CORE_CLONE" 2>&1)"
set -e
echo "$CORE_OUT" | grep -Fq 'REVIEW_RECORD_SKIP reason=git_scope_mismatch' \
  || fail "core.worktree scope mismatch: $CORE_OUT"
echo "$CORE_OUT" | grep -Fq 'reason=no_trigger_paths' && fail "core.worktree must not no_trigger_paths"
rm -rf "$CORE_CLONE"

# submodule (separate superproject so INT_TMP stays usable)
INT_SUB_SRC="$(mktemp -d "${TMPDIR:-/tmp}/rr-subsrc.XXXXXX")"
git -C "$INT_SUB_SRC" init -q
git -C "$INT_SUB_SRC" config user.email "rr-sub@example.com"
git -C "$INT_SUB_SRC" config user.name "rr-sub"
echo sub >"$INT_SUB_SRC/README"
git -C "$INT_SUB_SRC" add README
git -C "$INT_SUB_SRC" commit -qm "sub"
SUB_SUPER="$(mktemp -d "${TMPDIR:-/tmp}/rr-subsuper.XXXXXX")"
git -C "$SUB_SUPER" init -q
git -C "$SUB_SUPER" config user.email "rr-super@example.com"
git -C "$SUB_SUPER" config user.name "rr-super"
echo super >"$SUB_SUPER/README"
git -C "$SUB_SUPER" add README
git -C "$SUB_SUPER" commit -qm "super"
git -C "$SUB_SUPER" -c protocol.file.allow=always submodule add "$INT_SUB_SRC" vendor_rr_sub
SUB_PATH="$SUB_SUPER/vendor_rr_sub"
SUB_GITDIR="$SUB_SUPER/.git/modules/vendor_rr_sub"
set +e
SUB_OUT="$(bash scripts/verify-review-record.sh "$SUB_PATH" 2>&1)"
set -e
echo "$SUB_OUT" | grep -Fq 'reason=git_scope_mismatch' && fail "submodule must not scope-mismatch: $SUB_OUT"
SUB_GDIR="$(printf '%s\n' "$SUB_OUT" | sed -n 's/^review_record_git_dir=//p' | head -1)"
samefile_py "$SUB_GDIR" "$SUB_GITDIR" || fail "submodule git_dir samefile: got=$SUB_GDIR want=$SUB_GITDIR"
rm -rf "$SUB_SUPER"

# Token literals must come from this program's own outcome, never from its inputs.
# Diagnostics echo the package path, the --base value, trigger paths and the
# offending front-matter line, so each is a route for a token spelled in an input
# to appear in output a consumer greps. Both directions are checked.
LEAK_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/rr-leak.XXXXXX")"
LEAK_PKG="$LEAK_ROOT/REVIEW_RECORD_OK"
mkdir -p "$LEAK_PKG/docs/evidence/reviews" "$LEAK_PKG/scripts"
printf 'scripts/assert_gate.sh\n' >"$LEAK_ROOT/paths.txt"
# Front matter carrying a production literal: the schema path echoes the line.
LEAK_ID="$(python3 -c '
import sys
from pathlib import Path
sys.path.insert(0, "scripts/lib")
from review_record import compute_diff_id
sys.path.pop(0)
print(compute_diff_id(Path(sys.argv[1]), ["scripts/assert_gate.sh"]))
' "$LEAK_PKG")"
printf -- '---\nREVIEW_RECORD_OK\n---\n' >"$LEAK_PKG/docs/evidence/reviews/${LEAK_ID}.md"
set +e
LEAK_OUT="$(python3 scripts/lib/review_record.py "$LEAK_PKG" \
  --paths-file="$LEAK_ROOT/paths.txt" --base=REVIEW_RECORD_SKIP 2>&1)"
set -e
assert_no_production_token "$LEAK_OUT" "token-named path, record content and --base value"
echo "$LEAK_OUT" | grep -Fq 'REVIEW_RECORD_FIXTURE_FAIL reason=schema' \
  || fail "leak case must still reach the schema FAIL: $LEAK_OUT"
echo "$LEAK_OUT" | grep -Fq 'REVIEW_RECORD_<redacted>' \
  || fail "leak case must show the redaction, proving the route was exercised: $LEAK_OUT"
# A redaction that returns the marker for everything satisfies the assertions above
# while destroying the diagnostics, so require the surrounding content to survive.
# LEAK_ROOT contains no token, so it must come through untouched.
LEAK_RESOLVED="$(python3 -c "from pathlib import Path; print(Path('$LEAK_ROOT').resolve())")"
echo "$LEAK_OUT" | grep -Fq "review_record_pkg=$LEAK_RESOLVED/" \
  || fail "redaction must keep the rest of the path: $LEAK_OUT"
echo "$LEAK_OUT" | grep -Fq 'front matter line 2 not recognised:' \
  || fail "redaction must keep the diagnostic itself: $LEAK_OUT"
# Reverse direction: a production run must not emit a fixture literal either.
REV_PKG="$LEAK_ROOT/REVIEW_RECORD_FIXTURE_PASS"
mkdir -p "$REV_PKG"
set +e
REV_OUT="$(bash scripts/verify-review-record.sh "$REV_PKG" 2>&1)"
set -e
echo "$REV_OUT" | grep -Fq 'REVIEW_RECORD_FIXTURE' \
  && fail "production run must not emit a fixture literal: $REV_OUT"
# The bare prefix, which is what a consumer separating the namespaces greps for.
BARE_PKG="$LEAK_ROOT/REVIEW_RECORD_FIXTURE"
mkdir -p "$BARE_PKG"
set +e
BARE_OUT="$(bash scripts/verify-review-record.sh "$BARE_PKG" 2>&1)"
set -e
echo "$BARE_OUT" | grep -Fq 'REVIEW_RECORD_FIXTURE' \
  && fail "production run must not emit the bare fixture prefix either: $BARE_OUT"

# The wrapper echoes argv and paths verbatim by design (§4.4). What must hold is its
# exit contract and that the diagnostic still identifies what was rejected — a version
# that redacted these returned 1 instead of 2 for an unknown flag carrying an illegal
# UTF-8 byte, because sed failed under set -e and took the message with it.
set +e
WRAP_FLAG="$(bash scripts/verify-review-record.sh --paths-file=x 2>&1)"
WRAP_FLAG_EC=$?
WRAP_DIR="$(bash scripts/verify-review-record.sh "$LEAK_ROOT/absent" 2>&1)"
WRAP_DIR_EC=$?
WRAP_BAD="$(bash scripts/verify-review-record.sh $'--bad=\xff' 2>&1)"
WRAP_BAD_EC=$?
set -e
[[ "$WRAP_FLAG_EC" == "2" ]] || fail "wrapper unknown flag must exit 2: got $WRAP_FLAG_EC"
[[ "$WRAP_DIR_EC" == "1" ]] || fail "wrapper missing dir must exit 1: got $WRAP_DIR_EC"
[[ "$WRAP_BAD_EC" == "2" ]] \
  || fail "an illegal byte in argv must not change the exit code: got $WRAP_BAD_EC"
echo "$WRAP_FLAG" | grep -Fq 'unknown flag --paths-file=' \
  || fail "wrapper must name the rejected flag: $WRAP_FLAG"
echo "$WRAP_DIR" | grep -Fq "not a directory: $LEAK_ROOT/absent" \
  || fail "wrapper must name the path: $WRAP_DIR"
# LC_ALL=C because grep itself cannot match a line carrying an illegal byte under a
# UTF-8 locale — the same trap that broke the wrapper when it filtered through sed.
echo "$WRAP_BAD" | LC_ALL=C grep -Fq 'unknown flag --bad=' \
  || fail "an illegal byte must not cost the diagnostic: $WRAP_BAD"

# pack-health decides on anchored patterns, so a token spelled in a diagnostic cannot
# change its verdict. Both directions, using that consumer's own patterns.
DIAG_LINE="FAIL: not a directory: /tmp/x/REVIEW_RECORD_FAIL/y"
printf '%s\n' "$DIAG_LINE" | grep -Eq '^REVIEW_RECORD_FAIL([^A-Za-z0-9_]|$)' \
  && fail "anchored FAIL pattern must not match a token inside a diagnostic"
printf '%s\n' "REVIEW_RECORD_FAIL reason=missing_record" \
  | grep -Eq '^REVIEW_RECORD_FAIL([^A-Za-z0-9_]|$)' \
  || fail "anchored FAIL pattern must still match the real outcome line"
printf '%s\n' "trigger=tests/REVIEW_RECORD_OK.txt" \
  | grep -Eq '^REVIEW_RECORD_(OK|SKIP)([^A-Za-z0-9_]|$)' \
  && fail "anchored OK pattern must not match a token inside a trigger line"
grep -Fq "^REVIEW_RECORD_FAIL(" scripts/pack-health.sh \
  || fail "pack-health must keep its FAIL pattern anchored"
grep -Fq "^REVIEW_RECORD_(OK|SKIP)(" scripts/pack-health.sh \
  || fail "pack-health must keep its OK|SKIP pattern anchored"
rm -rf "$LEAK_ROOT"

echo "INVOCATION_PROVENANCE_CASES_OK"

# --- Batch 3 E5: hidden_worktree + vacuous_base (production tokens) ---

E5_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/rr-e5.XXXXXX")"

# skip-worktree on a gate file with disk ≠ HEAD
E5_SW="$E5_ROOT/skipwt"
mkdir -p "$E5_SW/scripts" "$E5_SW/docs/evidence/reviews"
git -C "$E5_SW" init -q
git -C "$E5_SW" config user.email "rr-e5@example.com"
git -C "$E5_SW" config user.name "rr-e5"
# two commits so vacuous_base does not fire first
printf '#!/usr/bin/env bash\necho baseline\n' >"$E5_SW/scripts/assert_gate.sh"
git -C "$E5_SW" add -A
git -C "$E5_SW" commit -qm "e5 sw c1"
printf '#!/usr/bin/env bash\necho tip\n' >"$E5_SW/scripts/assert_gate.sh"
git -C "$E5_SW" add -A
git -C "$E5_SW" commit -qm "e5 sw c2"
printf '#!/usr/bin/env bash\necho hidden dirty\n' >"$E5_SW/scripts/assert_gate.sh"
git -C "$E5_SW" update-index --skip-worktree scripts/assert_gate.sh
git -C "$E5_SW" status --porcelain | grep -q . && fail "skip-worktree must hide porcelain dirt" || true
set +e
E5_SW_OUT="$(bash scripts/verify-review-record.sh "$E5_SW" 2>&1)"
E5_SW_EC=$?
set -e
echo "$E5_SW_OUT" | grep -Fq 'REVIEW_RECORD_FAIL reason=hidden_worktree' \
  || fail "skip-worktree dirty gate must FAIL hidden_worktree: $E5_SW_OUT"
echo "$E5_SW_OUT" | grep -Fq 'reason=no_trigger_paths' \
  && fail "skip-worktree must not look like clean SKIP: $E5_SW_OUT"
[[ "$E5_SW_EC" -ne 0 ]] || fail "hidden_worktree must be non-zero"
git -C "$E5_SW" update-index --no-skip-worktree scripts/assert_gate.sh

# assume-unchanged (not only skip-worktree)
E5_AU="$E5_ROOT/assume"
mkdir -p "$E5_AU/scripts"
git -C "$E5_AU" init -q
git -C "$E5_AU" config user.email "rr-e5@example.com"
git -C "$E5_AU" config user.name "rr-e5"
printf '#!/usr/bin/env bash\necho baseline\n' >"$E5_AU/scripts/assert_gate.sh"
git -C "$E5_AU" add -A
git -C "$E5_AU" commit -qm "e5 au c1"
printf '#!/usr/bin/env bash\necho tip\n' >"$E5_AU/scripts/assert_gate.sh"
git -C "$E5_AU" add -A
git -C "$E5_AU" commit -qm "e5 au c2"
printf '#!/usr/bin/env bash\necho assume dirty\n' >"$E5_AU/scripts/assert_gate.sh"
git -C "$E5_AU" update-index --assume-unchanged scripts/assert_gate.sh
set +e
E5_AU_OUT="$(bash scripts/verify-review-record.sh "$E5_AU" 2>&1)"
set -e
echo "$E5_AU_OUT" | grep -Fq 'REVIEW_RECORD_FAIL reason=hidden_worktree' \
  || fail "assume-unchanged dirty gate must FAIL hidden_worktree: $E5_AU_OUT"
echo "$E5_AU_OUT" | grep -Fq 'reason=no_trigger_paths' \
  && fail "assume-unchanged must not look like clean SKIP: $E5_AU_OUT"
git -C "$E5_AU" update-index --no-assume-unchanged scripts/assert_gate.sh

# single-commit repo (no HEAD~1) → vacuous_base even when clean
E5_SOLO="$E5_ROOT/solo"
mkdir -p "$E5_SOLO/scripts"
git -C "$E5_SOLO" init -q
git -C "$E5_SOLO" config user.email "rr-e5@example.com"
git -C "$E5_SOLO" config user.name "rr-e5"
printf '#!/usr/bin/env bash\necho solo\n' >"$E5_SOLO/scripts/assert_gate.sh"
git -C "$E5_SOLO" add -A
git -C "$E5_SOLO" commit -qm "e5 solo only"
git -C "$E5_SOLO" rev-parse --verify HEAD~1 >/dev/null 2>&1 \
  && fail "solo fixture must lack HEAD~1"
set +e
E5_SOLO_OUT="$(bash scripts/verify-review-record.sh "$E5_SOLO" 2>&1)"
set -e
echo "$E5_SOLO_OUT" | grep -Fq 'REVIEW_RECORD_FAIL reason=vacuous_base' \
  || fail "solo-commit must FAIL vacuous_base: $E5_SOLO_OUT"
echo "$E5_SOLO_OUT" | grep -Fq 'reason=no_trigger_paths' \
  && fail "solo-commit must not SKIP no_trigger_paths: $E5_SOLO_OUT"

# shallow clone --depth 1 of multi-commit history → vacuous_base
E5_DEEP="$E5_ROOT/deep"
mkdir -p "$E5_DEEP/scripts"
git -C "$E5_DEEP" init -q
git -C "$E5_DEEP" config user.email "rr-e5@example.com"
git -C "$E5_DEEP" config user.name "rr-e5"
printf '#!/usr/bin/env bash\necho c1\n' >"$E5_DEEP/scripts/assert_gate.sh"
git -C "$E5_DEEP" add -A
git -C "$E5_DEEP" commit -qm "e5 deep c1"
printf '#!/usr/bin/env bash\necho c2\n' >"$E5_DEEP/scripts/assert_gate.sh"
git -C "$E5_DEEP" add -A
git -C "$E5_DEEP" commit -qm "e5 deep c2"
E5_SHALLOW="$E5_ROOT/shallow"
git clone -q --depth 1 "file://$E5_DEEP" "$E5_SHALLOW"
git -C "$E5_SHALLOW" rev-parse --verify HEAD~1 >/dev/null 2>&1 \
  && fail "depth-1 clone must lack HEAD~1"
set +e
E5_SH_OUT="$(bash scripts/verify-review-record.sh "$E5_SHALLOW" 2>&1)"
set -e
echo "$E5_SH_OUT" | grep -Fq 'REVIEW_RECORD_FAIL reason=vacuous_base' \
  || fail "depth-1 clone must FAIL vacuous_base: $E5_SH_OUT"
echo "$E5_SH_OUT" | grep -Fq 'reason=no_trigger_paths' \
  && fail "depth-1 clone must not SKIP no_trigger_paths: $E5_SH_OUT"

# Renaming a guarded path OUT of the allow-list must not SKIP. git's rename
# detection reports only the destination, so changed_paths passes --no-renames.
E5_MV="$E5_ROOT/renamed"
mkdir -p "$E5_MV/scripts"
git -C "$E5_MV" init -q
git -C "$E5_MV" config user.email "rr-e5@example.com"
git -C "$E5_MV" config user.name "rr-e5"
printf '#!/usr/bin/env bash\necho gate\n' >"$E5_MV/scripts/verify-matrix-substantive.sh"
printf '# readme\n' >"$E5_MV/README.md"
git -C "$E5_MV" add -A
git -C "$E5_MV" commit -qm "e5 mv c1"
git -C "$E5_MV" mv scripts/verify-matrix-substantive.sh scripts/check-matrix-substantive.sh
git -C "$E5_MV" commit -qm "e5 mv rename out of gate"
set +e
E5_MV_OUT="$(bash scripts/verify-review-record.sh "$E5_MV" 2>&1)"
set -e
echo "$E5_MV_OUT" | grep -Fq 'reason=no_trigger_paths' \
  && fail "rename out of the allow-list must not SKIP: $E5_MV_OUT"
echo "$E5_MV_OUT" | grep -Fq 'trigger=scripts/verify-matrix-substantive.sh' \
  || fail "renamed-away guarded path must still count as a trigger: $E5_MV_OUT"
echo "$E5_MV_OUT" | grep -Eq '^REVIEW_RECORD_FAIL reason=missing_record' \
  || fail "rename with no record must FAIL missing_record: $E5_MV_OUT"

# dirty only an unlisted script → honest no_trigger_paths SKIP.
# (verify-*.sh became a gate trigger in v0.9.3.3, so the stand-in is an exempt
# script that neither writes hub state nor defines acceptance.)
E5_NT="$E5_ROOT/notrig"
mkdir -p "$E5_NT/scripts"
git -C "$E5_NT" init -q
git -C "$E5_NT" config user.email "rr-e5@example.com"
git -C "$E5_NT" config user.name "rr-e5"
printf '#!/usr/bin/env bash\necho v\n' >"$E5_NT/scripts/resolve-pkg-root.sh"
printf '#!/usr/bin/env bash\necho g\n' >"$E5_NT/scripts/assert_gate.sh"
git -C "$E5_NT" add -A
git -C "$E5_NT" commit -qm "e5 nt c1"
printf '#!/usr/bin/env bash\necho v2\n' >"$E5_NT/scripts/resolve-pkg-root.sh"
git -C "$E5_NT" add -A
git -C "$E5_NT" commit -qm "e5 nt c2"
printf '# dirt\n' >>"$E5_NT/scripts/resolve-pkg-root.sh"
set +e
E5_NT_OUT="$(bash scripts/verify-review-record.sh "$E5_NT" 2>&1)"
set -e
echo "$E5_NT_OUT" | grep -Fq 'REVIEW_RECORD_SKIP reason=no_trigger_paths' \
  || fail "unlisted verify dirt must SKIP no_trigger_paths: $E5_NT_OUT"

# CI job review-record must exist and parse REVIEW_RECORD_TEST_OK
grep -Fq 'review-record:' .github/workflows/tier0.yml \
  || fail "workflow missing job review-record"
grep -Fq 'tests/test_review_record.sh' .github/workflows/tier0.yml \
  || fail "workflow must invoke test_review_record.sh"
grep -Fq 'REVIEW_RECORD_TEST_OK' .github/workflows/tier0.yml \
  || fail "workflow must parse REVIEW_RECORD_TEST_OK"

# pack-health E3 allow-list: accept the two reasons; reject unknown SKIP
ph_allow() {
  local line="$1"
  printf '%s\n' "$line" | grep -Eq 'reason=(no_trigger_paths|git_scope_mismatch)([^A-Za-z0-9_]|$)'
}
ph_allow "REVIEW_RECORD_SKIP reason=no_trigger_paths" \
  || fail "E3 must allow no_trigger_paths"
ph_allow "REVIEW_RECORD_SKIP reason=git_scope_mismatch" \
  || fail "E3 must allow git_scope_mismatch"
ph_allow "REVIEW_RECORD_SKIP reason=synthetic" \
  && fail "E3 must reject unknown SKIP reason"
grep -Fq 'reason=(no_trigger_paths|git_scope_mismatch)' scripts/pack-health.sh \
  || fail "pack-health must keep SKIP reason allow-list"

rm -rf "$E5_ROOT"
echo "ENFORCEMENT_E5_E3_CASES_OK"

echo "REVIEW_RECORD_TEST_OK"
