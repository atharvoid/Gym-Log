# Build Report — audit/a1-cold-start

## 1. Commit SHA & Remotes
- **Local HEAD SHA:** `7035bfe2a52ce34a30ef5bd57d3408d7e773aedb`
- **origin (`atharvoid/Gym-Log`):** `7035bfe2a52ce34a30ef5bd57d3408d7e773aedb`
- **twizzy (`twi-zzy/gymlog`):** `fc9f4c46d4517690f68d2c3614e08383e8d5a2db`
- **Mirror `lib/` tree diff:** `git diff origin/audit/a1-cold-start twizzy/audit/a1-cold-start -- lib` returned 0 changes (**100% byte-identical `lib/` tree**).

## 2. Toolchain
- **Flutter:** 3.44.0 (channel stable)
- **Framework:** revision `559ffa3f75`
- **Engine:** hash `fcf463a2242790d1fdcd9d044f533080f5022e18` (revision `4c525dac5e`)
- **Dart:** 3.12.0
- **DevTools:** 2.57.0

## 3. Command Execution Summary

| Command | Exit Code | Result / Notes |
|---|---|---|
| `git fetch --all --prune` | 0 | Fetched all remote refs cleanly |
| `git checkout -B audit/a1-cold-start origin/audit/a1-cold-start` | 0 | Checked out branch tracking origin |
| `git pull` | 0 | Already up to date |
| `flutter clean` | 0 | Cleaned build artifacts |
| `flutter pub get` | 0 | Installed 109 packages cleanly |
| `dart run build_runner build --delete-conflicting-outputs` | 0 | Succeeded after 59.7s with 1634 outputs (3405 actions). `lib/core/database/database.g.dart` generated (274,307 bytes) |
| `flutter analyze` | 1 | 85 issues found (64 errors, 14 warnings, 7 info) |
| `dart format --set-exit-if-changed .` | 1 | 48 files formatted / changed |
| `flutter test` | 1 | 303 PASSED, 40 FAILED/FAILED-TO-LOAD |
| `.\scripts\verify.ps1` | 1 | Aborted at analyze gate |

## 4. Analysis Summary
- **Errors:** 64
- **Warnings:** 14
- **Info:** 7
- **High-Risk Target Verification:**
  - `lib/core/bootstrap/bootstrap.dart`: Clean (0 errors).
  - `lib/core/services/sync_engine.dart`: Clean (0 errors).
  - `lib/core/services/sync_remote.dart`: Clean (0 errors).

## 5. Test Suite Verification
- **Baseline Expected:** 529 passing tests
- **Tests Executed:** ~343
- **Passed:** 303
- **Failed / Compilation Failed:** 40
- **Missing / Disappeared Tests (~186 tests):**
  - Multiple test files failed to compile before running tests due to stale file references or missing parameters (e.g. `ImportTestHelper` missing in `test/import/import_screen_polish_test.dart`, missing `unit` parameter in `test/profile_weekly_bar_chart_test.dart`, missing `exercise_history_provider.dart` in `test/screens_theme_test.dart`).

## 6. Task 8 — Repo Hygiene Reconciliation
- **Removed Vendored Assets from Git & Disk:**
  - `node_modules/` removed (`git rm -r --cached node_modules`, deleted from disk)
  - `android_backup/` removed (`git rm -r --cached android_backup`, deleted from disk)
- **Updated `.gitignore`:** Added `node_modules/` and `android_backup/`.
- **Committed & Pushed to Remotes:**
  - Commit: `b3860a0` (`chore(repo): remove vendored node_modules and android_backup`)
  - Pushed to `origin/audit/a1-cold-start` and `twizzy/audit/a1-cold-start`.
- **Backlog Reconciliation (`audit/backlog.md`):**

| Finding ID | Description | Status | Verification Note |
|---|---|---|---|
| **AUTH-1** | Google Sign-in release SHA-1 configuration missing | `open` (still-open) | OAuth config / Google Sign-In requires SHA-1 setup in Supabase dashboard |
| **HOME-7** | Performance lag on heavy history feed | `open` (still-open) | Workout history feed virtualization outstanding |
| **AW-3** | Exercise block spacing and font size inconsistencies | `open` (still-open) | UX-95-04 active workout density reconstruction open |
| **AW-5** | Finish summary sheet navigation polish | `open` (still-open) | Finish summary sheet navigation polish open |
| **WD-1** | Scroll layout constraints on small screens | `open` (still-open) | Workout detail small-screen reflow open |
| **WD-5** | Volume graph range filters | `open` (still-open) | Volume graph range filter state open |
| **IM-2** | CSV template download button styling | `open` (still-open) | Import screen CSV template styling open |
