# Launch sequence — what runs, in what order, and how to verify it

A cold start on Android 12+ paints **three** things before your UI. Almost every
"there's a weird logo screen on startup" bug is a mismatch between them.

| # | Surface | Owned by | Configured in |
|---|---------|----------|---------------|
| 1 | OS splash (icon on a solid background) | Android 12+, mandatory | `android/app/src/main/res/values-v31/styles.xml` |
| 2 | Window background | Your launch theme | `android/app/src/main/res/drawable-v21/launch_background.xml` (the file every supported device resolves — minSdk is 21) + `values/styles.xml` / `values-night/styles.xml` |
| 3 | First Flutter frame — here, the `/splash` route | Dart | `lib/core/router/router.dart` (`initialLocation: '/splash'`) |

## What this branch changed

- (1) now exists at all. It was unstyled, so it used platform defaults.
- (2) was `@android:color/white` on a `Theme.Light` parent in
  `drawable/launch_background.xml`, in an app whose `AppColors.bgBase` is
  `#000000`. That white slab was the visible flash. That fix landed in the
  wrong file, though: minSdk is 21, so Android always resolves
  `drawable-v21/launch_background.xml` instead, which still used
  `?android:colorBackground` — a theme attribute that is light in day mode.
  The white flash was still reproducible on any API 21-30 device in day mode.
  Both files are now pinned to the same explicit black (B23).
- (3) is **untouched**. If you still see a Flutter-rendered splash after this,
  it is surface 3, and it is intentional app code — not a launch bug.

## Telling surface 1/2 apart from surface 3 in one test

Cold-start the app in airplane mode with the device on a slow/cold cache:

- A flash that appears **before** any app colour or motion = surface 1/2.
- Anything with app typography, the accent colour, or animation = surface 3.

## Verification (cannot be done from a hot restart)

The Android 12 splash is only drawn on a genuine cold start of an installed
APK. Hot restart, `flutter run` re-attach, and app-switcher resume all skip it.

```sh
flutter clean
flutter pub get
flutter build apk --release --dart-define-from-file=.env
adb install -r build/app/outputs/flutter-apk/app-release.apk
adb shell am force-stop com.<your.app.id>   # force a true cold start
adb shell monkey -p com.<your.app.id> -c android.intent.category.LAUNCHER 1
```

Record it if the flash is short:

```sh
adb shell screenrecord --time-limit 6 /sdcard/launch.mp4
adb pull /sdcard/launch.mp4
```

Step through the recording frame by frame. A correct sequence never shows a
non-black frame. Test in **both** day and night mode, and ideally on an API
21-30 device or emulator as well as API 31+ — the day-mode API 21-30 path is
the one that regressed silently before B23.

## If you want to remove surface 3 as well

Two options, in order of preference:

1. **Drop the `/splash` route** and make the router's `initialLocation` depend
   directly on auth state. The route only exists to cover async bootstrap; if
   bootstrap is fast, the route is a self-inflicted extra screen.
2. **Keep it but make it indistinguishable** from surface 1/2: black
   background, no logo, no animation. Then the user perceives one launch, and
   the route is free to wait on bootstrap for as long as it needs.

This branch does neither, because it changes perceived-startup behaviour and
that is your call, not a UI-regression fix.

## Optional: `flutter_native_splash`

If you would rather generate surfaces 1 and 2 from one config, add
`flutter_native_splash` to `dev_dependencies`, add a `flutter_native_splash:`
block to `pubspec.yaml` with `color: "#000000"` and `android_12: { color:
"#000000" }`, then run:

```sh
dart run flutter_native_splash:create
```

That command **overwrites** `launch_background.xml` and `values-v31/styles.xml`,
including the comments in them. It was deliberately not used here: adding a
code-generator and a new dependency is a bigger change than the seven lines the
bug actually needed, and the generated files would then be the source of truth
instead of these ones.
