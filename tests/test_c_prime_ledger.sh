#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/docs/vibage/ledger"
bash "$ROOT/scripts/ledger-append.sh" "$TMP" '{"id":"c1","subject_type":"repo","subject_id":"svc-a","claim_class":"floor_identity","statement":"exists","pointers":[{"path":"svc-a/README.md","quote":"# A","branch_ref":"main","env_id":""}],"state":"proven","updated_at":"t","evidence_hash":"h"}'
bash "$ROOT/scripts/ledger-append.sh" "$TMP" '{"id":"c2","subject_type":"repo","subject_id":"svc-a","claim_class":"floor_deps","statement":"no compose deps","pointers":[{"path":"svc-a","quote":"absent","branch_ref":"main","env_id":""}],"state":"proven","updated_at":"t","evidence_hash":"h2"}'
out="$(bash "$ROOT/scripts/verify-ledger-slice.sh" "$TMP" svc-a floor_identity,floor_deps)"
[[ "$out" == "LEDGER_SLICE_PROVEN" ]]
# failed-only must NOT print LEDGER_SLICE_PROVEN
bash "$ROOT/scripts/ledger-append.sh" "$TMP" '{"id":"c3","subject_type":"repo","subject_id":"svc-b","claim_class":"floor_identity","statement":"x","pointers":[{"path":"svc-b","quote":"fail","branch_ref":"main","env_id":""}],"state":"failed","updated_at":"t","evidence_hash":"h3"}'
if bash "$ROOT/scripts/verify-ledger-slice.sh" "$TMP" svc-b floor_identity; then echo "FAIL: failed slice must not be PROVEN"; exit 1; fi
grep -q 'svc-b' "$TMP/docs/vibage/ledger/ROLLUP.md"

# Task 0.3: UNDERSTANDING_ROLLUP_OK without matrix
mkdir -p "$TMP/svc-a/.git" "$TMP/svc-b/.git"
bash "$ROOT/scripts/graph-floor.sh" "$TMP"
[[ ! -f "$TMP/docs/vibage/maps/env_branch_matrix.json" ]]
out="$(bash "$ROOT/scripts/verify-ledger-slice.sh" "$TMP" svc-a floor_identity,floor_deps)"
[[ "$out" == "LEDGER_SLICE_PROVEN" ]]
out="$(bash "$ROOT/scripts/verify-ledger-slice.sh" "$TMP" svc-b floor_identity,floor_deps)"
[[ "$out" == "LEDGER_SLICE_PROVEN" ]]
out="$(bash "$ROOT/scripts/verify-understanding-rollup.sh" "$TMP")"
[[ "$out" == "UNDERSTANDING_ROLLUP_OK" ]]
