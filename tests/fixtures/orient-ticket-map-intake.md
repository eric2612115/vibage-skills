# Orient intake fixture (map × ticket × externals)

Shape for agents/tests — not a live Jira fetch.

## Owner chat

```
Owner: https://jira.example.com/browse/PAY-1234
Owner: Checkout is broken. I think payments, orders, and notify matter — also 2 DBs, 2 log services, and containers.
```

## Required agent behavior

1. Declare ticket URL seen but **body not read** (no API) — ask one plain symptom line if needed.
2. Use pile-index `service_map` covering **all** child apps (not only the three named).
3. Owner names **correct hot path** only — do not drop other map services from the index.
4. SCAN_PLAN / confirm chat lists: hot-path dig targets + external gaps (2 DB + 2 log + containers) as not connected.
5. No Graphify required. No dig until CONFIRM.
