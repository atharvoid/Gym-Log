# GymLog — Agent Context

> Flutter workout logging app. This file captures build steps, conventions, and architectural decisions agents need to work effectively in this codebase.

---

## Project Overview

| | |
|---|---|
| **Name** | GymLog |
| **Version** | 0.1.0 |
| **Type** | Cross-platform mobile app (Flutter) |
| **Purpose** | Workout / exercise logger with progress tracking |

### Tech Stack

- **Framework**: Flutter / Dart
- **State Management**: Riverpod (manual `StateNotifier` + code-generated `@riverpod`)
- **Database**: Drift (SQLite) — 8 tables, 4 DAOs
- **Backend/Auth**: Supabase (Google Sign-In via native + web OAuth)
- **Routing**: GoRouter
- **Code Generation**: `build_runner` (Drift, Riverpod, Freezed, JSON serializable)
- **Theme**: OLED-first dark mode, pure black background, electric purple accent

---

## Build & Run

```bash
# Install dependencies
flutter pub get

# Run code generation (required after schema or provider changes)
flutter pub run build_runner build --delete-conflicting-outputs

# Analyze
flutter analyze

# Run (debug)
flutter run

# Build release APK
flutter build apk
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
- `scripts/` — Utility scripts (e.g., `seed_exercises.py`)

---

## Conventions

Project conventions are documented in detail under `docs/CONVENTIONS.md`. Key points:

- Feature-based organization
- Riverpod for state management (mixed manual + code-gen)
- Drift for local persistence
- OLED-first dark theme

---

## Environment & Secrets

- `.env` is **gitignored** but loaded as a Flutter asset
- Supabase credentials and OAuth config live in `.env`
- Do not commit `.env`

---

## Testing

- Only a default widget test exists (`test/widget_test.dart`)
- **Known issue**: widget test references `MyApp` which no longer exists — it will fail until updated

---

## Notes for Agents

- Always run `build_runner` after modifying Drift tables, Riverpod providers, or Freezed models
- The project uses **mixed Riverpod patterns** — some providers are manual `StateNotifier`, others use `@riverpod` code generation
- No CI/CD workflows are configured
- `node_modules/` only contains `chrome-devtools-mcp` (unrelated to the app — do not treat as a Node.js project)
