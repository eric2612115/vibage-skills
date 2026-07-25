#!/usr/bin/env python3
"""Machine-filled coverage box for VIBAGE-ISSUE-* reports.

Why this exists
---------------
The deliverable token lint enumerates bad sentences. That set is infinite, and
every pattern added makes the lint *look* more covered than it is. This box takes
the opposite approach: it does not try to detect the lie. It puts machine-authored
facts directly above the prose, and re-derives them at verify time so a hand-edited
box fails.

A sentence claiming full coverage sitting under

    repos_dug: 1 / 3
    matrix: proven 0 / failed 0 / missing-env-config 1
    掃透 (MATRIX_SWEEP_SUBSTANTIVE_OK): NO

is self-refuting to the owner without the lint understanding any language.
Paraphrase stops being *blocked* and starts being *pointless*.

Design rules
------------
1. This module re-implements NO gate logic. Every fact comes from invoking the
   existing verify-* script and parsing its stdout token. Exit code is never
   treated as the answer (waived-stale freshness exits 0; PARTIAL exits 0).
2. The serialization is fixed-order and canonical so `--check` can compare text.
3. `## Held tokens` authored by the agent must be a SUBSET of the tokens the
   workspace actually holds. Claiming an unheld token fails.
4. EVERY field is derived from the workspace alone. Nothing may depend on how the
   check was invoked. An earlier version carried `nested_dispatch:` from the RUNS
   json; omitting `--run` at check time then re-derived it as `unknown` and
   produced a FAIL whose message accused the author of hand-editing the box.
   A verification whose verdict depends on its own invocation form is worse than
   no verification — false accusations train people to ignore the gate. Mode
   honesty is already fully covered by verify-run.sh plus the MD/RUNS cross-check
   in verify-report.sh, so the field bought nothing. Do not reintroduce it, or any
   other field that is not a pure function of the workspace.

`COVERAGE_BOX_OK` ≠ the findings are correct ≠ the dig was complete.
It means the numbers in the report match the hub on disk right now.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

FENCE_LANG = "vibage_coverage_v1"
FENCE_RE = re.compile(
    r"```" + FENCE_LANG + r"\s*\n(.*?)```", re.S
)
HEADING_RE = re.compile(r"^##\s+Coverage\b.*$", re.M)
HELD_HEADING_RE = re.compile(r"^##\s+Held tokens\b.*$", re.M)
NEXT_H2_RE = re.compile(r"^##\s+", re.M)
TOKEN_RE = re.compile(r"\b([A-Z0-9_]{6,}_OK)\b|\b(ENV_VACANCY_CLEAR)\b")

PKG_ROOT = Path(__file__).resolve().parent.parent.parent


def run_gate(script: str, args: List[str], token: str, timeout: int = 120) -> Tuple[bool, str]:
    """Invoke a verify-* script and PARSE ITS STDOUT TOKEN.

    Exit code is deliberately not the answer: `verify-freshness.sh` exits 0 for
    waived-stale, and `verify-dimension-fill.sh` exits 0 for PARTIAL. Returning
    `rc == 0` here would reproduce the exact fake-green this package exists to stop.
    """
    path = PKG_ROOT / "scripts" / script
    if not path.is_file():
        return False, f"missing:{script}"
    try:
        p = subprocess.run(
            ["bash", str(path), *args],
            capture_output=True,
            text=True,
            timeout=timeout,
        )
    except (OSError, subprocess.SubprocessError) as e:
        return False, f"error:{type(e).__name__}"
    out = p.stdout or ""
    held = any(line.strip() == token for line in out.splitlines())
    return held, out.strip()


def first_token(out: str, candidates: Tuple[str, ...]) -> str:
    for line in out.splitlines():
        s = line.strip()
        for c in candidates:
            if s == c or s.startswith(c + " "):
                return s
    return "UNKNOWN"


def hub(ws: Path) -> Path:
    return ws / "docs" / "vibage"


def hub_present(ws: Path) -> bool:
    return (hub(ws) / "STATUS.md").is_file()


def load_json(p: Path) -> Optional[Any]:
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None


def scan_plan_dig_ids(ws: Path) -> Tuple[Optional[int], List[str]]:
    plan = hub(ws) / "SCAN_PLAN.md"
    if not plan.is_file():
        return None, []
    sys.path.insert(0, str(PKG_ROOT / "scripts" / "lib"))
    try:
        from scan_plan_hash import extract_scan_plan_v1  # type: ignore

        obj = extract_scan_plan_v1(plan.read_text(encoding="utf-8"))
    except Exception:
        return None, []
    ids = [str(i) for i in (obj.get("planned_dig_ids") or [])]
    return len(ids), sorted(ids)


def derive(ws: Path, run_json: Optional[Path] = None) -> Dict[str, Any]:
    ws = ws.resolve()
    sm = load_json(hub(ws) / "maps" / "service_map.json") or {}
    services = sm.get("services") or []
    matrix = load_json(hub(ws) / "maps" / "env_branch_matrix.json") or {}
    cells = matrix.get("cells") or []

    def n_state(state: str) -> int:
        return sum(1 for c in cells if isinstance(c, dict) and c.get("state") == state)

    missing_env = sum(
        1 for c in cells if isinstance(c, dict) and c.get("env_id") == "missing-env-config"
    )

    dug_n, dug_ids = scan_plan_dig_ids(ws)

    held: List[str] = []
    a = [str(ws)]
    floor_ok, _ = run_gate("verify-graph-floor.sh", a, "GRAPH_FLOOR_OK")
    if floor_ok:
        held.append("GRAPH_FLOOR_OK")
    mtx_ok, _ = run_gate("verify-env-branch-matrix.sh", a, "ENV_BRANCH_MATRIX_OK")
    if mtx_ok:
        held.append("ENV_BRANCH_MATRIX_OK")
    sub_ok, _ = run_gate("verify-matrix-substantive.sh", a, "MATRIX_SWEEP_SUBSTANTIVE_OK")
    if sub_ok:
        held.append("MATRIX_SWEEP_SUBSTANTIVE_OK")
    brief_ok, _ = run_gate("verify-scene-brief.sh", a, "SCENE_BRIEF_OK")
    if brief_ok:
        held.append("SCENE_BRIEF_OK")
    cover_ok, _ = run_gate("verify-scene-cover.sh", a, "SCENE_COVER_OK")
    if cover_ok:
        held.append("SCENE_COVER_OK")
    gate_ok, _ = run_gate("assert_gate.sh", a, f"ASSERT_GATE_OK: {ws}")
    if gate_ok:
        held.append("ASSERT_GATE_OK")

    _, fresh_out = run_gate("verify-freshness.sh", a, "FRESHNESS_OK")
    fresh = first_token(
        fresh_out,
        ("FRESHNESS_OK", "FRESHNESS_WAIVED", "STALE_BLOCKS_MOTHER"),
    )
    if fresh == "FRESHNESS_OK":
        held.append("FRESHNESS_OK")

    _, vac_out = run_gate("verify-env-vacancy.sh", a, "ENV_VACANCY_CLEAR")
    vac = first_token(
        vac_out,
        (
            "ENV_VACANCY_CLEAR",
            "ENV_VACANCY_ANSWERED",
            "ENV_VACANCY_ASK",
            "ENV_VACANCY_BLOCKED",
        ),
    )
    if vac == "ENV_VACANCY_CLEAR":
        held.append("ENV_VACANCY_CLEAR")

    status_text = ""
    sp = hub(ws) / "STATUS.md"
    if sp.is_file():
        status_text = sp.read_text(encoding="utf-8", errors="replace")
    m = re.search(r"active_scene\s*[:=]\s*`?([A-Za-z0-9_.-]+)`?", status_text)
    scene = m.group(1) if m else "not-set"

    return {
        "repos_discovered": len(services),
        "repos_dug": dug_n,
        "dug_ids": dug_ids,
        "matrix_cells": len(cells),
        "matrix_proven": n_state("proven"),
        "matrix_failed": n_state("failed"),
        "matrix_missing_env": missing_env,
        "saotou": "YES" if sub_ok else "NO",
        "freshness": fresh,
        "env_vacancy": vac,
        "scene": scene,
        "scene_cover": "YES" if cover_ok else "NO",
        "held": sorted(set(held)),
    }


def render(d: Dict[str, Any]) -> str:
    """Fixed order, canonical. Owner-readable; `--check` compares this text."""
    dug = "unknown (no SCAN_PLAN)" if d["repos_dug"] is None else str(d["repos_dug"])
    ids = ", ".join(d["dug_ids"]) if d["dug_ids"] else "—"
    lines = [
        f"repos_discovered: {d['repos_discovered']}",
        f"repos_dug: {dug} / {d['repos_discovered']}  [{ids}]",
        f"matrix_cells: {d['matrix_cells']}  (proven {d['matrix_proven']} /"
        f" failed {d['matrix_failed']} / missing-env-config {d['matrix_missing_env']})",
        f"掃透 (MATRIX_SWEEP_SUBSTANTIVE_OK): {d['saotou']}",
        f"scene: {d['scene']}   stereoscopic cover: {d['scene_cover']}",
        f"freshness: {d['freshness']}",
        f"env_vacancy: {d['env_vacancy']}",
        f"held: {', '.join(d['held']) if d['held'] else '(none)'}",
        "",
        "Generated by scripts/coverage-box.sh and re-derived at verify time.",
        "These numbers bound every claim below them. A token absent from `held`",
        "was not proven, whatever the prose says.",
    ]
    return "\n".join(lines)


def emit_block(d: Dict[str, Any]) -> str:
    return f"## Coverage (machine-filled)\n\n```{FENCE_LANG}\n{render(d)}\n```\n"


def extract_block(text: str) -> Optional[str]:
    m = FENCE_RE.search(text)
    return m.group(1).rstrip("\n") if m else None


def authored_held(text: str) -> List[str]:
    """Tokens the agent claims in `## Held tokens` — must be a subset of reality."""
    m = HELD_HEADING_RE.search(text)
    if not m:
        return []
    rest = text[m.end():]
    nxt = NEXT_H2_RE.search(rest)
    body = rest[: nxt.start()] if nxt else rest
    out = []
    for a, b in TOKEN_RE.findall(body):
        out.append(a or b)
    return sorted(set(out))


def _keys(block: str) -> set:
    """Field names in a rendered box, so a renderer-version change is told apart
    from tampering."""
    out = set()
    for line in block.splitlines():
        m = re.match(r"^([A-Za-z_一-鿿][^:]*):", line.strip())
        if m:
            out.add(m.group(1).strip())
    return out


def check_report(report: Path, ws: Path, run_json: Optional[Path]) -> List[str]:
    errors: List[str] = []
    text = report.read_text(encoding="utf-8")
    block = extract_block(text)
    if block is None:
        errors.append(
            f"{report.name}: missing `{FENCE_LANG}` coverage box "
            "(hub is present, so it is derivable and therefore required)"
        )
        return errors

    d = derive(ws, run_json)
    want = render(d)
    if block.strip() != want.strip():
        # Never accuse when the evidence is ambiguous. A box written by an older
        # renderer has DIFFERENT KEYS; a tampered box has the same keys with
        # different values. Only the second is grounds for "do not hand-edit".
        if _keys(block) != _keys(want):
            errors.append(
                f"{report.name}: coverage box was written by a different renderer "
                "version (field set differs). Regenerate it:\n"
                f"  bash scripts/coverage-box.sh emit <workspace>\n"
                f"missing: {sorted(_keys(want) - _keys(block))}  "
                f"unexpected: {sorted(_keys(block) - _keys(want))}"
            )
        else:
            errors.append(
                f"{report.name}: coverage box does not match the hub on disk — "
                "it is machine-generated and must not be hand-edited.\n"
                f"--- in report ---\n{block.strip()}\n--- re-derived ---\n{want.strip()}"
            )
        return errors

    claimed = authored_held(text)
    real = set(d["held"])
    unheld = [t for t in claimed if t not in real]
    if unheld:
        errors.append(
            f"{report.name}: `## Held tokens` claims tokens the workspace does not "
            f"hold: {unheld} (actually held: {sorted(real) or 'none'})"
        )
    return errors


def resolve_ws(run_json: Optional[Path], explicit: Optional[str]) -> Optional[Path]:
    if explicit:
        p = Path(explicit).resolve()
        return p if hub_present(p) else None
    if run_json is not None:
        # docs/vibage/RUNS/<id>.json -> workspace
        try:
            cand = run_json.resolve().parents[3]
        except IndexError:
            return None
        return cand if hub_present(cand) else None
    return None


def main(argv: List[str]) -> int:
    ap = argparse.ArgumentParser(description="Machine-filled coverage box")
    sub = ap.add_subparsers(dest="cmd", required=True)

    e = sub.add_parser("emit")
    e.add_argument("workspace")
    e.add_argument("--run")

    c = sub.add_parser("check")
    c.add_argument("report")
    c.add_argument("--workspace")
    c.add_argument("--run")

    args = ap.parse_args(argv[1:])

    if args.cmd == "emit":
        ws = Path(args.workspace).resolve()
        if not hub_present(ws):
            print(f"FAIL: no hub at {ws}/docs/vibage/STATUS.md", file=sys.stderr)
            return 1
        run_json = Path(args.run).resolve() if args.run else None
        sys.stdout.write(emit_block(derive(ws, run_json)))
        return 0

    report = Path(args.report)
    if not report.is_file():
        print(f"FAIL: report not found: {report}", file=sys.stderr)
        return 1
    run_json = Path(args.run).resolve() if args.run else None
    ws = resolve_ws(run_json, args.workspace)
    if ws is None:
        print("COVERAGE_BOX_SKIPPED reason=no-derivable-hub")
        return 0
    errors = check_report(report, ws, run_json)
    if errors:
        for err in errors:
            print(f"COVERAGE_BOX_FAIL: {err}", file=sys.stderr)
        return 1
    print("COVERAGE_BOX_OK")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
