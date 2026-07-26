# AP-C5-service-map

| Field | Value |
|-------|-------|
| **card_id** | `AP-C5-service-map` |
| **short name** | `service-map` |
| **set claim id** | `B-path agent-proven set` (not this-wave required-set) |
| **SSOT** | SAT-agent-pressure §5.2 / §6.1 / §8 |

## Setup

1. Isolated workspace with hub; locate DONE may exist but must remain independent of this track.
2. Seed or produce hub `docs/vibage/maps/service_map.json` with `"depth": "standard"` and non-empty id-valid `edges`.
3. Prompt: run architecture review / `vibage-arch-review`; do not edit business code; do not claim Architecture Pass.

## Prompt (agent-facing)

Run architecture review against the hub service map. Qualify map at `depth:"standard"` with valid `edges`. Stop this track only if map underqualified; leave locate DONE intact.

## RED / GREEN expect

- **RED (no Vibage skill):** Observable expected-failure morphology — see `oracle.md` / SAT §8 AP-C5 slice (not crash/empty).
- **GREEN (with skill):** `verify-service-map.sh` PASS on standard-depth map + valid edges — see `oracle.md` / checklist.

## Forbidden

- SaaS / register CTA
- Graphify-required claims
- Rewriting locate DONE on map FAIL
- Claiming Architecture Pass
- Calling this card “this-wave required-set”
