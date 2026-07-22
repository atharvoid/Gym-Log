# GymLog Workout Import & Export Specification

> **Status:** Active / Production Authoritative
> **Owner:** Core Engineering
> **Last verified SHA:** `aef17b09305ebf0455244c3c04159577f37e0a84`
> **Last reviewed date:** 2026-07-22
> **Next review date:** 2026-10-22

Lets users export their training data losslessly and import training history into GymLog from **GymLog (v1/v2)**, **Hevy**, or **Strong**. Free for everyone — it's the user's own data.

Entry points:
- **Settings → Data → Export workouts**
- **Settings → Data → Import workouts** (`/settings/import`)

## Pipeline

```
file → CsvCodec → WorkoutCsvParser → ExerciseMatcher → WorkoutImportService → Drift
        (tokenise)  (map to sessions)  (name → id)       (dedup + persist + PRs)
```

| Layer | File | Responsibility |
| --- | --- | --- |
| Tokeniser | `lib/features/import/data/csv_codec.dart` | RFC-4180 reader; auto-detects `,` `;` or tab; handles quotes, embedded newlines, BOM, CRLF. |
| Parser | `lib/features/import/data/workout_csv_parser.dart` | Detects source app/schema, maps each format to `ParsedSession`s, converts units. |
| Matcher | `lib/features/import/data/exercise_matcher.dart` | Resolves exercise name & measurement type to catalog entry or custom exercise. |
| Service | `lib/features/import/data/workout_import_service.dart` | Builds custom exercises, dedups, writes sessions in transaction, runs PR detection. |
| Exporter | `lib/core/services/workout_export_service.dart` | Exports lossless GymLog v2 CSV format (`gymlog_schema_version = 2`). |
| UI | `lib/features/import/presentation/screens/import_screen.dart` | Pick → preview → confirm → progress → result. |

## Formats handled

| | GymLog v2 | Hevy | Strong |
| --- | --- | --- | --- |
| Schema Version | `gymlog_schema_version = 2` | N/A | N/A |
| Delimiter | comma | comma (tab for Pro) | semicolon (comma variant tolerated) |
| Unit | `weight_kg` (kg, dot decimal) | in header (`weight_kg` / `weight_lbs`) | `Weight Unit` column, or **assumed** |
| Set index | 0-based `set_index` | 0-based `set_index` | 1-based `Set Order` (`w` = warmup) |
| Set type | explicit `set_type` | explicit `set_type` | inferred (warmup from `Set Order`/`Notes`) |
| Metrics | metric-aware (`weight_kg`, `reps`, `duration_seconds`, `distance_meters`, `measurement_type`) | `weight_kg`, `reps` | `weight`, `reps`, `seconds`, `distance` |
| Timestamps | ISO-8601 | `30 Jun 2025, 19:56` | `2025-06-30 19:56:00` |
| PR Tracking | `is_pr`, `pr_type`, `estimated_1rm` | N/A | N/A |

## Round-Trip Invariant

`decode(encode(workout))` preserves:
- exercise order and set order
- measurement types (`weight_and_reps`, `reps_only`, `duration`, `distance`)
- null vs populated metrics without fake zero substitution
- ISO-8601 timestamps & completed times
- set types (`normal`, `warmup`, `dropset`, `failure`)
- PR status and PR types (`estimated_1rm`, `max_weight`, `max_reps`, `max_duration`, `max_distance`, `best_pace`, `none`)
- session & exercise notes via RFC-4180 escaping

## Guarantees

- **Kilograms only.** All weights are converted at parse time; display-unit preference is preserved.
- **Lossless.** Exercises with no catalog match are created as custom exercises (and reported), never dropped.
- **Idempotent.** Sessions are de-duplicated by minute-resolution start time + name.
- **Backward Compatible.** GymLog v1 and competitor CSVs remain fully readable.
- **Forward Guard.** Schema versions greater than 2 throw an explicit error.

## Tests

`test/import/` & `test/workout_export_test.dart` — CSV tokeniser, parsers, exporter, matcher, round-trip specs, and in-memory DB integration tests.
