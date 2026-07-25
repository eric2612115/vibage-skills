#!/usr/bin/env python3
"""W3a P0 dimension-fill: validate+append claims + scope verify tokens.

Spec: docs/superpowers/specs/2026-07-25-vibage-c-prime-dimension-fill-design.md
P0 only — no orchestrator / synth / deepen migrate.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Sequence, Set, Tuple

_SCRIPTS = Path(__file__).resolve().parent.parent
_PKG = _SCRIPTS.parent
if str(_SCRIPTS) not in sys.path:
    sys.path.insert(0, str(_SCRIPTS))

from lib.env_discovery import SECRET_DOTENV_NAMES  # noqa: E402

DIMENSION_CLASSES = frozenset(
    {
        "dimension_behavior",
        "dimension_tests",
        "dimension_security",
        "dimension_ops",
    }
)
TERMINAL_STATES = frozenset({"proven", "failed"})
REQUIRED_CLAIM_KEYS = (
    "id",
    "subject_type",
    "subject_id",
    "claim_class",
    "state",
    "pointers",
)
JSON_FENCE_RE = re.compile(r"```json\s*(\{.*?\})\s*```", flags=re.S)
VACANCY_DISCLOSED = ("ENV_VACANCY_CLEAR", "ENV_VACANCY_ANSWERED", "ENV_VACANCY_ASK")


def mother_marker(path: Path) -> bool:
    return (path / "docs" / "vibage" / "STATUS.md").is_file()


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def load_policy(mother: Path) -> Dict[str, Any]:
    p = mother / "docs" / "vibage" / "OWNER_POLICY.json"
    if not p.is_file():
        return {}
    try:
        obj = load_json(p)
    except (OSError, json.JSONDecodeError):
        return {}
    return obj if isinstance(obj, dict) else {}


def load_freeze(mother: Path) -> Optional[Dict[str, Any]]:
    """Latest DECISIONS.md fenced JSON with dimension_yes (consent freeze)."""
    p = mother / "docs" / "vibage" / "DECISIONS.md"
    if not p.is_file():
        return None
    try:
        text = p.read_text(encoding="utf-8")
    except OSError:
        return None
    freeze = None
    for raw in JSON_FENCE_RE.findall(text):
        if "dimension_yes" not in raw:
            continue
        try:
            cand = json.loads(raw)
        except json.JSONDecodeError:
            continue
        if not isinstance(cand, dict):
            continue
        if "dimension_yes" in cand:
            freeze = cand
    return freeze


def consent_ok(freeze: Optional[Dict[str, Any]]) -> bool:
    if not freeze or not isinstance(freeze, dict):
        return False
    return freeze.get("dimension_yes") is True


def scope_ids(freeze: Optional[Dict[str, Any]]) -> List[str]:
    if not freeze or not isinstance(freeze, dict):
        return []
    ids = freeze.get("dimension_scope_ids")
    if not isinstance(ids, list):
        return []
    out: List[str] = []
    for x in ids:
        s = str(x).strip()
        if s:
            out.append(s)
    return out


def _class_subset(raw: Any) -> Optional[Set[str]]:
    if raw is None:
        return None
    if not isinstance(raw, list):
        return None
    out: Set[str] = set()
    for x in raw:
        s = str(x).strip()
        if s in DIMENSION_CLASSES:
            out.add(s)
    return out


def required_classes(mother: Path, freeze: Optional[Dict[str, Any]]) -> Set[str]:
    """Freeze classes ∩ policy subset ∩ default DIMENSION_CLASSES."""
    classes: Set[str] = set(DIMENSION_CLASSES)
    if freeze:
        fc = _class_subset(freeze.get("dimension_classes"))
        if fc is not None:
            classes &= fc
    policy = load_policy(mother)
    pc = _class_subset(policy.get("dimension_classes"))
    if pc is not None:
        classes &= pc
    return classes


def resolve_repo_root(mother: Path, repo_id: str) -> Optional[Path]:
    """Resolve child repo path from service_map or mother/<repo_id>."""
    sm = mother / "docs" / "vibage" / "maps" / "service_map.json"
    if sm.is_file():
        try:
            obj = load_json(sm)
        except (OSError, json.JSONDecodeError):
            obj = None
        if isinstance(obj, dict):
            for key in ("repos", "services"):
                for row in obj.get(key) or []:
                    if not isinstance(row, dict):
                        continue
                    rid = str(row.get("repo_id") or row.get("id") or "").strip()
                    if rid != repo_id:
                        continue
                    rel = str(row.get("path") or repo_id).strip() or repo_id
                    cand = (mother / rel).resolve()
                    if cand.is_dir():
                        return cand
    cand = (mother / repo_id).resolve()
    if cand.is_dir():
        return cand
    return None


def _is_under(child: Path, root: Path) -> bool:
    try:
        child_r = child.resolve()
        root_r = root.resolve()
    except OSError:
        return False
    if child_r == root_r:
        return True
    return root_r in child_r.parents


def pointer_path_ok(path_str: str, repo_root: Path) -> Tuple[bool, str]:
    if not path_str or not str(path_str).strip():
        return False, "pointer path empty"
    raw = str(path_str).strip()
    base = Path(raw).name
    if base in SECRET_DOTENV_NAMES:
        return False, f"secret dotenv basename forbidden: {base}"
    p = Path(raw)
    candidates: List[Path] = []
    if p.is_absolute():
        candidates.append(p)
    else:
        candidates.append(repo_root / p)
        # mother-relative paths like svc-a/README.md
        candidates.append(repo_root.parent / p)
    for c in candidates:
        if _is_under(c, repo_root):
            return True, ""
    return False, f"pointer path not under repo: {raw}"


def validate_claim(claim: Any, repo_root: Path) -> Tuple[bool, str]:
    if not isinstance(claim, dict):
        return False, "claim must be a JSON object"
    for key in REQUIRED_CLAIM_KEYS:
        if key not in claim:
            return False, f"claim missing required field: {key}"
    if claim.get("subject_type") != "repo":
        return False, "subject_type must be repo"
    sid = str(claim.get("subject_id") or "").strip()
    if not sid:
        return False, "subject_id required"
    cls = claim.get("claim_class")
    if cls not in DIMENSION_CLASSES:
        return False, f"claim_class must be one of {sorted(DIMENSION_CLASSES)}"
    state = claim.get("state")
    if state not in TERMINAL_STATES:
        return False, "state must be proven|failed"
    pointers = claim.get("pointers")
    if not isinstance(pointers, list) or len(pointers) < 1:
        return False, "pointers must be a non-empty list"
    for i, ptr in enumerate(pointers):
        if not isinstance(ptr, dict):
            return False, f"pointers[{i}] must be an object"
        path = ptr.get("path")
        if not path:
            return False, f"pointers[{i}] must include path"
        ok, err = pointer_path_ok(str(path), repo_root)
        if not ok:
            return False, err
    return True, ""


def _run_script(script_name: str, mother: Path) -> Tuple[int, str]:
    script = _PKG / "scripts" / script_name
    try:
        r = subprocess.run(
            ["bash", str(script), str(mother)],
            capture_output=True,
            text=True,
            check=False,
        )
    except OSError as e:
        return 1, f"FAIL: {e}"
    out = (r.stdout or "").strip()
    return int(r.returncode), out


def _primary_token(stdout: str) -> str:
    for line in (stdout or "").splitlines():
        line = line.strip()
        if line:
            return line.split()[0] if line.split() else line
    return ""


def _first_line(stdout: str) -> str:
    for line in (stdout or "").splitlines():
        line = line.strip()
        if line:
            return line
    return ""


def graph_floor_ok(mother: Path) -> bool:
    rc, out = _run_script("verify-graph-floor.sh", mother)
    return rc == 0 and "GRAPH_FLOOR_OK" in out


def matrix_ok(mother: Path) -> bool:
    rc, out = _run_script("verify-env-branch-matrix.sh", mother)
    return rc == 0 and "ENV_BRANCH_MATRIX_OK" in out


def vacancy_probe(mother: Path) -> Tuple[str, str]:
    """Return (primary_token, first_line)."""
    _rc, out = _run_script("verify-env-vacancy.sh", mother)
    return _primary_token(out), _first_line(out)


def load_latest_dimension_claims(mother: Path) -> Dict[Tuple[str, str], Dict[str, Any]]:
    """Latest claim per (subject_id, claim_class) for dimension_* classes."""
    path = mother / "docs" / "vibage" / "ledger" / "claims.jsonl"
    latest: Dict[Tuple[str, str], Dict[str, Any]] = {}
    if not path.is_file():
        return latest
    try:
        text = path.read_text(encoding="utf-8")
    except OSError:
        return latest
    for line in text.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            claim = json.loads(line)
        except json.JSONDecodeError:
            continue
        if not isinstance(claim, dict):
            continue
        cls = claim.get("claim_class")
        if cls not in DIMENSION_CLASSES:
            continue
        sid = str(claim.get("subject_id") or "").strip()
        if not sid:
            continue
        latest[(sid, str(cls))] = claim
    return latest


def tally_and_token(
    mother: Path,
    scope: Sequence[str],
    classes: Set[str],
) -> Tuple[str, int]:
    """Return (token_line, exit_code) per W3a §7 / P0 probes."""
    freeze = load_freeze(mother)
    if not consent_ok(freeze):
        return "DIMENSION_FILL_BLOCKED reason=no_consent", 1

    if not mother_marker(mother):
        return "DIMENSION_FILL_BLOCKED reason=no_floor", 1
    if not graph_floor_ok(mother):
        return "DIMENSION_FILL_BLOCKED reason=no_floor", 1

    m_ok = matrix_ok(mother)
    v_tok, _v_line = vacancy_probe(mother)
    disclosed = any(v_tok.startswith(p) for p in VACANCY_DISCLOSED)
    if not m_ok and not disclosed:
        return "DIMENSION_FILL_BLOCKED reason=matrix_opaque", 1

    if v_tok.startswith("ENV_VACANCY_ASK"):
        return "DIMENSION_FILL_PARTIAL reason=vacancy_ask", 0

    scope_list = [str(x).strip() for x in scope if str(x).strip()]
    if not scope_list:
        # freeze present but empty scope → incomplete
        return "DIMENSION_FILL_PARTIAL reason=incomplete_scope", 0
    if not classes:
        return "DIMENSION_FILL_PARTIAL reason=incomplete_scope", 0

    latest = load_latest_dimension_claims(mother)
    proven = 0
    failed = 0
    missing = 0
    for rid in scope_list:
        for cls in sorted(classes):
            claim = latest.get((rid, cls))
            if not claim or claim.get("state") not in TERMINAL_STATES:
                missing += 1
                continue
            if claim.get("state") == "proven":
                proven += 1
            else:
                failed += 1

    if missing > 0:
        return "DIMENSION_FILL_PARTIAL reason=incomplete_scope", 0

    return f"DIMENSION_FILL_OK tally=proven:{proven},failed:{failed}", 0


def _heuristic_allowed(mother: Path, claim_path_hint: str) -> bool:
    if os.environ.get("VIBAGE_DIMENSION_HEURISTIC", "").strip() != "1":
        return False
    # Fixture/test only: mother or claim path under tests/ or system temp
    candidates = [str(mother.resolve()), claim_path_hint or ""]
    for c in candidates:
        if not c:
            continue
        norm = c.replace("\\", "/")
        if "/tests/" in norm or norm.endswith("/tests"):
            return True
        if "/tmp/" in norm or norm.startswith("/tmp") or "/var/folders/" in norm:
            return True
    return False


def cmd_verify(args: argparse.Namespace) -> int:
    mother = Path(args.mother).resolve()
    freeze = load_freeze(mother)
    if not consent_ok(freeze):
        print("DIMENSION_FILL_BLOCKED reason=no_consent")
        return 1
    ids = scope_ids(freeze)
    classes = required_classes(mother, freeze)
    token, code = tally_and_token(mother, ids, classes)
    print(token)
    return int(code)


def cmd_search(args: argparse.Namespace) -> int:
    mother = Path(args.mother).resolve()
    if not mother_marker(mother):
        print("FAIL: mother missing docs/vibage/STATUS.md", file=sys.stderr)
        return 1

    repo_id = str(args.repo_id).strip()
    claim_class = str(args.claim_class).strip()
    if claim_class not in DIMENSION_CLASSES:
        print(
            f"FAIL: claim_class must be one of {sorted(DIMENSION_CLASSES)}",
            file=sys.stderr,
        )
        return 1

    repo_root = resolve_repo_root(mother, repo_id)
    if repo_root is None:
        print(f"FAIL: cannot resolve repo_id={repo_id}", file=sys.stderr)
        return 1

    src = args.claim_json
    hint = ""
    if src == "-":
        raw = sys.stdin.read()
        hint = "-"
    else:
        hint = str(Path(src).resolve())
        try:
            raw = Path(src).read_text(encoding="utf-8")
        except OSError as e:
            print(f"FAIL: cannot read claim JSON: {e}", file=sys.stderr)
            return 1

    try:
        claim = json.loads(raw)
    except json.JSONDecodeError as e:
        print(f"FAIL: claim is not valid JSON: {e}", file=sys.stderr)
        return 1

    heuristic = bool(getattr(args, "heuristic", False)) or bool(
        isinstance(claim, dict) and claim.get("heuristic")
    )
    if heuristic and not _heuristic_allowed(mother, hint):
        print(
            "FAIL: heuristic minting refused "
            "(set VIBAGE_DIMENSION_HEURISTIC=1 for fixture/test only)",
            file=sys.stderr,
        )
        return 1

    if isinstance(claim, dict):
        # Normalize identity from CLI when omitted
        claim.setdefault("subject_type", "repo")
        claim.setdefault("subject_id", repo_id)
        claim.setdefault("claim_class", claim_class)
        if str(claim.get("subject_id") or "") != repo_id:
            print(
                f"FAIL: subject_id must match repo_id={repo_id}",
                file=sys.stderr,
            )
            return 1
        if claim.get("claim_class") != claim_class:
            print(
                f"FAIL: claim_class must match {claim_class}",
                file=sys.stderr,
            )
            return 1

    ok, err = validate_claim(claim, repo_root)
    if not ok:
        print(f"FAIL: {err}", file=sys.stderr)
        return 1

    append = _PKG / "scripts" / "ledger-append.sh"
    payload = json.dumps(claim, ensure_ascii=False, separators=(",", ":"))
    try:
        r = subprocess.run(
            ["bash", str(append), str(mother), payload],
            capture_output=True,
            text=True,
            check=False,
        )
    except OSError as e:
        print(f"FAIL: ledger-append: {e}", file=sys.stderr)
        return 1
    if r.returncode != 0:
        msg = (r.stderr or r.stdout or "ledger-append failed").strip()
        print(msg, file=sys.stderr)
        return 1
    out = (r.stdout or "").strip()
    if out:
        print(out)
    return 0


def main(argv: Optional[List[str]] = None) -> int:
    p = argparse.ArgumentParser(prog="dimension_fill.py")
    sub = p.add_subparsers(dest="cmd", required=True)

    v = sub.add_parser("verify")
    v.add_argument("mother")
    v.set_defaults(func=cmd_verify)

    s = sub.add_parser("search")
    s.add_argument("mother")
    s.add_argument("repo_id")
    s.add_argument("claim_class")
    s.add_argument("claim_json", help="path to claim JSON, or - for stdin")
    s.add_argument(
        "--heuristic",
        action="store_true",
        help="fixture/test only; requires VIBAGE_DIMENSION_HEURISTIC=1",
    )
    s.set_defaults(func=cmd_search)

    args = p.parse_args(argv)
    return int(args.func(args))


if __name__ == "__main__":
    sys.exit(main())
