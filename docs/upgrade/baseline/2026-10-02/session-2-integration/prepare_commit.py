"""Prepare an explicit Session 2 staging manifest without writing the index."""
from pathlib import Path
import difflib
import json
import subprocess

ROOT = Path(__file__).resolve().parents[5]
BASE = Path(__file__).resolve().parent
ADMIN = ROOT / ".dart_tool/session-2-staging"
ADMIN.mkdir(parents=True, exist_ok=True)
ADMIN_NAMES = {"session-2-only.patch", "expected-index-source.json",
               "staging-manifest.json", "whole-paths.nul"}
PARTIAL = [
    "lib/features/home/presentation/screens/home_screen.dart",
    "lib/features/workout/presentation/screens/workout_screen.dart",
    "lib/features/routines/presentation/widgets/routine_card.dart",
    "docs/LOOP_LOG.md",
]
WHOLE = [
    "docs/upgrade/LEDGER.md",
    "lib/features/routines/presentation/providers/training_launch_provider.dart",
    "lib/features/routines/presentation/widgets/training_launchpad.dart",
    "test/radius_token_test.dart", "test/screens_theme_test.dart",
]
for area, pattern in [
    ("test/upgrade", "session_2_*.dart"),
    ("test/upgrade/goldens/session-2", "*.png"),
    ("docs/upgrade/renders/session-2", "*"),
    ("docs/upgrade/reviews/session-2", "*"),
    ("docs/upgrade/baseline/2026-10-02", "session-2-*"),
]:
    WHOLE += [p.relative_to(ROOT).as_posix() for p in (ROOT / area).rglob(pattern)
              if p.is_file() and "__pycache__" not in p.parts and p.name not in ADMIN_NAMES]
WHOLE += [p.relative_to(ROOT).as_posix() for p in BASE.glob("*")
          if p.is_file() and p.name not in ADMIN_NAMES]
patch = []
expected = {}
for name in PARTIAL:
    head = subprocess.run(["git", "show", "HEAD:" + name], cwd=ROOT, capture_output=True, check=True).stdout.decode().replace("\r\n", "\n")
    current = (ROOT / name).read_text(encoding="utf-8")
    if name == "docs/LOOP_LOG.md":
        # Another task appended a PR-share regression entry to this shared doc.
        # Commit our two exact entries; leave every other added line untouched.
        prefixes = ["| 2026-10-02 | Home did not preserve explicit training intent;",
                    "| 2026-10-03 | Session 2 selection follow-up:",
                    "| 2026-10-03 | Session 2 emptied-plan ownership:"]
        own = []
        for prefix in prefixes:
            matches = [line for line in current.splitlines(keepends=True)
                       if line.startswith(prefix)]
            assert len(matches) == 1, prefix
            own += matches
        staged = head + "".join(own)
    else:
        # These exact generic annotations were already dirty before Session 2.
        assert current.count("showActionBottomSheet<void>(") == 1, name
        staged = current.replace("showActionBottomSheet<void>(", "showActionBottomSheet(")
    patch.append(f"diff --git a/{name} b/{name}\n")
    patch.extend(difflib.unified_diff(head.splitlines(keepends=True), staged.splitlines(keepends=True),
                                    fromfile="a/" + name, tofile="b/" + name))
    expected[name] = staged
(ADMIN / "session-2-only.patch").write_bytes("".join(patch).encode("utf-8"))
(ADMIN / "expected-index-source.json").write_text(json.dumps(expected, indent=2), encoding="utf-8")
paths = sorted(set(PARTIAL + WHOLE))
assert all(p in PARTIAL + WHOLE and p.startswith(("docs/upgrade/", "docs/LOOP_LOG", "lib/features/", "test/")) for p in paths)
(ADMIN / "staging-manifest.json").write_text(json.dumps({"partial": PARTIAL, "whole": sorted(set(WHOLE)), "all": paths}, indent=2))
(ADMIN / "whole-paths.nul").write_bytes(("\0".join(sorted(set(WHOLE))) + "\0").encode())
for name in ADMIN_NAMES:
    old = BASE / name
    if old.exists():
        old.unlink()  # Exact generated administrative files, not source/evidence.
print(json.dumps({"partial_source_files": len(PARTIAL), "whole_files": len(set(WHOLE)),
                  "preexisting_generic_hunks_kept_unstaged": 3}))
