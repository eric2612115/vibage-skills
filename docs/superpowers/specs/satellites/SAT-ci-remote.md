# SAT-ci-remote

**Owns:** Honest skip when no remote `origin`; when `origin` exists, remote CI may mirror Tier-0 only.  
**Umbrella:** §9.1 `SAT-ci-remote`; §9.2 `P7-ci-when-remote`  
**Plan:** P7 / Plan-P  
**Local ship entry:** `bash scripts/test-tier0.sh` (independent of remote CI until Actions green)

---

## 1. No origin → SKIPPED

When `git remote -v` shows **no remotes**, or shows remotes but **no `origin`**:

1. Remote CI is **SKIPPED** — do **not** create any `.github/workflows/*.yml`.
2. Package `STATUS.md` must be grep-able as `skipped` or `SKIPPED`.
3. Must **not** claim P7 complete, remote workflow active, or remote CI Proven from local runs alone.
4. Local **Tier-0 green** is allowed. That is **≠** remote CI success.
5. No remote ≠ publish-ready.

---

## 2. When `origin` exists

Add a GitHub Actions workflow that runs **only**:

```bash
bash scripts/test-tier0.sh
```

Same command as local Tier-0. Do not widen the remote job beyond that entry without a new plan.

STATUS must:

- Note `origin` present and workflow on-tree (e.g. `.github/workflows/tier0.yml`)
- Set remote CI Proven-green only after an Actions run actually passes
- Keep ≠ publish-ready until human decides otherwise
- Still point at this satellite

Do not claim remote success from local `TIER0_OK` alone.

---

## 3. Optional mechanical check

`tests/test_ci_remote_skip.sh` (optional track; **not** wired into Tier-0):

- No origin → no workflow YAML + STATUS skip wording.
- Has origin → workflow YAML exists and names `test-tier0.sh`; STATUS must not pretend “no origin / SKIPPED forever”.

---

## 4. Out of scope

- CI status badges in this satellite
- Treating local Tier-0 green as remote CI proof without Actions
- SaaS / register / cloud locate
