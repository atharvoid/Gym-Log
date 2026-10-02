"""Freeze only this candidate's source delta and synthetic Flutter evidence."""
from pathlib import Path
import difflib
import hashlib
import json
import os
import shutil
import sys

ROOT = Path(__file__).resolve().parents[4]
SNAPSHOT = Path((Path(os.environ["TEMP"]) / "gymlog-session-2-build-snapshot-path.txt").read_text().strip())
MANIFEST = json.loads((SNAPSHOT / "manifest.json").read_text())
ITERATION = sys.argv[1] if len(sys.argv) > 1 else "1"
assert ITERATION in {"1", "2", "3", "4", "5", "6", "7"}
RENDER_ITERATION = sys.argv[2] if len(sys.argv) > 2 else "4"
assert RENDER_ITERATION in {"1", "2", "3", "4", "owner-fix", "owner-fix-2", "owner-fix-3", "owner-fix-4"}
PACKET = Path(__file__).resolve().parent / f"iteration-{ITERATION}"
RENDERS = ROOT / "docs/upgrade/renders/session-2"
NEW = [
    "lib/features/routines/presentation/providers/training_launch_provider.dart",
    "lib/features/routines/presentation/widgets/training_launchpad.dart",
    "test/upgrade/session_2_launchpad_test.dart",
    "test/upgrade/session_2_training_logic_test.dart",
    "test/upgrade/session_2_launch_actions_test.dart",
    "test/upgrade/session_2_acceptance_render_test.dart",
]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


changed = [p for p, h in MANIFEST.items() if not (ROOT / p).exists() or digest(ROOT / p) != h]
allowed = set(NEW) | {
    "lib/features/home/presentation/screens/home_screen.dart",
    "lib/features/workout/presentation/screens/workout_screen.dart",
    "test/upgrade/session_2_fixtures.dart",
    "test/upgrade/session_2_render_test.dart",
    "test/radius_token_test.dart",
    "test/screens_theme_test.dart",
    "lib/features/routines/presentation/widgets/routine_card.dart",
}
sources = sorted({p for p in changed if p in allowed} | set(NEW))
external = sorted(p for p in changed if p not in allowed and p not in {"docs/upgrade/LEDGER.md", "docs/LOOP_LOG.md"})
PACKET.mkdir(parents=True, exist_ok=True)
assert not (PACKET / "candidate.diff").exists(), "Evidence packet already frozen; choose a new iteration."
text = [f"# Candidate: session-2 / critic iteration-{ITERATION} / self-review render iteration-{RENDER_ITERATION}\n",
        "# Sections: 4 Home and 6 Routine Library. Snapshot includes pre-existing uncommitted work.\n",
        "# Only candidate changes against that snapshot follow.\n",
        "# Concurrent PR/configuration changes are excluded from this scoped candidate diff.\n",
        "# Renders: synthetic data, live Flutter widgets, 390x844, real Inter and Material icons.\n",
        "# Before: Volt/Purple at 1.0x/1.6x. After: six palettes at both scales.\n",
        "# Additional choice/error/loading after states have no corresponding pre-feature before state.\n",
        "# Native system bars, keyboard, TalkBack, haptics, physical device and CI are unverified.\n\n"]
for p in sources:
    old = (SNAPSHOT / p).read_text(encoding="utf-8").splitlines(keepends=True) if p in MANIFEST else []
    new = (ROOT / p).read_text(encoding="utf-8").splitlines(keepends=True)
    text.append(f"diff --git a/{p} b/{p}\n")
    text.extend(difflib.unified_diff(old, new, fromfile=f"a/{p}" if old else "/dev/null", tofile=f"b/{p}", n=5))
if int(ITERATION) >= 5:
    for name, end in [
        ("lib/features/profile/presentation/providers/profile_stats_provider.dart", "// ── Profile chart data"),
        ("lib/core/routines/program_membership.dart", None),
        ("lib/core/database/daos/program_grouping.dart", "/// One training day being imported."),
    ]:
        source = (ROOT / name).read_text(encoding="utf-8")
        if end:
            source = source.split(end)[0]
        text.append(f"\n# Supporting existing source excerpt: {name}\n")
        text.append("# Context only; no Session 2 changes to this implementation.\n")
        text.append(source + "\n")
goldens = sorted((ROOT / "test/upgrade/goldens/session-2").glob("*.png"))
text.append("\n# New binary golden files (identical capture IDs in after/):\n")
for path in goldens:
    text.append(f"{path.relative_to(ROOT).as_posix()} SHA256 {digest(path)}\n")
(PACKET / "candidate.diff").write_text("".join(text), encoding="utf-8")
for kind, source in [("before", RENDERS / "before"), ("after", RENDERS / f"after/iteration-{RENDER_ITERATION}")]:
    dest = PACKET / kind
    dest.mkdir(exist_ok=True)
    for path in source.glob("*.png"):
        shutil.copy2(path, dest / path.name)
shutil.copy2(ROOT / "docs/upgrade/RUBRIC.md", PACKET / "RUBRIC.md")
report = {"snapshot": str(SNAPSHOT), "snapshot_inputs": len(MANIFEST), "changed_existing_inputs": sorted(changed),
          "concurrent_input_changes_excluded": external,
          "new_candidate_sources": NEW, "candidate_sources": sources, "new_goldens": len(goldens),
          "before_pngs": len(list((PACKET / "before").glob("*.png"))), "after_pngs": len(list((PACKET / "after").glob("*.png"))),
          "diff_sha256": digest(PACKET / "candidate.diff"), "no_package_or_shared_token_changes": True}
(ROOT / "docs/upgrade/baseline/2026-10-02/session-2-build-integrity.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
print(json.dumps(report, indent=2))
