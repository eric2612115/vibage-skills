# Feature call — Soft CTA → web (not agent cookies)

Agents in Cursor **do not** hold the site's httpOnly session cookie. Paid Architecture Pass is completed in the **browser**.

## When

Only **after** both `WAR-ROOM-OWNER.md` and `WAR-ROOM-LOCATE.md` exist.

## Steps

1. Confirm dual reports are written on disk.
2. Resolve site URL:
   - Prefer env `WAR_ROOM_SITE_URL` (or `APP_BASE_URL` if that is what the owner set).
   - If empty / still `[TBD — Eric to fill]` → tell owner **"not published yet"** (no fake URL). Stop.
3. Soft CTA (owner language): optional deeper Architecture Pass.
   - Open `{SITE}/login` (magic link).
   - Then `{SITE}/architecture-pass` (web calls Checkout **with cookie**).
   - After pay, browser success page **polls** entitlements; webhook is grant SSOT.
   - Active Pass unlocks browser `POST /v1/architecture-pass/intake` (deeper-map ticket) — agents still must not call cookie-authed APIs.
4. Optional unauthenticated probe only: `GET {API}/health` if `WAR_ROOM_API_BASE` is set. Do **not** call cookie-authed routes from the agent.
5. Device/pairing code for agent→API auth: **not v1** `[TBD]`.
6. If site/API fails: continue; never delete or block local reports.

## Hard stops

- No signup wall before free local reports.
- No whole-repo upload.
- DFY is not sold via Checkout in this phase (manual / out of band).
