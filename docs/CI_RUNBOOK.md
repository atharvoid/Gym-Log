# GymLog CI & Release-Integrity Runbook

> **Status:** Active / Production Authoritative
> **Owner:** Core Engineering
> **Last verified SHA:** `aef17b09305ebf0455244c3c04159577f37e0a84`
> **Last reviewed date:** 2026-07-22
> **Next review date:** 2026-10-22

The mechanical trust layer that keeps `main` shippable. Read this once; refer to
it when a build goes red or before opening a PR.

---

## 1. How the pipeline works

Two workflows live in `.github/workflows/`:

| Workflow | File | Trigger | Blocks merge? |
|---|---|---|---|
| **CI** | `ci.yml` | every PR to `main` + every push to `main` | **Yes** |
| **Dependency Audit** | `dependency-audit.yml` | weekly cron (Mon 09:00 UTC) + manual | No (report only) |

**CI** runs four jobs:

1. **Analyze & Test** (`ubuntu`) — `flutter pub get` → `dart format` check → `flutter analyze --fatal-infos --fatal-warnings` (zero tolerance) → `dart run custom_lint` (riverpod_lint) → `flutter test --machine` (uploads `test-results.json`). Installs `libsqlite3-dev` so the DAO integration tests can open host SQLite.
2. **Build Android (release)** (`ubuntu`) — `flutter build apk --release --obfuscate --split-debug-info=…` (R8 shrink is configured in `build.gradle.kts`). Uploads the obfuscation symbols artifact.
3. **Build iOS (release, no codesign)** (`macos`) — `flutter build ios --release --no-codesign`.
4. **CI Gate** — passes only if all three above pass. Mark **this** as the required status check (simplest), or require all three individually.

> **Pin the Flutter version.** `ci.yml` uses `channel: stable`. For reproducible
> analyzer output, set `FLUTTER_CHANNEL`/`flutter-version` to match your local
> `flutter --version`. A different Flutter version can surface different lints.

### Expected execution time & resources

| Job | Cold | Warm (cache hit) | Runner |
|---|---|---|---|
| Analyze & Test | ~4–7 min | ~2–4 min | ubuntu (2-core, free) |
| Build Android | ~6–10 min | ~4–6 min | ubuntu (2-core, free) |
| Build iOS | ~10–18 min | ~7–12 min | **macOS (10× minute multiplier)** |
| Dependency Audit | ~2–3 min | — | ubuntu |

macOS minutes are billed at **10×** on private repos — the iOS job is the
expensive one. If minutes get tight, move `build-ios` to a nightly schedule and
keep analyze/test + Android as the per-PR gate (see "Tuning" below).

---

## 2. Branch protection — exact setup (GitHub web UI)

Direct pushes to `main` cannot be configured by the app token; do this once by
hand. **Settings → Branches → Add branch protection rule** (classic rules):

1. **Branch name pattern:** `main`
2. ☑ **Require a pull request before merging**
   - ☑ **Require approvals** → set **1**
   - (leave "Dismiss stale approvals" optional)
3. ☑ **Require status checks to pass before merging**
   - ☑ **Require branches to be up to date before merging**
   - In the search box add: **`CI Gate`** (or add all of `Analyze & Test`,
     `Build Android (release)`, `Build iOS (release, no codesign)`).
   - ⚠️ A check only appears in this list **after it has run at least once** —
     so let the first PR run CI, then come back and select it.
4. ☑ **Do not allow bypassing the above settings** — see the solo-repo note below.
5. **Save changes.**

Effect: nobody can push to `main` directly; every change is a PR; merge stays
disabled until CI is green and one approval exists.

### ⚠️ Solo-repo gotcha (read this)

GitHub does **not** let you approve your **own** PR. On a single-maintainer repo,
"Require 1 approval" + "Do not allow bypassing (incl. admins)" will **hard-lock
you out of merging anything.** Pick one:

- **Recommended for solo:** enable "Require a pull request" + "Require status
  checks", **require 1 approval, but leave "Do not allow bypassing" OFF.** You
  still get the safety (no direct push, checks must be green) and you can admin-
  merge after reviewing your own green PR — the PR + green checks supply the
  "moment of deliberation."
- **Strict:** add a second trusted GitHub account (or a review bot) as a
  collaborator to provide the approval. Then you can keep bypassing OFF for
  everyone.

Either way: **never disable the status-check requirement.** The check gate is
the non-negotiable part; the human-approval part is the tunable part on a solo
repo.

---

## 3. Run the same checks locally (before opening a PR)

Requires the Flutter SDK + Android SDK; the iOS step requires macOS + Xcode.

```bash
flutter --version                       # record this for the baseline report
flutter pub get

# If you touched @freezed / Drift / @riverpod code:
dart run build_runner build --delete-conflicting-outputs

dart format .                           # then commit any reformatting
flutter analyze --fatal-infos --fatal-warnings   # must print "No issues found!"
dart run custom_lint                    # riverpod_lint — must be clean
flutter test                            # all tests pass

flutter build apk --release --obfuscate --split-debug-info=build/debug-symbols
flutter build ios --release --no-codesign        # macOS only
```

One-liner to mirror the gate (stops at the first failure):

```bash
flutter pub get && dart format --output=none --set-exit-if-changed . \
  && flutter analyze --fatal-infos --fatal-warnings \
  && dart run custom_lint \
  && flutter test
```

---

## 4. Interpreting failures

| Symptom in Actions | Likely cause | Fix |
|---|---|---|
| `analyze` fails with `info •`/`warning •` lines | A lint from `analysis_options.yaml` | Fix the code at the cited file:line. Don't add `// ignore:` without a written reason. |
| `Check formatting` fails | Unformatted Dart | `dart format .` and commit. |
| `custom_lint` fails | riverpod_lint rule (e.g. passing a `Ref` around, missing provider deps) | Fix per the cited rule. |
| A test fails (e.g. `wipeAllData`, 1RM regression, routine-cap) | Real regression | Reproduce locally with `flutter test test/<file>.dart`; fix the code, **not** the test. |
| `sqlite3` load error in tests | Host SQLite missing | CI installs `libsqlite3-dev`; locally install it (Linux) — macOS ships it. |
| Android build: missing Play Core / R8 error | proguard keep/dontwarn rule | See `android/app/proguard-rules.pro` (Play-Core `-dontwarn` rules already present). |
| iOS build: Pod/native error | CocoaPods or a plugin's native breakage | `cd ios && pod repo update && pod install`; check the failing plugin. |
| iOS build: signing error | Should not happen with `--no-codesign` | Confirm the flag is present. |
| Whole job: Flutter version mismatch lints | CI Flutter ≠ local | Pin `FLUTTER_CHANNEL`/version in `ci.yml`. |

---

## 5. Rollback decision tree (a red build slipped onto `main`)

```
Is main red?
├─ Caused by the LAST merged PR?
│   ├─ Trivial, obvious one-line fix?  → open a hotfix PR, fast-review, merge.
│   └─ Not obvious / risky?            → `git revert <merge_sha>` via a PR,
│                                         merge the revert to make main green,
│                                         then fix forward on a branch.
├─ Caused by an external change (Flutter/dep/runner image)?
│   ├─ Pin the Flutter version / dep version that last worked, PR it.
│   └─ If a dependency advisory: see §6 escalation.
└─ Caused by flaky infra (runner timeout, network)?
    └─ Re-run the job once. If it flakes twice, treat as a real failure.
```

Rule: **main is always green.** Prefer reverting to leaving `main` red while you
investigate.

---

## 6. Weekly dependency review ritual

Every Monday (the audit runs at 09:00 UTC; set a calendar reminder):

1. Open **Actions → Dependency Audit → latest run** and read the job summary.
2. **Freshness** (`flutter pub outdated`): note majors behind; schedule upgrades
   for low-risk packages.
3. **Security** (OSV-Scanner over `pubspec.lock`): for any advisory, check
   severity.

**Escalation criteria — a dependency becomes a release blocker when:**
- It has a **HIGH or CRITICAL** OSV/CVE advisory with a fixed version available, **or**
- It is **two or more major versions** behind and blocks a security fix, **or**
- It is **unmaintained** (no release in ~18 months) and carries an open advisory.

No release candidate ships with an unresolved high-severity advisory.

Run the audit locally any time:
```bash
flutter pub outdated
# OSV (install once: brew install osv-scanner  /  go install github.com/google/osv-scanner/cmd/osv-scanner@latest)
osv-scanner --lockfile=pubspec.lock
```

---

## 7. Tuning (optional)

- **Save macOS minutes:** move the `build-ios` job to a nightly `schedule:` and
  drop it from the per-PR `needs:`/`ci-gate`, keeping analyze/test + Android as
  the per-PR gate. iOS breakage is then caught within a day instead of per-PR.
- **Speed up:** the Flutter action cache (`cache: true`) is on; first run is
  cold, subsequent runs warm.
- **Codegen drift guard:** add a step `dart run build_runner build
  --delete-conflicting-outputs && git diff --exit-code` to fail if committed
  generated files are stale. (Off by default to keep the gate fast.)
