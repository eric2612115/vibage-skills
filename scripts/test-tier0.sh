#!/usr/bin/env bash
# Tier-0 ship entry — local complete script truth
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "== tier0: pytest hash =="
python3 -m pytest tests/test_scan_plan_hash.py -q

echo "== tier0: assert_gate =="
bash tests/test_assert_gate.sh

echo "== tier0: verify-run =="
bash tests/test_verify_run.sh

echo "== tier0: report names =="
bash tests/test_report_names.sh

echo "== tier0: handoff =="
bash tests/test_handoff.sh

echo "== tier0: optional track gates =="
bash tests/test_optional_track_gates.sh

echo "== tier0: p1 smoke (gate RED after mutate) =="
bash tests/test_p1_smoke.sh

echo "== tier0: install safety (if present) =="
if [[ -f tests/test_install_force_safety.sh ]]; then
  bash tests/test_install_force_safety.sh
fi
if [[ -f tests/test_install_manifest.sh ]]; then
  bash tests/test_install_manifest.sh
fi

echo "TIER0_OK"
