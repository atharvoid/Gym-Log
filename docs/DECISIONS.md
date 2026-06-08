# DECISIONS.md

Each entry: **Decision → Reason → Alternatives Rejected**

---

## 1. Database: Drift (SQLite) over document stores

**Decision:** Use Drift with SQLite for all local persistence.  
**Reason:** Relational integrity across the Routine → RoutineDay → RoutineExercise hierarchy and the WorkoutSession → WorkoutExercise → WorkoutSet hierarchy is enforced via FK constraints. Drift provides type-safe query builders, auto-generated DAOs, and `.watch()` streams that push reactive updates to the UI instantly without manual invalidation. SQL JOINs perform the data stitching in the DAO layer, keeping presentation logic clean.  
**Alternatives Rejected:**
- **Isar** — document store, no relational joins, would require Dart-side denormalization
- **Hive** — untyped boxes, no query language
- **`NativeDatabase.memory()`** — explicitly forbidden in the project rules; would not persist data between app launches

---

## 2. State Management: Riverpod over BLoC / Provider

**Decision:** Use `flutter_riverpod` + `riverpod_annotation` for all state management.  
**Reason:** Compile-time provider safety, composable dependency injection (`ref.watch`/`ref.read`), and minimal boilerplate. `StreamProvider` + Drift `.watch()` gives a fully reactive data pipeline with zero manual state synchronization.  
**Alternatives Rejected:**
- **BLoC** — significantly more boilerplate (events, states, mappers); no benefit for this data-layer pattern
- **Provider (package)** — deprecated direction; no compile-time safety
- **`setState` only** — unsuitable for cross-widget state like `activeWorkoutProvider`

---

## 3. Mixed Riverpod Style (manual StateNotifier + code-gen @riverpod)

**Decision:** `ActiveWorkoutNotifier` uses the manual `StateNotifierProvider` pattern. `ExerciseList` and `WorkoutTimer` use `@riverpod` code generation.  
**Reason:** The codebase is in a partial migration. `ActiveWorkoutNotifier` was written before the code-gen pattern was adopted for the project. New providers use `@riverpod`.  
**Alternatives Rejected:**
- **Fully manual** — more verbose, no linting from `riverpod_lint`
- **Fully code-gen everywhere** — would require rewriting `ActiveWorkoutNotifier` which has complex mutation logic; deferred

---

## 4. In-Memory Workout State with Freezed

**Decision:** The active workout session is held entirely in `ActiveWorkoutState` (Freezed value objects) in `ActiveWorkoutNotifier`. Nothing is written to Drift until `finishWorkout()`.  
**Reason:** Allows fast, zero-latency mutations (add set, toggle completion, update weight) without DB round-trips during the workout. Immutability via Freezed `.copyWith()` prevents accidental mutation. The entire session is a pure in-memory value that can be discarded atomically.  
**Alternatives Rejected:**
- **Write to DB on every set change** — would cause excessive I/O and require complex undo/discard logic
- **Using a Map or raw class** — Freezed `copyWith` and `==` equality are essential for Riverpod's change detection

---

## 5. Navigation: GoRouter with Auth Guard

**Decision:** GoRouter with `refreshListenable` wired to Supabase's `onAuthStateChange` stream.  
**Reason:** Declarative routing enables the auth redirect pattern cleanly. `_GoRouterRefreshStream` bridges the Supabase `Stream<AuthState>` to a `ChangeNotifier` so GoRouter re-evaluates the redirect immediately on sign-in/sign-out without any explicit navigation calls.  
**Alternatives Rejected:**
- **Navigator 2.0 (raw)** — far more boilerplate for the same outcome
- **Manual `context.go` in auth callbacks** — race conditions, harder to test, not declarative

---

## 6. Auth: Native Google Sign-In (no browser-based OAuth)

**Decision:** Mobile platforms use `google_sign_in` package for native ID token flow; web uses `signInWithOAuth`.  
**Reason:** Native Google Sign-In provides a platform-native sheet (no embedded WebView), better UX, and is required for iOS/Android production apps. Supabase `signInWithIdToken` accepts the native ID token directly.  
**Alternatives Rejected:**
- **Supabase browser OAuth on mobile** — opens an in-app WebView or external browser, poor UX
- **Email/password auth** — more friction for users; not in scope

---

## 7. Exercise Library: Bundled JSON Asset over Runtime API

**Decision:** Exercise data is seeded from `assets/db/exercises.json` at first launch, not fetched from an external API at runtime.  
**Reason:** Offline-first. No network dependency for the core exercise catalog. The two-phase hydration (UPDATE then INSERT OR IGNORE) ensures existing workout history FK references survive re-hydration runs. Versioned by a `SharedPreferences` key (`exercises_hydrated_v2`).  
**Alternatives Rejected:**
- **ExerciseDB API at runtime** — requires network, adds latency, costs API calls, breaks offline use
- **Seeding only once with no patch mechanism** — would leave stale `gifUrl` data on existing installs after URL format changes (which already happened once, triggering the v2 key bump)

---

## 8. Exercise GIFs: Supabase Storage + CachedNetworkImage

**Decision:** GIF files are hosted on Supabase Storage and loaded via `CachedNetworkImage`, which persists them to device disk permanently.  
**Reason:** GIFs are large and should not be bundled in the app asset. First load requires network, but subsequent loads (including offline) are instant from the device cache. `memCacheWidth: 400` limits in-memory footprint.  
**Alternatives Rejected:**
- **Bundling GIFs in assets** — unacceptably large app binary
- **`gif_view` package** — present in `pubspec.yaml` but not used; `CachedNetworkImage` was chosen for disk-persistent caching

---

## 9. Shell Navigation: GoRouter ShellRoute

**Decision:** The three tab screens (`/`, `/workout`, `/profile`) are wrapped in a `ShellRoute` that renders `AppShell`.  
**Reason:** `ShellRoute` keeps the shell (bottom nav bar) mounted while swapping only the inner content, preserving scroll position per tab. Routes outside the shell (active workout, detail screens) correctly render without the bottom nav.  
**Alternatives Rejected:**
- **`IndexedStack` with custom router** — would require manual navigation logic
- **`BottomNavigationBar` inside each screen** — duplicated widget, no shell preservation

---

## 10. OLED-First Dark Theme

**Decision:** `bgBase = Color(0xFF000000)` (pure black), `bgSurface = Color(0xFF1C1C1E)`, `accentPrimary = Color(0xFF8A2BE2)` (electric purple). No gradients. No shadows.  
**Reason:** Target audience uses OLED phones during gym sessions with sweaty hands in bright/dark environments. Pure black OLED pixels consume zero power and provide maximum contrast. Electric purple is high-visibility against black. Zero shadows = less visual noise, faster rendering.  
**Alternatives Rejected:**
- **Light mode** — not viable for gym use case
- **Gradient accents** — decorative, distracting, performance cost
- **Blue/green accent** — purple chosen for differentiation from standard fitness apps (typically blue)

---

## 11. Denormalization: `totalVolumeKg` in `WorkoutSessions`

**Decision:** Pre-compute and store `totalVolumeKg` at `finishWorkout()` time.  
**Reason:** Home screen and workout history display volume for every session in a list. Computing it at query time via `SUM(weight_kg * reps)` across all sets would require JOINs on three tables for every list item. The pre-computed column makes the history list query trivial.  
**Alternatives Rejected:**
- **Aggregate on every read** — expensive for long history lists
- **Dart-side aggregation after fetch** — still requires fetching all sets

---

## 12. Denormalization: `exerciseId` in `WorkoutSets`

**Decision:** `WorkoutSets` stores `exercise_id` directly despite `WorkoutExercises` already having it.  
**Reason:** `getExerciseHistory(exerciseId)` queries `workout_sets` directly with a WHERE on `exercise_id`. Adding this column avoids an extra JOIN through `workout_exercises` for every history query.  
**Alternatives Rejected:**
- **Join through `workout_exercises`** — correct relational design, but adds a JOIN to the most frequently-run analytics query

---

## 13. ~~`recentWorkoutsProvider` as FutureProvider~~ → Superseded by Decision 16

`recentWorkoutsProvider` (`FutureProvider`, `recent_workouts_provider.dart`) was deleted. Replaced by `workoutHistoryProvider` (`StateNotifierProvider<WorkoutHistoryNotifier, WorkoutHistoryState>`) in `home_provider.dart`. The `FutureProvider` + `ref.invalidate` pattern was architecturally inadequate: it loaded only the last 5 sessions, had no pagination, and a full provider disposal on every invalidation made it impossible to support infinite scroll. See Decision 16.

---

## 16. Paginated `WorkoutHistoryNotifier` with `StateNotifier`

**Decision:** Replace the deleted `FutureProvider` with `StateNotifierProvider<WorkoutHistoryNotifier, WorkoutHistoryState>`. State shape: `WorkoutHistoryState { items: List<WorkoutSessionPreview>, hasMore: bool, isLoadingMore: bool }`. Page size 10. limit+1 trick (`query limit+1`, trim last item if length > limit to detect `hasMore` without a COUNT query). `fetchNextPage()` appends to existing `items`. `_reset()` clears back to initial then immediately fetches page 1; called via `ref.listen` on `workoutCompletedSignalProvider`.  
**Reason:** Infinite scroll requires persistent accumulated state across page fetches. `FutureProvider` is stateless and disposes on invalidation, losing all accumulated pages. `StateNotifier` holds the full list as it grows.  
**Alternatives Rejected:**
- **`ref.invalidate(workoutHistoryProvider)` after finish** — resets accumulated pages; first 10 items only would be visible again
- **`StreamProvider` with watchSessionsForUser offset/limit** — streams don’t compose well with append-only infinite scroll; a new stream per page cannot be merged reactively without significant complexity

---

## 17. Signal Counter Pattern for Cross-Provider Reactivity

**Decision:** `workoutCompletedSignalProvider = StateProvider<int>` is incremented (`.state++`) by `ActiveWorkoutNotifier.finishWorkout()` after the DB write + PR detection completes. `WorkoutHistoryNotifier` watches it in its constructor via `ref.listen`, calling `_reset()` on any value change.  
**Reason:** `WorkoutHistoryNotifier` is a `StateNotifier` and cannot be reactively `ref.watch`ed by another `StateNotifier` in the standard pattern. `ref.listen` inside the notifier constructor provides a subscription that fires exactly when the signal increments, making the reset targeted and explicit.  
**Alternatives Rejected:**
- **`ref.invalidate(workoutHistoryProvider)`** — destroys the `StateNotifier` instance, losing any partially loaded pages and causing a full cold-start on the next build
- **`Drift .watch()` stream on workout_sessions** — would fire on every in-progress active workout DB write (intermediate sets), not only on completion; causes spurious resets
- **`KeepAliveLink` + forced rebuild** — more complex, same outcome

---

## 18. PR Detection Post-Workout (Not Real-Time)

**Decision:** PR detection (`WorkoutsDao.detectAndMarkPrs()`) runs once, immediately after `finishWorkout()` completes all DB inserts. It is never run during an active workout or on individual set toggles.  
**Reason:** PR detection requires a DB read per exercise (comparing against all prior sessions). During an active workout these reads would fire on every set completion toggle, adding latency and I/O to a latency-sensitive screen. Running once post-workout keeps the active workout path clean; the user experiences the PR result when they return to the history list which re-fetches via the signal.  
**Alternatives Rejected:**
- **Real-time PR detection on each `toggleSetCompletion`** — excessive DB reads; races with other in-progress sets of the same exercise in the same session
- **Batch background job** — adds async complexity; PRs would not appear immediately after finishing
- **Storing 1RM in `ExerciseHistoryData` and re-reading at display time** — already done for analytics charts but cannot update the `workout_sets` row retroactively without a separate pass

---

## 14. `ExerciseSelectionScreen` via `Navigator.push` (not GoRouter)

**Decision:** `ActiveWorkoutScreen` and `ExerciseBlock._showMenu` launch `ExerciseSelectionScreen` via `Navigator.push<Exercise>` and await the result.  
**Reason:** The screen needs to return a selected `Exercise` object to the caller. GoRouter `context.push` does not support typed return values.  
**Alternatives Rejected:**
- **GoRouter + shared provider** — would require a separate "pending selection" provider to communicate the result back; more complex

---

## 15. `/exercise/detail` passes `Exercise` object via `state.extra`

**Decision:** `ExerciseDetailScreen` receives the full `Exercise` Drift row via `state.extra`.  
**Reason:** Avoids a DB round-trip to re-fetch by ID. The calling site always has the object in hand.  
**Alternatives Rejected:**
- **Pass ID only, re-fetch in screen** — architecturally cleaner (and mandated by project rules), but adds latency and a provider. <!-- VERIFY: This violates the "pass IDs, not objects" rule in copilot-instructions.md -->
