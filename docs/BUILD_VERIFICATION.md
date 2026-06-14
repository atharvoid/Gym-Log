# GymLog Build Verification Report

**Date:** 2026-06-14

## Static analysis

- Command: `flutter analyze --fatal-infos --fatal-warnings`
- Result: **No issues found**

## Test suite

- Command: `flutter test`
- Result: **116 tests passed**
- Fixed en route:
  - Added missing `const` constructors and removed redundant inner `const` keywords.
  - Removed unused `package:drift/drift.dart` import from `test/import/import_service_test.dart`.
  - Added explicit `<double>` type argument to `fold` to resolve an analyzer `FutureOr<double>` inference issue.
  - Updated `test/explore_catalog_integrity_test.dart` exercise names to match the bundled library naming convention.
  - Updated `test/workout_export_test.dart` to reflect the expanded CSV export format (added `ended_at`, `workout_notes`, `rpe`, `estimated_1rm`).

## Android release build

- Command: `flutter build apk --release`
- Result: **Built successfully**
- Output: `build/app/outputs/flutter-apk/app-release.apk`
- Size: **69.5 MB**

### Bloat investigation

The APK exceeds the 20 MB guidance threshold because it is a **universal APK** containing native libraries for three ABIs:

| Component | Approximate uncompressed size | Notes |
|---|---|---|
| `libflutter.so` (3 ABIs) | ~33 MB | Flutter engine per ABI |
| `libapp.so` (3 ABIs) | ~28 MB | Compiled Dart app per ABI |
| `libsqlite3.so` (3 ABIs) | ~4.5 MB | Drift/sqlite3 native libs |
| `libsentry.so` (3 ABIs) | ~3.2 MB | Sentry native SDK |
| `classes.dex` | ~7.4 MB | Android bytecode |
| `assets/db/exercises.json` | ~0.5 MB | Bundled exercise catalog |

**Conclusion:** The bloat is almost entirely multi-ABI native libraries, which is expected for a universal APK. For Play Store distribution, use `flutter build appbundle --release`; Google Play will serve a much smaller ABI-specific APK to each device (estimated ~22–28 MB download).

## iOS release build

- Command: `flutter build ios --release --no-codesign`
- Result: **Could not be executed locally**
- Reason: The current environment is Windows; iOS release builds require macOS + Xcode. This build is covered by the `build-ios` job in `.github/workflows/ci.yml`, which runs on `macos-latest`.

## Build fixes applied

1. **Sentry upload misconfiguration:** The Sentry Android Gradle plugin was configured with a placeholder org slug and no auth token, causing release builds to fail during `uploadSentryProguardMappingsRelease`. The plugin was removed from `android/settings.gradle.kts` and `android/app/build.gradle.kts`; the Sentry Flutter SDK still captures Dart errors at runtime. Re-enable the Android plugin once real `SENTRY_AUTH_TOKEN` and `SENTRY_ORG` values are available.
2. **Pubspec Sentry plugin:** Set `upload_debug_symbols`, `upload_source_maps`, `upload_sources`, and `commits` to `false` so the Dart Sentry plugin does not attempt uploads without credentials.

## Recommendation

- Switch CI and store submission to `flutter build appbundle --release` to eliminate the multi-ABI APK overhead.
- Run the iOS build verification on a Mac or via the GitHub Actions `build-ios` job before store submission.
