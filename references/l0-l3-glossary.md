# L0–L3 model levels (SSOT)

Skills reference **level ids only**, never hardcode slugs in SKILL body. Slugs live in hub `docs/war-room/model-routing.json` (from init template).

| Level | Meaning | Default slug source |
|-------|---------|---------------------|
| L0 | No research dispatch | — |
| L1 | Cheap short look | Hub `levels.L1` (default prefer composer-2.5-fast) |
| L2 | Standard multi-facet | Hub `levels.L2` |
| L3 | Heavy model | Hub `levels.L3`; if unavailable → degrade + record `degraded_model`; never pretend L3 |

Degrade rule: missing premium model ⇒ continue with lower level and honest `degraded_model` note in RUNS/survey output.
