# GymLog Privacy Policy

> **Status:** Active / Production Authoritative
> **Owner:** Legal & Product Compliance
> **Last verified SHA:** `aef17b09305ebf0455244c3c04159577f37e0a84`
> **Last reviewed date:** 2026-07-22
> **Next review date:** 2026-10-22

**Effective date:** 14 June 2026

GymLog is a local-first workout tracker. This policy is short because the
honest answer to "what do you do with my data?" is: very little, and you can
delete all of it at any time.

## What we collect

| Data | Where it lives | Why |
|------|----------------|-----|
| Google account email, display name, account ID | Supabase (our auth provider) | Sign-in, and your cross-device profile |
| Workouts, sets, reps, weights, routines, personal records | **Your device** (a private local database) — and, **if you are signed in, a compressed copy in Supabase** | Local tracking is the core app; the cloud copy syncs across your devices and survives reinstalls |
| App preferences (units, rest timer, weekly goal) | Your device, and a compressed copy in Supabase when signed in | App behavior + cross-device continuity |
| Subscription entitlement status | RevenueCat (purchase processor) + a local cache | To unlock Pro features you paid for |
| Crash & error reports (device model, OS, stack traces; your account UUID only) | Sentry | Diagnosing crashes. Email/IP are scrubbed before sending |

## Cloud sync — what actually leaves the device

When you are signed in, GymLog can sync your routines, workout history, and
preferences to our backend (Supabase) so they follow you across devices and
survive a reinstall. The synced body is a compressed payload tied to your
account ID and protected by row-level security (only you can read it). If you
are signed out, nothing syncs and your data stays on the device only.

## What we do NOT do

- We do **not** run ads or sell your data to anyone.
- We do **not** use third-party advertising or tracking SDKs.
- We do **not** collect location, contacts, photos, or health-platform data.

## Third-party services

- **Supabase** — authentication (Google sign-in), the cloud sync store, and
  hosting of the public exercise-illustration library your device downloads from.
- **RevenueCat / Google Play / App Store** — payment processing for the
  optional Pro subscription. We never see your payment details.
- **Sentry** — crash and error reporting (PII scrubbed; only your account UUID
  is attached).

## Data retention

- **Cloud data** (profile + synced workouts/routines/preferences) is retained
  for as long as your account exists. When you delete your account it is
  removed immediately (see below).
- **Crash reports** are retained by Sentry per its standard retention window
  (typically up to 90 days) and contain no directly identifying information.
- **Local data** stays on your device until you delete the account, clear the
  app's storage, or uninstall the app.

## How to delete your account and data

Deletion is permanent and removes your cloud account, your synced data, and the
data stored locally on the device.

1. **In the app:** **Settings → Delete account**. Type `DELETE` to confirm. This
   permanently deletes your sign-in account and any cloud-synced data from
   Supabase, erases the local database on the device, and signs you out.
2. **Without the app** (e.g. after uninstalling): visit
   **https://atharvoid.github.io/Gym-Log/legal/delete-account.html**, sign in to
   verify ownership, and confirm deletion.
3. **By email:** if you cannot use either option, email
   **support@gymlog.app** from your registered address and we will delete your
   account within 30 days.

CSV files you have exported to your device's Downloads/Files are **your
property** and are never accessed or removed by deletion.

## Data export

Settings → **Export workouts** produces a CSV of every set you have logged.
Your data is portable, free, forever.

## Changes

Material changes to this policy will be reflected in this document with a new
effective date and noted in release notes.

## Contact

Questions or deletion help: **support@gymlog.app**, or open an issue on the
GymLog repository.
