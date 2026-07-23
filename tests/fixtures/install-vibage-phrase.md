# Fixture: owner says only “install Vibage”

**Owner (one line):** 幫我裝 Vibage  

**Agent must (no owner bash):**

1. Resolve package root (`resolve-pkg-root` or known checkout path).
2. `bash …/scripts/install.sh` (default three surfaces).
3. `bash …/scripts/install.sh --with-project-rule=<this parent workspace>`.
4. `bash …/scripts/verify-project-entry.sh <parent>` → `PROJECT_ENTRY_OK`.
5. `bash …/scripts/verify-pins.sh` (owner-language recovery on fail).
6. Read **using-vibage**; stop before dig unless owner describes a problem.

**Not required of owner:** typing any shell, pasting NEW-CHAT, opening GitHub Settings.

**Evidence files:** `prompts/SAY-INSTALL-VIBAGE.md` · `skills/using-vibage/SKILL.md` § Install phrase.
