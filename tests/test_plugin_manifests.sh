#!/usr/bin/env bash
# Plugin / marketplace manifest shape — NOT Tier-0, NOT “listed on store”.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "FAIL: $*"; exit 1; }

[[ -f .cursor-plugin/plugin.json ]] || fail "missing .cursor-plugin/plugin.json"
[[ -f .claude-plugin/plugin.json ]] || fail "missing .claude-plugin/plugin.json"
[[ -f .claude-plugin/marketplace.json ]] || fail "missing .claude-plugin/marketplace.json"
[[ -f assets/logo.svg ]] || fail "missing assets/logo.svg"
[[ -f docs/install/MARKETPLACE.md ]] || fail "missing docs/install/MARKETPLACE.md"

python3 - <<'PY' || fail "manifest JSON / path checks failed"
import json
from pathlib import Path

root = Path(".").resolve()

def load(p: Path):
    with p.open() as f:
        return json.load(f)

cur = load(root / ".cursor-plugin" / "plugin.json")
assert cur.get("name") == "vibage", cur
assert cur.get("version"), "cursor version required"
assert cur.get("license") == "MIT"
assert cur.get("skills") == "./skills/"
assert (root / "skills" / "using-vibage" / "SKILL.md").is_file()
rules = cur.get("rules")
assert rules, "cursor rules path required"
rule_path = root / str(rules).lstrip("./")
assert rule_path.is_file(), f"missing rules path {rule_path}"
logo = cur.get("logo")
assert logo, "cursor logo required"
assert (root / str(logo).lstrip("./")).is_file(), f"missing logo {logo}"
assert ".." not in str(cur.get("skills", ""))
assert ".." not in str(rules)

cla = load(root / ".claude-plugin" / "plugin.json")
assert cla.get("name") == "vibage"
assert cla.get("version") == cur.get("version"), "cursor/claude versions must match"

mkt = load(root / ".claude-plugin" / "marketplace.json")
assert mkt.get("name") == "vibage"
plugins = mkt.get("plugins") or []
assert len(plugins) >= 1
p0 = plugins[0]
assert p0.get("name") == "vibage"
assert p0.get("source") in ("./", ".")
assert p0.get("version") == cla.get("version"), "marketplace entry version must match plugin.json"

doc = (root / "docs" / "install" / "MARKETPLACE.md").read_text()
assert "PROJECT_ENTRY_OK" in doc
assert "cursor.com/marketplace/publish" in doc
assert "/plugin marketplace add" in doc
assert "≠" in doc or "not" in doc.lower()
print("PLUGIN_MANIFESTS_OK")
PY

echo "PLUGIN_MANIFESTS_OK"
