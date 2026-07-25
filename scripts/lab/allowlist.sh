#!/usr/bin/env bash
# Allowlist gate for lab sources. No HOME scan. Named mothers only.
# Usage:
#   source allowlist.sh
#   lab_assert_source_allowed /abs/path
set -euo pipefail

LAB_ALLOW_PREFIXES=(
  "/Users/eric.fang/Projects"
  "/Users/eric.fang/MindOwnBuz"
  "/Users/eric.fang/Rust"
)

# Exact mother roots used by Round 1–3 (not a HOME scan).
LAB_NAMED_MOTHERS=(
  "/Users/eric.fang/Projects/AI-Project"
  "/Users/eric.fang/Projects/AI_Game"
  "/Users/eric.fang/Projects/LangSight"
  "/Users/eric.fang/Projects/OmRate_Phalanx"
  "/Users/eric.fang/Projects/Termmax"
  "/Users/eric.fang/Projects/Trading"
  "/Users/eric.fang/MindOwnBuz"
  "/Users/eric.fang/Rust"
)

lab_assert_source_allowed() {
  local raw="${1:-}"
  [[ -n "$raw" ]] || { echo "LAB_ALLOWLIST_FAIL: empty source" >&2; return 1; }
  [[ -d "$raw" ]] || { echo "LAB_ALLOWLIST_FAIL: not a directory: $raw" >&2; return 1; }

  local resolved
  resolved="$(cd "$raw" && pwd -P)" || {
    echo "LAB_ALLOWLIST_FAIL: cannot resolve: $raw" >&2
    return 1
  }

  local ok=0
  local p
  for p in "${LAB_ALLOW_PREFIXES[@]}"; do
    if [[ "$resolved" == "$p" || "$resolved" == "$p"/* ]]; then
      ok=1
      break
    fi
  done

  if [[ "$ok" -ne 1 ]]; then
    echo "LAB_ALLOWLIST_FAIL: $resolved not under allowlist (Projects|MindOwnBuz|Rust). HOME scan forbidden." >&2
    return 1
  fi

  echo "LAB_ALLOWLIST_OK source=$resolved"
  return 0
}

# Emit named mothers that exist on disk (skip missing without scanning HOME).
lab_list_named_mothers() {
  local m
  for m in "${LAB_NAMED_MOTHERS[@]}"; do
    if [[ -d "$m" ]]; then
      echo "$(cd "$m" && pwd -P)"
    else
      echo "LAB_MOTHER_SKIP missing=$m" >&2
    fi
  done
}

# Back-compat alias used by older callers.
lab_list_project_mothers() {
  lab_list_named_mothers
}

# True if path is under a live allowlist prefix (for write-guard).
lab_is_live_allowlist_path() {
  local resolved="$1"
  local p
  for p in "${LAB_ALLOW_PREFIXES[@]}"; do
    if [[ "$resolved" == "$p" || "$resolved" == "$p"/* ]]; then
      return 0
    fi
  done
  return 1
}
