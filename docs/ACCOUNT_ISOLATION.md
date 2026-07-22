# GymLog Local Account Isolation Policy

> **Status:** Active / Production Authoritative
> **Owner:** Core Engineering
> **Last verified SHA:** `aef17b09305ebf0455244c3c04159577f37e0a84`
> **Last reviewed date:** 2026-07-22
> **Next review date:** 2026-10-22

This document defines the policy and architectural guidelines for handling multiple user accounts on the same device.

## Isolation Principle
The local database may contain multiple accounts, but **every user-owned row and query is strictly scoped by `userId`**.

To prevent cross-account leakage (PII, history, or custom configs):
1. **User Scoping:** All queries on tables that contain user data (e.g. `workout_sessions`, `routines`, `sync_failures`, `sync_outbox`) MUST include a strict `where(userId = ...)` clause matching the currently authenticated user.
2. **Custom Exercise Isolation:** Standard exercise library/catalog is shared across all users (where `isCustom = false`). However, custom exercises (where `isCustom = true`) are strictly filtered to only show those where `createdBy` matches the active `userId`.
3. **Draft Resiliency Isolation:** The resumable active workout draft loaded by `WorkoutDraftStore` on launch is bound to the `userId` in the payload envelope. If the ID doesn't match the current signed-in user, the draft is ignored.
4. **Safe Sign-Out:** When a user triggers sign-out, any auto-sync or draft changes are stopped or saved, account-scoped providers are invalidated, and state transitions cleanly back to the authentication screen.
