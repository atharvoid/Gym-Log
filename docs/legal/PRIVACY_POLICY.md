# GymLog Privacy Policy

**Effective date:** 12 June 2026

GymLog is a local-first workout tracker. This policy is short because the
honest answer to "what do you do with my data?" is: almost nothing.

## What we collect

| Data | Where it lives | Why |
|------|----------------|-----|
| Google account email, display name, account ID | Supabase (our auth provider) | Sign-in only |
| Workouts, sets, reps, weights, personal records | **Your device only** — a private local database | The entire point of the app |
| Subscription entitlement status | RevenueCat (purchase processor) + a local cache | To unlock Pro features you paid for |
| App preferences (units, rest timer, weekly goal) | Your device only | App behavior |

## What we do NOT do

- We do **not** upload your training data. Workouts never leave your device.
- We do **not** run ads or sell data to anyone.
- We do **not** use third-party analytics or tracking SDKs.
- We do **not** collect location, contacts, photos, or health-platform data.

## Third-party services

- **Supabase** — authentication (Google sign-in) and hosting of the public
  exercise-illustration library your device downloads images from.
- **RevenueCat / Google Play / App Store** — payment processing for the
  optional Pro subscription. We never see your payment details.

## Data deletion

Your training data is on your device: uninstalling the app (or clearing its
storage) permanently deletes it. To delete your sign-in account record,
email the developer (see the repository profile) from your registered
address and it will be removed within 30 days.

## Data export

Settings → **Export workouts** produces a CSV of every set you have logged.
Your data is portable, free, forever.

## Changes

Material changes to this policy will be reflected in this document with a new
effective date and noted in release notes.

## Contact

Questions: open an issue on the GymLog repository or contact the developer
via the repository profile.
