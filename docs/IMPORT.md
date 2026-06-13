# Workout import (Hevy & Strong CSV)

Lets a new user bring their full training history into GymLog from **Hevy** or
**Strong** by importing the CSV those apps export. Free for everyone — it's the
user's own data and the obvious migration on-ramp.

Entry point: **Settings → Data → Import workouts** (`/settings/import`).

## Pipeline

```
file → CsvCodec → WorkoutCsvParser → ExerciseMatcher → WorkoutImportService → Drift
        (tokenise)  (map to sessions)  (name → id)       (dedup + persist + PRs)
```

| Layer | File | Responsibility |
| --- | --- | --- |
| Tokeniser | `lib/features/import/data/csv_codec.dart` | RFC-4180 reader; auto-detects `,` `;` or tab; handles quotes, embedded newlines, BOM, CRLF. |
| Parser | `lib/features/import/data/workout_csv_parser.dart` | Detects source app, maps each format to `ParsedSession`s, converts to kg. |
| Matcher | `lib/features/import/data/exercise_matcher.dart` | Resolves an exercise name to a catalog id (exact + punctuation-normalised, equipment preserved). |
| Service | `lib/features/import/data/workout_import_service.dart` | Builds custom exercises, dedups, writes each session in a transaction, runs PR detection. |
| UI | `lib/features/import/presentation/screens/import_screen.dart` | Pick → preview → confirm → progress → result. |

## Formats handled

| | Hevy | Strong |
| --- | --- | --- |
| Delimiter | comma (tab for Pro) | semicolon (comma variant tolerated) |
| Unit | in the header name (`weight_kg` / `weight_lbs`) | `Weight Unit` column, or **assumed** (user is prompted) when absent |
| Set index | 0-based `set_index` | 1-based `Set Order` (`w` = warmup) |
| Set type | explicit `set_type` | inferred (warmup from `Set Order`/`Notes`) |
| Date | `30 Jun 2025, 19:56` | `2025-06-30 19:56:00` |
| End time | `end_time` column | derived from `Workout Duration` |

## Guarantees

- **Kilograms only.** All weights are converted at parse time; the user's
  display-unit preference is never changed.
- **Lossless.** Exercises with no catalog match are created as custom
  exercises (and reported), never dropped.
- **Idempotent.** Sessions are de-duplicated by minute-resolution start time +
  name, so re-importing the same file is a no-op.
- **Correct PRs.** Sessions import oldest-first, then `detectAndMarkPrs` runs
  per session, so historical bests are attributed correctly.

## Tests

`test/import/` — CSV tokeniser, both parsers (against real sample exports),
the matcher, and an in-memory-DB service integration test. The Hevy and Strong
fixtures encode the *same* two workouts, so both must import to the same
kilogram volume (≈ 9483 kg) — a built-in cross-check.
