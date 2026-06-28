# Auth System Audit

## 1. Auth Screen UI
- **Sign-in options available:** 
  - Email/Password form fields (Text fields for Email and Password)
  - "Continue with Google" button
- **Email/password fields present:** `YES`
- **"Sign Up" button present:** `YES` (toggled via a link "Don't have an account? Sign up" which changes the primary button label to "Sign up")
- **Unexpected screens found:** None. The auth screen directory contains:
  - `auth_screen.dart` (main screen)
  - `onboarding_screen.dart` (captures display name post-login)
  - `splash_screen.dart` (handling start-up routing)

## 2. Auth Repository Methods
- **Methods implemented:**
  - `signInWithGoogle()` (native client on mobile, OAuth redirection on web)
  - `signOut()`
  - `currentUser` getter
  - `currentSession` getter
  - `authStateChanges` stream
- **Methods actually called from UI:**
  - `signInWithGoogle()` (when tapping the Google button)
  - `signOut()` (when cancelling onboarding or logging out in settings)
- **Dead code identified:**
  - The entire email/password UI (visibility state, controllers, text fields, toggle text, and the form button) is **dead code**. The email/password button action is a dummy stub:
    ```dart
    onPressed: () {
      // Stub for email/password action
    },
    ```
    No registration or login methods for email/password exist in `AuthRepository` or the providers.

## 3. Google Sign-In Release Configuration
- **Debug SHA-1 in Google Cloud:** `YES` (Google Sign-In functions correctly in local debug mode, indicating the debug SHA-1 has been registered in the Google Cloud Console credentials for Android).
- **Release SHA-1 in Google Cloud:** **NO / MISSING**
  - **Analysis:** This is the root cause of the release-build login failure. When compiling the release build (signed with a release key or Google Play App Signing key), the SHA-1 fingerprint changes. If this new release SHA-1 fingerprint is not added to the Google Cloud Console under the Android OAuth 2.0 Client ID for `com.gym_log`, Google Sign-In throws an error (typically API Exception 10 or 12500) and fails to return an ID token.
- **Supabase Google provider enabled:** `YES` (verified by the fact that login works in local debug builds).
- **Supabase redirect URI:** standard native OAuth client redirection; web redirects to `http://127.0.0.1:8080/`.
- **`applicationId` matches OAuth Client ID:** `YES` (`applicationId` is `com.gym_log` in `android/app/build.gradle.kts`, matching the package name configuration).

## 4. Email/Password Source
- **Source of feature:** Boilerplate template UI code added during screen setup but never integrated with the actual data/auth layer.
- **Files touched:**
  - `lib/features/auth/presentation/screens/auth_screen.dart`
- **Effort to remove:** `Small` (requires deleting the unused text controllers, form fields, switch link, and replacing it with a clean layout containing the single "Continue with Google" primary button).

## 5. Recommendation
- **Google login fix:**
  1. Retrieve the **Release SHA-1 fingerprint** of the signing key (if using Google Play App Signing, this fingerprint is retrieved from the Google Play Console under **Release** -> **Setup** -> **App Integrity** -> **App signing key certificate**; if building and signing locally, retrieve it via `keytool` on the release keystore).
  2. Go to the [Google Cloud Console](https://console.cloud.google.com/) -> **APIs & Services** -> **Credentials**.
  3. Find the **OAuth 2.0 Client IDs** and edit the **Android Client ID** matching package `com.gym_log`.
  4. Add the release SHA-1 fingerprint to the list and save.
- **Email/password decision:** **REMOVE**
  - **Justification:** GymLog's philosophy is "local-first, simple, honest". Maintaining email/password auth introduces significant maintenance overhead: password strength requirements, secure hashing, reset passwords, email confirmation, account locks, and email recovery support. Eliminating it entirely keeps onboarding seamless, reduces the code footprint, and avoids account management support.
  - **Clean Up Steps:** Delete the stubs and unused widgets from `auth_screen.dart` to make "Continue with Google" the prominent primary action.
