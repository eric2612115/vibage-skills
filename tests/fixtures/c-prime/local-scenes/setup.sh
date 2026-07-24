#!/usr/bin/env bash
# Build local-scenes parent workspace into DEST (L1 / C′ Chunk 3).
# Four scenes (architecture/x402/quant/mindblow), keywords non-empty,
# seed_method=fixture, scenes_draft=false, shared hub, exclusive per scene,
# exclusive↔exclusive edge, no isolation_waiver. Pre-seeds matrix for mtime check.
set -euo pipefail

DEST="${1:-}"
if [[ -z "$DEST" ]]; then
  echo "Usage: $0 /path/to/dest-parent" >&2
  exit 2
fi
mkdir -p "$DEST"
DEST="$(cd "$DEST" && pwd)"

mkdir -p \
  "$DEST/docs/vibage/scenes" \
  "$DEST/docs/vibage/maps" \
  "$DEST/docs/vibage/ledger" \
  "$DEST/docs/vibage/briefs"

cat >"$DEST/docs/vibage/STATUS.md" <<'EOF'
# Vibage Hub STATUS

schema_version: 1
hub_ready: true
active_scene:
scenes_draft: false
phase: installed
notes: "local-scenes L1 fixture"
EOF

cat >"$DEST/docs/vibage/scenes/SCENES.json" <<'EOF'
{
  "scenes": [
    {
      "scene_id": "architecture",
      "title": "Architecture Domain",
      "keywords": ["arch", "infra", "topology"],
      "repo_ids": ["arch-a", "hub"],
      "hot_edge_ids": ["arch-a->hub"],
      "default_env_ids": [],
      "notes": "exclusive arch-a + shared hub",
      "seed_method": "fixture"
    },
    {
      "scene_id": "x402",
      "title": "X402 Payments",
      "keywords": ["payment", "x402", "settle"],
      "repo_ids": ["x402-a", "hub"],
      "hot_edge_ids": ["x402-a->hub"],
      "default_env_ids": [],
      "notes": "exclusive x402-a + shared hub",
      "seed_method": "fixture"
    },
    {
      "scene_id": "quant",
      "title": "Quant Research",
      "keywords": ["quant", "alpha", "signal"],
      "repo_ids": ["quant-a", "hub"],
      "hot_edge_ids": ["quant-a->hub"],
      "default_env_ids": [],
      "notes": "exclusive quant-a + shared hub",
      "seed_method": "fixture"
    },
    {
      "scene_id": "mindblow",
      "title": "Mindblow Experiments",
      "keywords": ["mindblow", "experiment", "lab"],
      "repo_ids": ["mindblow-a", "hub"],
      "hot_edge_ids": ["mindblow-a->hub"],
      "default_env_ids": [],
      "notes": "exclusive mindblow-a + shared hub",
      "seed_method": "fixture"
    }
  ]
}
EOF

# Intentionally no WAIVERS.json (isolation_waiver forbidden in this fixture)

cat >"$DEST/docs/vibage/maps/service_map.json" <<'EOF'
{
  "schema_version": "1",
  "pipeline_id": "service_map",
  "scale": "Subset",
  "quality_bar": "MEDIUM",
  "discover_mode": "flat",
  "discover_max_depth": 1,
  "depth": "standard",
  "services": [
    {"id": "arch-a", "name": "arch-a", "path": "arch-a", "definition": "architecture exclusive"},
    {"id": "x402-a", "name": "x402-a", "path": "x402-a", "definition": "x402 exclusive"},
    {"id": "quant-a", "name": "quant-a", "path": "quant-a", "definition": "quant exclusive"},
    {"id": "mindblow-a", "name": "mindblow-a", "path": "mindblow-a", "definition": "mindblow exclusive"},
    {"id": "hub", "name": "hub", "path": "hub", "definition": "shared hub"}
  ],
  "repos": [
    {"id": "arch-a", "repo_id": "arch-a", "name": "arch-a", "path": "arch-a"},
    {"id": "x402-a", "repo_id": "x402-a", "name": "x402-a", "path": "x402-a"},
    {"id": "quant-a", "repo_id": "quant-a", "name": "quant-a", "path": "quant-a"},
    {"id": "mindblow-a", "repo_id": "mindblow-a", "name": "mindblow-a", "path": "mindblow-a"},
    {"id": "hub", "repo_id": "hub", "name": "hub", "path": "hub"}
  ],
  "edges": [
    {"id": "arch-a->hub", "from": "arch-a", "to": "hub"},
    {"id": "x402-a->hub", "from": "x402-a", "to": "hub"},
    {"id": "quant-a->hub", "from": "quant-a", "to": "hub"},
    {"id": "mindblow-a->hub", "from": "mindblow-a", "to": "hub"},
    {"id": "arch-a->x402-a", "from": "arch-a", "to": "x402-a"},
    {"id": "quant-a->mindblow-a", "from": "quant-a", "to": "mindblow-a"}
  ]
}
EOF

# Pre-seed terminal matrix so scene switch can assert mtime unchanged
cat >"$DEST/docs/vibage/maps/env_branch_matrix.json" <<'EOF'
{
  "schema_version": "1",
  "status": "ok",
  "max_branches_per_repo": 30,
  "max_matrix_cells": 500,
  "cells": [
    {
      "repo_id": "hub",
      "branch_ref": "main",
      "env_id": "staging",
      "pointers": [
        {
          "path": "hub/docker-compose.yml",
          "quote": "APP_ENV: staging",
          "branch_ref": "main",
          "env_id": "staging"
        }
      ],
      "state": "proven"
    }
  ]
}
EOF

cat >"$DEST/docs/vibage/maps/inventory_manifest.json" <<'EOF'
{
  "schema_version": "1",
  "rows": [
    {"repo_id": "hub", "branch_ref": "main", "env_id": "staging"}
  ]
}
EOF

: >"$DEST/docs/vibage/ledger/claims.jsonl"

echo "OK: local-scenes setup at $DEST"
