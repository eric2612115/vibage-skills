#!/usr/bin/env bash
# Build friend-chaos parent workspace into DEST (F1 / C′ Chunk 3).
# ≥10 micro-repos, ≥2 glob-matching branches each, ≥2 real envs (compose+ci),
# ≥1 nested git, OWNER_POLICY.discover_nested_git=true, no env_vacancy_waiver.
set -euo pipefail

DEST="${1:-}"
if [[ -z "$DEST" ]]; then
  echo "Usage: $0 /path/to/dest-parent" >&2
  exit 2
fi
mkdir -p "$DEST"
DEST="$(cd "$DEST" && pwd)"

make_micro_repo() {
  local root="$1"
  local name
  name="$(basename "$root")"
  mkdir -p "$root/.github/workflows"
  (
    cd "$root"
    # Real git required for branch inventory + git show evidence extract.
    git init -q -b main
    git config user.email "fixture@vibage.test"
    git config user.name "Vibage Fixture"
    printf '# %s\n\nFriend-chaos micro-repo.\n' "$name" >README.md
    # Real env configs via compose filename patterns (≥2 envs)
    cat >docker-compose.staging.yml <<'EOF'
services:
  app:
    image: app:staging
    environment:
      APP_ENV: staging
EOF
    cat >docker-compose.prod.yml <<'EOF'
services:
  app:
    image: app:prod
    environment:
      APP_ENV: prod
EOF
    # CI env config (second surface; staging already present via compose)
    cat >.github/workflows/deploy.yml <<'EOF'
name: deploy
on:
  push:
    branches: [main, staging]
jobs:
  deploy-staging:
    environment: staging
    runs-on: ubuntu-latest
    steps:
      - run: echo deploy-staging
  deploy-prod:
    environment: prod
    runs-on: ubuntu-latest
    steps:
      - run: echo deploy-prod
EOF
    git add README.md docker-compose.staging.yml docker-compose.prod.yml .github
    git commit -q -m "init ${name} staging+prod envs"
    # Second branch matching default globs (main already exists)
    git branch -q staging
    # Keep HEAD on main for predictable extract
    git checkout -q main
  )
}

# 9 top-level + 1 nested = 10 repos
for i in 01 02 03 04 05 06 07 08 09; do
  make_micro_repo "$DEST/svc-$i"
done
make_micro_repo "$DEST/nest/deep-svc"

# Hub policy: nested discovery ON; vacancy waiver forbidden for this fixture
mkdir -p "$DEST/docs/vibage"
cat >"$DEST/docs/vibage/OWNER_POLICY.json" <<'EOF'
{
  "discover_nested_git": true,
  "discover_max_depth": 3,
  "include_submodules": false
}
EOF

cat >"$DEST/docs/vibage/STATUS.md" <<'EOF'
# Vibage Hub STATUS

schema_version: 1
hub_ready: true
active_scene:
scenes_draft: false
phase: installed
notes: "friend-chaos F1 fixture"
EOF

echo "OK: friend-chaos setup at $DEST (10 micro-repos + nested)"
