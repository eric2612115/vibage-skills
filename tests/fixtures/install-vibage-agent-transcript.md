# Agent transcript (install phrase) — re-runnable evidence shape

This is the **expected chat shape** when the owner says only the install line.  
Mechanical double-check: `bash tests/test_install_phrase_e2e.sh` → `INSTALL_PHRASE_E2E_OK`.

```
Owner: 幫我裝 Vibage

Agent: [invokes using-vibage § Install phrase]
Agent: [runs] install.sh
Agent: [runs] install.sh --with-project-rule=<this parent>
Agent: [runs] verify-project-entry.sh → PROJECT_ENTRY_OK
Agent: [runs] verify-pins.sh
Agent: Install ready. What problem should we find? (Do not dig yet.)

Owner: （用白話描述症狀；仍不打 bash）
```

**Honesty:** This fixture + e2e script = agent-equivalent proof. Not a recorded screen video. Not locate DONE.
