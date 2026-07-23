#!/usr/bin/env python3
"""Extract scan_plan_v1 and SHA-256 payload_hash per P1 spec."""
from __future__ import annotations

import hashlib
import json
import re
import sys
from typing import Any

FENCE_RE = re.compile(
    r"```(?:json)?\s*scan_plan_v1\s*\n(.*?)```",
    re.DOTALL | re.IGNORECASE,
)

REQUIRED = (
    "schema_version",
    "root_refs",
    "budgets",
    "hot_path_ids",
    "known_incompleteness",
    "planned_dig_ids",
)


def extract_scan_plan_v1(markdown: str) -> dict[str, Any]:
    m = FENCE_RE.search(markdown)
    if not m:
        raise ValueError("missing fenced scan_plan_v1 JSON block")
    obj = json.loads(m.group(1))
    for k in REQUIRED:
        if k not in obj:
            raise ValueError(f"scan_plan_v1 missing key: {k}")
    return obj


def payload_hash(obj: dict[str, Any]) -> str:
    canonical = json.dumps(
        obj, sort_keys=True, separators=(",", ":"), ensure_ascii=False
    )
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def hash_scan_plan_file(path: str) -> str:
    with open(path, encoding="utf-8") as f:
        text = f.read()
    return payload_hash(extract_scan_plan_v1(text))


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <SCAN_PLAN.md>", file=sys.stderr)
        sys.exit(2)
    print(hash_scan_plan_file(sys.argv[1]))
