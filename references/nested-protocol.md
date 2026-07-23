# Nested investigation protocol (MUST)

## Scale heuristic

| Scale | N investigators | M reviewers |
|-------|-----------------|-------------|
| Small / single package | 2 | 1 |
| Fat / multi-identity (dual trees / many services) | 3 | 2 |
| Hard cap | 4 | 2 |

- Nesting depth ≤ 2; investigators **must not** recursively spawn further investigators.
- Reviewer may spawn **1** leaf verifier only if CritiqueVerdict is `NEEDS_REVISION`.
- Kill finding without `path` + evidence quote.
- Engineer findings ≤ 7 after review.
- Language: match owner; identifiers English.
- Max wall time for nested phase: ~15–20 min unless owner extends.

## Platform capability matrix

| Need | Cursor | Claude Code | Codex | If missing |
|------|--------|-------------|-------|------------|
| Nested investigators → fresh reviewers | Task / subagents | Agent tool / subagents | subagents | `Mode: degraded` |
| Soft CTA open site | browser / MCP | MCP / give human URL | computer-use / give human URL | paste URL only; never block reports |

Use whichever spawn API the host exposes. Record platform ids when available; otherwise parent-generated labels in `nested_dispatch`.

## CritiqueVerdict (enum)

`APPROVE | REJECT | NEEDS_REVISION | INCONCLUSIVE`

## Per-finding fields (reviewer)

`{id, SUPPORT|WEAK|CONTRADICT|UNVERIFIABLE, path, quote_span, kill_reason?}`

## Flow

1. Parent orients (README / STATUS / AGENTS / compose; if missing → `$PKG_ROOT/references/no-docs-cold-start.md`) → writes 2–4 hypotheses.
2. Dispatch investigators using **Investigator template** below (fill ROOT / SEAM / HYPOTHESIS).
3. Fresh reviewers using **Fresh reviewer template** (attach investigator output as REPORT). Not the same agents as investigators.
4. Parent synthesizes into dual reports.

## Investigator template (main fills SEAM / HYPOTHESIS / ROOT)

```text
You are a Vibage investigator. READ ONLY — do not edit files.
Workspace root: {{ROOT}}
Seam: {{SEAM}}
Hypothesis: {{HYPOTHESIS}}
Return markdown with: (1) findings list each with id, claim, path, quote_span, evidence status SUPPORT|WEAK; (2) kill anything without path+quote; (3) max 5 findings. Do NOT spawn further investigator subagents. Do NOT write VIBAGE-*.md.
```

## Fresh reviewer template (main attaches investigator output as {{REPORT}})

```text
You are a Vibage fresh reviewer. Critique only — do not investigate new seams, do not edit code.
Workspace root: {{ROOT}}
Investigator report:
{{REPORT}}
Return: CritiqueVerdict = APPROVE|REJECT|NEEDS_REVISION|INCONCLUSIVE; per_finding {id, SUPPORT|WEAK|CONTRADICT|UNVERIFIABLE, path, quote_span, kill_reason?}; evidence_gaps; must_fix. No recursive spawn except optional one leaf verifier if verdict NEEDS_REVISION.
```

## Evidence in VIBAGE-LOCATE.md (required fields)

```markdown
## Nested pass
- Investigators: N — ids or labels
- Reviewers: M — ids or labels
- CritiqueVerdict summary: APPROVE|REJECT|NEEDS_REVISION|INCONCLUSIVE
- Dropped after review: …
- Mode: full nested | degraded
```

Optional after write: `"$PKG_ROOT/scripts/verify-report.sh" VIBAGE-LOCATE.md` (checklist only; does not prove subagents ran).

## Failure modes / degrade

- Nested unavailable or timeout → **do not silently skip**. Set `Mode: degraded` in Nested pass; state reason in **both** owner + locate reports.
- **Forbidden:** writing `Mode: full nested` unless investigators and fresh reviewers were actually dispatched in this run.
- Degraded path: parent runs single-pass hot-path search using pinned `systematic-debugging`; still require path+quote; still ≤7 findings.
- Pin verify fails → stop locate until owner upgrades or re-pins (owner-language steps in locate/init skills).
