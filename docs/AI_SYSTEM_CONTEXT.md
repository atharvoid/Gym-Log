# 🧠 GYMLOG: MASTER AI CONTEXT FILE

> **Notice to AI Assistants:** You are reading the ultimate source of truth for the GymLog project. This document contains the exact technical specifications, architectural boundaries, design philosophies, and agentic workflows you must adhere to. Do not deviate from these rules. You are expected to operate as a 150-IQ senior engineer and system architect.

## 1. Project Overview & Tech Stack
- **Name:** GymLog (v0.1.0)
- **Framework:** Flutter / Dart (Cross-platform mobile)
- **State Management:** Riverpod (Mixed usage: manual `StateNotifier` for complex state, and `@riverpod` code generation for standard async operations)
- **Local Database:** Drift (SQLite) with 8 tables and 4 DAOs.
- **Backend / Auth:** Supabase (Google Sign-In, native + web OAuth). Credentials live in a git-ignored `.env` file loaded as a Flutter asset.
- **Routing:** GoRouter (with Supabase auth stream refresh to handle redirect logic)
- **Code Generation:** `build_runner` (used heavily for Drift, Riverpod, Freezed, JSON serializable). Always run `flutter pub run build_runner build --delete-conflicting-outputs` after schema/state changes.

## 2. Design Philosophy: "The Luminous Engine"
You are strictly bound to the **Stitch Design System**. This is a high-end, futuristic, editorial experience. It is not a standard Material template.
- **The "No-Line" Rule:** Do not use 1px solid borders to define sections or containers. Layout boundaries must be established solely through background color shifts (e.g., placing `bgSurface` on `bgBase`) or tonal transitions.
- **Ghost Borders (Fallback):** If a container absolutely requires a boundary for accessibility, use `outline-variant` at 10-20% opacity. This creates a "breath" of a line rather than a hard edge.
- **Glassmorphism:** Use semi-transparent `bgSurface` with `backdrop-blur` (12-20px) for floating elements (nav bars, overlays).
- **Typography:** 
  - `Space Grotesk` (futuristic/engineered) for high-impact numerical data, display, and headlines.
  - `Inter` (clean, minimalist) for all functional reading, body, titles, and navigation.
- **Elevation via Depth:** Achieved by tonal stacking (e.g. `surface-container-lowest` over `surface-container-low`). Ambient shadows (extra diffused, tinted with `on-surface`, 4-8% opacity, 24-40px blur) are reserved only for floating modals. NO pure black drop shadows.
- **Status & Colors:** High contrast for chips (`primary_fixed` or `error_container` backgrounds). The primary palette uses a pure OLED-black background with electric purple accents.

## 3. Architecture & Code Organization
Folder structure is strictly feature-based:
- `lib/core/`: Infrastructure (Drift DB config, router, theme tokens, formatters, pure utility functions).
- `lib/features/<feature>/`: Self-contained feature slices (`auth`, `exercises`, `home`, `profile`, `routines`, `workout`).
  - Contains `data/`, `domain/` (only if Freezed state models exist, like in `workout`), and `presentation/` (`providers/`, `screens/`, `widgets/`).
- `lib/shared/`: Shared app-level widgets (`AppShell`, `BottomNavBar`, atom-level `ui/` components like `PrimaryButton`, `TrackerCard`).

**Dependency Rules:** 
- DAOs live in `core/database/daos/`. Access them via `databaseProvider` mapped through Riverpod.
- Never import a feature's internal widget/provider from another feature directly. Use `core` providers for cross-feature communication.

## 4. State Management (Riverpod)
- **UI State Providers:** Async data streams use `.when(data: loading: error:)`. Standard loading is a centered `CircularProgressIndicator(color: AppColors.accentPrimary)`. Error is a `TrackerCard` with `AppColors.error` text.
- **Active Workout (`activeWorkoutProvider`):** Manual `StateNotifierProvider`. Holds the ENTIRE workout session in memory (using Freezed `ActiveWorkoutState`, `WorkoutExerciseState`, `WorkoutSetState`).
- **Database Write Transaction:** `finishWorkout()` performs a single massive transaction to insert `WorkoutSession`, `WorkoutExercises`, and `WorkoutSets`. 
- **PR Detection:** After saving, `WorkoutsDao.detectAndMarkPrs()` tags Personal Records (PRs) using the Epley 1RM formula (`weight * (1 + reps/30)`).
- **Pagination Pattern:** `workoutHistoryProvider` paginates with page size 10, utilizing a `limit + 1` query trick to set `hasMore`.

## 5. Data Model (Drift / SQLite)
- **Tables (8):** 
  1. `user_profiles` (id is Supabase UUID)
  2. `exercises` (seeded from `assets/db/exercises.json`)
  3. `routines` 
  4. `routine_days` 
  5. `routine_exercises`
  6. `workout_sessions` (tracks total_volume_kg)
  7. `workout_exercises`
  8. `workout_sets` (tracks normal/warmup/dropset/failure, reps, weight_kg, is_pr, estimated_1rm).
- **Hydration DAOs:** Complex JOINs are flattened into plain Dart classes via DAOs (e.g., `HydratedWorkout`, `HydratedRoutine`, `WorkoutSessionPreview`) instead of raw Drift classes.
- **Exercise GIFs:** Hosted on Supabase Storage. URL pattern: `$_kGifBase/{exercise_db_id}.gif`. Rendered via `ExerciseGifWidget` (cached).

## 6. Coding Conventions & UI Patterns
- **Files:** `snake_case.dart` (e.g., `home_screen.dart`, `workouts_dao.dart`).
- **Classes:** `PascalCase`. Screens append `Screen`. DAOs append `Dao`.
- **Riverpod:** Providers named `camelCaseProvider`. Code-gen classes start with `@riverpod`.
- **Screen Structure Standard:** 
  ```dart
  Scaffold(
    backgroundColor: AppColors.bgBase, // ALWAYS explicitly set
    appBar: AppBar(
      title: Text('Title', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 28)),
      // ...
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120), // 120px to clear AppShell BottomNavBar
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [...]),
    ),
  )
  ```
- **Context Menus:** ALWAYS use `showModalBottomSheet` for 3-dot menus. NEVER use `PopupMenuButton`. Bottom sheets must have `backgroundColor: Colors.transparent`, a rounded `bgSurface` inner container, and a 36x4px top drag handle.

## 7. AI Agent Workflows & "Claude Flow"
If you are operating as part of an agentic swarm (e.g. `Ruflo` / Claude Code configuration):
- **Coordination:** Coordinate strictly via `SendMessage` pipelines or fan-out patterns. NEVER poll for status. When an agent finishes, it must message the next agent in the pipeline.
- **Agent Roles:** Assume your designated role (e.g., `architect`, `coder`, `tester`). Do what has been asked, nothing more.
- **Temporary Files:** NEVER save temporary, working, or test-scratchpad files to the repository root. Always use `/scripts`, `/docs`, `/tests`, etc.
- **Sanity Checks:** Validate input at system boundaries. ALWAYS run tests and run the analyzer (`flutter analyze`) after code changes. 

---
**End of Context.** You possess the knowledge to execute any feature addition, refactor, or debugging task perfectly aligned with the project's vision. Now, begin your work.
