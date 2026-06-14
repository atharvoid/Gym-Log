/// Compile-time configuration for GymLog.
///
/// Every value is injected at BUILD time via `--dart-define` /
/// `--dart-define-from-file` — nothing is bundled as a readable runtime
/// asset and nothing secret lives in source control.
///
/// Local development & release builds (a gitignored `.env` file in the repo
/// root keeps the old workflow — same keys, same file, new mechanism):
///
/// ```bash
/// flutter run --dart-define-from-file=.env
/// flutter build apk --release --dart-define-from-file=.env
/// ```
///
/// Keys enabling full functionality (all optional — a clean checkout builds
/// and runs with auth + purchases disabled while local logging keeps working):
///
///   SUPABASE_URL / SUPABASE_ANON_KEY            → Google sign-in (auth only)
///   REVENUECAT_ANDROID_KEY / REVENUECAT_IOS_KEY → premium entitlements
///   SENTRY_DSN                                  → crash/error reporting
///
/// Overridable public identifiers (safe, non-secret defaults baked in —
/// OAuth client IDs and public storage URLs are visible in any shipped
/// binary by design; centralizing them here keeps source greppable and
/// rotation one-flag simple):
///
///   GOOGLE_SERVER_CLIENT_ID → Google OAuth server client id
///   GIF_BUCKET_BASE         → public storage bucket for exercise GIFs
abstract final class Env {
  /// Supabase project URL. Empty on builds without `--dart-define-from-file`.
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Supabase anon (publishable) key — designed to be public, protected by
  /// RLS server-side. Still injected at build time, never bundled as a file.
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Google OAuth *server* client id used by native Google Sign-In to mint
  /// an idToken Supabase will accept.
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '90567853200-0o67mbmlv5qluq95q1courn77lddhcui.apps.googleusercontent.com',
  );

  /// Base URL of the public storage bucket hosting exercise GIFs.
  /// (`excercises` typo is the real bucket name — do not "fix".)
  static const gifBucketBase = String.fromEnvironment(
    'GIF_BUCKET_BASE',
    defaultValue:
        'https://otcfigaprxfknickyrdh.supabase.co/storage/v1/object/public/excercises',
  );

  /// Public URL of the standalone web account-deletion page (Google Play
  /// requires a deletion path reachable WITHOUT the app). Served from the
  /// repo's `docs/legal/delete-account.html` via GitHub Pages by default;
  /// override per environment. Documented in the privacy policy + Play Console.
  static const accountDeletionUrl = String.fromEnvironment(
    'ACCOUNT_DELETION_URL',
    defaultValue:
        'https://atharvoid.github.io/Gym-Log/legal/delete-account.html',
  );

  /// RevenueCat public SDK keys. Absent → PremiumService runs in free mode.
  static const revenueCatAndroidKey =
      String.fromEnvironment('REVENUECAT_ANDROID_KEY');
  static const revenueCatIosKey = String.fromEnvironment('REVENUECAT_IOS_KEY');

  /// Sentry DSN for crash/error reporting. Absent → Sentry is initialized but
  /// silently drops events (the SDK requires a non-empty DSN to send).
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  static const String sentryAuthToken = String.fromEnvironment('SENTRY_AUTH_TOKEN');
  static const String sentryOrg = String.fromEnvironment('SENTRY_ORG');
  static const String sentryProject = String.fromEnvironment('SENTRY_PROJECT');

  /// True when the build carries enough config for Supabase auth.
  static const hasSupabaseConfig = supabaseUrl != '' && supabaseAnonKey != '';

  /// True when the build carries a Sentry DSN.
  static const hasSentryConfig = sentryDsn != '';
}
