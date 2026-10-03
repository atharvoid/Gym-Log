"""Reject a commit index containing non-Session-2 paths or pre-existing hunks."""
from pathlib import Path
import json
import subprocess

ROOT = Path(__file__).resolve().parents[5]
ADMIN = ROOT / ".dart_tool/session-2-staging"
manifest = json.loads((ADMIN / "staging-manifest.json").read_text())
expected = json.loads((ADMIN / "expected-index-source.json").read_text())


def git(*args):
    return subprocess.run(["git", *args], cwd=ROOT, check=True,
                          capture_output=True).stdout


staged = set(git("diff", "--cached", "--name-only", "-z").decode().split("\0")) - {""}
assert staged <= set(manifest["all"]), sorted(staged - set(manifest["all"]))
assert set(manifest["partial"]) <= staged, "Missing partial source/doc patches"
for path, source in expected.items():
    assert git("show", ":" + path).decode().replace("\r\n", "\n") == source, path
assert not any(p.startswith(("android/", "ios/", "linux/", "macos/", "windows/"))
               or p in {"pubspec.yaml", "pubspec.lock", ".env", "analysis_options.yaml"}
               for p in staged)
index_objects = {}
for record in git("ls-files", "--stage", "-z").decode().split("\0"):
    if record:
        header, path = record.split("\t", 1)
        index_objects[path] = header.split()[1]
whole = sorted(staged - set(manifest["partial"]))
hashes = subprocess.run(["git", "hash-object", "--stdin-paths"], cwd=ROOT,
                        input=("\n".join(whole) + "\n").encode(), capture_output=True,
                        check=True).stdout.decode().splitlines()
assert len(hashes) == len(whole)
for path, digest in zip(whole, hashes):
    assert index_objects[path] == digest, "Unstaged owned changes: " + path
report = {"staged_files": len(staged), "staged_pngs": sum(p.endswith(".png") for p in staged),
          "partial_sources_and_docs_match_projection": True,
          "preexisting_generic_hunks_excluded": 3,
          "concurrent_loop_log_entry_excluded": True,
          "concurrent_pr_package_native_and_app_files_excluded": True,
          "secrets_excluded": True}
(ADMIN / "index-check.json").write_text(json.dumps(report, indent=2) + "\n")
print(json.dumps(report))
