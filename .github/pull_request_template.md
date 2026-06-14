## What & why

<!-- One or two sentences: what this PR changes and why. Link any issue. -->

## Local quality gate — run BEFORE requesting review

CI will run all of these; confirming them locally first saves a round-trip.

- [ ] `flutter analyze --fatal-infos --fatal-warnings` → **0 issues**
- [ ] `dart run custom_lint` → **0 issues**
- [ ] `dart format --output=none --set-exit-if-changed .` → clean (run `dart format .` if not)
- [ ] `flutter test` → **all pass** (incl. DAO integration, 1RM regression, routine-cap, account-deletion wipe)
- [ ] `flutter build apk --release` → succeeds
- [ ] `flutter build ios --release --no-codesign` → succeeds (if on macOS)

## Notes

- [ ] If I touched `@freezed` / Drift / `@riverpod` code, I re-ran `dart run build_runner build --delete-conflicting-outputs` and committed the generated files.
- [ ] I added/updated tests for the behavior changed here.
- [ ] No analyzer warnings were suppressed (`// ignore:`) without a one-line justification.
