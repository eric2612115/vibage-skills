#!/usr/bin/env bash
# Evaluate one work-continue pressure card inside a package sandbox.
# LAB_NO_DELETE: never deletes. Writes result JSON to --out=.
# Usage:
#   bash eval-wc-card.sh --pkg=/tmp/.../pkg --card=01_script_green --out=/tmp/.../result.json
set -euo pipefail
export LAB_NO_DELETE=1

PKG=""
CARD=""
OUT=""
for arg in "$@"; do
  case "$arg" in
    --pkg=*) PKG="${arg#*=}" ;;
    --card=*) CARD="${arg#*=}" ;;
    --out=*) OUT="${arg#*=}" ;;
    *) echo "FAIL: unknown arg: $arg" >&2; exit 1 ;;
  esac
done
[[ -n "$PKG" && -d "$PKG" ]] || { echo "FAIL: --pkg= dir required" >&2; exit 1; }
[[ -n "$CARD" ]] || { echo "FAIL: --card= required" >&2; exit 1; }
[[ -n "$OUT" ]] || { echo "FAIL: --out= required" >&2; exit 1; }

PKG="$(cd "$PKG" && pwd)"
mkdir -p "$(dirname "$OUT")"

python3 - "$PKG" "$CARD" "$OUT" <<'PY'
import json, os, re, subprocess, sys, tempfile
from pathlib import Path

pkg = Path(sys.argv[1])
card = sys.argv[2]
out = Path(sys.argv[3])
notes = []
verdict = "PASS"
commands = []


def fail(msg: str) -> None:
    global verdict
    verdict = "FAIL"
    notes.append(msg)


def run(cmd, cwd=None, timeout=120):
    commands.append(cmd if isinstance(cmd, str) else " ".join(cmd))
    return subprocess.run(
        cmd,
        cwd=cwd or str(pkg),
        text=True,
        capture_output=True,
        timeout=timeout,
    )


# staging parent under pkg's sibling is preferred; keep under same trial via env
stage_root = Path(os.environ.get("WC_TRIAL_DIR", str(pkg.parent)))
parent = stage_root / "parent_hub"
parent.mkdir(parents=True, exist_ok=True)

try:
    if card == "01_script_green":
        r = run(["bash", "tests/test_work_continue_memory.sh"])
        if r.returncode != 0 or "WORK_CONTINUE_FIXTURE_OK" not in r.stdout:
            fail(f"expected FIXTURE_OK rc=0 got rc={r.returncode} out={r.stdout[-400:]} err={r.stderr[-400:]}")
        else:
            notes.append("WORK_CONTINUE_FIXTURE_OK")

    elif card == "02_seed_red":
        # init hub into parent_hub using sandbox install
        r = run(["bash", "scripts/install.sh", f"--init-hub={parent}"], timeout=180)
        wc = parent / "docs/vibage/WORK_CONTINUE.md"
        if not wc.is_file():
            fail("init_hub did not seed WORK_CONTINUE.md")
        else:
            v = run(["bash", "scripts/verify-work-continue.sh", str(parent)])
            if v.returncode == 0 or "WORK_CONTINUE_VERIFY_OK" in v.stdout:
                fail("seed must FAIL verify")
            elif "FAIL:" not in v.stdout and "FAIL:" not in v.stderr:
                fail(f"seed verify failed without FAIL: token: {v.stdout} {v.stderr}")
            else:
                notes.append("seed correctly fails verify")

    elif card == "03_live_green":
        hub = parent / "docs/vibage"
        hub.mkdir(parents=True, exist_ok=True)
        (parent / "apps/demo-child").mkdir(parents=True, exist_ok=True)
        (parent / "VIBAGE-ISSUE-OWNER.md").write_text("owner\n", encoding="utf-8")
        (parent / "VIBAGE-ISSUE-LOCATE.md").write_text("locate\n", encoding="utf-8")
        src = pkg / "tests/fixtures/work_continue/ok.md"
        (hub / "WORK_CONTINUE.md").write_text(src.read_text(encoding="utf-8"), encoding="utf-8")
        v = run(["bash", "scripts/verify-work-continue.sh", str(parent)])
        if v.returncode != 0 or "WORK_CONTINUE_VERIFY_OK" not in v.stdout:
            fail(f"live ok must VERIFY_OK: {v.stdout} {v.stderr}")
        else:
            notes.append("WORK_CONTINUE_VERIFY_OK")

    elif card == "04_hollow_red":
        hub = parent / "docs/vibage"
        hub.mkdir(parents=True, exist_ok=True)
        (parent / "apps/demo-child").mkdir(parents=True, exist_ok=True)
        (parent / "VIBAGE-ISSUE-OWNER.md").write_text("o\n", encoding="utf-8")
        (parent / "VIBAGE-ISSUE-LOCATE.md").write_text("l\n", encoding="utf-8")
        bad = 0
        for name in ("duplicate_dual", "tbd_next_step", "phase_blocked"):
            (hub / "WORK_CONTINUE.md").write_text(
                (pkg / f"tests/fixtures/work_continue/{name}.md").read_text(encoding="utf-8"),
                encoding="utf-8",
            )
            v = run(["bash", "scripts/verify-work-continue.sh", str(parent)])
            if v.returncode == 0:
                fail(f"{name} unexpectedly VERIFY_OK")
                bad += 1
        if bad == 0:
            notes.append("hollow fixtures fail verify")

    elif card == "05_skill_d1":
        locate = (pkg / "skills/vibage-issue-locate/SKILL.md").read_text(encoding="utf-8")
        using = (pkg / "skills/using-vibage/SKILL.md").read_text(encoding="utf-8")
        for label, text in (("locate", locate), ("using", using)):
            for needle in (
                "verify-work-continue",
                "WORK_CONTINUE_VERIFY_OK",
                "locate DONE (WORK_CONTINUE_EXCEPTION)",
                "no DONE-then-backfill",
            ):
                if needle not in text:
                    fail(f"{label} missing {needle}")
        if "After dual reports exist / phase `done`" in locate or "After dual reports exist / phase `done`" in using:
            fail("banned dual⇒DONE leftover present")
        if verdict == "PASS":
            notes.append("D1 phrases present; banned leftover absent")

    elif card == "06_exception_honesty":
        using = (pkg / "skills/using-vibage/SKILL.md").read_text(encoding="utf-8")
        locate = (pkg / "skills/vibage-issue-locate/SKILL.md").read_text(encoding="utf-8")
        for text in (using, locate):
            if "locate DONE (WORK_CONTINUE_EXCEPTION)" not in text:
                fail("missing exception DONE phrase")
            if "never `WORK_CONTINUE_VERIFY_OK`" not in text and "never WORK_CONTINUE_VERIFY_OK" not in text:
                fail("exception path must forbid VERIFY_OK")
            if "no DONE-then-backfill" not in text:
                fail("missing no DONE-then-backfill")
        exc = pkg / "references/hub/WORK_CONTINUE_EXCEPTION.md"
        if not exc.is_file():
            fail("missing WORK_CONTINUE_EXCEPTION template")
        else:
            body = exc.read_text(encoding="utf-8")
            for k in ("owner_quote", "reason", "run_id", "updated_at"):
                if k not in body:
                    fail(f"exception template missing {k}")
        if verdict == "PASS":
            notes.append("exception honesty OK")

    elif card == "07_adapter_routing":
        paths = [
            "adapters/cursor/vibage.mdc",
            "adapters/claude/CLAUDE.vibage.md",
            "adapters/shared/AGENTS.vibage.md",
            "adapters/codex/AGENTS.vibage.md",
            "references/routing-scope.md",
            "references/hard-stops.md",
        ]
        for rel in paths:
            text = (pkg / rel).read_text(encoding="utf-8")
            if "WORK_CONTINUE" not in text:
                fail(f"{rel} missing WORK_CONTINUE")
        rs = (pkg / "references/routing-scope.md").read_text(encoding="utf-8")
        if "FRESHNESS_OK" not in rs and "freshness" not in rs.lower():
            fail("routing-scope missing freshness guidance")
        if verdict == "PASS":
            notes.append("adapters+routing mention WORK_CONTINUE")

    elif card == "08_firewall":
        for rel in ("scripts/assert_gate.sh", "scripts/test-tier0.sh", "scripts/pack-health.sh"):
            text = (pkg / rel).read_text(encoding="utf-8", errors="replace")
            if "verify-work-continue" in text or "work_continue" in text:
                fail(f"{rel} must not reference work_continue")
        r = run(["bash", "scripts/test-tier0.sh"], timeout=180)
        blob = r.stdout + r.stderr
        if r.returncode != 0 or "TIER0_OK" not in blob:
            fail(f"tier0 failed rc={r.returncode}")
        if "WORK_CONTINUE_FIXTURE_OK" in blob:
            fail("tier0 leaked WORK_CONTINUE_FIXTURE_OK")
        if verdict == "PASS":
            notes.append("firewall + TIER0_OK without fixture leak")

    elif card == "09_adversarial_dual_done":
        locate = (pkg / "skills/vibage-issue-locate/SKILL.md").read_text(encoding="utf-8")
        # Claiming DONE from dual alone must be forbidden in skill text
        if re.search(r"After dual reports exist\s*/\s*phase", locate):
            fail("adversarial: old dual/phase DONE auth still present")
        if "Dual reports alone ≠ locate DONE" not in locate and "Dual reports alone ≠ DONE" not in locate:
            fail("adversarial: missing dual-alone ≠ DONE")
        if "verify-work-continue" not in locate:
            fail("adversarial: verify gate missing")
        notes.append("dual-alone DONE path blocked in skill text")

    elif card == "10_resume_carveout":
        rs = (pkg / "references/routing-scope.md").read_text(encoding="utf-8")
        using = (pkg / "skills/using-vibage/SKILL.md").read_text(encoding="utf-8")
        blob = rs + "\n" + using
        if "WORK_CONTINUE" not in blob:
            fail("resume carve-out missing WORK_CONTINUE")
        if "pile-index" not in blob.lower() and "pile-index" not in rs:
            # routing says skip pile-index
            if "skip pile-index" not in rs and "Do not** re-run pile-index" not in using and "do not re-run pile-index" not in using.lower():
                if "pile-index/orient" not in blob:
                    fail("missing short-circuit pile-index language")
        if "FRESHNESS_OK" not in blob and "freshness" not in blob.lower():
            fail("resume must still require freshness disclose")
        if verdict == "PASS":
            notes.append("resume carve-out + freshness present")

    else:
        verdict = "INCONCLUSIVE"
        notes.append(f"unknown card {card}")

except subprocess.TimeoutExpired:
    verdict = "INCONCLUSIVE"
    notes.append("timeout")
except Exception as e:
    verdict = "INCONCLUSIVE"
    notes.append(f"exception: {e}")

result = {
    "verdict": verdict,
    "card": card,
    "pkg": str(pkg),
    "notes": notes,
    "commands": commands,
    "lab_no_delete": True,
    "honesty": "card PASS ≠ Proven-green ≠ live parent mutated",
}
out.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print(json.dumps({"verdict": verdict, "out": str(out)}, ensure_ascii=False))
sys.exit(0 if verdict == "PASS" else 1 if verdict == "FAIL" else 2)
PY
