from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts" / "lib"))
from scan_plan_hash import extract_scan_plan_v1, payload_hash, hash_scan_plan_file

FIXTURE = Path(__file__).parent / "fixtures" / "sample_SCAN_PLAN.md"


def test_extract_and_hash_stable():
    text = FIXTURE.read_text(encoding="utf-8")
    obj = extract_scan_plan_v1(text)
    assert obj["schema_version"] == "1"
    h1 = payload_hash(obj)
    h2 = payload_hash(obj)
    assert h1 == h2
    assert len(h1) == 64


def test_key_order_does_not_change_hash():
    a = {
        "schema_version": "1",
        "root_refs": [],
        "budgets": {"max_wall_min": 25, "max_files": 40, "max_depth": 3},
        "hot_path_ids": [],
        "known_incompleteness": "x",
        "planned_dig_ids": [],
    }
    b = {
        "budgets": {"max_depth": 3, "max_files": 40, "max_wall_min": 25},
        "planned_dig_ids": [],
        "hot_path_ids": [],
        "known_incompleteness": "x",
        "root_refs": [],
        "schema_version": "1",
    }
    assert payload_hash(a) == payload_hash(b)


def test_hash_scan_plan_file():
    h = hash_scan_plan_file(str(FIXTURE))
    assert len(h) == 64
