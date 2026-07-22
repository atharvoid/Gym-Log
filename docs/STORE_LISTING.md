# GymLog Store Listing & Metadata Specification

> **Status:** Active / Production Authoritative
> **Owner:** Core Engineering
> **Last verified SHA:** `aef17b09305ebf0455244c3c04159577f37e0a84`
> **Last reviewed date:** 2026-07-22
> **Next review date:** 2026-10-22

---

## Canonical Store Metadata

| Field | Google Play Store | Apple App Store |
|---|---|---|
| **App Name** | GymLog — Workout Tracker | GymLog: Workout Tracker |
| **Short Description** | OLED-first workout logger, local-first data, zero bloat, analytics & PRs. | High-density workout logger, local-first privacy, zero bloat, analytics & PRs. |
| **Support Email** | `support@gymlog.app` | `support@gymlog.app` |
| **Privacy Policy URL** | `https://atharvoid.github.io/Gym-Log/legal/privacy-policy.html` | `https://atharvoid.github.io/Gym-Log/legal/privacy-policy.html` |
| **Terms of Service URL** | `https://atharvoid.github.io/Gym-Log/legal/terms-of-service.html` | `https://atharvoid.github.io/Gym-Log/legal/terms-of-service.html` |
| **Account Deletion URL** | `https://atharvoid.github.io/Gym-Log/legal/delete-account.html` | `https://atharvoid.github.io/Gym-Log/legal/delete-account.html` |
| **Category** | Health & Fitness | Health & Fitness |
| **Content Rating** | Everyone / 4+ | Everyone / 4+ |

---

## Full App Description

GymLog is a fast, OLED-first workout logger designed for gym enthusiasts who want clean, high-density tracking without ads, social clutter, or unnecessary bloat.

### Key Features

- **OLED-First Pure Dark Mode**: Designed for low-power high-contrast visibility on the gym floor.
- **Fast Logging**: Record sets, reps, weights, rest timers, and set types in seconds.
- **Metric-Aware Personal Records**: Track estimated 1RM, max weight, max reps, max duration, max distance, and best pace per exercise.
- **Local-First Privacy**: Your workout data stays on your device in a private SQLite database. Optional cloud sync keeps your profile backed up safely.
- **Data Portability**: Export your complete workout history to RFC 4180 CSV anytime. Your data belongs to you.
- **Automatic Rest Timer**: Customizable rest countdowns with accessibility announcements and background notification support.

---

## Entitlements & Pricing

- **Free Tier**: Unlimited workout logging, exercise catalog, routine templates, and local backups.
- **GymLog Pro**: Optional subscription for extended historical analytics (1Y and All-Time chart ranges) and cross-device cloud sync via RevenueCat (`premium` entitlement ID).
