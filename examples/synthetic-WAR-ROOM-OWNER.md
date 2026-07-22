# War Room — Owner Brief — 2026-07-22 (synthetic example)

## Symptom (owner words)
The dashboard looks empty and I'm afraid the bot is trading real money.

## Plain-language diagnosis
The screen is showing research/mock data. Real-money trading is not wired up in this synthetic story.

## Confidence
high — UI and mode docs both say paper/mock.

## Do-not-touch
- `legacy/bot/` quarantine tree
- Any `.env` secret values

## Capability (from questionnaire)
tests/git/docker: unsure

## 3 owner actions
1. Use only `apps/web` as the product UI (no local docker required).
2. Do not fund a live exchange account from this app today.
3. Paste the three builder asks below — do not run docker yourself.

## 3 copy-paste asks for builder
1. Is `QUANT_RUN_MODE` (or equivalent) set to paper/default?
2. Which folder should I treat as the live product surface?
3. Is Grafana/legacy on port 3000 something I should ignore?

## Want a deeper pass?
If you want architecture / debt mapping beyond this locate, open:
`not published yet`
No account required for this local report.
