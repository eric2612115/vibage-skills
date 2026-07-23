# SAT-ci-remote

**Owns:** Honest skip when no remote `origin`; later remote CI may mirror Tier-0 only.  
**Umbrella:** §9.1 `SAT-ci-remote`; §9.2 `P7-ci-when-remote`  
**Plan:** P7 in `docs/superpowers/plans/2026-07-23-vibage-v2-p4-p7-follow-ons.md`  
**Local ship entry:** `bash scripts/test-tier0.sh` (independent of remote CI)

---

## 1. This-wave rule (no origin → SKIPPED)

When `git remote -v` shows **no remotes**, or shows remotes but **no `origin`**:

1. Remote CI is **SKIPPED** — do **not** create any `.github/workflows/*.yml` (not only `tier0.yml`).
2. Package `STATUS.md` P7 must be grep-able as `skipped` or `SKIPPED`.
3. Must **not** claim P7 complete, remote workflow active, or remote CI success / Proven from local runs alone.
4. Local **Tier-0 green** wording is allowed (`TIER0_OK` from `scripts/test-tier0.sh`). That is **≠** remote CI success.
5. No remote ≠ publish-ready.

This satellite is the thin contract only: **no** checked-in workflow body, **no** CI badges.

---

## 2. When `origin` exists later

Add a GitHub Actions workflow that runs **only**:

```bash
bash scripts/test-tier0.sh
```

Same command as local Tier-0. Do not widen the remote job beyond that entry without a new plan. Do not claim remote success until the remote job actually passes.

---

## 3. Optional mechanical check

`tests/test_ci_remote_skip.sh` (optional track; **not** wired into Tier-0):

- Requires this satellite file.
- When no remotes **or** no `origin`: asserts no `.github/workflows/*.yml` and `STATUS.md` has skip wording.

---

## 4. Out of scope (this wave without origin)

- Any on-tree `.github/workflows/` YAML body
- CI status badges
- Treating local Tier-0 green as remote CI proof
- SaaS / register / cloud locate
