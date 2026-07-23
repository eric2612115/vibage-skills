# Extending Vibage (local pack — no marketplace required)

How to add an **optional** skill without breaking locate DONE or Tier-0.

## Steps

1. Create `skills/<name>/SKILL.md` (English identifiers; match owner language in prose).
2. Add `<name>` to `skills/MANIFEST.txt` under the optional section (comment why locate DONE stays independent).
3. If it needs a verify script: `scripts/verify-….sh` + `tests/test_…_usable.sh` (**not** wired into `test-tier0.sh` unless a new plan says so).
4. Point from `using-vibage` finishing **only if** owner asks (no soft CTA).
5. Document honesty in `STATUS.md` (Designed / On-tree / Proven only with proof).
6. Optional: thin satellite under `docs/superpowers/specs/satellites/`.

## Do not

- Put register / SaaS CTA in local entry surfaces.
- Recurse `--with-project-rule` into every child repo.
- Claim marketplace / publish-ready from a new skill alone.

Marketplace listing is a **later public** choice (after you open the repo / SaaS wave) — not required for local extensibility.
