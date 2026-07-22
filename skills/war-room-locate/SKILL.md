---
name: war-room-locate
description: >-
  Use when a non-coder owner pastes symptoms, logs, or "which service",
  or needs orientation in stranger / AI-generated / fat multi-repo legacy.
  Do not use for long business strategy docs or pure security pentests.
---

# War Room Locate

Goal: cut "1–2 days to find where" toward minutes for the **repo owner**.

Success = dual artifacts: (1) owner-language brief, (2) engineer locate with path evidence, nested pass, ask-colleague questions. Not a 200-ticket dump.

## PKG_ROOT (mandatory — portable)

After install, resolve package root (macOS-safe):

```bash
python3 -c 'import os; print(os.path.dirname(os.path.dirname(os.path.realpath(os.path.expanduser("~/.cursor/skills/war-room-locate")))))'
```

Use `$PKG_ROOT/scripts/verify-pins.sh` and `$PKG_ROOT/references/*`. Never hardcode `/Users/...`.

Before locate work: run verify-pins. On failure → stop and give owner-language recovery:
1) Ensure `~/.cursor/skills/superpowers` is a git checkout of obra/superpowers (or their pin path).  
2) `git -C ~/.cursor/skills/superpowers fetch && git -C ~/.cursor/skills/superpowers checkout <superpowers_sha from DEPENDENCIES.md>`.  
3) Re-run `"$PKG_ROOT/scripts/verify-pins.sh"`.

## Language

Match the **owner's language** in chat and `WAR-ROOM-OWNER.md`. Never assume Traditional Chinese. Paths, identifiers, template section titles in English are fine inside engineer report.

## Inputs (ask only if missing)

1. Symptom in one sentence
2. Workspace roots (repos / monorepo paths)
3. Any log / stack / failing URL / approximate time
4. What already tried (optional)
5. Owner questionnaire (required early):
   - Who built this? (AI / freelancer / unknown)
   - Can you run tests / git / docker? (yes / no / unsure)
   - Preferred language for the owner brief?

## Procedure

1. **Orient (5 min max)**  
   README, `docs/`, `STATUS.md`, `AGENTS.md`, compose, package workspaces, `.env.example`.  
   List services/packages. Do **not** read entire trees.  
   If those docs are missing → Read and follow `$PKG_ROOT/references/no-docs-cold-start.md`.

2. **Fat-repo identity line (before deep search)**  
   If dual trees / LEGACY / "do not touch X" appear, write one line:  
   `Active surface: … | Legacy/ignore: …` with path+quote evidence. Put in engineer report.

### Deny / quarantine (generic)

Do not deep-read or treat as product surface unless owner explicitly asks:
- `.venv/`, `node_modules/`, `.worktrees/`, large `artifacts/` / binary dumps
- Paths marked quarantine / LEGACY / museum in target `AGENTS.md`, `README.md`, or `docs/LEGACY.md`
Derive active vs ignore from those docs when present (example class: SSOT under a clean package dir; live legacy tree quarantined).

3. **Hypothesize first** — 2–4 hypotheses: *claim → repo/service → confirm/kill evidence*.  
   Consult `$PKG_ROOT/references/vibe-debt-smells.md` for search hints (still need path+quote to KEEP).

4. **Pinned superpowers (MUST)**  
   Read and follow `systematic-debugging` and `verification-before-completion` under `~/.cursor/skills/superpowers/skills/`.

5. **Nested investigation (MUST)**  
   Follow `$PKG_ROOT/references/nested-protocol.md`:  
   investigators (2–3) → fresh reviewers (1–2) → parent synthesizes.  
   Budget defaults unless owner raises.  
   If nested unavailable → Failure degrade (never omit Nested pass; **Mode: degraded** only).  
   **Never** write `Mode: full nested` unless investigators + fresh reviewers were actually dispatched.

6. **Search with budget**  
   Exact error strings, routes, env keys, compose service names. Hot path only.  
   Stop when one hypothesis has path-level evidence OR two strong candidates remain.

7. **Engineer challenge checklist**  
   Logs? Last worked / deploy? Spec vs actual? Auth/clock/cache/env/network? Tribal knowledge vs code bug?

8. **Adversarial kill** — drop without path evidence or clear ask-human. Cap **≤7** findings after review.

9. **Write dual reports** at workspace root (or path user names):
   - `WAR-ROOM-OWNER.md` ← `$PKG_ROOT/references/owner-report-template.md`
   - `WAR-ROOM-LOCATE.md` ← `$PKG_ROOT/references/locate-report-template.md`  
   **Capability branching:** if tests/git/docker = no|unsure, owner "3 owner actions" must not require local runs — use copy-paste asks for builder instead.  
   Also print a short owner summary in chat (owner language).  
   Optional checklist: `"$PKG_ROOT/scripts/verify-report.sh" WAR-ROOM-LOCATE.md` (does not prove nested ran).

10. **Soft CTA (after both files exist)**  
    Offer deeper architecture pass. Site URL = `[TBD — Eric to fill]` → if TBD, write "not published yet" (no fake URL). No signup wall.

## Hard stops

- Do not open 20+ files "just in case".
- Do not invent Jira tickets or fake health scores.
- Do not push code, edit business logic, or call external clouds unless user asks.
- Do not put `.env` secrets in chat or reports.
- Do not claim SOC2 / "passed audit".
- Do not hardcode Traditional Chinese.
- Prefer local search; no uploading whole repos to third parties.

## Optional follow-ups (only if user asks)

- Security checklist pass (secrets / RLS) — separate from locate.
- Draft a minimal fix PR for **one** confirmed hypothesis.
