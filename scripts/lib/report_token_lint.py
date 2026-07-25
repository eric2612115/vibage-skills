#!/usr/bin/env python3
"""Deliverable narrative token lint for VIBAGE-ISSUE-*.md (≠ chat proof)."""
from __future__ import annotations

import re
import sys
from pathlib import Path
from typing import List, Optional, Set, Tuple

H2 = re.compile(r"^##\s+(.+?)\s*$", re.M)
FENCE = re.compile(r"```(?:[^\n`]*)\n(.*?)```", re.S)

# Per-slogan adjacent negation (must bind to that slogan; NOT any ≠ on the line).
NEG_SAOTOU = [
    re.compile(r"≠\s*掃透"),
    re.compile(r"\bnot\s+掃透", re.I),
    re.compile(r"\bnever\s+掃透", re.I),
    re.compile(r"不得掃透"),
    re.compile(r"Asking\s*≠\s*掃透", re.I),
    re.compile(r"never\s+claim\s+掃透", re.I),
]
NEG_LITI = [
    re.compile(r"≠\s*立體"),
]
NEG_UNDERSTOOD = [
    re.compile(r"≠\s*full-understanding", re.I),
    re.compile(r"\bnot\s+(?:system\s+)?understood", re.I),
    re.compile(r"never\s+claim\s+(?:system\s+)?understood", re.I),
]
NEG_DIG_READY = [
    re.compile(r"≠\s*(?:dig-ready|ready-after-install-alone)", re.I),
    re.compile(r"never\s+claim\s+(?:dig-ready|ready-after-install)", re.I),
]

# (slogan_pat, required Held tokens or None=always forbidden, negation pats)
RULES: List[Tuple[re.Pattern[str], Optional[Set[str]], List[re.Pattern[str]]]] = [
    (
        re.compile(r"全環境全\s*branch\s*掃透|全環境掃透|掃透"),
        {"MATRIX_SWEEP_SUBSTANTIVE_OK"},
        NEG_SAOTOU,
    ),
    (
        re.compile(r"無漏掃|矩陣終態"),
        {"ENV_BRANCH_MATRIX_OK"},
        [],
    ),
    (
        re.compile(r"多領域立體場景(?:切換)?|立體場景切換|立體場景"),
        {"SCENE_BRIEF_OK", "SCENE_COVER_OK"},
        NEG_LITI,
    ),
    (
        re.compile(r"系統已懂|全懂|full-understanding|system\s+understood", re.I),
        None,
        NEG_UNDERSTOOD,
    ),
    (
        re.compile(
            r"\bdig-ready\b|ready-after-install-alone|install→ready|install->ready",
            re.I,
        ),
        None,
        NEG_DIG_READY,
    ),
]


def _split_sections(text: str) -> Tuple[str, str, str]:
    matches = list(H2.finditer(text))
    if not matches:
        return text, "", ""
    body_chunks = [text[: matches[0].start()]]
    held = ""
    evid = ""
    for i, m in enumerate(matches):
        title = m.group(1).strip().lower()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
        chunk = text[m.end() : end]
        if title.startswith("held tokens"):
            held = chunk
            continue
        if title.startswith("token evidence"):
            evid = chunk
            continue
        body_chunks.append(text[m.start() : end])
    return "".join(body_chunks), held, evid


def _held_tokens(held_body: str) -> Set[str]:
    found: Set[str] = set()
    for m in re.finditer(r"`([A-Z0-9_]+)`|\b([A-Z0-9_]{6,}_OK)\b", held_body):
        found.add(m.group(1) or m.group(2))
    return found


def _fenced_evidence_lines(evid_body: str) -> Set[str]:
    """Tokens that appear as their own line inside a ``` fence under Token evidence."""
    found: Set[str] = set()
    for block in FENCE.findall(evid_body):
        for raw in block.splitlines():
            line = raw.strip().strip("`")
            if re.fullmatch(r"[A-Z0-9_]{6,}_OK", line):
                found.add(line)
    return found


def _negated(line: str, neg_pats: List[re.Pattern[str]]) -> bool:
    return any(n.search(line) for n in neg_pats)


def lint_report(path: Path) -> List[str]:
    text = path.read_text(encoding="utf-8")
    body, held, evid = _split_sections(text)
    tokens = _held_tokens(held)
    evid_lines = _fenced_evidence_lines(evid)
    errors: List[str] = []

    for line in body.splitlines():
        for slogan_pat, req, neg_pats in RULES:
            if not slogan_pat.search(line):
                continue
            if _negated(line, neg_pats):
                continue
            if req is None:
                errors.append(
                    f"{path.name}: forbidden slogan on line: {line.strip()[:120]}"
                )
                continue
            missing = req - tokens
            if missing:
                errors.append(
                    f"{path.name}: slogan requires Held {sorted(req)}; "
                    f"missing {sorted(missing)}; line: {line.strip()[:100]}"
                )
                continue
            for tok in req:
                if tok not in evid_lines:
                    errors.append(
                        f"{path.name}: Held {tok} but ## Token evidence fence "
                        f"missing exact line {tok!r}"
                    )
    return errors


def main(argv: List[str]) -> int:
    if len(argv) < 2:
        print("Usage: report_token_lint.py <report.md> [more.md...]", file=sys.stderr)
        return 2
    errs: List[str] = []
    for a in argv[1:]:
        p = Path(a)
        if not p.is_file():
            errs.append(f"missing file: {a}")
            continue
        errs.extend(lint_report(p))
    if errs:
        for e in errs:
            print(f"VERIFY_REPORT_FAIL: token lint: {e}", file=sys.stderr)
        return 1
    print("REPORT_TOKEN_LINT_OK")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
