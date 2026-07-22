# Vibe-debt smells (AI / outsourced fat repos)

Use after hypotheses. Each KEEP finding still needs `path` + quote. Smells are search hints — not tickets by themselves.

| ID | Smell | Search hints | Confirm | Kill if |
|----|-------|--------------|---------|---------|
| S1 | Dual live trees | `src/` + `apps/`, `legacy/`, `LEGACY.md` | Docs or compose point at one | Both trees equally wired with no quarantine note |
| S2 | Museum UI | Streamlit, Grafana, old `:3000` | README says museum / quarantine | Owner intentionally uses that UI |
| S3 | Fake / fixture UI | `FAKE`, `fixture`, `mock data`, `TODO wire` | UI file states no API | Real API client on same screen |
| S4 | Name lies (`real/`, `live/`) | dirs named `real`, `prod`, `live` | Code is offline/backtest | Actually hits exchange/broker |
| S5 | Paper vs live flag confusion | `--live`, `PAPER`, `DRY_RUN` | Flag = MD only / sim fills | Flag submits real orders |
| S6 | Env fork | multiple `.env*`, `env.example` drift | Runtime reads different file than docs | Single consistent env |
| S7 | Dead route | frontend route with no handler | 404 / unused import | Handler exists + tests |
| S8 | Shadow CRUD | duplicate services for same entity | Two writers, one unread | One clearly deprecated |
| S9 | Generated mixed with hand-edit | `generated/`, prisma, protobuf | Hand edits inside generated | Clean codegen boundary |
| S10 | Quarantine ignored | `polymarket_live`, `DO NOT EXPAND` | AGENTS forbids expand | Explicit W-decision to unquarantine |
| S11 | Test theater | always-green mocks | Tests never hit IO | Real integration exists |
| S12 | Port collision | two apps default same port | Compose vs Vite/Next clash | Distinct ports documented |
