# SAT-issue-fix-unlock

**Owns:** Unlock file shape, `OWNER_POLICY` preference, branch/PR default, dual-consent edge cases, script-verifiable usable gate.  
**Skill:** `skills/vibage-issue-fix/SKILL.md`  
**Verify:** `scripts/verify-issue-fix-unlock.sh <workspace_root>`  
**Umbrella:** §4.1 Dual consent for code edit

**Usable (this wave):** Dual-consent + unlock gates are **script-proven** (verify + fixture tests). That is **not** letter **B** complete, and **not** an agent fix E2E / quality guarantee.

---

## 1. Dual consent (normative)

Two independent gates. Both required before any business-code edit:

| Gate | Hub path | Meaning |
|------|----------|---------|
| **Preference** | `docs/vibage/OWNER_POLICY.json` | Owner wants fix track considered (`fix_preference`) |
| **Unlock** | `docs/vibage/ISSUE_FIX_UNLOCK.json` | File-backed **scope confirm after** locate reports |

**Preference ≠ unlock.** Writing unlock does not imply YES. Writing YES does not imply scoped unlock.

### 1.1 Preference (`OWNER_POLICY.json`)

- Required key: `fix_preference` ∈ `{YES, NO}` (strings).
- Default / absent intent: **NO** (do not enter fix; do not solicit unlock).
- Not in scan_plan hash.
- Package example: `docs/superpowers/specs/satellites/OWNER_POLICY.example.json` (copy shape into hub path).

### 1.2 Unlock (`ISSUE_FIX_UNLOCK.json`)

- Path (this wave): `docs/vibage/ISSUE_FIX_UNLOCK.json`
- Package example: `docs/superpowers/specs/satellites/unlock.example.json`
- Required keys:

| Key | Rule |
|-----|------|
| `schema_version` | present (string; this wave `"1"`) |
| `locate_run_id` | non-empty string |
| `allowed_paths` | non-empty list of path strings |
| `confirmed_at` | present (ISO-8601 string recommended) |
| `confirmed_by` | present (owner / operator id string) |

Unlock is valid only when schema rules pass **and** preference is already YES.

---

## 2. Hard gates

1. If `fix_preference` is **NO** (or missing / not YES): agent **must not** enter `vibage-issue-fix` or solicit unlock. Locate may still DONE.
2. If owner wants fix: set `OWNER_POLICY.json` → `fix_preference=YES`, **then** after dual locate reports, write unlock with scoped `allowed_paths`.
3. Unlock without preference=YES is forbidden.
4. Preference=YES without a valid unlock is forbidden.
5. No dig / business edit without prior locate reports (`VIBAGE-ISSUE-OWNER.md` + `VIBAGE-ISSUE-LOCATE.md`, or prior locate run DONE).
6. Prefer **branch/PR**; no silent push; no deploy.
7. Edits stay inside `allowed_paths` from unlock.

---

## 3. Script verify (usable proof)

```bash
bash "$PKG_ROOT/scripts/verify-issue-fix-unlock.sh" <workspace_root>
```

Exit **0** only when:

- `docs/vibage/OWNER_POLICY.json` exists with `fix_preference=YES`
- `docs/vibage/ISSUE_FIX_UNLOCK.json` exists and passes schema (keys present; `locate_run_id` non-empty; `allowed_paths` non-empty list)

Exit **non-zero** for: missing files, preference NO, unlock present without YES, bad schema.

Print clear `OK:` / `FAIL:` lines. Fixture proof: `tests/test_issue_fix_usable.sh` (optional track; **not** wired into Tier-0).

**Honesty:** `usable` + package `STATUS` Proven-green(script) for issue-fix means **gates verifiable**. It does **not** mean letter B complete, and does **not** guarantee agent E2E fix quality.

---

## 4. Edge cases

| Case | Behavior |
|------|----------|
| Preference missing / not `YES`\|`NO` | Treat as not YES → verify FAIL; do not enter skill |
| Preference NO + unlock file present | Unlock ignored / forbidden; verify FAIL (unlock without YES) |
| Preference YES + missing unlock | verify FAIL; no edits |
| Unlock missing required keys | bad schema → FAIL |
| `allowed_paths` empty or not a list | bad schema → FAIL |
| `locate_run_id` empty | bad schema → FAIL |
| Locate reports absent | Skill stops before unlock/edits (script does not replace locate) |
| Owner flips YES→NO mid-flight | Stop edits; revoke unlock use; locate DONE unchanged |
| Path outside `allowed_paths` | Forbidden |
| Silent push / direct main | Forbidden; prefer branch/PR |

---

## 5. Branch / PR default

- Create or use a feature branch; open a PR when the host allows.
- Do not push silently to protected/default branches.
- Do not deploy.
- Commit messages stay owner-visible; no force-push unless owner explicitly asks.

---

## 6. Locate independence

- Locate DONE does **not** require issue-fix.
- Preference NO must **not** block locate DONE.
- Fix-track failure / refusal does **not** rewrite locate dual reports or undo DONE.

---

## 7. Handoff / `artifacts_ok` (non-cross)

- `artifacts_ok` does **not** cross pipelines by default (umbrella §8.4).
- Do **not** reuse a locate-wave `artifacts_ok` / `verify-handoff.sh` verdict as fix-run proof.
- Do **not** modify `scripts/verify-handoff.sh` for this track.
- Fix usable proof is `verify-issue-fix-unlock.sh` + optional `tests/test_issue_fix_usable.sh` only.

---

## 8. Out of scope (this wave)

- Agent E2E fix quality / Focus agent-pressure cards for issue-fix
- Letter **B** (needs issue-fix **and** 架構檢視 usable)
- SaaS / register CTA
- Changing Tier-0 body to require `test_issue_fix_usable.sh`
