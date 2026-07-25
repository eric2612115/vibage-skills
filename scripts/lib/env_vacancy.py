#!/usr/bin/env python3
"""W2 env vacancy ask/configure: answers JSON + tokens + resolved logic.

Spec: docs/superpowers/specs/2026-07-25-vibage-c-prime-env-vacancy-ask-design.md
"""
from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

# scripts/ on path when run as CLI; allow import of env_discovery
_SCRIPTS = Path(__file__).resolve().parent.parent
if str(_SCRIPTS) not in sys.path:
    sys.path.insert(0, str(_SCRIPTS))

from lib.env_discovery import SECRET_DOTENV_NAMES  # noqa: E402

ACTIONS = frozenset({"skip", "point", "classify"})
REPO_CLASSES = frozenset({"no-deploy", "docs-only", "tooling", "other"})
MISSING_ENV = "missing-env-config"
ASK_LINE = (
    "VIBAGE_ENV_VACANCY_ASK: repo={rid} has missing-env-config. "
    "Choose skip | point:<rel-path> | classify:<class> — reason required. Asking ≠ 掃透."
)


def utc_now_str() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def mother_marker(path: Path) -> bool:
    return (path / "docs" / "vibage" / "STATUS.md").is_file()


def answers_path(mother: Path) -> Path:
    return mother / "docs" / "vibage" / "maps" / "env_vacancy_answers.json"


def matrix_path(mother: Path) -> Path:
    return mother / "docs" / "vibage" / "maps" / "env_branch_matrix.json"


def cell_key(repo_id: str, branch_ref: str, env_id: str) -> str:
    return f"{repo_id}|{branch_ref}|{env_id}"


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def empty_answers() -> Dict[str, Any]:
    return {
        "schema_version": "1",
        "updated_at": utc_now_str(),
        "answers": {},
    }


def load_answers(mother: Path) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    """Return (obj, error). Missing file → empty answers. Malformed → error."""
    p = answers_path(mother)
    if not p.is_file():
        return empty_answers(), None
    try:
        obj = load_json(p)
    except (OSError, json.JSONDecodeError) as e:
        return None, f"answers unreadable: {e}"
    if not isinstance(obj, dict):
        return None, "answers must be a JSON object"
    ans = obj.get("answers")
    if ans is None:
        obj = dict(obj)
        obj["answers"] = {}
        return obj, None
    if not isinstance(ans, dict):
        return None, "answers.answers must be an object"
    return obj, None


def save_answers(mother: Path, obj: Dict[str, Any]) -> None:
    p = answers_path(mother)
    p.parent.mkdir(parents=True, exist_ok=True)
    out = dict(obj)
    out["schema_version"] = str(out.get("schema_version") or "1")
    out["updated_at"] = utc_now_str()
    if not isinstance(out.get("answers"), dict):
        out["answers"] = {}
    p.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")


def load_matrix(mother: Path) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    p = matrix_path(mother)
    if not p.is_file():
        return None, f"missing {p}"
    try:
        obj = load_json(p)
    except (OSError, json.JSONDecodeError) as e:
        return None, f"matrix unreadable: {e}"
    if not isinstance(obj, dict):
        return None, "matrix must be a JSON object"
    cells = obj.get("cells")
    if not isinstance(cells, list):
        return None, "matrix.cells must be a list"
    return obj, None


def missing_cells(matrix: Dict[str, Any]) -> List[Dict[str, Any]]:
    out: List[Dict[str, Any]] = []
    for c in matrix.get("cells") or []:
        if not isinstance(c, dict):
            continue
        if c.get("env_id") == MISSING_ENV:
            out.append(c)
    return out


def is_secret_dotenv_path(relpath: str) -> bool:
    base = Path(relpath).name
    return base in SECRET_DOTENV_NAMES or base == ".env"


def validate_answer_entry(
    entry: Dict[str, Any],
    mother: Path,
    *,
    require_point_exists: bool = True,
) -> Optional[str]:
    """Return error message or None if valid."""
    if not isinstance(entry, dict):
        return "answer entry must be an object"
    action = entry.get("action")
    if action not in ACTIONS:
        return f"invalid action {action!r}"
    reason = str(entry.get("reason") or "").strip()
    if not reason:
        return "reason required (non-empty)"
    for k in ("repo_id", "branch_ref", "env_id"):
        if not str(entry.get(k) or "").strip():
            return f"{k} required"
    if action == "skip":
        return None
    if action == "classify":
        rc = entry.get("repo_class")
        if rc not in REPO_CLASSES:
            return f"repo_class must be one of {sorted(REPO_CLASSES)}"
        return None
    # point
    pp = str(entry.get("point_path") or "").strip()
    if not pp:
        return "point_path required"
    if Path(pp).is_absolute() or pp.startswith("..") or "/../" in f"/{pp}/":
        return "point_path must be repo-relative (no ..)"
    if is_secret_dotenv_path(pp):
        return f"point_path refuses secret dotenv basename: {Path(pp).name}"
    if require_point_exists:
        repo_id = str(entry.get("repo_id") or "").strip()
        target = (mother / repo_id / pp).resolve()
        repo_root = (mother / repo_id).resolve()
        try:
            target.relative_to(repo_root)
        except ValueError:
            return "point_path escapes repo root"
        if not target.is_file():
            return f"point_path does not exist: {repo_id}/{pp}"
    return None


def is_skip_or_classify_resolved(entry: Optional[Dict[str, Any]]) -> bool:
    """True iff answer is skip|classify with required fields (no filesystem check)."""
    if not isinstance(entry, dict):
        return False
    action = entry.get("action")
    if action not in ("skip", "classify"):
        return False
    if not str(entry.get("reason") or "").strip():
        return False
    for k in ("repo_id", "branch_ref", "env_id"):
        if not str(entry.get(k) or "").strip():
            return False
    if action == "classify" and entry.get("repo_class") not in REPO_CLASSES:
        return False
    return True


def answers_map(obj: Dict[str, Any]) -> Dict[str, Any]:
    ans = obj.get("answers") if isinstance(obj, dict) else None
    return ans if isinstance(ans, dict) else {}


def validate_answers_payload(
    obj: Dict[str, Any], mother: Path
) -> Optional[str]:
    """Validate all answer entries; return first error or None."""
    for key, entry in answers_map(obj).items():
        if not isinstance(entry, dict):
            return f"answers[{key!r}] must be an object"
        err = validate_answer_entry(entry, mother, require_point_exists=True)
        if err:
            return f"answers[{key!r}]: {err}"
        # key consistency
        expect = cell_key(
            str(entry.get("repo_id") or ""),
            str(entry.get("branch_ref") or ""),
            str(entry.get("env_id") or ""),
        )
        if key != expect:
            return f"answers key {key!r} != {expect!r}"
    return None


def cell_is_resolved(
    cell: Dict[str, Any], ans_map: Dict[str, Any]
) -> bool:
    """Resolved for matrix §5.1: skip|classify only. Point-pending = False."""
    key = cell_key(
        str(cell.get("repo_id") or ""),
        str(cell.get("branch_ref") or ""),
        str(cell.get("env_id") or ""),
    )
    return is_skip_or_classify_resolved(ans_map.get(key))


def check_mother(mother: Path) -> int:
    """Print exactly one primary ENV_VACANCY_* token; exit per §6."""
    if not mother_marker(mother):
        print("ENV_VACANCY_BLOCKED")
        print("FAIL: mother missing docs/vibage/STATUS.md", file=sys.stderr)
        return 1

    matrix, merr = load_matrix(mother)
    if merr or matrix is None:
        print("ENV_VACANCY_BLOCKED")
        print(f"FAIL: {merr}", file=sys.stderr)
        return 1

    answers_obj, aerr = load_answers(mother)
    if aerr or answers_obj is None:
        print("ENV_VACANCY_BLOCKED")
        print(f"FAIL: {aerr}", file=sys.stderr)
        return 1

    verr = validate_answers_payload(answers_obj, mother)
    if verr:
        print("ENV_VACANCY_BLOCKED")
        print(f"FAIL: {verr}", file=sys.stderr)
        return 1

    miss = missing_cells(matrix)
    n = len(miss)
    if n == 0:
        print("ENV_VACANCY_CLEAR")
        return 0

    ans_map = answers_map(answers_obj)
    unanswered: List[Dict[str, Any]] = []
    for c in miss:
        if cell_is_resolved(c, ans_map):
            continue
        unanswered.append(c)

    if unanswered:
        print(f"ENV_VACANCY_ASK count={len(unanswered)}")
        seen: set = set()
        for c in unanswered:
            rid = str(c.get("repo_id") or "")
            if rid and rid not in seen:
                seen.add(rid)
                print(ASK_LINE.format(rid=rid))
        return 1

    # All missing are skip|classify resolved; n≥1
    print(f"ENV_VACANCY_ANSWERED count={n}")
    return 0


def cmd_check(args: argparse.Namespace) -> int:
    mother = Path(args.mother).resolve()
    return check_mother(mother)


def cmd_answer(args: argparse.Namespace) -> int:
    mother = Path(args.mother).resolve()
    if not mother_marker(mother):
        print("FAIL: mother missing docs/vibage/STATUS.md", file=sys.stderr)
        return 1

    reason = (args.reason or "").strip()
    if not reason:
        print("FAIL: --reason required (non-empty)", file=sys.stderr)
        return 1

    repo_id = (args.repo or "").strip()
    branch_ref = (args.branch or "").strip()
    env_id = (args.env or "").strip() or MISSING_ENV
    if not repo_id or not branch_ref:
        print("FAIL: --repo and --branch required", file=sys.stderr)
        return 1

    if args.skip:
        action = "skip"
        entry: Dict[str, Any] = {
            "action": "skip",
            "reason": reason,
            "at": utc_now_str(),
            "repo_id": repo_id,
            "branch_ref": branch_ref,
            "env_id": env_id,
        }
    elif args.classify is not None:
        action = "classify"
        entry = {
            "action": "classify",
            "reason": reason,
            "at": utc_now_str(),
            "repo_id": repo_id,
            "branch_ref": branch_ref,
            "env_id": env_id,
            "repo_class": args.classify,
        }
    elif args.point is not None:
        action = "point"
        entry = {
            "action": "point",
            "reason": reason,
            "at": utc_now_str(),
            "repo_id": repo_id,
            "branch_ref": branch_ref,
            "env_id": env_id,
            "point_path": args.point.strip(),
        }
    else:
        print("FAIL: need --skip | --classify=<class> | --point=<relpath>", file=sys.stderr)
        return 1

    err = validate_answer_entry(entry, mother, require_point_exists=True)
    if err:
        print("ENV_VACANCY_BLOCKED")
        print(f"FAIL: {err}", file=sys.stderr)
        return 1

    obj, aerr = load_answers(mother)
    if aerr or obj is None:
        print("ENV_VACANCY_BLOCKED")
        print(f"FAIL: {aerr}", file=sys.stderr)
        return 1

    key = cell_key(repo_id, branch_ref, env_id)
    ans = answers_map(obj)
    ans[key] = entry
    obj["answers"] = ans
    save_answers(mother, obj)
    print(f"OK: recorded {action} for {key}")
    return 0


def main(argv: Optional[List[str]] = None) -> int:
    p = argparse.ArgumentParser(prog="env_vacancy.py")
    sub = p.add_subparsers(dest="cmd", required=True)

    c = sub.add_parser("check")
    c.add_argument("mother")
    c.set_defaults(func=cmd_check)

    a = sub.add_parser("answer")
    g = a.add_mutually_exclusive_group(required=True)
    g.add_argument("--skip", action="store_true")
    g.add_argument("--classify", metavar="CLASS", default=None)
    g.add_argument("--point", metavar="RELPATH", default=None)
    a.add_argument("--reason", required=True)
    a.add_argument("--repo", required=True)
    a.add_argument("--branch", required=True)
    a.add_argument("--env", default=MISSING_ENV)
    a.add_argument("mother")
    a.set_defaults(func=cmd_answer)

    args = p.parse_args(argv)
    return int(args.func(args))


if __name__ == "__main__":
    sys.exit(main())
