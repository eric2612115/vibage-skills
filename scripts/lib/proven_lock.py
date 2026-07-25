#!/usr/bin/env python3
"""Proven-green lock: apply the assert_gate idiom to STATUS.md itself.

STATUS.md `## Capability` table is the capability SSOT. This module extracts the
*proven projection* of that table (capability + Proven-green + scope kind +
cited `*_OK` tokens), hashes it canonically, and compares against a signed lock
at `docs/PROVEN-LOCK.json`.

What this buys: changing a Proven cell without re-signing fails, so drift stops
being silent. Re-signing is still possible for anyone with write access — the win
is that it becomes an explicit, reviewable act, exactly like CONFIRM.json for
SCAN_PLAN.

What it does NOT buy — state these before the positive claim:
  - It does not make drift impossible. It makes unsigned drift visible.
  - "Evidence exists" means a path inside this package resolves to a real file
    containing the declared run_ts. It says nothing about whether that file's
    content supports the claim.
  - Scope prose (the `≠` caveats) is deliberately outside the hash. Only the
    tri-state cells, scope kind, cited `*_OK` tokens and cited `run_ts=` are
    signed. A caveat can be deleted without tripping this gate.
  - `PROVEN_LOCK_OK` ≠ the claims are true ≠ letter B ≠ live panel re-run.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

CAP_HEADING_RE = re.compile(r"^##\s+Capability\b.*$", re.M)
NEXT_H2_RE = re.compile(r"^##\s+", re.M)
SEP_RE = re.compile(r"^\|[\s:|-]+\|$")
OK_TOKEN_RE = re.compile(r"`([A-Z0-9_]{6,}_OK)`")
RUN_TS_RE = re.compile(r"^\d{8}T\d{6}Z$")
SCOPE_RUN_TS_RE = re.compile(r"run_ts\s*=\s*`?(\d{8}T\d{6}Z)`?")
SCOPE_KINDS = ("script+live-pressure", "script", "agent", "blank", "—")
EVIDENCE_KINDS = frozenset({"script", "run", "none"})
HEADER = ["Capability", "Designed", "On-tree", "Proven-green", "Scope"]


def die(msg: str) -> None:
    """Fail closed WITH a token — consumers are told to parse tokens, not exit codes."""
    print("PROVEN_LOCK_BLOCKED")
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)


def clean_capability(cell: str) -> str:
    """Strip markdown emphasis / backticks so the key is stable across edits."""
    s = cell.replace("**", "").replace("`", "").strip()
    return re.sub(r"\s+", " ", s)


def scope_kind(scope_cell: str) -> str:
    s = scope_cell.strip()
    for kind in SCOPE_KINDS:
        if s == kind or s.startswith(kind + " ") or s.startswith(kind + "("):
            return kind
    return "unknown"


def parse_capability_table(status_text: str) -> List[Dict[str, Any]]:
    """Every pipe-line in the `## Capability` section is a row — including indented
    ones, which GitHub still renders as table rows. A regex that only captures a
    column-0 contiguous block would let an appended `  | ... | YES |` row render in
    the table while staying invisible to the gate."""
    heads = CAP_HEADING_RE.findall(status_text)
    if len(heads) != 1:
        die(
            f"expected exactly one '## Capability' heading, found {len(heads)} "
            "(a second one would shadow the governed table)"
        )
    m = CAP_HEADING_RE.search(status_text)
    assert m is not None
    rest = status_text[m.end():]
    nxt = NEXT_H2_RE.search(rest)
    block = rest[: nxt.start()] if nxt else rest

    pipe_lines = [ln.strip() for ln in block.splitlines() if ln.strip().startswith("|")]
    if len(pipe_lines) < 3:
        die("capability table not found (need header + separator + >=1 row)")

    header = [c.strip() for c in pipe_lines[0].strip("|").split("|")]
    if header != HEADER:
        die(f"bad capability header {header}; expected {HEADER}")
    if not SEP_RE.match(pipe_lines[1]):
        die(f"expected markdown separator row, got: {pipe_lines[1]}")

    rows: List[Dict[str, Any]] = []
    for line in pipe_lines[2:]:
        cells = [c.strip() for c in line.strip("|").split("|")]
        if len(cells) != 5:
            die(f"capability row must have 5 cells: {line}")
        cap, designed, on_tree, proven, scope = cells
        key = clean_capability(cap)
        if any(r["capability"] == key for r in rows):
            die(f"duplicate capability row: {key}")
        rows.append(
            {
                "capability": key,
                "designed": designed,
                "on_tree": on_tree,
                "proven_green": proven,
                "scope_kind": scope_kind(scope),
                "scope_tokens": sorted(set(OK_TOKEN_RE.findall(scope))),
                # Factual citation, not prose: must agree with the lock's evidence_run_ts.
                "scope_run_ts": sorted(set(SCOPE_RUN_TS_RE.findall(scope))),
            }
        )
    if not rows:
        die("capability table has no rows")
    return rows


def projection(rows: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Only the Proven-relevant fields. Prose edits in Scope must not trip the lock,
    but Proven-green / scope kind / cited evidence tokens must.

    `scope_tokens` is a raw citation set used for *change detection* — it includes
    any `*_OK` token spelled in the Scope cell, even a retired brand mentioned in a
    "≠ / retired" clause. It is NOT a validated evidence list; the validated one is
    `evidence_paths` in docs/PROVEN-LOCK.json, which must resolve on disk.
    """
    proj = [
        {
            "capability": r["capability"],
            "designed": r["designed"],
            "on_tree": r["on_tree"],
            "proven_green": r["proven_green"],
            "scope_kind": r["scope_kind"],
            "scope_tokens": r["scope_tokens"],
            "scope_run_ts": r["scope_run_ts"],
        }
        for r in rows
    ]
    return sorted(proj, key=lambda r: r["capability"])


def evidence_projection(rows: Any) -> List[Dict[str, Any]]:
    """The evidence half of the signed assertion.

    Signing only the STATUS projection would leave the pointers unsigned: a YES
    could be silently re-pointed at any other file that happens to exist and the
    hash would still match. The assertion being signed is *both* halves —
    "STATUS claims X" AND "the evidence for X is Y"."""
    out: List[Dict[str, Any]] = []
    for r in rows if isinstance(rows, list) else []:
        if not isinstance(r, dict):
            continue
        out.append(
            {
                "capability": str(r.get("capability", "")),
                "evidence_kind": r.get("evidence_kind"),
                "evidence_paths": sorted(str(p) for p in (r.get("evidence_paths") or [])),
                "evidence_run_ts": str(r.get("evidence_run_ts") or ""),
            }
        )
    return sorted(out, key=lambda r: r["capability"])


def payload_hash(proj: List[Dict[str, Any]], evidence: Optional[List[Dict[str, Any]]] = None) -> str:
    payload = {"status_projection": proj, "evidence": evidence or []}
    canonical = json.dumps(
        payload, sort_keys=True, separators=(",", ":"), ensure_ascii=False
    )
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def read_status(pkg_root: Path) -> str:
    p = pkg_root / "STATUS.md"
    if not p.is_file():
        die(f"missing {p}")
    return p.read_text(encoding="utf-8")


def status_projection(pkg_root: Path) -> List[Dict[str, Any]]:
    return projection(parse_capability_table(read_status(pkg_root)))


def load_lock(pkg_root: Path) -> Dict[str, Any]:
    p = pkg_root / "docs" / "PROVEN-LOCK.json"
    if not p.is_file():
        die(f"missing {p} — run: proven_lock.py sign <pkg_root>")
    try:
        obj = json.loads(p.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as e:
        die(f"lock unreadable: {e}")
    if not isinstance(obj, dict):
        die("lock must be a JSON object")
    return obj


def build_lock_rows(
    proj: List[Dict[str, Any]], prior: Optional[Dict[str, Any]] = None
) -> List[Dict[str, Any]]:
    """Carry evidence pointers forward when the capability already existed."""
    prior_map: Dict[str, Dict[str, Any]] = {}
    if prior:
        for r in prior.get("rows") or []:
            if isinstance(r, dict) and r.get("capability"):
                prior_map[str(r["capability"])] = r
    out: List[Dict[str, Any]] = []
    for r in proj:
        old = prior_map.get(r["capability"], {})
        row = {
            "capability": r["capability"],
            "proven_green": r["proven_green"],
            "scope_kind": r["scope_kind"],
            "evidence_kind": old.get(
                "evidence_kind", "none" if r["proven_green"] != "YES" else "script"
            ),
            "evidence_paths": old.get("evidence_paths", []),
            "evidence_run_ts": old.get("evidence_run_ts", ""),
        }
        out.append(row)
    return out


def safe_evidence_target(pkg_root: Path, rel: str) -> Tuple[Optional[Path], Optional[str]]:
    """Evidence must be a real file inside the package — not an absolute path, not a
    `..` escape, not a symlink pointing outside. `pkg_root / '/etc/hosts'` silently
    discards pkg_root, so this must be checked before touching the filesystem."""
    rel = str(rel)
    p = Path(rel)
    if p.is_absolute():
        return None, f"evidence_path must be package-relative: {rel}"
    if ".." in p.parts:
        return None, f"evidence_path must not contain '..': {rel}"
    target = pkg_root / p
    if target.is_symlink():
        return None, f"evidence_path must not be a symlink: {rel}"
    if not target.is_file():
        return None, f"evidence_path does not exist: {rel}"
    try:
        target.resolve().relative_to(pkg_root.resolve())
    except ValueError:
        return None, f"evidence_path escapes package root: {rel}"
    return target, None


def check_evidence(
    pkg_root: Path, lock: Dict[str, Any], proj_map: Dict[str, Dict[str, Any]]
) -> List[str]:
    """Every Proven-green=YES row must point at an artifact that exists.

    evidence_kind:
      script — evidence_paths are tests/scripts on tree (re-runnable proof)
      run    — evidence_paths are committed evidence docs; at least one must
               contain evidence_run_ts
      none   — only legal when proven_green != YES
    """
    errors: List[str] = []
    for r in lock.get("rows") or []:
        if not isinstance(r, dict):
            errors.append(f"lock row must be an object, got {type(r).__name__}")
            continue
        cap = str(r.get("capability", "<unnamed>"))
        # SSOT for the claim is STATUS.md, never the lock's own copy of it —
        # otherwise flipping the lock to NO would silently disable every check below.
        status_row = proj_map.get(cap)
        if status_row is None:
            errors.append(f"{cap}: signed row has no STATUS counterpart")
            continue
        proven = status_row["proven_green"]
        if r.get("proven_green") != proven:
            errors.append(
                f"{cap}: lock proven_green={r.get('proven_green')!r} disagrees with "
                f"STATUS {proven!r}"
            )
            continue
        if r.get("scope_kind") != status_row["scope_kind"]:
            errors.append(
                f"{cap}: lock scope_kind={r.get('scope_kind')!r} disagrees with "
                f"STATUS {status_row['scope_kind']!r}"
            )
            continue
        kind = r.get("evidence_kind")
        paths = r.get("evidence_paths")
        run_ts = str(r.get("evidence_run_ts") or "").strip()

        if kind not in EVIDENCE_KINDS:
            errors.append(f"{cap}: evidence_kind must be one of {sorted(EVIDENCE_KINDS)}")
            continue
        if not isinstance(paths, list):
            errors.append(f"{cap}: evidence_paths must be a list")
            continue
        if proven != "YES":
            if kind != "none":
                errors.append(
                    f"{cap}: Proven-green={proven!r} must use evidence_kind=none"
                )
            continue
        # proven_green == YES from here
        if kind == "none":
            errors.append(f"{cap}: Proven-green=YES requires evidence_kind script|run")
            continue
        if not paths:
            errors.append(f"{cap}: Proven-green=YES requires >=1 evidence_paths")
            continue
        targets: List[Path] = []
        path_errs: List[str] = []
        for p in paths:
            t, err = safe_evidence_target(pkg_root, p)
            if err:
                path_errs.append(f"{cap}: {err}")
            else:
                assert t is not None
                targets.append(t)
        if path_errs:
            errors.extend(path_errs)
            continue
        if kind == "run":
            if not RUN_TS_RE.match(run_ts):
                errors.append(
                    f"{cap}: evidence_run_ts must look like 20260724T171248Z, got {run_ts!r}"
                )
                continue
            # The run_ts must be public in the SSOT, not only inside the lock —
            # otherwise the lock alone could name any timestamp that happens to
            # appear somewhere in the evidence file.
            cited = status_row.get("scope_run_ts") or []
            if not cited:
                errors.append(
                    f"{cap}: evidence_kind=run requires STATUS Scope to cite "
                    f"run_ts={run_ts} (a lock-only timestamp is not a public claim)"
                )
                continue
            if run_ts not in cited:
                errors.append(
                    f"{cap}: STATUS Scope cites run_ts {cited} but lock signed "
                    f"{run_ts} — a forged citation must not pass"
                )
                continue
            hit = any(
                run_ts in t.read_text(encoding="utf-8", errors="replace") for t in targets
            )
            if not hit:
                errors.append(
                    f"{cap}: evidence_run_ts {run_ts} not found in any of {paths}"
                )
        elif kind == "script" and run_ts:
            errors.append(f"{cap}: evidence_kind=script must leave evidence_run_ts empty")
    return errors


def cmd_hash(args: argparse.Namespace) -> int:
    pkg_root = Path(args.pkg_root).resolve()
    proj = status_projection(pkg_root)
    lock_path = pkg_root / "docs" / "PROVEN-LOCK.json"
    ev: List[Dict[str, Any]] = []
    if lock_path.is_file():
        try:
            ev = evidence_projection(
                json.loads(lock_path.read_text(encoding="utf-8")).get("rows")
            )
        except (OSError, json.JSONDecodeError):
            ev = []
    print(payload_hash(proj, ev))
    return 0


def cmd_sign(args: argparse.Namespace) -> int:
    pkg_root = Path(args.pkg_root).resolve()
    proj = status_projection(pkg_root)
    lock_path = pkg_root / "docs" / "PROVEN-LOCK.json"
    prior = None
    if lock_path.is_file():
        try:
            prior = json.loads(lock_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            prior = None
    rows = build_lock_rows(proj, prior)
    h = payload_hash(proj, evidence_projection(rows))
    obj = {
        "schema_version": "1",
        "hash_alg": "sha256",
        "payload_hash": h,
        "note": (
            "Signed assertion = STATUS.md `## Capability` projection AND the evidence "
            "pointers below. Re-sign only with evidence. PROVEN_LOCK_OK != claims true "
            "!= letter B != panel re-run."
        ),
        # The exact hashed status half, kept verbatim so a mismatch can name the
        # field that moved instead of guessing. Verified against STATUS on check.
        "projection": proj,
        "rows": rows,
    }
    lock_path.parent.mkdir(parents=True, exist_ok=True)
    lock_path.write_text(json.dumps(obj, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"SIGNED {lock_path} payload_hash={h}")
    return 0


def cmd_check(args: argparse.Namespace) -> int:
    pkg_root = Path(args.pkg_root).resolve()
    proj = status_projection(pkg_root)
    lock = load_lock(pkg_root)
    h = payload_hash(proj, evidence_projection(lock.get("rows")))

    if lock.get("hash_alg", "sha256") != "sha256":
        print("PROVEN_LOCK_BLOCKED")
        print(f"FAIL: unsupported hash_alg={lock.get('hash_alg')}", file=sys.stderr)
        return 1

    rows_obj = lock.get("rows")
    if not isinstance(rows_obj, list) or not all(isinstance(r, dict) for r in rows_obj):
        print("PROVEN_LOCK_BLOCKED")
        print("FAIL: lock.rows must be a list of objects", file=sys.stderr)
        return 1

    lock_caps = {str(r.get("capability")) for r in (lock.get("rows") or [])}
    status_caps = {r["capability"] for r in proj}
    if lock_caps != status_caps:
        print("PROVEN_LOCK_MISMATCH")
        for c in sorted(status_caps - lock_caps):
            print(f"FAIL: capability in STATUS but not signed: {c}", file=sys.stderr)
        for c in sorted(lock_caps - status_caps):
            print(f"FAIL: capability signed but not in STATUS: {c}", file=sys.stderr)
        return 1

    if lock.get("payload_hash") != h:
        print("PROVEN_LOCK_MISMATCH")
        print(
            f"FAIL: payload_hash mismatch (STATUS={h} lock={lock.get('payload_hash')})",
            file=sys.stderr,
        )
        signed = lock.get("projection")
        if isinstance(signed, list):
            signed_map = {
                str(r.get("capability")): r for r in signed if isinstance(r, dict)
            }
            for r in proj:
                old = signed_map.get(r["capability"])
                if old is None:
                    print(f"FAIL: {r['capability']}: not in signed projection", file=sys.stderr)
                    continue
                for field in (
                    "designed",
                    "on_tree",
                    "proven_green",
                    "scope_kind",
                    "scope_tokens",
                    "scope_run_ts",
                ):
                    if old.get(field) != r[field]:
                        print(
                            f"FAIL: {r['capability']}: {field} {old.get(field)!r} -> {r[field]!r}",
                            file=sys.stderr,
                        )
            if signed == proj:
                # STATUS half is byte-identical to what was signed, so the drift is
                # on the evidence half: a pointer, kind, or run_ts was re-aimed.
                print(
                    "FAIL: STATUS projection is unchanged — the evidence pointers in "
                    "`rows` were edited without re-signing (evidence_kind / "
                    "evidence_paths / evidence_run_ts)",
                    file=sys.stderr,
                )
        else:
            print(
                "FAIL: lock has no `projection` — re-sign to get field-level diffs",
                file=sys.stderr,
            )
        print(
            "FAIL: the signature covers BOTH the STATUS projection and the evidence "
            "pointers — an unsigned change to either side lands here",
            file=sys.stderr,
        )
        print("FAIL: re-sign only with evidence (proven_lock.py sign)", file=sys.stderr)
        return 1

    # Stored projection must agree with STATUS even when the hash matches, or the
    # lock becomes a misleading artifact for anyone reading it instead of running it.
    stored = lock.get("projection")
    if isinstance(stored, list) and stored != proj:
        print("PROVEN_LOCK_MISMATCH")
        print(
            "FAIL: lock.projection disagrees with STATUS.md (stale or hand-edited copy)",
            file=sys.stderr,
        )
        return 1

    proj_map = {r["capability"]: r for r in proj}
    errors = check_evidence(pkg_root, lock, proj_map)
    if errors:
        print("PROVEN_LOCK_NO_EVIDENCE")
        for e in errors:
            print(f"FAIL: {e}", file=sys.stderr)
        return 1

    yes_n = sum(1 for r in proj if r["proven_green"] == "YES")
    print("PROVEN_LOCK_OK")
    print(
        f"OK: {len(proj)} capabilities signed; {yes_n} Proven-green=YES in STATUS, "
        f"each naming an in-package evidence path that exists"
    )
    return 0


def git_show(pkg_root: Path, ref: str, rel: str) -> Optional[str]:
    try:
        out = subprocess.run(
            ["git", "-C", str(pkg_root), "show", f"{ref}:{rel}"],
            capture_output=True,
            text=True,
            timeout=30,
        )
    except (OSError, subprocess.SubprocessError) as e:
        die(f"git show failed: {e}")
    if out.returncode != 0:
        return None
    return out.stdout


def cmd_diff(args: argparse.Namespace) -> int:
    """Answer 'which Proven cells moved since <ref>?' with a script, not a memory."""
    pkg_root = Path(args.pkg_root).resolve()
    old_text = git_show(pkg_root, args.since, "STATUS.md")
    if old_text is None:
        die(f"cannot read STATUS.md at ref {args.since}")
    old = {r["capability"]: r for r in projection(parse_capability_table(old_text))}
    new = {r["capability"]: r for r in projection(parse_capability_table(read_status(pkg_root)))}

    changes: List[str] = []
    for cap in sorted(set(old) | set(new)):
        o, n = old.get(cap), new.get(cap)
        if o is None:
            changes.append(f"ADDED    {cap}: Proven-green={n['proven_green']} scope={n['scope_kind']}")
            continue
        if n is None:
            changes.append(f"REMOVED  {cap}: was Proven-green={o['proven_green']}")
            continue
        if o["proven_green"] != n["proven_green"]:
            changes.append(
                f"PROVEN   {cap}: {o['proven_green']} -> {n['proven_green']}"
            )
        if o["on_tree"] != n["on_tree"]:
            changes.append(f"ONTREE   {cap}: {o['on_tree']} -> {n['on_tree']}")
        if o["designed"] != n["designed"]:
            changes.append(f"DESIGNED {cap}: {o['designed']} -> {n['designed']}")
        if o["scope_kind"] != n["scope_kind"]:
            changes.append(f"SCOPE    {cap}: {o['scope_kind']} -> {n['scope_kind']}")
        if o["scope_tokens"] != n["scope_tokens"]:
            changes.append(
                f"EVIDENCE {cap}: {o['scope_tokens']} -> {n['scope_tokens']}"
            )
        if "unknown" in (o["scope_kind"], n["scope_kind"]):
            changes.append(
                f"NOTE     {cap}: a side has scope_kind=unknown — that row's columns "
                "were malformed at one end, so the field-to-field diff above may be "
                "column noise rather than a real claim change"
            )

    if not changes:
        print(f"PROVEN_DIFF_NONE since={args.since}")
        return 0
    print(f"PROVEN_DIFF rows_changed={len(changes)} since={args.since}")
    for c in changes:
        print(f"  {c}")
    return 0


def main(argv: List[str]) -> int:
    ap = argparse.ArgumentParser(description="Proven-green lock for STATUS.md")
    sub = ap.add_subparsers(dest="cmd", required=True)
    for name, fn in (("hash", cmd_hash), ("sign", cmd_sign), ("check", cmd_check)):
        p = sub.add_parser(name)
        p.add_argument("pkg_root")
        p.set_defaults(func=fn)
    p = sub.add_parser("diff")
    p.add_argument("pkg_root")
    p.add_argument("--since", required=True)
    p.set_defaults(func=cmd_diff)
    args = ap.parse_args(argv[1:])
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
