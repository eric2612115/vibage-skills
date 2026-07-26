#!/usr/bin/env bash
# Fail if package plans put Plan-loop work into Implement todos (word-level).
# Scans only docs/superpowers/plans/**/*.md "todo-ish" lines:
#   - [ ] / - [x] checklists
#   - id: plan-loop* yaml-ish
#   numbered steps: 1. / 1)
#   bullets: * / +
#   markdown table rows: |
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

# Forbidden: Plan-loop-as-Implement phrases (word-level; rewrite still possible)
FAIL_RE='plan-loop-converge|run[[:space:]]+[0-9]+[[:space:]]+plan[[:space:]]+reviews|run[[:space:]]+N[[:space:]]+plan[[:space:]]+reviews|plan[[:space:]]*three reviews'

is_todoish_line() {
  local line="$1"
  # checklist
  [[ "$line" =~ ^[[:space:]]*-[[:space:]]*\[[[:space:]xX]\] ]] && return 0
  # yaml-ish id
  [[ "$line" =~ ^[[:space:]]*-[[:space:]]*id:[[:space:]]*plan-loop ]] && return 0
  # numbered: 1. or 1)
  [[ "$line" =~ ^[[:space:]]*[0-9]+\.[[:space:]] ]] && return 0
  [[ "$line" =~ ^[[:space:]]*[0-9]+\)[[:space:]] ]] && return 0
  # bullets * or + (not --- rules)
  [[ "$line" =~ ^[[:space:]]*[*+][[:space:]]+ ]] && return 0
  # markdown table row (must look like a row, not |---| separator alone)
  if [[ "$line" =~ ^[[:space:]]*\| ]] && [[ ! "$line" =~ ^[[:space:]]*\|[[:space:]]*[-:]+ ]]; then
    return 0
  fi
  return 1
}

hits=0
while IFS= read -r -d '' f; do
  while IFS= read -r line || [[ -n "$line" ]]; do
    is_todoish_line "$line" || continue
    # allow deliverable / token names unless also forbidden task phrases
    if echo "$line" | grep -Eiq 'verify-plan-loop-hygiene|plan-loop-hygiene|PLAN_LOOP_HYGIENE_OK|references/looping-review'; then
      if echo "$line" | grep -Eiq 'plan-loop-converge|run[[:space:]]+[0-9N]+[[:space:]]+plan[[:space:]]+reviews|plan[[:space:]]*three reviews'; then
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
