#!/usr/bin/env bash
# Fail if package plans put Plan-loop work into Implement todos (word-level).
# Scans only docs/superpowers/plans/**/*.md checklist/todo lines.
# Does NOT scan ~/.cursor/plans. ∉ Tier-0. Token: PLAN_LOOP_HYGIENE_OK
# Usage: bash verify-plan-loop-hygiene.sh [<pkg_root>]
set -euo pipefail
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ $# -ge 1 && -n "${1:-}" ]]; then
  PKG_ROOT="$(cd "$1" && pwd)"
fi
PLANS="$PKG_ROOT/docs/superpowers/plans"
[[ -d "$PLANS" ]] || {
  echo "PLAN_LOOP_HYGIENE_OK reason=no_plans_dir"
  exit 0
}

# Todo/checklist lines only
# Forbidden: Plan-loop-as-Implement phrases
# Allowed on same line: verify-plan-loop-hygiene, PLAN_LOOP_HYGIENE_OK, references/looping-review
FAIL_RE='plan-loop-converge|run[[:space:]]+[0-9]+[[:space:]]+plan[[:space:]]+reviews|run[[:space:]]+N[[:space:]]+plan[[:space:]]+reviews|plan[[:space:]]*三審|審[[:space:]]*plan'

hits=0
while IFS= read -r -d '' f; do
  while IFS= read -r line || [[ -n "$line" ]]; do
    # checklist / todo-ish lines
    if ! [[ "$line" =~ ^[[:space:]]*-[[:space:]]*\[[[:space:]xX]\] ]] \
      && ! [[ "$line" =~ ^[[:space:]]*-[[:space:]]*id:[[:space:]]*plan-loop ]]; then
      continue
    fi
    # allow deliverable / token names
    if echo "$line" | grep -Eiq 'verify-plan-loop-hygiene|plan-loop-hygiene|PLAN_LOOP_HYGIENE_OK|references/looping-review'; then
      # still fail if also has converge / run N plan reviews as the task
      if echo "$line" | grep -Eiq 'plan-loop-converge|run[[:space:]]+[0-9N]+[[:space:]]+plan[[:space:]]+reviews|plan[[:space:]]*三審'; then
        :
      else
        continue
      fi
    fi
    if echo "$line" | grep -Eiq "$FAIL_RE"; then
      echo "FAIL: plan-loop-as-implement todo in $f" >&2
      echo "  $line" >&2
      hits=$((hits + 1))
    fi
  done <"$f"
done < <(find "$PLANS" -type f -name '*.md' -print0 2>/dev/null)

if [[ "$hits" -gt 0 ]]; then
  echo "PLAN_LOOP_HYGIENE_FAIL count=$hits" >&2
  exit 1
fi
echo "PLAN_LOOP_HYGIENE_OK"
exit 0
