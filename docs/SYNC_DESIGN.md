# GymLog Sync Architecture & Quarantine Specification

> **Status:** Active / Production Authoritative
> **Owner:** Core Engineering
> **Last verified SHA:** `aef17b09305ebf0455244c3c04159577f37e0a84`
> **Last reviewed date:** 2026-07-22
> **Next review date:** 2026-10-22

## Principles
- **Local-first.** Every write commits to SQLite (Drift) immediately and the UI
  reads only local state. The app is fully functional offline.
- **Cloud is a mirror, not a dependency.** After a local commit, a compressed
  versioned snapshot is queued and uploaded in the background. The network never blocks
  the user and a failure never loses data.
- **Failure Quarantine.** Deterministic decode, version, or payload errors are quarantined
  locally to prevent infinite retries and to isolate single corrupt objects.
- **Monotonic Revisions.** Replaces wall-clock-only LWW with per-entity monotonic revisions
  and unique operation IDs to detect conflicts accurately without device clock dependencies.
- **Free-tier conscious.** Batched upserts, gzip-compressed payloads, one row
  per entity, and **no realtime subscriptions** — high-frequency workout data is
  pulled on demand only.

## Payload Versioning (schemaVersion 2)
Every payload is wrapped in a versioned envelope:
```json
{
  "schemaVersion": 2,
  "entityType": "session",
  "entityId": "...",
  "body": {...}
}
```
Unsupported future versions (`schemaVersion > 2`) or corrupt payloads are quarantined locally with an explicit failure reason rather than silently retried.

## Failure Quarantine
`SyncFailureRecord` persists quarantined objects locally in `sync_failures`:
- `SyncFailureReason`: `decodeFailure`, `unsupportedVersion`, `invalidPayload`, `localConstraintFailure`, `ownershipMismatch`, `networkFailure`.
- Quarantined rows do NOT retry on every app launch.
- Settings exposes a nontechnical user warning if items are quarantined.
- Logs strictly maintain privacy and never contain payloads, emails, or access tokens.

## Data Flow & Monotonic Revisions
```
write ─▶ SQLite commit ─▶ outbox.enqueue(coalesced) ─▶ debounce(5s)
                                                            │
 explicit triggers (post-workout, app background, Sync Now) ┤
                                                            ▼
                                 SyncEngine.syncNow ─▶ drain outbox
                                 with monotonic revision + operationId.
                                 Server accepts, reports duplicate, or
                                 flags conflict explicitly.
```

- **Outbox Uniqueness:** `(user_id, entity_type, entity_id)` identity coalesces edits locally.
- **Monotonic Revisions:** Each server record tracks `revision` (incremented on accepted update) and `operation_id` for idempotency.
- **Conflict Handling:** Base revisions older than the server revision trigger an explicit conflict result. Clock skew does not dictate win/loss.
