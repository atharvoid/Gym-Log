# GymLog — Clean Baseline Verification Report

> Fill this in after running the full local gate (Runbook §3) on a clean
> checkout. This is the immutable proof the codebase was known-good when the
> pipeline was established. Commit it as `docs/CI_BASELINE_<date>.md`.

| Field | Value |
|---|---|
| Date / time (UTC) | `____` |
| Verifier | `____` |
| Commit hash (`git rev-parse HEAD`) | `____` |
| Branch | `____` |
| `flutter --version` (full) | `____` |
| OS / machine | `____` |

---

## 1. Static analysis

```
$ flutter analyze --fatal-infos --fatal-warnings
<paste exact output — must end with: "No issues found!">
```
- Result: ☐ 0 issues  ☐ issues found (must be 0 to pass)

```
$ dart run custom_lint
<paste — must report no issues>
```
- Result: ☐ clean  ☐ issues found

```
$ dart format --output=none --set-exit-if-changed .
<paste — must exit 0>
```
- Result: ☐ formatted  ☐ needs `dart format .`

## 2. Tests

```
$ flutter test
<paste the final summary line, e.g. "All tests passed!" / "+NN: All tests passed">
```
- Total tests: `____`  ·  Passed: `____`  ·  Failed: **0**
- Key suites confirmed present & passing:
  - ☐ `test/dao_integration_test.dart` — 1RM regression + `wipeAllData` + count/uniqueness
  - ☐ `test/routine_cap_test.dart` — free routine cap + chart gating
  - ☐ `test/import/…` — CSV import / matcher / catalog integrity
  - ☐ `test/compile_surface_test.dart` — full-graph compile gate

## 3. Release compilation

```
$ flutter build apk --release --obfuscate --split-debug-info=build/debug-symbols
<paste final line, e.g. "✓ Built build/app/outputs/flutter-apk/app-release.apk (NN.NMB)">
```
- Result: ☐ success  ·  APK size: `____`

```
$ flutter build ios --release --no-codesign
<paste final line, e.g. "✓ Built Runner.app">
```
- Result: ☐ success  ☐ n/a (no macOS)

## 4. Dependency audit (first run)

```
$ flutter pub outdated
<paste summary — # direct deps with newer versions>
```
```
$ osv-scanner --lockfile=pubspec.lock
<paste — # advisories, severities>
```
- High/critical advisories: `____` (must be 0 for a release candidate)

---

## Sign-off

- [ ] Analyzer: **0 issues** (infos + warnings fatal), no suppressions added
- [ ] `custom_lint`: clean
- [ ] Tests: **0 failures**, **0 skipped**
- [ ] Android release: built
- [ ] iOS release: built (or explicitly n/a)
- [ ] Dependency audit reviewed; no unresolved high-severity advisory

**Baseline established at commit `____` — codebase known-good.**
