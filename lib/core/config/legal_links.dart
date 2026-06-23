/// Canonical legal-document URLs, shared by the Settings screen and the
/// pre-sign-in Auth screen. Centralized so the App Store / Play Store
/// required links never drift between the two surfaces.
///
/// These point at the in-repo policy docs. Swap for a hosted privacy page
/// before public launch if you move them off GitHub.
library;

const String kPrivacyPolicyUrl =
    'https://atharvoid.github.io/Gym-Log/legal/PRIVACY_POLICY.md';

const String kTermsOfServiceUrl =
    'https://atharvoid.github.io/Gym-Log/legal/terms-of-service.html';
