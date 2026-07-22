# GymLog Documentation Index

> **Status:** Active / Production Authoritative
> **Owner:** Core Engineering
> **Last verified SHA:** `aef17b09305ebf0455244c3c04159577f37e0a84`
> **Last reviewed date:** 2026-07-22
> **Next review date:** 2026-10-22

Welcome to the GymLog documentation index. This folder contains the architectural, structural, legal, and operational specifications governing the application.

---

## Core Technical & Architectural Specifications

1. [**ARCHITECTURE.md**](ARCHITECTURE.md)
   - Feature-first structure, Riverpod state management, Drift persistence, and router configuration.
2. [**CONVENTIONS.md**](CONVENTIONS.md)
   - Code conventions, state patterns, naming rules, theme tokens, and testing requirements.
3. [**DATA_MODEL.md**](DATA_MODEL.md)
   - Drift/SQLite local data schema, table structures (schema v16), and relationship definitions.
4. [**SYNC_DESIGN.md**](SYNC_DESIGN.md)
   - Monotonic version payloads, outbox queueing, RLS security, and sync quarantine rules.
5. [**ACCOUNT_ISOLATION.md**](ACCOUNT_ISOLATION.md)
   - User ID row-level isolation policies, safe sign-out workflow, and pending work guards.
6. [**REVENUECAT_CONFIG.md**](REVENUECAT_CONFIG.md)
   - Canonical entitlement (`premium`), purchase verification, anonymous IDs, and paywall rules.
7. [**IMPORT.md**](IMPORT.md)
   - Lossless workout CSV v2 format (20 columns), RFC 4180 escaping, and historic PR rehydration.

---

## Design, Testing & Operations

8. [**DESIGN_NORTH_STAR.md**](DESIGN_NORTH_STAR.md)
   - OLED-first theme tokens, 6 accent palettes, micro-interactions, and visual hierarchy guidelines.
9. [**CI_RUNBOOK.md**](CI_RUNBOOK.md)
   - CI pipeline architecture, local verification, and build scripts.
10. [**CONSOLE_CHECKLIST.md**](CONSOLE_CHECKLIST.md)
    - Google Play Console & App Store Connect release readiness checklist.
11. [**STORE_LISTING.md**](STORE_LISTING.md)
    - App Store & Play Store metadata, short descriptions, and support identity.

---

## Legal & Compliance Specifications

12. [**legal/PRIVACY_POLICY.md**](legal/PRIVACY_POLICY.md)
    - Privacy policy, data collection scope, Sentry telemetry, and support contact details.
13. [**legal/TERMS_OF_SERVICE.md**](legal/TERMS_OF_SERVICE.md)
    - Terms of service, subscription policies, and health disclaimers.
14. [**legal/DEPENDENCY_LICENSE_INVENTORY.md**](legal/DEPENDENCY_LICENSE_INVENTORY.md)
    - Open-source dependency license inventory and attribution details.
