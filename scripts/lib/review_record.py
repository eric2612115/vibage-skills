#!/usr/bin/env python3
"""Review-record gate helpers. ∉ Tier-0.

diff_id = sha256 of sorted trigger paths + content digests.
Excludes docs/evidence/reviews/** so writing a record cannot invalidate its id.
exit 0 ≠ REVIEW_RECORD_OK — parse stdout tokens.
"""
from __future__ import annotations

import hashlib
import os
import re
import subprocess
import sys
from pathlib import Path

TRIGGER_PREFIXES = (
    "scripts/lib/",
    "adapters/",
    "skills/using-vibage/",
    "tests/",
)
TRIGGER_EXACT = {
    "references/hard-stops.md",
    "references/looping-review.md",
    "references/routing-scope.md",
    "scripts/assert_gate.sh",
    "scripts/write_confirm.sh",
    "scripts/coverage-box.sh",
    "scripts/test-tier0.sh",
    "scripts/pack-health.sh",
}
TRIGGER_VERIFY_GLOB = "scripts/verify-"

REVIEWS_DIR = "docs/evidence/reviews"


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
    # worktree + index vs HEAD
    for args in (["diff", "--name-only"], ["diff", "--name-only", "--cached"]):
        out = git_stdout(pkg, args)
        paths.update(p for p in out.splitlines() if p.strip())
    # untracked (needed for first landing of new guarded files)
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
    # Minimal YAML subset for our schema (no PyYAML dependency)
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
                    # inline list not supported beyond empty
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
    revs = data.get("reviewers") or []
    if len(revs) < 3:
        errs.append(f"need ≥3 reviewers, got {len(revs)}")
    for i, r in enumerate(revs):
        if r.get("verdict") == "FAIL":
            errs.append(f"reviewer[{i}] verdict FAIL")
        if r.get("blocking"):
            errs.append(f"reviewer[{i}] blocking non-empty: {r.get('blocking')}")
        if not r.get("model"):
            errs.append(f"reviewer[{i}] missing model")
    if not data.get("frozen"):
        errs.append("frozen must be true")
    div = data.get("diversity")
    if div == "ok":
        models = {r.get("model") for r in revs if r.get("model")}
        if len(models) < 2:
            errs.append("diversity=ok requires ≥2 distinct model strings")
    elif div == "waived":
        if not (data.get("diversity_reason") or "").strip():
            errs.append("diversity=waived requires diversity_reason")
    else:
        errs.append("diversity must be ok|waived")
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
            # History insufficient to evaluate — FAIL (not SKIP / not fake-green)
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
