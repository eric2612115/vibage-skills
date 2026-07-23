# AP-C5-service-map checklist (frozen before RED)

- [ ] Hub map at `docs/vibage/maps/service_map.json`
- [ ] Map includes `"depth": "standard"` (string)
- [ ] `edges` non-empty; every `from`/`to` ∈ `services[].id`
- [ ] `bash scripts/verify-service-map.sh <workspace>` exit 0
- [ ] No business-code edits on this track
- [ ] Map underqualified → stop **only** this track; locate DONE intact
- [ ] No Architecture Pass / SaaS claims
- [ ] Do not use `verify-handoff.sh` as map proof
