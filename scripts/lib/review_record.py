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
import re
import subprocess
import sys
from pathlib import Path

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


def git_stdout(pkg: Path, args: list[str]) -> str:
    r = subprocess.run(
        ["git", "-C", str(pkg), *args],
        capture_output=True,
        text=True,
        check=False,
    )
    if r.returncode != 0:
        return ""
    return r.stdout


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
        r = subprocess.run(
            ["git", "-C", str(pkg), "rev-parse", "--verify", cand],
            capture_output=True,
            text=True,
            check=False,
        )
        if r.returncode != 0:
            continue
        mb = git_stdout(pkg, ["merge-base", "HEAD", cand]).strip()
        if mb:
            break
    parent = ""
    r = subprocess.run(
        ["git", "-C", str(pkg), "rev-parse", "--verify", "HEAD~1"],
        capture_output=True,
        text=True,
        check=False,
    )
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


def parse_front_matter(text: str) -> dict:
    if not text.startswith("---"):
        raise ValueError("missing YAML front matter")
    parts = text.split("---", 2)
    if len(parts) < 3:
        raise ValueError("unterminated front matter")
    body = parts[1]
    data: dict = {"reviewers": []}
    cur_rev: dict | None = None
    in_paths = False
    in_blocking = False
    path_list: list[str] = []
    for raw in body.splitlines():
        line = raw.rstrip()
        if not line.strip() or line.strip().startswith("#"):
            continue
        if line.startswith("  - id:") or line.startswith("  -id:"):
            if cur_rev:
                data["reviewers"].append(cur_rev)
            cur_rev = {
                "id": line.split(":", 1)[1].strip().strip("\"'"),
                "blocking": [],
            }
            in_blocking = False
            in_paths = False
            continue
        if cur_rev is not None and re.match(r"^    \w", line):
            key, _, val = line.strip().partition(":")
            key, val = key.strip(), val.strip().strip("\"'")
            if key == "blocking":
                in_blocking = True
                if val not in ("", "[]"):
                    pass
                cur_rev["blocking"] = []
                continue
            if in_blocking and line.strip().startswith("- "):
                cur_rev["blocking"].append(line.strip()[2:].strip().strip("\"'"))
                continue
            in_blocking = False
            cur_rev[key] = val
            continue
        if cur_rev is not None and line.startswith("    - ") and in_blocking:
            cur_rev["blocking"].append(line.strip()[2:].strip().strip("\"'"))
            continue
        if not line.startswith(" ") and ":" in line:
            if cur_rev:
                data["reviewers"].append(cur_rev)
                cur_rev = None
            key, _, val = line.partition(":")
            key, val = key.strip(), val.strip().strip("\"'")
            if key == "subject_paths":
                in_paths = True
                path_list = []
                data["subject_paths"] = path_list
                continue
            in_paths = False
            if key == "reviewers":
                continue
            if val in ("true", "false"):
                data[key] = val == "true"
            elif val.isdigit():
                data[key] = int(val)
            else:
                data[key] = val
            continue
        if in_paths and line.strip().startswith("- "):
            path_list.append(line.strip()[2:].strip().strip("\"'"))
            continue
    if cur_rev:
        data["reviewers"].append(cur_rev)
    if "subject_paths" not in data:
        data["subject_paths"] = path_list
    return data


def validate_record(data: dict, triggers: list[str], expected_id: str) -> list[str]:
    errs: list[str] = []
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
        if r.get("verdict") == "FAIL":
            errs.append(f"reviewer[{i}] verdict FAIL")
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
    if not (data.get("conclusion") or "").strip():
        errs.append("missing conclusion")
    return errs


def main(argv: list[str]) -> int:
    pkg = Path(argv[1] if len(argv) > 1 else ".").resolve()
    paths_file = None
    base_override = None
    i = 2
    while i < len(argv):
        a = argv[i]
        if a.startswith("--paths-file="):
            paths_file = a.split("=", 1)[1]
        elif a.startswith("--base="):
            base_override = a.split("=", 1)[1]
        i += 1

    mode = "fixture"
    if paths_file:
        # --paths-file is TEST-ONLY; must not be used as production acceptance path.
        all_changed = [
            ln.strip()
            for ln in Path(paths_file).read_text(encoding="utf-8").splitlines()
            if ln.strip()
        ]
        base = base_override or "fixture"
    else:
        if base_override:
            base, mode = base_override, "override"
        else:
            base, mode = resolve_base(pkg)
        if base is None:
            print("REVIEW_RECORD_FAIL reason=no_git_base")
            print("Honesty: no_git_base cannot pass pack-health; need fetch-depth:0 / git history")
            return 1
        if mode == "head1":
            print("review_record_mode=head1")
        elif mode == "merge_base":
            print("review_record_mode=merge_base")
        all_changed = changed_paths(pkg, base)

    triggers = [p for p in all_changed if is_trigger(p)]
    if not triggers:
        print("REVIEW_RECORD_SKIP reason=no_trigger_paths")
        print("Honesty: exit 0 is not the OK token; SKIP ≠ reviewed")
        return 0

    try:
        cls = blast_class_for(triggers)
        budget = budget_for(cls)
    except ValueError as e:
        print(f"FAIL: {e}", file=sys.stderr)
        print("REVIEW_RECORD_FAIL reason=blast_class")
        return 1

    print(f"blast_class={cls}")
    print(f"review_budget_n={budget['min_reviewers']}")
    print("Honesty: implementer/model/context/reviewer_selected_by are self-declared and unverifiable")
    print("Honesty: model family is disclosure only; diversity gate is reviewer context")

    diff_id = compute_diff_id(pkg, triggers)
    rec_path = pkg / REVIEWS_DIR / f"{diff_id}.md"
    print(f"diff_id={diff_id}")
    print(f"diff_base={base}")
    print(f"trigger_count={len(triggers)}")
    for t in triggers:
        print(f"trigger={t}")

    if not rec_path.is_file():
        print(f"FAIL: missing review record path={rec_path}", file=sys.stderr)
        print("REVIEW_RECORD_FAIL reason=missing_record")
        return 1

    try:
        data = parse_front_matter(rec_path.read_text(encoding="utf-8"))
    except Exception as e:
        print(f"FAIL: parse record: {e}", file=sys.stderr)
        print("REVIEW_RECORD_FAIL reason=parse")
        return 1

    # G1: disclose after parse (visible even when schema later FAIL)
    print_selected_by_disclosure(data.get("reviewers") or [])

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
        print("REVIEW_RECORD_FAIL reason=schema")
        return 1

    print(f"REVIEW_RECORD_OK path={rec_path}")
    print("Honesty: REVIEW_RECORD_OK ≠ review quality ≠ adversarial proof")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
