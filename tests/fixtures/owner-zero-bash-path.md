# Owner zero-bash path (Plan-S W1 evidence fixture)

**Claim:** After parent `install.sh --with-project-rule=<parent>`, the owner chat path does not require the owner to type bash.

## Roles

| Actor | Actions |
|-------|---------|
| Owner | Opens parent workspace chat; speaks in plain language (“help me find where the problem is”) |
| Agent | Agent runs `resolve-pkg-root`, `verify-pins`, reads package `STATUS.md`, follows **using-vibage** + parent routers |

## Expected transcript shape (illustrative)

```
Owner: This parent folder is messy — start from Vibage and find where the problem is.
Agent: [reads using-vibage / parent vibage.mdc]
Agent: [runs] bash …/verify-pins.sh
Agent: [reads] package STATUS.md
Agent: Hub missing or ready? → vibage-init or vibage-orient …
Owner: (answer confirms / questions only; no shell paste)
…
Agent: Dual reports ready. Finishing options: (1) preview (2) stop (3) optional fix/arch if you ask.
```

## Explicit non-requirements

- Owner does **not** paste install commands after first-time setup by agent/human operator.
- Pasting `NEW-CHAT.md` is optional when session entry + using-vibage already route.
- This fixture is evidence for dim4 scoring — not a runtime enforcer.
