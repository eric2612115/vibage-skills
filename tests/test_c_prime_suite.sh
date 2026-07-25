#!/usr/bin/env bash
# Orchestrate all C′ script tests. Prints C_PRIME_SUITE_OK on full green.
# Excludes this file. Fail-fast; names the failing script.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "FAIL: $*" >&2; exit 1; }

n=0
while IFS= read -r t; do
  [[ -z "$t" ]] && continue
  n=$((n + 1))
  echo "=== RUN $t ==="
  if ! bash "$t"; then
    fail "suite stopped at $t"
  fi
done < <(find tests -maxdepth 1 -type f -name 'test_c_prime_*.sh' ! -name 'test_c_prime_suite.sh' | sort)

[[ "$n" -ge 1 ]] || fail "no test_c_prime_*.sh found"
echo "C_PRIME_SUITE_OK n=$n"
