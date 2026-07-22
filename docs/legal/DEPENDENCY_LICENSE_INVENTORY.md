# GymLog Open Source Dependency & License Inventory

> **Status:** Active / Production Authoritative
> **Owner:** Legal & Product Compliance
> **Last verified SHA:** `aef17b09305ebf0455244c3c04159577f37e0a84`
> **Last reviewed date:** 2026-07-22
> **Next review date:** 2026-10-22

This document lists all direct open-source dependencies used by GymLog, their licensing status, and an audit of the exercise media library.

---

## 1. Direct Dependency Inventory

| Package Name | Version | License | Purpose in GymLog |
|---|---|---|---|
| `drift` | `^2.18.0` | Apache-2.0 | Core local SQLite ORM and reactive database queries |
| `sqlite3_flutter_libs` | `^0.5.42` | MIT | SQLite database FFI binary wrapper for Android/iOS/Desktop |
| `flutter_riverpod` | `^2.5.0` | MIT | Core dependency injection and state management |
| `riverpod_annotation` | `^2.3.0` | MIT | Code generation annotations for Riverpod providers |
| `go_router` | `^14.0.0` | BSD-3-Clause | App routing and declarative URL-based navigation |
| `supabase_flutter` | `^2.5.0` | MIT | Cloud sync engine, user profile storage, and authentication |
| `flutter_secure_storage` | `^9.0.0` | BSD-3-Clause | Secure storage (Keychain/Keystore) for draft workout sessions |
| `google_sign_in` | `^6.2.0` | BSD-3-Clause | Native Google OAuth identity integration |
| `flutter_svg` | `^2.0.10` | MIT | Rendering muscle target vector drawings and icons |
| `cached_network_image` | `^3.3.0` | MIT | Caching network-delivered catalog illustrations |
| `gif_view` | `^0.4.0` | MIT | Rendering animated exercise guide loops in the catalog details |
| `fl_chart` | `^0.68.0` | MIT | Visualizing training volume and frequency charts |
| `google_fonts` | `^6.2.0` | Apache-2.0 | Dynamic Outfit/Inter font loading (locally bundled) |
| `url_launcher` | `^6.2.0` | BSD-3-Clause | Opening legal link documents and external email prompts |
| `purchases_flutter` | `^8.11.0` | MIT | RevenueCat billing backend and Pro entitlement validation |
| `share_plus` | `^12.0.2` | BSD-3-Clause | Sharing exported workout CSV files to other apps |
| `file_picker` | `^8.1.2` | MIT | Selecting local Strong/Hevy CSV backups for data import |
| `image_picker` | `^1.1.2` | BSD-3-Clause | Capturing or picking profile pictures from camera/gallery |
| `flutter_image_compress` | `^2.3.0` | MIT | Compressing user profile avatars before server uploads |
| `crop_your_image` | `^2.0.0` | MIT | Premium client-side cropper for customized profile pictures |
| `intl` | `^0.19.0` | BSD-3-Clause | Date/time and number localization formatting |
| `uuid` | `^4.4.0` | MIT | Generating unique IDs for sets, exercises, and workouts |
| `package_info_plus` | `^8.0.0` | BSD-3-Clause | Extracting bundle identifiers, builds, and versions |
| `shared_preferences` | `^2.2.0` | BSD-3-Clause | Storing local key-value options (e.g. weight unit override) |
| `path_provider` | `^2.1.0` | BSD-3-Clause | Accessing local database storage directories |
| `sentry_flutter` | `^8.14.0` | MIT | Automated crash tracking and stability analytics |
| `connectivity_plus` | `^7.1.1` | BSD-3-Clause | Real-time network detection for syncing |
| `flutter_local_notifications` | `^22.1.0` | BSD-3-Clause | Scheduling foreground and background local rest timers |

---

## 2. Exercise Media & Image Licensing Gaps

> [!WARNING]
> **Audit Status: Critical Action Required**
> - **Exercise Catalog Images & GIFs**: The app displays exercise visual guides (caching them via `cached_network_image` and `gif_view` from a Supabase storage bucket).
> - **Origin & Ownership**: The current repository does *not* contain licensing records (e.g. Creative Commons, commercial purchase, or proprietary release forms) for these media assets.
> - **Risk**: Shipping these images/GIFs without verified rights exposes the project to copyright strikes, store takedowns, and potential legal claims.
> - **Remediation Recommendation**: The owner must perform one of the following:
>   1. Verify that all hosted media falls under a permissive license (e.g. CC0 / Public Domain) or has a formal license agreement.
>   2. Replace the media library with verified open-source assets (such as the *wger* open-source catalog) or custom-produced recordings.

---

## 3. Specialist Legal Review Checklist

The following regulatory topics are flagged as out of scope for automated compliance checks and require review by a qualified legal professional:

- [ ] **COPPA Compliance**: Does the app target users under 13? (Google Sign-In generally restricts users below 13, but check-ins are recommended).
- [ ] **GDPR/CCPA Data Portability**: Verify that the CSV produced by "Export workouts" satisfies "Right to Portability" requests.
- [ ] **GDPR Article 17 (Right to Erasure)**: Ensure that deleting an account completely purges user backups from any Supabase automated database snapshots/backups within legal timelines.
- [ ] **Health/Biometrics Data**: Confirm that logging reps/sets/weights does not cross local thresholds for regulated medical/health data (e.g., HIPAA in the US, or special category data under GDPR).

---

## 4. Reviewer Sign-Off

*To be completed prior to production release:*

- **Legal Counsel Review Date:** `_____________________`
- **Legal Counsel Signature:** `_____________________`
- **App Owner Release Approval:** `_____________________`
