"""Record real-workspace inputs without reading compile-time secret values."""
from pathlib import Path
import hashlib
import json
import sys

ROOT = Path(__file__).resolve().parents[5]
BASE = Path(__file__).resolve().parent
paths = [p for directory in ["lib", "test"]
         for p in (ROOT / directory).rglob("*.dart")]
paths += [ROOT / p for p in ["pubspec.yaml", "pubspec.lock",
          "analysis_options.yaml", ".flutter-plugins-dependencies", "scripts/verify.ps1"]]
paths += [p for p in (ROOT / "android").rglob("*") if p.is_file()
          and p.suffix in {".gradle", ".kts", ".properties", ".kt", ".xml"}
          and not any(part in {"build", ".gradle"} for part in p.relative_to(ROOT / "android").parts)]
report = {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
          for p in paths if p.is_file()}
phase = sys.argv[1]
assert phase in {"before", "after"}
(BASE / f"verify-inputs-{phase}.json").write_text(json.dumps(report, indent=2) + "\n")
if phase == "after":
    before = json.loads((BASE / "verify-inputs-before.json").read_text())
    changed = sorted(p for p in before.keys() | report.keys() if before.get(p) != report.get(p))
    result = {"inputs": len(report), "changed_inputs_during_gate": changed,
              "secret_values_read": False}
    (BASE / "verify-input-integrity.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result))
else:
    print(json.dumps({"inputs": len(report), "secret_values_read": False}))
