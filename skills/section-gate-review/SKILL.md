---
name: section-gate-review
description: >-
  Use before the next design/plan section, or when the user says section OK
  without a prior gate for that digest. Do not edit product code; do not run
  locate nested; do not recurse into section-gate or research.
---

# Section Gate Review

Independent process skill for Vibage design/plan orchestration (not hard-wired into generic brainstorming).

## When / Not

| When | Not |
|------|-----|
| Before next design/plan § | Locate nested path+quote review |
| User "§N OK" without prior gate for digest | Web research (use research-survey-review) |
| | Product code edits |

## PKG_ROOT / models

Resolve PKG_ROOT via init/locate symlink. Use hub model-routing for L1/L2 slugs. Reference **level ids only**.

## Input schema

```json
{
  "schema_version": "1",
  "section_id": "<string>",
  "draft_digest": "<string>",
  "lenses": ["契約", "可執行", "擴展"],
  "max_rounds": 2
}
```

Defaults: `lenses` length 3 as above; `max_rounds` ≤ 2.

## Output schema

Write JSON (chat + optional `docs/vibage/RUNS/<review_run_id>.section-gate.json`):

```json
{
  "schema_version": "1",
  "review_run_id": "<string>",
  "section_id": "<string>",
  "verdict": "APPROVE|APPROVE_WITH_CHANGES|REJECT",
  "must_fix": ["<string>"],
  "go_next": true,
  "rounds": 1,
  "notes": "<string>"
}
```

**`go_next` ≠ locate `Mode`.** Do not invent Mode values here.

## Stop rules

- Stop when verdict is not REJECT and must_fix absorbed; or 2 rounds; or human skip
- `APPROVE_WITH_CHANGES` → L0 checklist verify (no new 3-agent round)
- `REJECT` → optional round 2
- Cap ≤6 agent calls/section
- Reviewers must not recurse into section-gate or research
- Same digest hash → idempotent skip

## Procedure

1. Normalize input; if same digest already APPROVED this session → skip
2. Dispatch up to 3 lens reviewers (L1/L2) — one pass
3. Parent synthesizes verdict + must_fix
4. If APPROVE_WITH_CHANGES → apply checklist; set `go_next` true only when fixes absorbed
5. Emit output schema; do not edit product code

## Hard stops

- Do not call any `vibage-*` product skill (`vibage-init`, `vibage-orient`, `vibage-locate`, `vibage-bootstrap`).
- No product code edits
- No recursive section-gate/research
- No locate dig
