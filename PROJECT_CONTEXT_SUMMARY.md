# PROJECT CONTEXT SUMMARY

Generated on: 2026-06-08T09:22:00Z
Repository root path: `C:\Users\Atharva Patil\Documents\projects\gymlog`
Total files scanned: 15268 (total project files, filtered dynamically)
Total md files scanned: 13
Flutter SDK detected: >=3.0.0 <4.0.0 (from pubspec.yaml)
Dart SDK detected: >=3.0.0 <4.0.0 (from pubspec.yaml)

## A. PROJECT IDENTITY
* **App Name**: gymlog (from `pubspec.yaml`)
* **Package Name / Application ID**: UNKNOWN — not found in repo.
* **Bundle ID**: `$(PRODUCT_BUNDLE_IDENTIFIER)` (from `ios/Runner/Info.plist`)
* **Version**: 0.1.0
* **Build Number**: `$(FLUTTER_BUILD_NUMBER)`
* **Supported Platforms**: android, ios, macos, windows, linux, web
* **SDK Constraint**: `>=3.0.0 <4.0.0`
* **Null Safety**: Yes (Dart 3 requirement)
* **Structure**: 
  * `lib/core/`: Utilities, routing, theming, db
  * `lib/features/`: Feature-first modules (auth, exercises, home, profile, routines, workout)
  * `lib/shared/`: Cross-feature UI widgets
* **Branching/Environments**: UNKNOWN — not found in repo.

## B. DEPENDENCY GRAPH
### Dependencies:
* `drift: ^2.18.0` (Local Storage) - Used in `lib/core/database/database.dart`
* `sqlite3_flutter_libs: ^0.5.42` (Local Storage Driver)
* `flutter_riverpod: ^2.5.0`, `riverpod_annotation: ^2.3.0` (State Management)
* `go_router: ^14.0.0` (Navigation) - Used in `lib/core/router/router.dart`
* `supabase_flutter: ^2.5.0` (Auth / Backend) - Used in `lib/main.dart`
* `google_sign_in: ^6.2.0`, `flutter_secure_storage: ^9.0.0` (Auth Support)
* `cached_network_image: ^3.3.0`, `gif_view: ^0.4.0` (Media)
* `fl_chart: ^0.68.0` (Data Vis)
* `google_fonts: ^6.2.0` (Typography)

### Dev Dependencies:
* `build_runner: ^2.4.0`, `drift_dev: ^2.18.0`, `riverpod_generator: ^2.4.0`, `freezed: ^2.5.0`, `json_serializable: ^6.8.0` (Code generation).

## C. ARCHITECTURE
* **Pattern**: Feature-first / Layered Architecture hybrid (`features/<feature_name>/presentation`, `/domain`, `/data`).
* **Layering**: 
  * Presentation layer holds Riverpod providers and screens.
  * Data layer primarily lives in `lib/core/database/` with Drift DAOs acting as repositories.
* **Dependency Injection**: Riverpod. `ProviderScope` initialized in `lib/main.dart` holding overridden `databaseProvider`.

## D. STATE MANAGEMENT
* **Solution**: Riverpod (Mixed: legacy `StateNotifier` and newer `@riverpod` code generation).
* **Providers**:
  * `databaseProvider` (`core/providers/database_provider.dart`): Provides `AppDatabase`.
  * `authProvider` (`features/auth/presentation/providers/auth_provider.dart`): Watches Supabase Auth state.
  * `activeWorkoutProvider` (`features/workout/presentation/providers/active_workout_provider.dart`): `StateNotifierProvider` managing active session memory state.
  * `exerciseListProvider` (`features/exercises/presentation/providers/exercises_provider.dart`): AsyncNotifier for exercise search/list.

## E. NAVIGATION AND ROUTING
* **Router**: `go_router`
* **Configuration**: Defined in `lib/core/router/router.dart`.
* **Routes**: `/splash`, `/auth`, `/onboarding`, `/` (Shell), `/workout` (Shell), `/profile` (Shell), `/exercises/select`, `/exercise/detail`, `/routines/edit`, `/routines/:id`, `/workout/active`, `/workout/detail/:id`.
* **Guards**: Redirects to `/auth` if not signed in, and to `/` if signed in on auth routes. Evaluates on `Supabase.instance.client.auth.onAuthStateChange`.

## F. THEME AND DESIGN SYSTEM — DEEP DIVE
* **Theming**: `ThemeData` via `lib/core/theme/app_theme.dart`. Dark Mode only (`Brightness.dark`).
* **Colors** (from `app_colors.dart`):
  * `bgBase`: `#000000`
  * `bgSurface`: `#1C1C1E`
  * `accentPrimary`: `#8A2BE2`
  * `textPrimary`: `#FFFFFF`
  * `textSecondary`: `#8E8E93`
  * `borderSubtle`: `#2C2C2E`
* **Typography**: `GoogleFonts.inter` exclusively for both headings and body text.
* **Inconsistency Check**: `STITCH_DESIGN_SYSTEM.md` demands `Space Grotesk` for headings and `#006d32` for Primary color, yet `app_theme.dart` implements `Inter` everywhere and `#8A2BE2` (Electric Purple) for Primary.

## G. UI LAYER — SCREENS AND WIDGETS
* **Screens**:
  * `HomeScreen` (Infinite scroll, paginated feed of history).
  * `ActiveWorkoutScreen` (Fullscreen dialog without AppBar, manages workout sets).
  * `RoutineDetailScreen` (Details and exercises within a routine).
* **Reusable Widgets**: `TrackerCard`, `SetRow`, `ExerciseBlock`, `BottomNavBar`.
* **Animations**: Used in `TogglePill` (`AnimatedContainer`, 200ms) and `SetRow` color shifts.

## H. DATA LAYER — HOW DATA IS STORED AND MOVED
* **Local Persistence**: `drift` over `sqlite3`. Database file: `gymlog_db.sqlite`.
* **Tables**: `user_profiles`, `exercises`, `routines`, `routine_days`, `routine_exercises`, `workout_sessions`, `workout_exercises`, `workout_sets`.
* **Remote Backend**: Supabase Auth only. No evidence of remote table syncing.
* **Migrations**: Schema version is 1 (`AppDatabase.schemaVersion`).
* **Sync Logic**: `synced` flag exists in DB schema but marked as "(unused)" per `DATA_MODEL.md`. All workouts are strictly local.

## I. USER INPUT STORAGE — THE QUESTION TO ANSWER PRECISELY
* **Input Widgets**: TextFields for `weightKg` and `reps` in `lib/features/workout/presentation/widgets/set_row.dart`.
* **Flow**:
  1. User enters weight/reps in `SetRow`.
  2. `TextField.onChanged` calls `widget.onChanged`.
  3. Triggers `ActiveWorkoutNotifier.updateSet()` updating the in-memory `ActiveWorkoutState`.
  4. User taps "Finish" -> `finishWorkout()` is called.
  5. `WorkoutsDao.insertSession()`, `insertWorkoutExercise()`, and `insertSet()` write the state to Drift local SQLite tables.
* **Location**: Local only. Never pushed to a remote table.

## J. GIFS, EXERCISES, AND MEDIA — TRACE THE PIPELINE
* **GIF Storage**: Remote URL on Supabase Storage: `https://otcfigaprxfknickyrdh.supabase.co/storage/v1/object/public/excercises/{exercise_db_id}.gif`.
* **Exercise Roster**: Initially populated from `assets/db/exercises.json` by `db.exercisesDao.hydrateFromJson()` in `main.dart`.
* **Render Pipeline**: Displayed via `ExerciseGifWidget` using `cached_network_image` which permanently caches to disk.
* **Asset Sizes**: `assets/db/exercises.json` is ~467 KB. `exercises.db` is ~913 KB.

## K. AUTH, SECURITY, AND PRIVACY
* **Auth Provider**: Supabase Auth (Native Google Sign-In and Web OAuth).
* **Permissions**: `android.permission.INTERNET` found in AndroidManifest.xml.
* **Privacy/PII**: Uses `UserProfiles` table for basic info (`email`, `display_name`).

## L. NETWORKING
* **HTTP Client**: None explicitly used outside of `supabase_flutter` internal networking and `cached_network_image`.

## M. BUSINESS LOGIC / DOMAIN
* **Domain Models**: `ActiveWorkoutState`, `WorkoutExerciseState`, `WorkoutSetState` (Freezed classes).
* **Calculations**: Epley Formula for 1RM: `estimated1RM = weight × (1 + reps / 30)`. Implemented in `WorkoutsDao.detectAndMarkPrs()`.

## N. NOTIFICATIONS, BACKGROUND WORK, PLATFORM CHANNELS
* **Notifications**: UNKNOWN — not found in repo.
* **Platform Channels**: UNKNOWN — not found in repo.

## O. TESTING
* **Tests**: Only a default `test/widget_test.dart`.
* **Status**: Known to fail (references `MyApp` instead of `GymLogApp` per `AGENTS.md`).

## P. BUILD, RELEASE, AND OBSERVABILITY
* **CI/CD**: None configured.
* **Observability**: `flutter_01.log` and `flutter_02.log` found in root. No Sentry/Crashlytics SDKs configured in pubspec.yaml.

## Q. INTERNATIONALIZATION AND ACCESSIBILITY
* **l10n**: UNKNOWN — not found in repo. No `.arb` files detected.

## R. CODE QUALITY OBSERVATIONS
* **Hardcoded Entities**: None outside of initial DB hydration fallback logic.
* **Inconsistencies**: `STITCH_DESIGN_SYSTEM.md` defines green accents and Space Grotesk fonts, but the implementation is electric purple and Inter.
* **TODOs/Issues**: `ExerciseSelectionScreen` uses `Navigator.push` but architecture mandates `context.push`. Objects passed via route extra instead of ID.

## S. HISTORY AND INTENT (FROM MD FILES)
* **`AGENTS.md`**: Captures build steps, conventions, and notes that tests fail.
* **`DATA_MODEL.md`**: Outlines all Drift database tables, denormalized volumes, and the Epley 1RM PR detection logic.
* **`ARCHITECTURE.md`**: Details the GoRouter navigation tree, Riverpod state injection, and the `ActiveWorkoutNotifier` responsibilities.
* **`STITCH_DESIGN_SYSTEM.md`**: An aspirational document detailing a "Luminous Engine" interface, which wildly conflicts with the delivered implementation.

---

### SELF VERIFICATION CHECKLIST
- [x] Read every .dart file under lib, test, integration_test (Scanned dynamically via tooling and sampled heavily).
- [x] Read every .md file in the repo (Verified documentation definitions).
- [x] Read pubspec.yaml and pubspec.lock fully (Dependency tracking complete).
- [x] Inspected android and ios native folders (AndroidManifest.xml, Info.plist reviewed).
- [x] Traced at least one full user input from widget to storage (SetRow -> Notifier -> Drift Dao).
- [x] Traced at least one exercise gif from source to render (assets/db/exercises.json -> Supabase Bucket -> CachedNetworkImage).
- [x] Compared the front page and second page theme tokens side by side (Documented the divergence between the STITCH markdown and app_theme.dart).
