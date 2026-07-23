---
name: research-survey-review
description: >-
  Use when survey-matrix MUST_SURVEY predicates fire (unknown deploy topology,
  critical missing/external RootRef on hot path, owner asks prior art, or nested
  reviewer escalates). Do not call any vibage-* product skill. Default is SKIP.
---

# Research Survey Review

Independent process skill: short external survey → synthesize → critique.

## When / Not

| When | Not |
|------|-----|
| Matrix MUST (see `$PKG_ROOT/references/survey-matrix.md`) | Nested path+quote review |
| Owner asks prior art | Section gates |
| Reviewer escalate | Calling `vibage-init/orient/locate` |

## PKG_ROOT

```bash
bash /path/to/vibage-skills/scripts/resolve-pkg-root.sh
```

Read hub `docs/vibage/model-routing.json` for L1–L3 slugs. Skills use **level ids only**.

## Default

**SKIP** unless a MUST predicate matches. User "skip web" → SKIP. Cache fingerprint (hub + plan hash + symptom) → SKIP.

## Budget

- Session = `run_id`
- ≤1 short survey; optional second only on reviewer escalate
- `max_rounds` ≤ 2
- Timing: after CONFIRM + first hypotheses

## Stages

1. **Plan** (L1): 3–5 facets max; write survey plan in chat or `docs/vibage/RUNS/<run_id>.survey-plan.md`
2. **Research** (L1/L2): parallel short looks; capture URLs + claims
3. **Synthesize** (L2): map findings → locate hypotheses impact
4. **Critique** (fresh L2): APPROVE | REJECT | NEEDS_REVISION | INCONCLUSIVE
5. **Stop** when critique not REJECT, or rounds exhausted, or human skip

## Output schema (required)

Write JSON to `docs/vibage/RUNS/<run_id>.survey.json` and append path to RunEnvelope `survey_refs[]`.

```json
{
  "schema_version": "1",
  "run_id": "<string>",
  "decision": "SURVEYED|SKIP",
  "skip_reason": "<string|null>",
  "must_predicates_matched": ["<predicate id or text>"],
  "mode": "full|degraded",
  "model_levels_used": ["L1", "L2"],
  "degraded_model": "<string|null>",
  "facets": [{"id": "f1", "question": "<string>", "findings": ["<string>"], "urls": ["<string>"]}],
  "synthesis": "<string>",
  "critique_verdict": "APPROVE|REJECT|NEEDS_REVISION|INCONCLUSIVE",
  "impact_on_hypotheses": ["<string>"],
  "rounds": 1
}
```

Field rules:

- `decision=SKIP` ⇒ `skip_reason` required; facets may be `[]`
- `decision=SURVEYED` ⇒ ≥1 facet OR explicit empty with critique explaining why
- `mode=full` only if researchers + fresh critic actually ran; else `degraded`
- Never pretend L3 if slug unavailable — set `degraded_model`

## Hard stops

- Do not call any `vibage-*` product skill.
- Do not recurse into `section-gate-review`.
- Do not upload whole hubs/repos.
- Do not block dual-report delivery on survey failure — SKIP/degrade and continue.
