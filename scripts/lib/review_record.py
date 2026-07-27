#!/usr/bin/env python3
"""Review-record gate helpers. ∉ Tier-0.

diff_id = sha256 of sorted trigger paths + content digests.
Excludes docs/evidence/reviews/** so writing a record cannot invalidate its id.
exit 0 ≠ REVIEW_RECORD_OK — parse stdout tokens.

Blast budget: N from trigger class; diversity axis = reviewer context (all classes).
Model family is disclosure only — never a gate.
"""
from __future__ import annotations

import hashlib
import os
import re
import subprocess
import sys
from pathlib import Path

_GIT_ENV_CLEAR = (
    "GIT_DIR",
    "GIT_WORK_TREE",
    "GIT_INDEX_FILE",
    "GIT_OBJECT_DIRECTORY",
    "GIT_ALTERNATE_OBJECT_DIRECTORIES",
    "GIT_COMMON_DIR",
    "GIT_NAMESPACE",
)

TRIGGER_PREFIXES = (
    "scripts/lib/",
    "adapters/",
    "skills/",  # G2: entire skills tree
    "tests/",
)
TRIGGER_EXACT = {
    "references/hard-stops.md",
    "references/looping-review.md",
    "references/routing-scope.md",
    "references/review-budget.md",
    "scripts/assert_gate.sh",
    "scripts/write_confirm.sh",
    "scripts/coverage-box.sh",
    "scripts/test-tier0.sh",
    "scripts/pack-health.sh",
}
TRIGGER_VERIFY_GLOB = "scripts/verify-"

REVIEWS_DIR = "docs/evidence/reviews"
_SELECTED_BY = frozenset({"owner", "implementer", "host_default"})
_SEVERITY = {"tests": 1, "narrative": 2, "gate": 3}
# Ban overclaim words in conclusion. "unverified" OK (no word-boundary hit).
# "not verified" OK via negative lookbehind. Positive "verified"/"proven"/"confirmed" FAIL.
_CONCLUSION_OVERCLAIM = re.compile(
    r"(?<!not )(?<!NOT )\b(verified|proven|confirmed)\b",
    re.IGNORECASE,
)


def is_trigger(rel: str) -> bool:
    rel = rel.replace("\\", "/").lstrip("./")
    if rel.startswith(REVIEWS_DIR + "/"):
        return False
    if rel.startswith(TRIGGER_VERIFY_GLOB) and rel.endswith(".sh"):
        return True
    if any(rel.startswith(p) for p in TRIGGER_PREFIXES):
        return True
    if rel in TRIGGER_EXACT:
        return True
    return False


def classify_path(rel: str) -> str | None:
    """Return blast class for a path, or None if not a trigger."""
    rel = rel.replace("\\", "/").lstrip("./")
    if not is_trigger(rel):
        return None
    if rel.startswith("tests/"):
        return "tests"
    if rel.startswith("adapters/") or rel.startswith("skills/"):
        return "narrative"
    if rel.startswith("references/") and rel in TRIGGER_EXACT:
        return "narrative"
    if rel.startswith(TRIGGER_VERIFY_GLOB) and rel.endswith(".sh"):
        return "gate"
    if rel.startswith("scripts/lib/"):
        return "gate"
    if rel in TRIGGER_EXACT and not rel.startswith("references/"):
        return "gate"
    # Unknown trigger shape: still gate (fail-closed upgrade)
    return "gate"


def blast_class_for(triggers: list[str]) -> str:
    if not triggers:
        raise ValueError("blast_class_for requires non-empty triggers")
    best, best_s = None, -1
    for t in triggers:
        if not is_trigger(t):
            continue
        c = classify_path(t)
        if c is None:
            raise ValueError(f"trigger without class: {t}")
        s = _SEVERITY[c]
        if s > best_s:
            best, best_s = c, s
    if best is None:
        raise ValueError("no trigger paths classified")
    return best


def budget_for(cls: str) -> dict:
    # A1: every class uses context diversity; model family is never diversity_kind
    table = {
        "gate": {"min_reviewers": 2, "diversity_kind": "context"},
        "narrative": {"min_reviewers": 2, "diversity_kind": "context"},
        "tests": {"min_reviewers": 2, "diversity_kind": "context"},
    }
    if cls not in table:
        raise ValueError(cls)
    return table[cls]


def effective_min_reviewers(loop: str, blast_n: int) -> int:
    if loop == "plan":
        return max(3, blast_n)
    if loop == "impl":
        return blast_n
    raise ValueError("loop must be plan|impl")


def contexts_ok(revs: list) -> bool:
    ctx = {(r.get("context") or "").strip() for r in revs}
    ctx.discard("")
    return len(ctx) >= 2


def selected_by_counts(revs: list) -> dict[str, int]:
    counts = {"owner": 0, "implementer": 0, "host_default": 0, "other": 0}
    for r in revs:
        sel = (r.get("reviewer_selected_by") or "").strip()
        if sel in ("owner", "implementer", "host_default"):
            counts[sel] += 1
        else:
            counts["other"] += 1
    return counts


def print_selected_by_disclosure(revs: list) -> None:
    """Disclose reviewer_selected_by distribution (G1). Does not fail the gate."""
    c = selected_by_counts(revs)
    print(
        "reviewer_selected_by: "
        f"owner={c['owner']} implementer={c['implementer']} "
        f"host_default={c['host_default']}"
        + (f" other={c['other']}" if c["other"] else "")
    )
    n = len(revs)
    if n > 0 and c["implementer"] == n:
        print(
            "Honesty: all reviewers selected by the implementing agent "
            "— highest-risk configuration"
        )


def git_run(pkg: Path, args: list[str]) -> subprocess.CompletedProcess[str]:
    """Run git with redirecting env cleared and --no-replace-objects on every call."""
    env = os.environ.copy()
    for key in _GIT_ENV_CLEAR:
        env.pop(key, None)
    return subprocess.run(
        ["git", "--no-replace-objects", "-C", str(pkg), *args],
        capture_output=True,
        text=True,
        check=False,
        env=env,
    )


def git_stdout(pkg: Path, args: list[str]) -> str:
    r = git_run(pkg, args)
    if r.returncode != 0:
        return ""
    return r.stdout


def check_git_scope(pkg: Path) -> tuple[bool, str, str]:
    """Require show-toplevel samefile as pkg. Return (ok, toplevel, git_dir)."""
    top = git_stdout(pkg, ["rev-parse", "--show-toplevel"]).strip()
    gdir = git_stdout(pkg, ["rev-parse", "--absolute-git-dir"]).strip()
    if not top:
        return False, "-", "-"
    try:
        if not os.path.samefile(top, str(pkg)):
            return False, top, gdir or "-"
    except OSError:
        return False, top, gdir or "-"
    return True, top, gdir or "-"


def resolve_base(pkg: Path) -> tuple[str | None, str]:
    """Return (base_sha, mode) where mode is merge_base|head1|none.

    Algorithm (B3):
      mb = merge-base(HEAD, main|master|origin/*)
      if mb == HEAD and HEAD~1 exists → base=HEAD~1, mode=head1
      elif mb → base=mb, mode=merge_base
      elif HEAD~1 → base=HEAD~1, mode=head1  (no main candidate)
      else → (None, none) → caller FAIL as no_git_base
    """
    head = git_stdout(pkg, ["rev-parse", "HEAD"]).strip()
    mb = ""
    for cand in ("main", "master", "origin/main", "origin/master"):
        r = git_run(pkg, ["rev-parse", "--verify", cand])
        if r.returncode != 0:
            continue
        mb = git_stdout(pkg, ["merge-base", "HEAD", cand]).strip()
        if mb:
            break
    parent = ""
    r = git_run(pkg, ["rev-parse", "--verify", "HEAD~1"])
    if r.returncode == 0:
        parent = r.stdout.strip()

    if mb and head and mb == head and parent:
        return parent, "head1"
    if mb:
        return mb, "merge_base"
    if parent:
        return parent, "head1"
    return None, "none"


def changed_paths(pkg: Path, base: str | None) -> list[str]:
    paths: set[str] = set()
    if base:
        out = git_stdout(pkg, ["diff", "--name-only", f"{base}...HEAD"])
        paths.update(p for p in out.splitlines() if p.strip())
    for args in (["diff", "--name-only"], ["diff", "--name-only", "--cached"]):
        out = git_stdout(pkg, args)
        paths.update(p for p in out.splitlines() if p.strip())
    out = git_stdout(pkg, ["ls-files", "--others", "--exclude-standard"])
    paths.update(p for p in out.splitlines() if p.strip())
    return sorted(paths)


def file_digest(pkg: Path, rel: str) -> str:
    p = pkg / rel
    if not p.is_file():
        return "missing"
    h = hashlib.sha256()
    h.update(p.read_bytes())
    return h.hexdigest()


def compute_diff_id(pkg: Path, triggers: list[str]) -> str:
    h = hashlib.sha256()
    for rel in sorted(triggers):
        h.update(rel.encode())
        h.update(b"\0")
        h.update(file_digest(pkg, rel).encode())
        h.update(b"\n")
    return h.hexdigest()


_TOP_LEVEL_KEYS = frozenset(
    {
        "diff_id",
        "diff_base",
        "subject_paths",
        "loop",
        "round",
        "frozen",
        "diversity",
        "diversity_reason",
        "reviewers",
        "conclusion",
        "blast_class",
        "review_budget_n",
        "min_reviewers",
    }
)
_REVIEWER_KEYS = frozenset(
    {
        "id",
        "lens",
        "verdict",
        "model",
        "context",
        "reviewer_selected_by",
        "blocking",
    }
)
_CONTAINER_KEYS = frozenset({"reviewers", "subject_paths"})
_TOP_KEY_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):(.*)$")
_REVIEWER_FIELD_RE = re.compile(r"^    ([A-Za-z_][A-Za-z0-9_]*):(.*)$")
_ID_TOKEN_RE = re.compile(r"^[A-Za-z0-9._-]+$")
_REVIEWER_ENTRY_LOOSE_RE = re.compile(r"^\s*-\s*id:")
# below U+0020 except tab; plus U+2028/U+2029 (non-raw so \u escapes apply)
_CONTROL_CHAR_RE = re.compile("[\x00-\x08\x0a-\x1f\u2028\u2029]")


def _strip_scalar_quotes(val: str) -> str:
    return val.strip().strip("\"'")


def _line_has_control_char(line: str) -> bool:
    """True if line has a forbidden control character (tab allowed)."""
    return _CONTROL_CHAR_RE.search(line) is not None


def _split_doc_lines(text: str) -> list[str]:
    """Split on \\n only; strip trailing \\r. Do not use str.splitlines()."""
    return [ln[:-1] if ln.endswith("\r") else ln for ln in text.split("\n")]


def _is_delimiter_line(line: str) -> bool:
    return line.rstrip() == "---"


def front_matter_region_bounds(text: str) -> tuple[int, int] | None:
    """Return (start, end) indices of front-matter body lines, or None if absent/unterminated."""
    lines = _split_doc_lines(text)
    if not lines or not _is_delimiter_line(lines[0]):
        return None
    for i in range(1, len(lines)):
        if _is_delimiter_line(lines[i]):
            return 1, i
    return None


def reviewers_outside_front_matter(text: str) -> int:
    """S5: whole-file loose id-entry count minus those inside the front-matter region."""
    lines = _split_doc_lines(text)
    bounds = front_matter_region_bounds(text)
    total = sum(1 for ln in lines if _REVIEWER_ENTRY_LOOSE_RE.match(ln))
    if bounds is None:
        return total
    start, end = bounds
    inside = sum(
        1 for ln in lines[start:end] if _REVIEWER_ENTRY_LOOSE_RE.match(ln)
    )
    return total - inside


def parse_front_matter(text: str) -> dict:
    lines = _split_doc_lines(text)
    if not lines or not _is_delimiter_line(lines[0]):
        raise ValueError("missing YAML front matter")
    close_idx = None
    for i in range(1, len(lines)):
        if _is_delimiter_line(lines[i]):
            close_idx = i
            break
    if close_idx is None:
        raise ValueError("unterminated front matter")

    data: dict = {"reviewers": [], "_parser_errors": []}
    errs: list[str] = data["_parser_errors"]
    cur_rev: dict | None = None
    path_list: list[str] = []
    recent_top: str | None = None
    recent_rev_field: str | None = None
    top_seen: set[str] = set()
    rev_seen: set[str] = set()

    def flush_rev() -> None:
        nonlocal cur_rev, recent_rev_field, rev_seen
        if cur_rev is not None:
            data["reviewers"].append(cur_rev)
            cur_rev = None
        recent_rev_field = None
        rev_seen = set()

    def set_top_value(key: str, val: str) -> None:
        if key == "frozen":
            if val == "true":
                data[key] = True
            elif val == "false":
                data[key] = False
            else:
                data[key] = val
                errs.append(f"frozen must be true or false, got '{val}'")
            return
        if val in ("true", "false"):
            data[key] = val == "true"
        elif val.isdigit():
            data[key] = int(val)
        else:
            data[key] = val

    def apply_blocking_value(rev: dict, val: str) -> None:
        nonlocal recent_rev_field
        rev["blocking"] = []
        if val in ("", "[]"):
            recent_rev_field = "blocking"
            return
        if val.startswith("[") and val.endswith("]"):
            inner = val[1:-1].strip()
            if inner:
                for part in inner.split(","):
                    item = _strip_scalar_quotes(part)
                    if item:
                        rev["blocking"].append(item)
            recent_rev_field = "blocking"
            return
        rev["blocking"].append(val)
        recent_rev_field = "blocking"

    for idx in range(1, close_idx):
        line = lines[idx]
        n = idx + 1  # 1-based file line number

        if _line_has_control_char(line):
            errs.append(f"front matter line {n} contains a control character")
            # keep scanning; do not stop
            # fall through — may also be unrecognised

        # Shape 1: blank
        if line.strip() == "":
            continue
        # Shape 2: comment
        if line.lstrip().startswith("#"):
            continue

        # Shape 3: top-level key
        m3 = _TOP_KEY_RE.match(line)
        if m3 and not line[0].isspace():
            key = m3.group(1)
            raw_after = m3.group(2)
            if key in _TOP_LEVEL_KEYS:
                flush_rev()
                recent_top = key
                recent_rev_field = None
                if key in top_seen:
                    errs.append(f"duplicate key '{key}'")
                    continue
                top_seen.add(key)
                if key in _CONTAINER_KEYS:
                    if raw_after.strip() != "":
                        errs.append(f"key '{key}' must have no inline value")
                    if key == "subject_paths":
                        path_list = []
                        data["subject_paths"] = path_list
                    # reviewers: container only; items via shape 5
                    continue
                val = _strip_scalar_quotes(raw_after)
                set_top_value(key, val)
                continue
            # key shape but not whitelisted → unrecognised below

        # Shape 5 before shape 4: reviewer entry start
        if line.startswith("  - id:") or line.startswith("  -id:"):
            flush_rev()
            id_val = _strip_scalar_quotes(line.split(":", 1)[1])
            cur_rev = {"id": id_val, "blocking": []}
            rev_seen = set()
            recent_rev_field = None
            # recent_top unchanged (still under reviewers typically)
            if not _ID_TOKEN_RE.match(id_val):
                i = len(data["reviewers"])  # this entry's index once flushed
                errs.append(
                    f"reviewer[{i}] id must be a simple token, got '{id_val}'"
                )
            continue

        # Shape 4: subject_paths item
        if line.startswith("  - ") and recent_top == "subject_paths":
            path_list.append(_strip_scalar_quotes(line[4:]))
            continue

        # Shape 6: reviewer field
        m6 = _REVIEWER_FIELD_RE.match(line)
        if m6 and cur_rev is not None:
            key = m6.group(1)
            raw_after = m6.group(2)
            if key in _REVIEWER_KEYS:
                if key in rev_seen:
                    i = len(data["reviewers"])
                    errs.append(f"reviewer[{i}] duplicate key '{key}'")
                    continue
                rev_seen.add(key)
                val = _strip_scalar_quotes(raw_after)
                if key == "blocking":
                    # retain inline/scalar/empty handling; do not discard
                    apply_blocking_value(cur_rev, val)
                    continue
                recent_rev_field = key
                cur_rev[key] = val
                continue
            # not whitelisted → unrecognised below

        # Shape 7: blocking item (payload after eight characters: "      - ")
        if (
            cur_rev is not None
            and recent_rev_field == "blocking"
            and line.startswith("      - ")
        ):
            cur_rev["blocking"].append(_strip_scalar_quotes(line[8:]))
            continue

        errs.append(f"front matter line {n} not recognised: {line}")

    flush_rev()
    if "subject_paths" not in data:
        data["subject_paths"] = path_list
    return data


def validate_record(data: dict, triggers: list[str], expected_id: str) -> list[str]:
    errs: list[str] = []
    errs.extend(data.get("_parser_errors") or [])
    if data.get("diff_id") != expected_id:
        errs.append(f"diff_id mismatch record={data.get('diff_id')} expected={expected_id}")
    subjects = set(data.get("subject_paths") or [])
    missing = [t for t in triggers if t not in subjects]
    if missing:
        errs.append(f"subject_paths missing triggers: {missing}")

    loop = data.get("loop")
    if loop not in ("plan", "impl"):
        errs.append("loop must be plan|impl")

    try:
        cls = blast_class_for(triggers)
        budget = budget_for(cls)
    except ValueError as e:
        errs.append(str(e))
        return errs

    try:
        n = effective_min_reviewers(
            str(loop) if loop is not None else "", budget["min_reviewers"]
        )
    except ValueError as e:
        errs.append(str(e))
        n = budget["min_reviewers"]

    if "blast_class" in data and data.get("blast_class") != cls:
        errs.append(f"blast_class mismatch record={data.get('blast_class')} expected={cls}")
    if "review_budget_n" in data:
        try:
            declared = int(data.get("review_budget_n"))
        except (TypeError, ValueError):
            declared = -1
        if declared != budget["min_reviewers"]:
            errs.append("review_budget_n disagrees with script-derived Impl floor")
    if "min_reviewers" in data:
        errs.append("min_reviewers must not be declared; omit field")

    revs = data.get("reviewers") or []
    if len(revs) < n:
        errs.append(f"need ≥{n} reviewers, got {len(revs)}")
    for i, r in enumerate(revs):
        raw_verdict = r.get("verdict")
        if raw_verdict is None or str(raw_verdict).strip() == "":
            errs.append(f"reviewer[{i}] missing verdict")
        else:
            trimmed = str(raw_verdict).strip()
            upper = trimmed.upper()
            if upper == "FAIL":
                errs.append(f"reviewer[{i}] verdict FAIL")
            elif upper in ("PASS", "PASS_WITH_GAPS"):
                pass
            else:
                errs.append(
                    f"reviewer[{i}] verdict must be PASS|PASS_WITH_GAPS|FAIL, "
                    f"got '{trimmed}'"
                )
        if r.get("blocking"):
            errs.append(f"reviewer[{i}] blocking non-empty: {r.get('blocking')}")
        if not r.get("model"):
            errs.append(f"reviewer[{i}] missing model")
        sel = (r.get("reviewer_selected_by") or "").strip()
        if sel not in _SELECTED_BY:
            errs.append(
                f"reviewer[{i}] reviewer_selected_by must be owner|implementer|host_default"
            )
    if not data.get("frozen"):
        errs.append("frozen must be true")

    div = data.get("diversity")
    if div not in ("ok", "waived"):
        errs.append("diversity must be ok|waived")
    else:
        # A1: context required for both ok and waived (waived does not skip context).
        if not contexts_ok(revs):
            errs.append("need ≥2 distinct non-empty reviewer context fields")
        if div == "waived" and not (data.get("diversity_reason") or "").strip():
            errs.append("diversity=waived requires diversity_reason")
    # A2: never require distinct model / model_family
    conclusion = (data.get("conclusion") or "").strip()
    if not conclusion:
        errs.append("missing conclusion")
    elif _CONCLUSION_OVERCLAIM.search(conclusion):
        errs.append(
            "conclusion must not claim verified|proven|confirmed "
            "(self-declared fields are unverifiable; use disclosed/unverified)"
        )
    return errs


def print_provenance(mode: str, pkg: Path, toplevel: str, git_dir: str) -> None:
    print(f"review_record_mode={mode}")
    print(f"review_record_pkg={pkg}")
    print(f"review_record_toplevel={toplevel}")
    print(f"review_record_git_dir={git_dir}")


def emit_outcome(flagged: bool, kind: str, detail: str) -> int:
    """Emit production or fixture token. kind is OK|SKIP|FAIL."""
    if flagged:
        tok = {
            "OK": "REVIEW_RECORD_FIXTURE_PASS",
            "SKIP": "REVIEW_RECORD_FIXTURE_SKIP",
            "FAIL": "REVIEW_RECORD_FIXTURE_FAIL",
        }[kind]
    else:
        tok = {
            "OK": "REVIEW_RECORD_OK",
            "SKIP": "REVIEW_RECORD_SKIP",
            "FAIL": "REVIEW_RECORD_FAIL",
        }[kind]
    print(f"{tok} {detail}")
    if kind == "FAIL":
        return 1
    return 0


def main(argv: list[str]) -> int:
    args = argv[1:]
    paths_file_present = False
    base_present = False
    paths_file_val = ""
    base_val = ""
    for a in args:
        if a.startswith("--paths-file="):
            paths_file_present = True
            paths_file_val = a.split("=", 1)[1]
        elif a.startswith("--base="):
            base_present = True
            base_val = a.split("=", 1)[1]

    pkg_arg = "."
    for a in args:
        if not a.startswith("--"):
            pkg_arg = a
            break
    pkg = Path(pkg_arg).resolve()
    flagged = paths_file_present or base_present

    if (paths_file_present and paths_file_val == "") or (
        base_present and base_val == ""
    ):
        mode = "fixture" if paths_file_present else "base_override"
        print_provenance(mode, pkg, "-", "-")
        return emit_outcome(True, "FAIL", "reason=empty_flag_value")

    if paths_file_present:
        mode = "fixture"
        pf = Path(paths_file_val)
        try:
            if not pf.is_file():
                print_provenance(mode, pkg, "-", "-")
                return emit_outcome(True, "FAIL", "reason=paths_file_unreadable")
            raw = pf.read_text(encoding="utf-8")
        except OSError:
            print_provenance(mode, pkg, "-", "-")
            return emit_outcome(True, "FAIL", "reason=paths_file_unreadable")
        print_provenance(mode, pkg, "-", "-")
        all_changed = [
            ln.strip() for ln in raw.splitlines() if ln.strip()
        ]
        base = base_val if base_present else "fixture"
    else:
        scope_ok, toplevel, git_dir = check_git_scope(pkg)
        if not scope_ok:
            mode = "base_override" if base_present else "none"
            print_provenance(mode, pkg, toplevel, git_dir)
            return emit_outcome(flagged, "SKIP", "reason=git_scope_mismatch")

        if base_present:
            base, mode = base_val, "base_override"
        else:
            base, mode = resolve_base(pkg)

        print_provenance(mode, pkg, toplevel, git_dir)

        if base is None:
            print(
                "Honesty: no_git_base cannot pass pack-health; "
                "need fetch-depth:0 / git history"
            )
            return emit_outcome(flagged, "FAIL", "reason=no_git_base")

        all_changed = changed_paths(pkg, base)

    triggers = [p for p in all_changed if is_trigger(p)]
    if not triggers:
        if flagged:
            print("Honesty: exit 0 is not a production acceptance path")
        else:
            print("Honesty: exit 0 is not the OK token; SKIP ≠ reviewed")
        return emit_outcome(flagged, "SKIP", "reason=no_trigger_paths")

    try:
        cls = blast_class_for(triggers)
        budget = budget_for(cls)
    except ValueError as e:
        print(f"FAIL: {e}", file=sys.stderr)
        return emit_outcome(flagged, "FAIL", "reason=blast_class")

    print(f"blast_class={cls}")
    print(f"review_budget_n={budget['min_reviewers']}")
    print(
        "Honesty: implementer/model/context/reviewer_selected_by "
        "are self-declared and unverifiable"
    )
    print(
        "Honesty: model family is disclosure only; "
        "diversity gate is reviewer context"
    )

    diff_id = compute_diff_id(pkg, triggers)
    rec_path = pkg / REVIEWS_DIR / f"{diff_id}.md"
    print(f"diff_id={diff_id}")
    print(f"diff_base={base}")
    print(f"trigger_count={len(triggers)}")
    for t in triggers:
        print(f"trigger={t}")

    if not rec_path.is_file():
        print(f"FAIL: missing review record path={rec_path}", file=sys.stderr)
        return emit_outcome(flagged, "FAIL", "reason=missing_record")

    try:
        record_text = rec_path.read_text(encoding="utf-8")
        data = parse_front_matter(record_text)
    except Exception as e:
        print(f"FAIL: parse record: {e}", file=sys.stderr)
        return emit_outcome(flagged, "FAIL", "reason=parse")

    # G1: disclose after parse (visible even when schema later FAIL)
    print_selected_by_disclosure(data.get("reviewers") or [])
    # S5: disclosure only — never fails the gate
    outside = reviewers_outside_front_matter(record_text)
    if outside > 0:
        print(f"reviewers_outside_front_matter={outside}")

    if data.get("loop") == "plan":
        try:
            eff = effective_min_reviewers("plan", budget["min_reviewers"])
            print(f"review_budget_n_effective={eff}")
        except ValueError:
            pass

    errs = validate_record(data, triggers, diff_id)
    if errs:
        for e in errs:
            print(f"FAIL: {e}", file=sys.stderr)
        return emit_outcome(flagged, "FAIL", "reason=schema")

    if flagged:
        print("Honesty: a fixture run is not a production acceptance path")
    else:
        print("Honesty: REVIEW_RECORD_OK ≠ review quality ≠ adversarial proof")
    return emit_outcome(flagged, "OK", f"path={rec_path}")


if __name__ == "__main__":
    sys.exit(main(sys.argv))
