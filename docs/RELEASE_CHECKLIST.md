# Release Certification Checklist — GymLog v1.0.0

> Phase 15 close-out. Cross off each item before shipping to stores.

## 1. Environment & Secrets

- [ ] **Sentry DSN**: Current `.env` value is a settings-page URL, not a DSN.
      Get the real DSN from Sentry → Project Settings → Client Keys (DSN).
      Format: `https://<key>@o<org>.ingest.sentry.io/projects/<project_id>`
- [ ] **RevenueCat Android key**: Add `REVENUECAT_ANDROID_KEY` to `.env`.
      Get it from RevenueCat → App Settings → API Keys → Android.
- [ ] **RevenueCat iOS key**: Add `REVENUECAT_IOS_KEY` to `.env`.
      Get it from RevenueCat → App Settings → API Keys → iOS.
- [ ] **Sentry Auth Token**: Create at `sentry.io/settings/account/api/auth-tokens/`
      with scopes `project:write`, `project:read`. Store as GitHub secret
      `SENTRY_AUTH_TOKEN`.
- [ ] **Sentry Org**: Set `SENTRY_ORG` as GitHub secret (value: `twizz-4i`).
- [ ] **CI release workflow**: Create a `release.yml` that runs `--dart-define-from-file=.env` and
      injects `SENTRY_AUTH_TOKEN`, `SENTRY_ORG` env vars.

## 2. Android

- [ ] **Upload keystore**: Create `android/upload-keystore.jks`:
      ```
      keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA \
        -keysize 2048 -validity 10000 -alias upload
      ```
- [ ] **Fill `android/key.properties`**: Point `storeFile` to `../upload-keystore.jks`
      and fill in the passwords.
- [ ] **Native symbol upload**: Consider enabling `uploadNativeSymbols.set(true)` in
      `android/app/build.gradle.kts` and removing `debugSymbolLevel = "none"` so
      native crashes are symbolicated in Sentry. Adds ~15 MB to artifacts.
- [ ] **Google Play App Signing**: Enable in Play Console.
      Upload the public certificate from the upload keystore.
- [ ] **ProGuard rules**: Verify `proguard-rules.pro` keeps all needed classes
      (particularly for Drift, Riverpod, Freezed, Sentry, RevenueCat).
- [ ] **Build signed AAB**: `flutter build appbundle --release --obfuscate
      --split-debug-info=build/app/outputs/symbols --dart-define-from-file=.env`
- [ ] **Physical device test**: Install the signed AAB on a Pixel and recent Samsung,
      verify: sign-in, workout flow, rest timer, import/export, premium.
- [ ] **Store listing**: Update screenshots, description, privacy policy link,
      account deletion link.

## 3. iOS

- [ ] **RevenueCat**: Verify `Info.plist` has `RevenueCat` RC configuration if needed
      (for observer mode or proxy). SDK keys are injected via dart-define, not plist.
- [ ] **Sentry**: Verify `ios/Runner/Runner.entitlements` or `Info.plist` has no
      conflicting Sentry setup (all Sentry config is Dart-side).
- [ ] **TestFlight**: Build with `flutter build ios --release --no-codesign`,
      then archive from Xcode with distribution certificate.
- [ ] **Apple App Store Connect**: Verify app metadata, privacy policy URLs,
      and account deletion policy.

## 4. Sentry

- [ ] **Source maps uploaded**: Verify Sentry dashboard → Project Settings → Debug Files
      shows the uploaded Dart source maps and ProGuard mapping.
- [ ] **Native symbols uploaded** (if enabled): same dashboard section shows `.so` symbols.
- [ ] **Test crash**: Verify a test crash appears in Sentry Issues.

## 5. CI & Gate

- [ ] **`--dart-define-from-file=.env`** available in release workflow for Sentry DSN
      and RevenueCat keys.
- [ ] **CI Gate** green on the release branch.
- [ ] **`verify.ps1`** passes locally: format, analyze, custom_lint, flutter test.

## 6. Post-Release

- [ ] **Tag**: `git tag v1.0.0 && git push origin v1.0.0`
- [ ] **Monitor Sentry** for 48h after release for unexpected crash clusters.
- [ ] **Monitor RevenueCat** for purchase/restore errors.
