# Vibage Local Prettier Maps (`Plan-G` / M Pretty-local) Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship Approach-1 thin local prettier maps (fail-soft optional Graphify sidecar + thin coverage notes + required pure-local SVG/HTML preview) on top of existing `service_map` floor + `depth:standard` edges — without changing `verify-service-map.sh`, Tier-0, letter B, or Focus Proven-green.

**Architecture:** **M Pretty-local** only (not S docs-only, not L platform). Two package scripts: **REQUIRED** `scripts/render-service-map-preview.sh` (pure local SVG/HTML from hub `service_map.json` `services`+`edges` → workspace `vibage-preview/service_map.html` + `.svg`; no external binary on success path) and **OPTIONAL** `scripts/generate-service-map-graph.sh` (`graphify`/documented CLI on PATH may write sidecar under `docs/vibage/maps/`; else exit 0 + `OK:GRAPHIFY_SKIP` + owner sentence). Coverage = sidecar `docs/vibage/maps/COVERAGE_NOTES.md` (or skill-written section) — **not** a verify field / floor gate. Preview root locked to `vibage-preview/` only. Proofs live **only** in `tests/test_prettier_maps.sh`.

**Tech Stack:** Bash, Python 3 (stdlib only for render), Markdown SAT/skills, existing fixtures under `tests/fixtures/service-map/`.

**Spec SSOT (consumers):** `@docs/superpowers/specs/satellites/SAT-map-schema.md`, `@docs/superpowers/specs/satellites/SAT-arch-review.md`, `skills/vibage-arch-review/SKILL.md`  
**Depends on:** Plan M (`depth:standard` + edges) already green; letter B agent-proven (`AP-C4`/`AP-C5`) already done — **do not rewrite**.  
**Index:** `2026-07-23-vibage-v2-plan-index.md` row **Plan-G** (order 12)  
**Package convention:** Commit steps are optional — **only commit when human asks**. Do **not** push. Do **not** enter new tests into `scripts/test-tier0.sh` or `tests/test_optional_track_gates.sh`.

**Honesty locks (absorb must_fix from DoD tri-review):**

1. **Fail-soft Graphify/render:** exit **0** + tokens `OK:GRAPHIFY_SKIP` / `OK:RENDER_SKIP` + owner sentence on **stdout**; missing binary ≠ `verify-service-map` FAIL.
2. **Locked choices (no OR):**
   - **REQUIRED:** `scripts/render-service-map-preview.sh` — pure local SVG/HTML from `service_map.json` `services`+`edges` → workspace `vibage-preview/service_map.html` (+ `.svg`). No external binary required for success path.
   - **OPTIONAL:** `scripts/generate-service-map-graph.sh` — if `graphify` (or documented CLI) on PATH, may write sidecar under `docs/vibage/maps/`; else exit 0 + `OK:GRAPHIFY_SKIP` + owner sentence.
   - **Coverage:** sidecar `docs/vibage/maps/COVERAGE_NOTES.md` (or section written by skill) — **NOT** a `verify-service-map` field; not a floor gate.
   - **Preview root:** `vibage-preview/` only (workspace root; fail-soft like existing preview).
3. **New tests:** `tests/test_prettier_maps.sh` **ONLY** — never wire into `test-tier0.sh` or `test_optional_track_gates.sh`; `verify-service-map.sh` **zero behavior change**.
4. **M Pretty-local ≠终局;** deeper Graphify / option **L** later allowed; `deferred-closed ≠ forever-forbidden`.
5. **No SaaS;** no cloud Architecture Pass; no letter B / Focus rewrite.
6. **Approach 1 thin;** Tier-0 OK.

---

## File map

| Path | Responsibility |
|------|----------------|
| `docs/superpowers/specs/satellites/SAT-map-schema.md` | Converge §6 OOS: Plan G unlocks local prettier (render/graphify/coverage notes) as optional local; **M ≠终局**; L may deepen later; cloud still out |
| `docs/superpowers/specs/satellites/SAT-arch-review.md` | Optional prettier procedure pointers; coverage notes + preview; still ≠ Architecture Pass |
| `skills/vibage-arch-review/SKILL.md` | Agent steps: optional graphify → coverage notes → required local render; fail-soft tokens |
| `scripts/render-service-map-preview.sh` | **REQUIRED** pure-local SVG/HTML writer → `$WS/vibage-preview/service_map.{html,svg}` |
| `scripts/generate-service-map-graph.sh` | **OPTIONAL** Graphify wrapper; PATH miss → soft skip |
| `docs/vibage/maps/` (workspace, not package) | Hub `service_map.json` + optional sidecar graph + `COVERAGE_NOTES.md` |
| `vibage-preview/` (workspace root) | Preview root only — `service_map.html` + `service_map.svg` beside existing `index.html` |
| `tests/test_prettier_maps.sh` | Sole Plan G proof harness |
| `STATUS.md` | Optional one honesty line — local prettier optional; ≠ Architecture Pass |
| **Do not modify behavior:** `scripts/verify-service-map.sh` | Zero behavior change (may be invoked only for regression in prettier tests) |
| **Do not wire:** `scripts/test-tier0.sh`, `tests/test_optional_track_gates.sh` | Must remain unaware of prettier tests |

**Hard bans:**

- Do not modify `scripts/verify-service-map.sh` logic/output contracts
- Do not wire `tests/test_prettier_maps.sh` into Tier-0 or optional-track gates
- Do not require Graphify for map qualification / letter B
- Do not add coverage fields that `verify-service-map` validates
- Do not write preview under `docs/vibage/maps/` (preview root = `vibage-preview/` only)
- Do not claim SaaS / cloud Architecture Pass / letter B upgrade / Focus Proven-green rewrite
- Do not invent forever-ban of deeper local Graphify/L

---

## Chunk 1: Spec / honesty lock

### Task 1: Converge SAT-map-schema OOS for Plan G

**Files:**
- Modify: `docs/superpowers/specs/satellites/SAT-map-schema.md`

- [x] **Step 1: Replace §6 “deferred this wave” Graphify/coverage/render wording**

Keep floor / §3.1 `depth:standard` rules untouched. Replace the Graphify/coverage/render bullet so it reads as **unlocked by Plan G (M Pretty-local)** without becoming a verify gate:

```markdown
## 6. Out of scope / adjacent local prettier (Plan G)

**Verify (`scripts/verify-service-map.sh`) still does not require** Graphify, coverage notes, or preview artifacts. Missing prettier sidecars must not fail map qualification.

**Plan G (M Pretty-local) unlocks locally (optional / fail-soft):**

| Piece | Contract |
|-------|----------|
| Render | `scripts/render-service-map-preview.sh` → workspace `vibage-preview/service_map.html` (+ `.svg`); pure local; no external binary on success path |
| Graphify | `scripts/generate-service-map-graph.sh` OPTIONAL; if CLI missing → exit 0 + `OK:GRAPHIFY_SKIP` + owner sentence; may write sidecar under `docs/vibage/maps/` when present |
| Coverage | Sidecar `docs/vibage/maps/COVERAGE_NOTES.md` (or skill-written section) — **not** a verify field; not a floor gate |

**Honesty:** M Pretty-local **≠终局**. Deeper local Graphify / coverage / render (option **L**) may open later. `deferred-closed ≠ forever-forbidden`. Cloud whole-repo upload/analysis and Architecture Pass remain out of scope (do not rewrite PRODUCT-LOCKS to a forever local ban).
```

Remove any phrasing that reads as “local maps forever never deepen.”

- [x] **Step 2: Grep lock phrases**

```bash
cd /Users/eric.fang/MindOwnBuz/vibage-skills
rg -n 'Pretty-local|GRAPHIFY_SKIP|COVERAGE_NOTES|forever|终局|render-service-map' \
  docs/superpowers/specs/satellites/SAT-map-schema.md
```

Expected: Plan G contracts present; “≠终局” / deferred≠forever present; no forever-ban-local-maps wording.

- [ ] **Commit (only if human requested)**

```bash
git add docs/superpowers/specs/satellites/SAT-map-schema.md
git commit -m "$(cat <<'EOF'
docs: unlock Plan G local prettier maps in SAT-map-schema

EOF
)"
```

---

### Task 2: SAT-arch-review + skill honesty pointers

**Files:**
- Modify: `docs/superpowers/specs/satellites/SAT-arch-review.md`
- Modify: `skills/vibage-arch-review/SKILL.md`

- [x] **Step 1: Add optional prettier procedure to SAT-arch-review**

Add a short subsection (after usable / verify procedure), e.g.:

```markdown
## Optional local prettier (Plan G — M Pretty-local)

After `verify-service-map.sh` exits 0, agents **may**:

1. OPTIONAL: `bash "$PKG_ROOT/scripts/generate-service-map-graph.sh" <workspace_root>`
   - If Graphify CLI missing → expect exit 0, stdout contains `OK:GRAPHIFY_SKIP` and one owner sentence. **Not** a qualification failure.
2. Thin coverage: write/update workspace `docs/vibage/maps/COVERAGE_NOTES.md` (services/edges coverage narrative). **Not** verified by `verify-service-map.sh`.
3. REQUIRED local preview (pure local, no external binary):  
   `bash "$PKG_ROOT/scripts/render-service-map-preview.sh" <workspace_root>`  
   → `vibage-preview/service_map.html` + `vibage-preview/service_map.svg`.  
   On soft skip/failure → exit 0 + `OK:RENDER_SKIP` + owner sentence; does not undo map usable / locate DONE.

Still ≠ cloud Architecture Pass. Still ≠ letter B upgrade. M Pretty-local ≠终局 (deeper Graphify/L later OK).
```

- [x] **Step 2: Mirror short steps in `skills/vibage-arch-review/SKILL.md`**

After the verify step in Usable procedure, add 3 bullets matching SAT (graphify optional → coverage notes → render). Explicit fail-soft tokens. Do **not** claim letter B / Architecture Pass / SaaS.

- [x] **Step 3: Grep honesty**

```bash
rg -n 'GRAPHIFY_SKIP|RENDER_SKIP|COVERAGE_NOTES|Architecture Pass|SaaS|letter B' \
  docs/superpowers/specs/satellites/SAT-arch-review.md \
  skills/vibage-arch-review/SKILL.md
```

Expected: soft tokens + COVERAGE_NOTES present; Architecture Pass / letter B denied or unchanged honesty; no SaaS CTA.

- [ ] **Commit (only if human requested)**

```bash
git add docs/superpowers/specs/satellites/SAT-arch-review.md \
  skills/vibage-arch-review/SKILL.md
git commit -m "$(cat <<'EOF'
docs: arch-review optional prettier maps procedure

EOF
)"
```

---

## Chunk 2: REQUIRED render script (TDD)

### Task 3: Write failing prettier tests for render first

**Files:**
- Create: `tests/test_prettier_maps.sh`
- Test fixture reuse: `tests/fixtures/service-map/standard-depth-ok.json`

- [x] **Step 1: Create `tests/test_prettier_maps.sh` skeleton with render cases**

```bash
#!/usr/bin/env bash
# Plan G — local prettier maps proofs ONLY.
# MUST NOT be wired into scripts/test-tier0.sh or tests/test_optional_track_gates.sh.
# MUST NOT require changing scripts/verify-service-map.sh behavior.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RENDER="$ROOT/scripts/render-service-map-preview.sh"
GRAPHIFY_GEN="$ROOT/scripts/generate-service-map-graph.sh"
VERIFY="$ROOT/scripts/verify-service-map.sh"
FIX_OK="$ROOT/tests/fixtures/service-map/standard-depth-ok.json"

pass() { echo "OK: $*"; }
fail() { echo "FAIL: $*" >&2; exit 1; }

[[ -f "$FIX_OK" ]] || fail "missing standard-depth-ok fixture"
[[ -f "$VERIFY" ]] || fail "missing verify-service-map.sh"

install_map() {
  local dir="$1" src="$2"
  mkdir -p "$dir/docs/vibage/maps"
  cp "$src" "$dir/docs/vibage/maps/service_map.json"
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- Render REQUIRED ---
[[ -f "$RENDER" ]] || fail "missing render-service-map-preview.sh"

WS_R="$TMP/render_ok"
install_map "$WS_R" "$FIX_OK"
set +e
OUT_R="$("$RENDER" "$WS_R" 2>&1)"
RC_R=$?
set -e
[[ "$RC_R" -eq 0 ]] || fail "render expected rc=0 got $RC_R; out=$OUT_R"
[[ -f "$WS_R/vibage-preview/service_map.html" ]] || fail "missing vibage-preview/service_map.html"
[[ -f "$WS_R/vibage-preview/service_map.svg" ]] || fail "missing vibage-preview/service_map.svg"
rg -q 'web|billing' "$WS_R/vibage-preview/service_map.svg" \
  || fail "svg should mention service ids from fixture"
rg -q 'service_map\.svg|Web frontend|billing' "$WS_R/vibage-preview/service_map.html" \
  || fail "html should reference svg or service labels"
echo "$OUT_R" | rg -q 'OK:RENDER' || fail "render stdout should include OK:RENDER token"
pass "render pure-local html+svg"

# Render must not place preview under maps/
[[ ! -f "$WS_R/docs/vibage/maps/service_map.html" ]] \
  || fail "preview must not land under docs/vibage/maps/"

# Missing map → fail-soft RENDER_SKIP (exit 0), no verify coupling
WS_MISS="$TMP/render_miss"
mkdir -p "$WS_MISS/docs/vibage/maps"
set +e
OUT_M="$("$RENDER" "$WS_MISS" 2>&1)"
RC_M=$?
set -e
[[ "$RC_M" -eq 0 ]] || fail "missing map render must exit 0 (fail-soft), got $RC_M"
echo "$OUT_M" | rg -q 'OK:RENDER_SKIP' || fail "expected OK:RENDER_SKIP"
# owner sentence: at least one non-token line of prose
echo "$OUT_M" | rg -qv '^(OK:|FAIL:)' || fail "RENDER_SKIP must include owner sentence on stdout"
pass "render missing map fail-soft"

# verify regression: standard fixture still qualifies (zero verify behavior change)
WS_V="$TMP/verify_still"
install_map "$WS_V" "$FIX_OK"
"$VERIFY" "$WS_V" >/dev/null
pass "verify-service-map unchanged path still PASS"

echo "ALL prettier_maps tests passed"
```

Make executable:

```bash
chmod +x tests/test_prettier_maps.sh
```

- [x] **Step 2: Run test to verify it fails (missing render script)**

```bash
bash tests/test_prettier_maps.sh
```

Expected: FAIL with `missing render-service-map-preview.sh` (or equivalent).

- [ ] **Commit (only if human requested)**

```bash
git add tests/test_prettier_maps.sh
git commit -m "$(cat <<'EOF'
test: add failing prettier maps render cases

EOF
)"
```

---

### Task 4: Implement REQUIRED `render-service-map-preview.sh`

**Files:**
- Create: `scripts/render-service-map-preview.sh`

- [x] **Step 1: Write pure-local renderer (Python stdlib + bash; no Graphify/dot/mermaid CLI)**

```bash
#!/usr/bin/env bash
# Usage: render-service-map-preview.sh <workspace_root>
# REQUIRED Plan G path: pure local SVG/HTML from hub service_map.json
# services+edges → $WS/vibage-preview/service_map.html (+ .svg).
# No external binary required for success. Fail-soft: exit 0 + OK:RENDER_SKIP.
set -euo pipefail

WS="${1:-}"
if [[ -z "$WS" || ! -d "$WS" ]]; then
  echo "FAIL: Usage: $0 <workspace_root>" >&2
  exit 2
fi

MAP="$WS/docs/vibage/maps/service_map.json"
DEST_DIR="$WS/vibage-preview"
SVG_OUT="$DEST_DIR/service_map.svg"
HTML_OUT="$DEST_DIR/service_map.html"

skip() {
  # Fail-soft: never fail verify; never non-zero for soft cases
  echo "OK:RENDER_SKIP"
  echo "$*"
  exit 0
}

[[ -f "$MAP" ]] || skip "Service map preview skipped: missing $MAP. Map qualification still uses verify-service-map.sh; locate DONE is unchanged."

mkdir -p "$DEST_DIR"

# must_fix: under set -e, wrap python so soft failures can print OK:RENDER_SKIP.
set +e
PY_OUT="$(python3 - "$MAP" "$SVG_OUT" "$HTML_OUT" <<'PY'
import json, html, sys
from pathlib import Path

map_path, svg_path, html_path = sys.argv[1], sys.argv[2], sys.argv[3]

def die_soft(msg: str) -> None:
    # Non-zero exit → bash skip path (OK:RENDER_SKIP).
    print(msg, file=sys.stderr)
    raise SystemExit(1)

try:
    obj = json.loads(Path(map_path).read_text(encoding="utf-8"))
except Exception as e:
    die_soft(f"unreadable service_map.json: {e}")

services = obj.get("services") or []
edges = obj.get("edges") or []
if not isinstance(services, list) or not services:
    die_soft("services missing or empty")

nodes = []
for i, s in enumerate(services):
    if not isinstance(s, dict):
        continue
    sid = str(s.get("id") or "").strip()
    if not sid:
        continue
    name = str(s.get("name") or sid).strip()
    nodes.append((sid, name))

if not nodes:
    die_soft("no valid service ids")

# Simple grid layout — pure local, no external layout binary
cols = max(1, int(len(nodes) ** 0.5 + 0.999))
w, h, pad = 160, 64, 40
positions = {}
for i, (sid, name) in enumerate(nodes):
    r, c = divmod(i, cols)
    positions[sid] = (pad + c * (w + pad), pad + r * (h + pad) + 20)

max_x = max(x for x, _ in positions.values()) + w + pad
max_y = max(y for _, y in positions.values()) + h + pad

def esc(s: str) -> str:
    return html.escape(s, quote=True)

parts = [
    f'<svg xmlns="http://www.w3.org/2000/svg" width="{max_x}" height="{max_y}" viewBox="0 0 {max_x} {max_y}">',
    '<rect width="100%" height="100%" fill="#0f1419"/>',
]
if isinstance(edges, list):
    for e in edges:
        if not isinstance(e, dict):
            continue
        a, b = e.get("from"), e.get("to")
        if a in positions and b in positions:
            x1, y1 = positions[a]
            x2, y2 = positions[b]
            parts.append(
                f'<line x1="{x1+w/2}" y1="{y1+h/2}" x2="{x2+w/2}" y2="{y2+h/2}" '
                f'stroke="#3d9cf0" stroke-width="2"/>'
            )
for sid, name in nodes:
    x, y = positions[sid]
    parts.append(
        f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="8" '
        f'fill="#1a2332" stroke="#2a3648"/>'
    )
    parts.append(
        f'<text x="{x+8}" y="{y+28}" fill="#e7ecf3" font-size="14" '
        f'font-family="IBM Plex Sans, Segoe UI, sans-serif">{esc(sid)}</text>'
    )
    parts.append(
        f'<text x="{x+8}" y="{y+48}" fill="#9aa7b8" font-size="11" '
        f'font-family="IBM Plex Sans, Segoe UI, sans-serif">{esc(name)}</text>'
    )
parts.append("</svg>")
Path(svg_path).write_text("\n".join(parts) + "\n", encoding="utf-8")

html_doc = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Vibage Service Map Preview</title>
  <style>
    body {{ margin: 0; font-family: "IBM Plex Sans", "Segoe UI", sans-serif;
      background: linear-gradient(160deg,#0f1419,#1a2332); color: #e7ecf3; }}
    main {{ max-width: 960px; margin: 0 auto; padding: 32px 20px; }}
    .brand {{ color: #3d9cf0; font-size: 0.85rem; letter-spacing: 0.08em; text-transform: uppercase; }}
    img, object {{ max-width: 100%; background: #0f1419; border: 1px solid #2a3648; }}
    a {{ color: #3d9cf0; }}
  </style>
</head>
<body>
  <main>
    <div class="brand">Vibage</div>
    <h1>Service map preview</h1>
    <p>Local render from <code>docs/vibage/maps/service_map.json</code> (Plan G). Not cloud Architecture Pass.</p>
    <p><a href="./index.html">Back to preview index</a></p>
    <object type="image/svg+xml" data="./service_map.svg">service_map.svg</object>
  </main>
</body>
</html>
"""
Path(html_path).write_text(html_doc, encoding="utf-8")
print("OK:RENDER wrote", html_path, "and", svg_path)
PY
)"
RC=$?
set -e
if [[ "$RC" -ne 0 ]]; then
  skip "Service map preview skipped: could not render from $MAP. Map usable still follows verify-service-map.sh only."
fi

if [[ -n "$PY_OUT" ]]; then
  echo "$PY_OUT"
else
  echo "OK:RENDER wrote $HTML_OUT and $SVG_OUT"
fi
```

Ensure executable:

```bash
chmod +x scripts/render-service-map-preview.sh
```

Note: Soft path must catch Python `RuntimeError` — adjust the bash wrapper so a non-zero python exit calls `skip` (as above). Do **not** call Graphify/dot.

- [x] **Step 2: Run prettier tests — render cases pass**

```bash
bash tests/test_prettier_maps.sh
```

Expected (until Graphify cases exist): either all-pass if graphify section not yet added, or FAIL only on missing `generate-service-map-graph.sh` if already asserted. Prefer completing Task 3 render-only first, then extend tests in Task 5.

If Task 3 script already ends after render cases with `ALL prettier_maps tests passed`, expect:

```
OK: render pure-local html+svg
OK: render missing map fail-soft
OK: verify-service-map unchanged path still PASS
ALL prettier_maps tests passed
```

- [ ] **Commit (only if human requested)**

```bash
git add scripts/render-service-map-preview.sh tests/test_prettier_maps.sh
git commit -m "$(cat <<'EOF'
feat: pure-local service map SVG/HTML preview

EOF
)"
```

---

## Chunk 3: OPTIONAL Graphify + coverage notes

### Task 5: Extend prettier tests for Graphify fail-soft + coverage sidecar

**Files:**
- Modify: `tests/test_prettier_maps.sh`

- [x] **Step 1: Append Graphify + coverage assertions before final pass line**

```bash
# --- Graphify OPTIONAL ---
[[ -f "$GRAPHIFY_GEN" ]] || fail "missing generate-service-map-graph.sh"

WS_G="$TMP/graphify_skip"
install_map "$WS_G" "$FIX_OK"
# Force missing CLI: prepend empty bin dir and clear PATH lookup for graphify
EMPTY_BIN="$TMP/empty_bin"
mkdir -p "$EMPTY_BIN"
set +e
OUT_G="$(PATH="$EMPTY_BIN:/usr/bin:/bin" "$GRAPHIFY_GEN" "$WS_G" 2>&1)"
RC_G=$?
set -e
[[ "$RC_G" -eq 0 ]] || fail "graphify missing must exit 0, got $RC_G; out=$OUT_G"
echo "$OUT_G" | rg -q 'OK:GRAPHIFY_SKIP' || fail "expected OK:GRAPHIFY_SKIP"
echo "$OUT_G" | rg -qv '^(OK:|FAIL:)' || fail "GRAPHIFY_SKIP must include owner sentence on stdout"
# Still must not break verify
"$VERIFY" "$WS_G" >/dev/null
pass "graphify missing fail-soft; verify still PASS"

# --- Coverage sidecar (not a verify field) ---
WS_C="$TMP/coverage_notes"
install_map "$WS_C" "$FIX_OK"
NOTES="$WS_C/docs/vibage/maps/COVERAGE_NOTES.md"
cat >"$NOTES" <<'EOF'
# Coverage notes (thin)

- Services in map: web, billing
- Edges present: web → billing
- This file is optional narrative; not enforced by verify-service-map.sh.
EOF
[[ -f "$NOTES" ]] || fail "COVERAGE_NOTES.md missing"
"$VERIFY" "$WS_C" >/dev/null
# Ensure verify does not require the notes file: delete and re-verify
rm -f "$NOTES"
"$VERIFY" "$WS_C" >/dev/null
pass "COVERAGE_NOTES optional; not a verify gate"

# Isolation: prettier test file must not be referenced by tier0 / optional gates
rg -q 'test_prettier_maps' "$ROOT/scripts/test-tier0.sh" \
  && fail "test_prettier_maps must NOT be wired into test-tier0.sh" || true
rg -q 'test_prettier_maps' "$ROOT/tests/test_optional_track_gates.sh" \
  && fail "test_prettier_maps must NOT be wired into test_optional_track_gates.sh" || true
pass "prettier tests isolated from Tier-0 and optional-track gates"
```

- [x] **Step 2: Run — expect FAIL on missing graphify script**

```bash
bash tests/test_prettier_maps.sh
```

Expected: FAIL `missing generate-service-map-graph.sh`.

- [ ] **Commit (only if human requested)**

```bash
git add tests/test_prettier_maps.sh
git commit -m "$(cat <<'EOF'
test: prettier maps graphify skip + coverage isolation

EOF
)"
```

---

### Task 6: Implement OPTIONAL `generate-service-map-graph.sh`

**Files:**
- Create: `scripts/generate-service-map-graph.sh`

- [x] **Step 1: Write fail-soft Graphify wrapper**

Documented CLI name: `graphify` on PATH (primary). No other SaaS API.

```bash
#!/usr/bin/env bash
# Usage: generate-service-map-graph.sh <workspace_root>
# OPTIONAL Plan G: if `graphify` (documented CLI) is on PATH, may write a
# sidecar under docs/vibage/maps/. Else exit 0 + OK:GRAPHIFY_SKIP + owner sentence.
# Never fails verify-service-map; never required for map qualification.
set -euo pipefail

WS="${1:-}"
if [[ -z "$WS" || ! -d "$WS" ]]; then
  echo "FAIL: Usage: $0 <workspace_root>" >&2
  exit 2
fi

MAP="$WS/docs/vibage/maps/service_map.json"
SIDE="$WS/docs/vibage/maps/service_map.graphify.md"
CLI="${VIBAGE_GRAPHIFY_CLI:-graphify}"

skip() {
  echo "OK:GRAPHIFY_SKIP"
  echo "$*"
  exit 0
}

[[ -f "$MAP" ]] || skip "Graphify sidecar skipped: missing $MAP. Optional only; map qualification uses verify-service-map.sh."

if ! command -v "$CLI" >/dev/null 2>&1; then
  skip "Graphify CLI \`$CLI\` not on PATH. Optional local prettier skipped; service map qualification is unchanged. Install locally later if you want a Graphify sidecar under docs/vibage/maps/."
fi

mkdir -p "$WS/docs/vibage/maps"

# Best-effort local invoke. Any failure → soft skip (do not fail qualification).
set +e
"$CLI" --help >/dev/null 2>&1
HELP_RC=$?
set -e
if [[ "$HELP_RC" -ne 0 ]]; then
  skip "Graphify CLI \`$CLI\` present but not usable. Sidecar not written; map qualification unchanged."
fi

# Minimal sidecar proof when CLI exists — do not upload repos; local only.
# Real graphify flags vary; keep thin: record that CLI was available and point at hub map.
cat >"$SIDE" <<EOF
# service_map Graphify sidecar (local, optional)

- Hub map: \`docs/vibage/maps/service_map.json\`
- Generator: \`$CLI\` (Plan G OPTIONAL)
- Deeper Graphify/L pipelines may replace this stub later (M Pretty-local ≠终局).
EOF

echo "OK:GRAPHIFY wrote $SIDE"
```

```bash
chmod +x scripts/generate-service-map-graph.sh
```

- [x] **Step 2: Run prettier tests**

```bash
bash tests/test_prettier_maps.sh
```

Expected:

```
ALL prettier_maps tests passed
```

- [ ] **Commit (only if human requested)**

```bash
git add scripts/generate-service-map-graph.sh tests/test_prettier_maps.sh
git commit -m "$(cat <<'EOF'
feat: optional fail-soft Graphify sidecar generator

EOF
)"
```

---

### Task 7: Coverage notes recipe in skill (no verify field)

**Files:**
- Modify: `skills/vibage-arch-review/SKILL.md` (if not already complete in Task 2)
- Modify (optional short pointer): `docs/superpowers/specs/satellites/SAT-arch-review.md`

- [x] **Step 1: Lock coverage as sidecar / skill section only**

Ensure skill text includes an example skeleton owners/agents may write:

```markdown
### Thin coverage notes (optional)

Write workspace `docs/vibage/maps/COVERAGE_NOTES.md` (not a `service_map.json` verify field):

- List services covered vs intentionally omitted
- Note edges present / unknown links
- Keep narrative; **do not** treat absence as `verify-service-map` FAIL
```

Do **not** add `coverage` / `coverage_notes` keys that verify validates.

- [x] **Step 2: Confirm verify ignores sidecar**

```bash
TMP=$(mktemp -d)
mkdir -p "$TMP/docs/vibage/maps"
cp tests/fixtures/service-map/standard-depth-ok.json "$TMP/docs/vibage/maps/service_map.json"
echo '# notes' >"$TMP/docs/vibage/maps/COVERAGE_NOTES.md"
bash scripts/verify-service-map.sh "$TMP"
rm -rf "$TMP"
```

Expected: exit 0 (extra files under `maps/` ignored per SAT-map-schema §2).

- [ ] **Commit (only if human requested)**

```bash
git add skills/vibage-arch-review/SKILL.md \
  docs/superpowers/specs/satellites/SAT-arch-review.md
git commit -m "$(cat <<'EOF'
docs: thin COVERAGE_NOTES sidecar recipe for Plan G

EOF
)"
```

---

## Chunk 4: Isolation + STATUS + DoD proofs

### Task 8: STATUS honesty + full regression

**Files:**
- Modify (optional one line): `STATUS.md`
- Read-only regression: `scripts/verify-service-map.sh`, `scripts/test-tier0.sh`, `tests/test_arch_review_usable.sh`

- [x] **Step 1: Optional STATUS line under 架構檢視 honesty**

Append at most one sentence:

> Local prettier maps (Plan G / M Pretty-local): optional Graphify sidecar + `COVERAGE_NOTES.md` + `vibage-preview/service_map` render are fail-soft / non-verify; ≠ Architecture Pass; ≠ letter B rewrite; M ≠终局.

Do **not** flip Focus / letter B rows. Do **not** claim SaaS.

- [x] **Step 2: Prove verify zero behavior change (git + functional)**

```bash
cd /Users/eric.fang/MindOwnBuz/vibage-skills
git diff -- scripts/verify-service-map.sh
bash tests/test_arch_review_usable.sh
bash tests/test_prettier_maps.sh
bash scripts/test-tier0.sh
```

Expected:

- `git diff -- scripts/verify-service-map.sh` → empty
- `ALL arch_review_usable tests passed`
- `ALL prettier_maps tests passed`
- `TIER0_OK`

- [x] **Step 3: Prove no Tier-0 / optional-gates wiring**

```bash
rg -n 'test_prettier_maps|render-service-map|generate-service-map-graph' \
  scripts/test-tier0.sh tests/test_optional_track_gates.sh \
  || true
```

Expected: **no matches** in those two files (prettier scripts may exist elsewhere).

- [x] **Step 4: Grep product bans**

```bash
rg -n 'Architecture Pass|SaaS|register|letter B|forever' \
  scripts/render-service-map-preview.sh \
  scripts/generate-service-map-graph.sh \
  tests/test_prettier_maps.sh \
  docs/superpowers/specs/satellites/SAT-map-schema.md \
  skills/vibage-arch-review/SKILL.md
```

Expected: Architecture Pass / letter B only in denial/honesty; no SaaS CTA; forever only in “≠ forever-forbidden” sense if present.

- [ ] **Commit (only if human requested)**

```bash
git add STATUS.md \
  docs/superpowers/specs/satellites/SAT-map-schema.md \
  docs/superpowers/specs/satellites/SAT-arch-review.md \
  skills/vibage-arch-review/SKILL.md \
  scripts/render-service-map-preview.sh \
  scripts/generate-service-map-graph.sh \
  tests/test_prettier_maps.sh
git commit -m "$(cat <<'EOF'
feat: Plan G local prettier maps (M Pretty-local)

EOF
)"
```

---

## Definition of Done (Plan G)

- [x] `scripts/render-service-map-preview.sh` writes `$WS/vibage-preview/service_map.html` + `.svg` from hub `services`+`edges` with **no** external binary on success path
- [x] `scripts/generate-service-map-graph.sh` OPTIONAL: PATH miss → exit 0 + `OK:GRAPHIFY_SKIP` + owner sentence on stdout; may write `docs/vibage/maps/` sidecar when CLI present
- [x] Coverage = `docs/vibage/maps/COVERAGE_NOTES.md` (or skill section) — **not** a verify field / floor gate
- [x] Preview root = `vibage-preview/` only; render miss → exit 0 + `OK:RENDER_SKIP` + owner sentence
- [x] `tests/test_prettier_maps.sh` green; **not** referenced by `test-tier0.sh` or `test_optional_track_gates.sh`
- [x] `git diff -- scripts/verify-service-map.sh` empty; `test_arch_review_usable.sh` + `test-tier0.sh` → green / `TIER0_OK`
- [x] SAT/skill/STATUS honesty: M Pretty-local ≠终局; deferred-closed ≠ forever-forbidden; no SaaS; no cloud Architecture Pass; no letter B / Focus rewrite
- [x] Approach 1 thin — no FSM / daemon / cloud upload

---

## Out of scope

- Option L Graphify-class platform, deep coverage gates, interactive dashboard
- Cloud Architecture Pass / whole-repo upload / remote analysis API
- Changing `verify-service-map.sh` floor or `depth:standard` rules
- Wiring prettier tests into Tier-0 or `test_optional_track_gates.sh`
- New agent-pressure cards / Focus Proven-green redefinition / letter B rewrite
- SaaS / register CTA / PRODUCT-LOCKS forever-ban of local map depth
- Committing unless the human explicitly asks
