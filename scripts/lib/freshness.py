#!/usr/bin/env python3
"""W1 freshness: fingerprints, stale compute, waiver, mother resolve.

Spec: docs/superpowers/specs/2026-07-25-vibage-c-prime-sync-freshness-design.md
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple

TERMINAL = frozenset({"proven", "failed"})
ESCALATE_LINE = (
    "VIBAGE_FRESHNESS_ESCALATE: repo={rid} refused hub update N>=3; "
    "mother session must disclose before continuum slogans"
)


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def utc_now_str() -> str:
    return utc_now().strftime("%Y-%m-%dT%H:%M:%SZ")


def parse_iso(s: str) -> Optional[datetime]:
    if not s or not isinstance(s, str):
        return None
    raw = s.strip()
    if raw.endswith("Z"):
        raw = raw[:-1] + "+00:00"
    try:
        dt = datetime.fromisoformat(raw)
    except ValueError:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def mother_marker(path: Path) -> bool:
    return (path / "docs" / "vibage" / "STATUS.md").is_file()


def resolve_mother(start: Path) -> Optional[Path]:
    env = os.environ.get("VIBAGE_PARENT", "").strip()
    if env:
        p = Path(env).expanduser()
        try:
            p = p.resolve()
        except OSError:
            p = Path(env)
        if mother_marker(p):
            return p
    cur = start.resolve()
    for cand in [cur, *cur.parents]:
        if mother_marker(cand):
            return cand
    return None


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


def freshness_path(mother: Path) -> Path:
    return mother / "docs" / "vibage" / "maps" / "freshness.json"


def matrix_path(mother: Path) -> Path:
    return mother / "docs" / "vibage" / "maps" / "env_branch_matrix.json"


def service_map_path(mother: Path) -> Path:
    return mother / "docs" / "vibage" / "maps" / "service_map.json"


def load_freshness(mother: Path) -> Optional[Dict[str, Any]]:
    p = freshness_path(mother)
    if not p.is_file():
        return None
    try:
        obj = load_json(p)
    except (OSError, json.JSONDecodeError):
        return None
    return obj if isinstance(obj, dict) else None


def save_freshness(mother: Path, obj: Dict[str, Any]) -> None:
    p = freshness_path(mother)
    p.parent.mkdir(parents=True, exist_ok=True)
    obj = dict(obj)
    obj["updated_at"] = utc_now_str()
    p.write_text(json.dumps(obj, indent=2) + "\n", encoding="utf-8")


def in_scope_repo_ids(mother: Path) -> List[str]:
    mp = service_map_path(mother)
    if not mp.is_file():
        return []
    try:
        obj = load_json(mp)
    except (OSError, json.JSONDecodeError):
        return []
    ids: List[str] = []
    seen: Set[str] = set()
    for r in obj.get("repos") or []:
        if not isinstance(r, dict):
            continue
        rid = r.get("repo_id") or r.get("path") or r.get("id") or ""
        rid = str(rid).strip()
        if rid and rid not in seen:
            seen.add(rid)
            ids.append(rid)
    if not ids:
        for s in obj.get("services") or []:
            if not isinstance(s, dict):
                continue
            rid = s.get("path") or s.get("id") or ""
            rid = str(rid).strip()
            if rid and rid not in seen:
                seen.add(rid)
                ids.append(rid)
    return ids


def repo_checkout(mother: Path, repo_id: str) -> Optional[Path]:
    """Resolve checkout path for repo_id (relative to mother or absolute)."""
    mp = service_map_path(mother)
    if mp.is_file():
        try:
            obj = load_json(mp)
        except (OSError, json.JSONDecodeError):
            obj = {}
        for r in obj.get("repos") or []:
            if not isinstance(r, dict):
                continue
            rid = str(r.get("repo_id") or r.get("path") or r.get("id") or "").strip()
            if rid != repo_id:
                continue
            path = str(r.get("path") or rid).strip()
            wt = r.get("worktree_path")
            if wt and str(wt) not in (".", ""):
                cand = Path(str(wt))
                if not cand.is_absolute():
                    cand = mother / cand
                if cand.is_dir():
                    return cand.resolve()
            cand = Path(path)
            if not cand.is_absolute():
                cand = mother / path
            if cand.is_dir():
                return cand.resolve()
    cand = mother / repo_id
    if cand.is_dir():
        return cand.resolve()
    return None


def git_head(repo_root: Optional[Path]) -> Optional[str]:
    if repo_root is None or not repo_root.is_dir():
        return None
    try:
        r = subprocess.run(
            ["git", "-C", str(repo_root), "rev-parse", "HEAD"],
            capture_output=True,
            text=True,
            check=False,
        )
    except OSError:
        return None
    if r.returncode != 0:
        return None
    h = (r.stdout or "").strip()
    return h or None


def ttl_days(mother: Path, freshness: Optional[Dict[str, Any]] = None) -> int:
    pol = load_policy(mother)
    if "freshness_ttl_days" in pol:
        try:
            d = int(pol["freshness_ttl_days"])
            if d >= 1:
                return d
        except (TypeError, ValueError):
            pass
    if freshness and "ttl_days" in freshness:
        try:
            d = int(freshness["ttl_days"])
            if d >= 1:
                return d
        except (TypeError, ValueError):
            pass
    return 7


def age_exceeds_ttl(scanned_at: str, ttl: int, now: Optional[datetime] = None) -> bool:
    dt = parse_iso(scanned_at)
    if dt is None:
        return True
    now = now or utc_now()
    return (now - dt).total_seconds() > ttl * 86400


def compute_stale(mother: Path) -> Dict[str, str]:
    """Return {repo_id: reason} for in-scope stale repos."""
    scope = in_scope_repo_ids(mother)
    fr = load_freshness(mother)
    ttl = ttl_days(mother, fr)
    stale: Dict[str, str] = {}
    if fr is None:
        for rid in scope:
            stale[rid] = "missing_freshness_json"
        return stale
    repos = fr.get("repos") if isinstance(fr.get("repos"), dict) else {}
    for rid in scope:
        entry = repos.get(rid) if isinstance(repos.get(rid), dict) else None
        if entry is None:
            stale[rid] = "missing_record"
            continue
        if entry.get("stale") is True:
            stale[rid] = "marked_stale"
            continue
        head_stored = str(entry.get("head") or "").strip()
        checkout = repo_checkout(mother, rid)
        head_now = git_head(checkout)
        # Empty stored head is never "fresh" when a checkout exists (anti-greenwash).
        if checkout is not None and not head_stored:
            stale[rid] = "empty_stored_head"
            continue
        if head_now is not None and head_stored and head_now != head_stored:
            stale[rid] = "head_changed"
            continue
        # Checkout became available after empty-head mark — treat as drift.
        if head_now is not None and not head_stored:
            stale[rid] = "empty_stored_head"
            continue
        scanned = str(entry.get("scanned_at") or "")
        if age_exceeds_ttl(scanned, ttl):
            stale[rid] = "ttl_expired"
            continue
    return stale


def refuse_counts(mother: Path) -> Dict[str, int]:
    fr = load_freshness(mother)
    if not fr:
        return {}
    repos = fr.get("repos") if isinstance(fr.get("repos"), dict) else {}
    out: Dict[str, int] = {}
    for rid, entry in repos.items():
        if not isinstance(entry, dict):
            continue
        try:
            n = int(entry.get("refuse_count") or 0)
        except (TypeError, ValueError):
            n = 0
        if n >= 3:
            out[str(rid)] = n
    return out


def incomplete_matrix_count(mother: Path) -> int:
    """Count unproven cells. Returns -1 if matrix file missing/unreadable."""
    mp = matrix_path(mother)
    if not mp.is_file():
        return -1
    try:
        obj = load_json(mp)
    except (OSError, json.JSONDecodeError):
        return -1
    n = 0
    for c in obj.get("cells") or []:
        if not isinstance(c, dict):
            continue
        if c.get("state") == "unproven":
            n += 1
    return n


def waiver_structurally_valid(w: Any) -> bool:
    if not isinstance(w, dict):
        return False
    reason = w.get("reason")
    if not isinstance(reason, str) or not reason.strip():
        return False
    at = parse_iso(str(w.get("at") or ""))
    review_by = parse_iso(str(w.get("review_by") or ""))
    if at is None or review_by is None:
        return False
    # review_by may be date-only; treat end of that UTC day if time midnight
    if utc_now() > review_by:
        # if review_by is date at 00:00Z, allow through end of that calendar day
        if review_by.hour == 0 and review_by.minute == 0 and review_by.second == 0:
            end = review_by.replace(hour=23, minute=59, second=59)
            if utc_now() > end:
                return False
        else:
            return False
    scope = w.get("scope")
    if not isinstance(scope, list) or not scope:
        return False
    for item in scope:
        if not isinstance(item, str) or not item.strip():
            return False
    return True


def waiver_covers(w: Dict[str, Any], stale_ids: Set[str]) -> bool:
    scope = [str(x).strip() for x in (w.get("scope") or [])]
    if "*" in scope:
        return True
    return stale_ids.issubset(set(scope))


def waiver_valid(pol: Dict[str, Any], stale_ids: Set[str]) -> bool:
    w = pol.get("freshness_skip_waiver")
    if not waiver_structurally_valid(w):
        return False
    assert isinstance(w, dict)
    if not stale_ids:
        return True
    return waiver_covers(w, stale_ids)


def cells_for_repo(mother: Path, repo_id: str) -> List[Dict[str, Any]]:
    mp = matrix_path(mother)
    if not mp.is_file():
        return []
    try:
        obj = load_json(mp)
    except (OSError, json.JSONDecodeError):
        return []
    out = []
    for c in obj.get("cells") or []:
        if isinstance(c, dict) and str(c.get("repo_id") or "") == repo_id:
            out.append(c)
    return out


def cells_all_terminal(mother: Path, repo_id: str) -> bool:
    cells = cells_for_repo(mother, repo_id)
    if not cells:
        return False
    for c in cells:
        if c.get("state") not in TERMINAL:
            return False
    return True


def ensure_repo_entry(fr: Dict[str, Any], repo_id: str) -> Dict[str, Any]:
    repos = fr.setdefault("repos", {})
    if not isinstance(repos, dict):
        repos = {}
        fr["repos"] = repos
    entry = repos.get(repo_id)
    if not isinstance(entry, dict):
        entry = {
            "head": "",
            "scanned_at": "",
            "stale": True,
            "refuse_count": 0,
        }
        repos[repo_id] = entry
    return entry


def mark_success(mother: Path, repo_id: str) -> Tuple[int, str]:
    if not cells_all_terminal(mother, repo_id):
        return 1, "FAIL: mark --success requires all matrix cells terminal for repo"
    checkout = repo_checkout(mother, repo_id)
    head = git_head(checkout)
    if not head:
        return 1, "FAIL: mark --success requires git HEAD for repo checkout"
    fr = load_freshness(mother) or {
        "schema_version": "1",
        "ttl_days": ttl_days(mother),
        "repos": {},
    }
    entry = ensure_repo_entry(fr, repo_id)
    entry["head"] = head
    entry["scanned_at"] = utc_now_str()
    entry["stale"] = False
    entry["refuse_count"] = 0
    save_freshness(mother, fr)
    return 0, f"OK: freshness marked success repo={repo_id}"


def mark_refuse(mother: Path, repo_id: str) -> Tuple[int, str]:
    fr = load_freshness(mother) or {
        "schema_version": "1",
        "ttl_days": ttl_days(mother),
        "repos": {},
    }
    entry = ensure_repo_entry(fr, repo_id)
    try:
        n = int(entry.get("refuse_count") or 0)
    except (TypeError, ValueError):
        n = 0
    entry["refuse_count"] = n + 1
    entry["stale"] = True
    save_freshness(mother, fr)
    return 0, f"OK: freshness refuse repo={repo_id} count={entry['refuse_count']}"


def check_mother(mother: Path) -> int:
    scope = in_scope_repo_ids(mother)
    if not service_map_path(mother).is_file() or not scope:
        print(
            "stale_count=-1 incomplete_matrix=-1",
            file=sys.stderr,
        )
        print(
            "NOTE: no in-scope repos / missing service_map — run graph-floor before FRESHNESS_OK",
            file=sys.stderr,
        )
        print("STALE_BLOCKS_MOTHER count=0")
        return 1
    stale = compute_stale(mother)
    escalate = refuse_counts(mother)
    incomplete = incomplete_matrix_count(mother)
    # Always emit session-useful counts on stderr for skills
    print(
        f"stale_count={len(stale)} incomplete_matrix={incomplete}",
        file=sys.stderr,
    )
    for rid, n in sorted(escalate.items()):
        print(ESCALATE_LINE.format(rid=rid).replace("N>=3", f"N>={n}"))
    if not stale:
        print("FRESHNESS_OK")
        return 0
    pol = load_policy(mother)
    if waiver_valid(pol, set(stale.keys())):
        print("FRESHNESS_WAIVED")
        print(f"STALE_DISCLOSED count={len(stale)}")
        return 0
    print(f"STALE_BLOCKS_MOTHER count={len(stale)}")
    return 1


def check_child(cwd: Path, repo_id: Optional[str]) -> int:
    mother = resolve_mother(cwd)
    if mother is None:
        print("VIBAGE_PARENT_UNRESOLVED")
        print("FRESHNESS_CHILD_WARN")
        return 0
    # Infer repo_id from cwd relative to mother if not set
    rid = repo_id
    if not rid:
        try:
            rel = str(cwd.resolve().relative_to(mother.resolve()))
            if rel and rel != ".":
                rid = rel.split("/")[0]
        except ValueError:
            rid = cwd.name
    stale = compute_stale(mother)
    escalate = refuse_counts(mother)
    if rid and rid in escalate:
        print(ESCALATE_LINE.format(rid=rid).replace("N>=3", f"N>={escalate[rid]}"))
    if rid and rid in stale:
        print("FRESHNESS_CHILD_WARN")
    elif not rid and stale:
        print("FRESHNESS_CHILD_WARN")
    elif rid and rid not in in_scope_repo_ids(mother):
        # child outside map still soft-warn if mother has any stale? Spec: warn if stale for this repo
        pass
    return 0


def cmd_check(args: argparse.Namespace) -> int:
    start = Path(args.path).resolve() if args.path else Path.cwd().resolve()
    if args.mode == "mother":
        mother = start if mother_marker(start) else resolve_mother(start)
        if mother is None:
            print("VIBAGE_PARENT_UNRESOLVED", file=sys.stderr)
            print("STALE_BLOCKS_MOTHER count=0")
            return 1
        return check_mother(mother)
    return check_child(start, args.repo)


def cmd_mark(args: argparse.Namespace) -> int:
    mother = Path(args.mother).resolve()
    if not mother_marker(mother):
        print("FAIL: mother missing docs/vibage/STATUS.md", file=sys.stderr)
        return 1
    if args.success:
        code, msg = mark_success(mother, args.repo_id)
    else:
        code, msg = mark_refuse(mother, args.repo_id)
    if code:
        print(msg, file=sys.stderr)
    else:
        print(msg)
    return code


def main(argv: Optional[List[str]] = None) -> int:
    p = argparse.ArgumentParser(prog="freshness.py")
    sub = p.add_subparsers(dest="cmd", required=True)

    c = sub.add_parser("check")
    c.add_argument("--mode", choices=("mother", "child"), required=True)
    c.add_argument("--repo", default=None)
    c.add_argument("path", nargs="?", default=".")
    c.set_defaults(func=cmd_check)

    m = sub.add_parser("mark")
    g = m.add_mutually_exclusive_group(required=True)
    g.add_argument("--success", action="store_true")
    g.add_argument("--refuse", action="store_true")
    m.add_argument("mother")
    m.add_argument("repo_id")
    m.set_defaults(func=cmd_mark)

    args = p.parse_args(argv)
    return int(args.func(args))


if __name__ == "__main__":
    sys.exit(main())
