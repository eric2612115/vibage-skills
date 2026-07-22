# Vibage Locate — 2026-07-22 (synthetic example)

## Symptom
Dashboard empty; owner fears live trading.

## Repo identity (fat repos)
- Active surface: `apps/web` + `packages/core`
- Legacy / ignore: `legacy/bot`
- Evidence: `docs/LEGACY.md` — "quarantine legacy/bot; primary UI apps/web"

## Top hypotheses (max 4)
1. **H1** — Empty UI is mock/fixtures — evidence: `apps/web/src/Monitor.tsx` — status: confirmed
2. **H2** — Live broker unimplemented — evidence: `packages/core/broker.py` — status: confirmed
3. **H3** — Wrong surface (legacy Grafana) — evidence: `docker-compose.yml` — status: likely

## Call
- Likely: human/process gap | config/env
- Confidence: high

## Ask colleagues (max 5)
- [ ] Builder — confirm no live broker process — unlocks owner fear

## Next actions (max 3)
1. Stay on paper/mock path.
2. Ignore `legacy/bot`.
3. Seed research runs if markets list empty.

## Nested pass
- Investigators: 3 — inv-ui, inv-broker, inv-identity
- Reviewers: 1 — rev-packet
- CritiqueVerdict summary: APPROVE
- Dropped after review: port anecdote without quote
- Mode: full nested (synthetic)

## Out of scope / deferred
- Implementing live broker
