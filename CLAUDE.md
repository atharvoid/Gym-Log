# GymLog — Claude Code Configuration

## Rules

- Do what has been asked; nothing more, nothing less
- NEVER create files unless absolutely necessary — prefer editing existing files
- NEVER create documentation files unless explicitly requested
- ALWAYS read a file before editing it
- NEVER commit secrets, credentials, or .env files
- Keep files under 500 lines
- Validate input at system boundaries

## Build & Test

This is a **Flutter / Dart** project. Never use `npm`, `node`, or JavaScript tooling.

```bash
# Install dependencies
flutter pub get

# Code generation (after schema / provider / Freezed changes)
flutter pub run build_runner build --delete-conflicting-outputs

# The mechanical "done" check — mirrors CI exactly.
# ALWAYS run this before declaring a task complete.
.\scripts\verify.ps1        # Windows (PowerShell)
# ./scripts/verify.sh       # Linux / macOS / CI

# What verify runs, in order:
# 1. dart format --output=none --set-exit-if-changed .
# 2. flutter analyze --fatal-infos --fatal-warnings
# 3. dart run custom_lint
# 4. flutter test

# Debug run
flutter run --dart-define-from-file=.env

# Release build
flutter build apk --release --obfuscate --split-debug-info=build/debug-symbols --dart-define-from-file=.env
```

## Key Architecture

- **State**: Riverpod (mixed `StateNotifier` + `@riverpod` code-gen)
- **DB**: Drift (SQLite), 8 tables, 4 DAOs
- **Theme**: OLED-dark, 6 accent palettes via `context.accent` — never hardcode accent colors
- **Design**: See `docs/DESIGN_NORTH_STAR.md`
- **Conventions**: See `docs/CONVENTIONS.md`
- **CI**: See `docs/CI_RUNBOOK.md` and `.github/workflows/ci.yml`

## Definition of Done

A task is NOT done until:
1. Behaviour written as a **failing test first**, then made to pass
2. `.\scripts\verify.ps1` passes (format + analyze + custom_lint + test)
3. New/changed UI has a **golden test** per affected accent theme
4. No hardcoded accent colors on live surfaces
5. CI Gate green on the branch
6. `docs/LOOP_LOG.md` entry if fixing a regression
