/// Canonical legal-document URLs, shared by the Settings screen and the
/// pre-sign-in Auth screen. Centralized so the App Store / Play Store
/// required links never drift between the two surfaces.
///
/// These point at the hosted HTML pages on GitHub Pages.
library;

const String kPrivacyPolicyUrl =
    'https://atharvoid.github.io/Gym-Log/legal/privacy-policy.html';

const String kTermsOfServiceUrl =
    'https://atharvoid.github.io/Gym-Log/legal/terms-of-service.html';

const String kAccountDeletionUrl =
    'https://atharvoid.github.io/Gym-Log/legal/delete-account.html';

const String kSupportEmail = 'support@gymlog.app';

const int kExerciseCatalogVersion = 2;
