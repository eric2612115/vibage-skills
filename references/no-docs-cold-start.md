# No-docs cold start (when README / STATUS / AGENTS missing)

Use this order. Still 5 min orient budget. Produce an identity line even without docs.

1. **Compose / orchestration** — `docker-compose*.yml`, `compose.yaml`: service names, ports, build contexts.
2. **Package graphs** — `package.json` workspaces, `pnpm-workspace.yaml`, `Cargo.toml` workspace, `pyproject.toml` / `go.work`.
3. **Lockfiles** — note package managers present (`pnpm-lock.yaml`, `uv.lock`, `Cargo.lock`) without reading entire trees.
4. **CI** — `.github/workflows/*`, `.gitlab-ci.yml`: what jobs imply "active" apps.
5. **Entrypoints** — `Dockerfile*`, `Makefile` targets, `main.py` / `cmd/*/main.go` / `src/main.*` at shallow depth.
6. **Ports / URLs** — from compose or `.env.example` keys (never print secret values).
7. **Symptom grep** — exact error string / route / env key from owner input.

Then write: `Active surface: … | Legacy/ignore: …` with at least one path+quote (compose service or entrypoint counts).

If still empty: say so in both reports; ask builder "which folder do you deploy?" — do not invent a service map.
