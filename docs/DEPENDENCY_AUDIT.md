# GymLog Dependency Audit Report

**Date:** 2026-06-14  
**Flutter version:** 3.44.0 (stable)  
**Dart SDK constraint:** `>=3.0.0 <4.0.0`

## Summary

No dependency upgrades were performed in this pass. The project compiles, passes static analysis, and passes the full test suite on the current lockfile. Several major-version upgrades are available, but they require deliberate migration work and are deferred to a dedicated maintenance window after launch.

## Packages flagged for attention

| Package | Current | Latest | Verdict |
|---|---|---|---|
| `intl` | 0.19.0 | 0.20.2 | **Deferred.** Breaking changes in 0.20.x around `DateFormat` skeletons and locale resolution. App uses `DateFormat('yyyy-MM-dd HH:mm')` and a small surface area, but safe migration needs test coverage review. |
| `sentry_flutter` | 8.14.2 | 9.22.0 | **Deferred (major).** Sentry 9.x introduces API changes to `Sentry.init`, feedback widgets, and tracing. Requires migration guide and re-validation of crash reporting. Symbol upload is already disabled pending real org credentials. |
| `purchases_flutter` | 8.11.0 | 10.2.3 | **Deferred (major).** RevenueCat SDK 10.x changes offering/purchase APIs and listener signatures. The paywall and `PremiumService` must be migrated and manually tested against the RevenueCat dashboard before shipping. |
| `path_provider` | 2.1.0 | 2.1.5 | **Up-to-date enough.** Not listed as outdated by `flutter pub outdated` at the current constraint; no action needed. |
| `http` | transitive | transitive | **Not a direct dependency.** Pulled in by `supabase_flutter` and `cached_network_image`. No direct exposure and no security advisories surfaced. |

## Other notable available upgrades

- **`drift` / `drift_dev`**: 2.21.x → 2.34.x. Drift 2.30+ adds new query syntax and generated-code changes. Requires regeneration of `database.g.dart` and full DAO/integration test re-run.
- **`riverpod` / `flutter_riverpod` / `riverpod_annotation` / `riverpod_generator` / `riverpod_lint`**: 2.x → 3.x/4.x. Major architectural changes (code-gen providers, new lint rules). Large refactor risk for a codebase using mixed manual + generated providers.
- **`go_router`**: 14.x → 17.x. Navigation API has accumulated deprecations and typed-routing changes. Router definitions need review.
- **`google_sign_in`**: 6.x → 7.x. May require Android/iOS config updates.
- **`freezed` / `freezed_annotation`**: 2.x → 3.x. Code-gen output changes; all Freezed models must be regenerated.
- **`file_picker`**: 8.x → 11.x/12.x beta. Breaking changes in file-filter APIs.

## Discontinued packages

The following transitive dev dependencies are discontinued. They are pulled in by the build/test toolchain, not by app code, and are safe to leave until the toolchain packages upgrade:

- `js`
- `build_resolvers`
- `build_runner_core`

## Security

No published security advisories for the currently locked versions were found during this audit. `flutter pub outdated` does not flag any security-critical updates.

## Recommendation

1. **Post-launch**: schedule a dependency sprint to migrate `sentry_flutter` and `purchases_flutter` to their latest major versions first, because they touch money and crash reporting.
2. **Before that**: keep `intl`, `drift`, and `riverpod` families at current majors unless a security patch is released.
3. **CI guard**: the new `.github/workflows/ci.yml` runs on every push/PR, so any future upgrade PR must keep `flutter analyze` and `flutter test` green before merge.
