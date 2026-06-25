# GymLog — Agent Context

> Flutter workout logging app. This file captures build steps, conventions, and
> architectural decisions agents need to work effectively in this codebase.
> **Last verified:** HEAD on `remediation/8-phase`.

---

## Project Overview

| | |
|---|---|
| **Name** | GymLog |
| **Version** | 1.0.0+1 |
| **Type** | Cross-platform mobile app (Flutter) |
| **Purpose** | Workout / exercise logger with progress tracking |

### Tech Stack

- **Framework**: Flutter / Dart
- **State Management**: Riverpod (manual `StateNotifier` + code-generated `@riverpod`)
- **Database**: Drift (SQLite) — 8 tables, 4 DAOs
- **Backend/Auth**: Supabase (Google Sign-In via native + web OAuth)
- **Routing**: GoRouter
- **Code Generation**: `build_runner` (Drift, Riverpod, Freezed, JSON serializable)
- **Theme**: OLED-first dark mode, pure black background, 6 selectable accent palettes

---

## Build & Run

> **Config model:** secrets/keys are injected at **compile time** via
> `--dart-define-from-file=.env` (see `lib/core/config/env.dart`). The
> gitignored `.env` file in the repo root keeps `SUPABASE_URL`,
> `SUPABASE_ANON_KEY`, `REVENUECAT_ANDROID_KEY`, `REVENUECAT_IOS_KEY` — it is
> **not** a Flutter asset and is never bundled into the binary. Builds without
> the flag work fine: auth and purchases degrade gracefully, local logging is
> fully functional.

```bash
# Install dependencies
flutter pub get

# Run code generation (required after schema or provider changes)
flutter pub run build_runner build --delete-conflicting-outputs

# Debug
flutter run --dart-define-from-file=.env

# Release (with Sentry symbol upload)
$env:SENTRY_AUTH_TOKEN="..."
$env:SENTRY_ORG="..."
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols --dart-define-from-file=.env
flutter pub run sentry_dart_plugin
```

---

## Project Structure

```
lib/
├── core/           # Shared core utilities, theme, database, routing
├── features/       # Feature-based modules
├── shared/         # Shared widgets / components
├── app.dart        # App widget / root configuration
└── main.dart       # Entry point
```

- `docs/` — Architecture decisions, data model, conventions, progress tracking
- `assets/db/` — Bundled database assets
- `scripts/` — Verify scripts, seed data

---

## Conventions

Project conventions are documented in detail under `docs/CONVENTIONS.md`. Key points:

- Feature-based organization
- Riverpod for state management (mixed manual + code-gen)
- Drift for local persistence
- OLED-first dark theme, 6 accent palettes via `context.accent`

---

## Environment & Secrets

- `.env` is **gitignored** and injected at compile time via `--dart-define-from-file=.env`
- Supabase credentials, OAuth config, RevenueCat keys, and Sentry DSN live in `.env`
- Do not commit `.env`

---

## Testing & CI

### Test Suite (18 files)

The test suite covers DAO integration (host SQLite via ffi), sync engine,
set-row widget behaviour, workout start, chart axis formatting, rest timer bar,
routine reorder, streak/formatter logic, profile sync, weekly bar chart, export,
explore catalog integrity, routine caps, weekly goal sheet, and a compile-surface
smoke test. Golden tests live in `test/golden/`.

### CI Pipeline (`.github/workflows/ci.yml`)

Zero-tolerance gate on every push/PR to `main` and `remediation/**`:

1. **Analyze & Test** — `dart format --set-exit-if-changed` → `flutter analyze --fatal-infos --fatal-warnings` → `dart run custom_lint` → `flutter test --machine`
2. **Build Android (release)** — `flutter build apk --release --obfuscate --split-debug-info=…`
3. **Build iOS (release, no codesign)** — `flutter build ios --release --no-codesign`
4. **CI Gate** — passes only if all three above pass

See `docs/CI_RUNBOOK.md` for details.

---

## Definition of Done

A task is **not** done until **all** of the following are true:

- [ ] Behaviour was written as a **failing test first**, then made to pass (spec-driven)
- [ ] `.\scripts\verify.ps1` passes locally: format, analyze (`--fatal-infos --fatal-warnings`), `custom_lint`, `flutter test`
- [ ] New/changed UI surfaces have or update a **golden** in every affected accent theme
- [ ] No hardcoded accent colors on live surfaces (use `context.accent`)
- [ ] CI Gate is green on the pushed branch
- [ ] A `docs/LOOP_LOG.md` entry exists if this fixed a reported regression

---

## Notes for Agents

- Always run `build_runner` after modifying Drift tables, Riverpod providers, or Freezed models
- The project uses **mixed Riverpod patterns** — some providers are manual `StateNotifier`, others use `@riverpod` code generation
- `node_modules/` only contains `chrome-devtools-mcp` (unrelated to the app — do not treat as a Node.js project)
- **Never** use `npm run build` or `npm test` — this is a Flutter project. Use `.\scripts\verify.ps1`
- The design north-star is `docs/DESIGN_NORTH_STAR.md` — read it before any visual work
