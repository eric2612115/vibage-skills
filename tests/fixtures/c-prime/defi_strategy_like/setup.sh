#!/usr/bin/env bash
# DefiStrategy-like parent: bare compose + .env.example + PKG sibling noise.
# Used by tests/test_c_prime_defi_pile.sh — not a live parent clone.
set -euo pipefail

DEST="${1:-}"
if [[ -z "$DEST" ]]; then
  echo "Usage: $0 /path/to/dest-parent" >&2
  exit 2
fi
mkdir -p "$DEST"
DEST="$(cd "$DEST" && pwd)"

init_git() {
  local root="$1"
  (
    cd "$root"
    git init -q -b main
    git config user.email "fixture@vibage.test"
    git config user.name "Vibage Fixture"
  )
}

# Fake PKG sibling (must be excluded from product map)
PKG_SIBLING="$DEST/vibage-skills"
mkdir -p "$PKG_SIBLING/skills" "$PKG_SIBLING/scripts"
echo "# fake" >"$PKG_SIBLING/skills/MANIFEST.txt"
echo '#!/usr/bin/env bash' >"$PKG_SIBLING/scripts/resolve-pkg-root.sh"
echo 'echo fake-pkg' >>"$PKG_SIBLING/scripts/resolve-pkg-root.sh"
chmod +x "$PKG_SIBLING/scripts/resolve-pkg-root.sh"
printf '# vibage-skills\n\nTooling package (fixture).\n' >"$PKG_SIBLING/README.md"
init_git "$PKG_SIBLING"
(
  cd "$PKG_SIBLING"
  git add -A
  git commit -q -m "init fake vibage-skills"
)

# app-api: bare compose + .env.example (no named APP_ENV)
API="$DEST/app-api"
mkdir -p "$API"
cat >"$API/docker-compose.yml" <<'EOF'
services:
  app-api:
    image: app-api:local
    ports:
      - "8080:8080"
EOF
cat >"$API/.env.example" <<'EOF'
# example only — never commit real secrets
DATABASE_URL=postgres://localhost/app
APP_ENV=local
PORT=8080
EOF
printf '# app-api\n\nAPI service.\n' >"$API/README.md"
cat >"$API/package.json" <<'EOF'
{
  "name": "app-api",
  "description": "API service"
}
EOF
init_git "$API"
(
  cd "$API"
  git add -A
  git commit -q -m "init app-api bare compose"
)

# app-web: compose service key references app-api (sibling name)
WEB="$DEST/app-web"
mkdir -p "$WEB"
cat >"$WEB/docker-compose.yml" <<'EOF'
services:
  app-web:
    image: app-web:local
  app-api:
    image: app-api:local
    # sibling service name for cheap edge discovery
EOF
cat >"$WEB/.env.example" <<'EOF'
NODE_ENV=development
API_URL=http://localhost:8080
EOF
printf '# app-web\n\nWeb frontend.\n' >"$WEB/README.md"
cat >"$WEB/package.json" <<'EOF'
{
  "name": "app-web",
  "description": "Web frontend"
}
EOF
init_git "$WEB"
(
  cd "$WEB"
  git add -A
  git commit -q -m "init app-web compose+sibling"
)

# orphan-lib: no compose, no .env* → may remain missing-env-config
ORPHAN="$DEST/orphan-lib"
mkdir -p "$ORPHAN"
printf '# orphan-lib\n\nShared lib without deploy surface.\n' >"$ORPHAN/README.md"
init_git "$ORPHAN"
(
  cd "$ORPHAN"
  git add -A
  git commit -q -m "init orphan-lib"
)

# stale tooling remnant (must be excluded even if OWNER_POLICY omits it)
WR="$DEST/war-room-skills"
mkdir -p "$WR"
printf '# war-room-skills\n\nStale rename remnant.\n' >"$WR/README.md"
printf '# FINAL-LOCK\n' >"$WR/FINAL-LOCK-digest-extracted.md"
init_git "$WR"
(
  cd "$WR"
  git add -A
  git commit -q -m "init war-room-skills remnant"
)

# Hub skeleton (install --init-hub also works; seed for direct c-prime-fill)
mkdir -p "$DEST/docs/vibage/maps"
cat >"$DEST/docs/vibage/STATUS.md" <<'EOF'
# STATUS (fixture)
phase: map
EOF
cat >"$DEST/docs/vibage/OWNER_POLICY.json" <<'EOF'
{
  "exclude_repo_globs": ["vibage-skills", "vibage-skills-*"]
}
EOF

echo "OK: defi_strategy_like parent at $DEST"
