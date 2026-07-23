# Agent transcript (install continuum) — re-runnable evidence shape

This is the **expected chat shape** when the owner says only the install line.  
Mechanical double-check: `bash tests/test_install_phrase_e2e.sh` → `INSTALL_PHRASE_E2E_OK`.

```
Owner: 幫我裝 Vibage

Agent: [invokes using-vibage § Install continuum]
Agent: [runs] install.sh
Agent: [runs] install.sh --with-project-rule=<this parent>   # required
Agent: [runs] verify-project-entry.sh → PROJECT_ENTRY_OK     # alwaysApply mdc
Agent: [runs] verify-pins.sh
Agent: [plain] Entry ready ≠ map ready ≠ dig. Next: checklist folder + map of every app folder.
Agent: [runs] install.sh --init-hub=<parent>
Agent: [invokes vibage-pile-index]
Agent: [runs] pile-index.sh → PILE_INDEX_OK
Agent: Map draft ready (N apps). Paste a ticket or say what hurts. (Do not dig yet.)

Owner: （貼票或白話症狀；仍不打 bash）
```

**Honesty:** Fixture + e2e = agent-equivalent proof. Not a screen video. Not locate DONE.  
Cold “install then halt” is **forbidden** (S04-amended).
