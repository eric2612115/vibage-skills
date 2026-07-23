# SAT-issue-fix-unlock (stub)

**Owns:** Unlock file shape, branch/PR default, dual-consent edge cases.  
**Skill:** `skills/vibage-issue-fix/SKILL.md`  
**Umbrella:** §4.1 Dual consent for code edit

## Dual consent (summary)

1. Preference → `docs/vibage/OWNER_POLICY.json` (`fix_preference`: YES|NO; default NO).
2. Unlock → file-backed scope confirm **after** locate reports. Preference ≠ unlock.

## Unlock file (thin example)

Path (this wave): `docs/vibage/ISSUE_FIX_UNLOCK.json`  
Example schema: `unlock.example.json` (same directory).

Required idea: `schema_version`, `locate_run_id`, `allowed_paths[]`, `confirmed_at`, `confirmed_by`.

## Defaults

- Prefer branch/PR; no silent push.
- Unlock without preference=YES forbidden.
- Locate DONE independent of fix track.
