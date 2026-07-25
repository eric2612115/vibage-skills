#!/usr/bin/env bash
# Fail-closed ripgrep presence check for tests/scripts that call `rg`.
# Source after ROOT is set:  source "$ROOT/scripts/lib/require_rg.sh"
# Missing `rg` must NOT silently pass slogan/copy guards (shell-function-only hosts).
if ! command -v rg >/dev/null 2>&1; then
  echo "FAIL: ripgrep (rg) required on PATH — see DEPENDENCIES.md (fail-closed)" >&2
  exit 1
fi
