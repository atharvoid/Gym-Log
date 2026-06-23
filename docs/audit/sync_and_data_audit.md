# GymLog Sync & Data Architecture Audit

---

## 1. Local Database Schema

### 1.1 AppDatabase (schemaVersion: 2)

Defined in [database.dart](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/lib/core/database/database.dart):
```dart
@DriftDatabase(
  tables: [
    UserProfiles,
    Exercises,
    Routines,
    RoutineDays,
    RoutineExercises,
    WorkoutSessions,
    WorkoutExercises,
    WorkoutSets,
    SyncOutbox,
  ],
  daos: [UserDao, ExercisesDao, WorkoutsDao, RoutinesDao, SyncOutboxDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          // v1 → v2: add the local sync queue. This ONLY creates a brand-new
          // table — no existing table is altered, so user data is untouched
          // and the upgrade is non-destructive.
          if (from < 2) {
            await m.createTable(syncOutbox);
          }
        },
        beforeOpen: (details) async {
          // Enforce referential integrity. SQLite ships with foreign keys
          // OFF; without this, child rows silently outlive their parents.
          await customStatement('PRAGMA foreign_keys = ON');

          // Hot-path indexes (idempotent — schema files stay untouched).
          // Every list/feed/analytics query filters or joins on these.
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_we_session ON workout_exercises (session_id)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_we_exercise ON workout_exercises (exercise_id)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_ws_workout_exercise ON workout_sets (workout_exercise_id)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_ws_exercise ON workout_sets (exercise_id)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_sessions_user_started ON workout_sessions (user_id, started_at DESC)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_sessions_routine_started ON workout_sessions (routine_id, started_at DESC)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_re_day ON routine_exercises (routine_day_id)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_rd_routine ON routine_days (routine_id)');
          // Sync queue drains FIFO per user.
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_outbox_user_created ON sync_outbox (user_id, created_at_ms)');
        },
      );

  Future<void> wipeAllData() async {
    await transaction(() async {
      await delete(workoutSets).go();
      await delete(workoutExercises).go();
      await delete(workoutSessions).go();
      await delete(routineExercises).go();
      await delete(routineDays).go();
      await delete(routines).go();
      await delete(syncOutbox).go();
      await delete(exercises).go(); // catalog + user customs
      await delete(userProfiles).go();
    });
  }
}
```

### 1.2 Table Definitions

#### UserProfiles
Defined in [user_profiles_table.dart](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/lib/core/database/tables/user_profiles_table.dart):
```dart
@DataClassName('UserProfile')
class UserProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get email => text()();
  TextColumn get displayName => text()();
  BoolColumn get isPremium => boolean().withDefault(const Constant(false))();
  DateTimeColumn get premiumExpiry => dateTime().nullable()();
  TextColumn get weightUnit => text().withDefault(const Constant('kg'))();
  IntColumn get defaultRestSeconds => integer().withDefault(const Constant(90))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

#### Exercises
Defined in [exercises_table.dart](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/lib/core/database/tables/exercises_table.dart):
```dart
@DataClassName('Exercise')
class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get exerciseDbId => text().unique().nullable()();
  TextColumn get name => text()();
  TextColumn get bodyPart => text()();
  TextColumn get equipment => text()();
  TextColumn get target => text()();
  TextColumn get gifUrl => text().nullable()();
  TextColumn get secondaryMuscles => text().nullable()();
  TextColumn get instructions => text().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get seededAt => dateTime().nullable()();
}
```

#### Routines
Defined in [routines_table.dart](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/lib/core/database/tables/routines_table.dart):
```dart
@DataClassName('Routine')
class Routines extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

#### RoutineDays
Defined in [routine_days_table.dart](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/lib/core/database/tables/routine_days_table.dart):
```dart
@DataClassName('RoutineDay')
class RoutineDays extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get routineId => text().references(Routines, #id)();
  TextColumn get name => text()();
  IntColumn get orderIndex => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
```

#### RoutineExercises
Defined in [routine_exercises_table.dart](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/lib/core/database/tables/routine_exercises_table.dart):
```dart
@DataClassName('RoutineExercise')
class RoutineExercises extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get routineDayId => text().references(RoutineDays, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get orderIndex => integer()();
  IntColumn get defaultSets => integer().withDefault(const Constant(3))();
  IntColumn get defaultReps => integer().nullable()();
  RealColumn get defaultWeightKg => real().nullable()();
  IntColumn get restSeconds => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

#### WorkoutSessions, WorkoutExercises, WorkoutSets
Defined in [workouts_table.dart](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/lib/core/database/tables/workouts_table.dart):
```dart
@DataClassName('WorkoutSession')
class WorkoutSessions extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get userId => text()();
  TextColumn get routineId => text().nullable()();
  TextColumn get name => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  RealColumn get totalVolumeKg => real().withDefault(const Constant(0))();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WorkoutExercise')
class WorkoutExercises extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get sessionId => text().references(WorkoutSessions, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get orderIndex => integer()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WorkoutSet')
class WorkoutSets extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get workoutExerciseId => text().references(WorkoutExercises, #id)();
  IntColumn get exerciseId => integer()();
  IntColumn get orderIndex => integer()();
  TextColumn get setType => text().withDefault(const Constant('normal'))();
  RealColumn get weightKg => real()();
  IntColumn get reps => integer()();
  RealColumn get rpe => real().nullable()();
  BoolColumn get isPr => boolean().withDefault(const Constant(false))();
  RealColumn get estimated1rm => real().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

#### SyncOutbox
Defined in [sync_outbox_table.dart](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/lib/core/database/tables/sync_outbox_table.dart):
```dart
@DataClassName('SyncOutboxRow')
class SyncOutbox extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()(); // 'session' | 'routine' | 'preferences'
  TextColumn get entityId => text()();
  TextColumn get userId => text()();
  TextColumn get op => text().withDefault(const Constant('upsert'))(); // 'upsert' | 'delete'
  TextColumn get payload => text().withDefault(const Constant(''))(); // gzip + base64 of entity JSON
  IntColumn get updatedAtMs => integer()();
  IntColumn get createdAtMs => integer()();
}
```

### 1.3 Data Access Objects (DAOs)

#### 1.3.1 UserDao
Defined in [user_dao.dart](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/lib/core/database/daos/user_dao.dart):
* `Future<UserProfile> getUser(String id)`
  * Query: `(select(userProfiles)..where((t) => t.id.equals(id))).getSingle()`
* `Future<void> insertUser(UserProfilesCompanion user)`
  * Query: `into(userProfiles).insert(user)`
* `Future<void> updateUser(UserProfilesCompanion user)`
  * Query: `(update(userProfiles)).replace(user)`
* `Future<void> deleteUser(String id)`
  * Query: `(delete(userProfiles)..where((t) => t.id.equals(id))).go()`
* `Future<void> upsertProfile({required String id, required String email, required String displayName})`
  * Query: Checks `getUserOrNull(id)`. If null, inserts profile row via `into(userProfiles).insert`. If exists, writes updates for `displayName` and `email` via `(update(userProfiles)..where((t) => t.id.equals(id))).write(...)`.
* `Future<UserProfile?> getUserOrNull(String id)`
  * Query: `(select(userProfiles)..where((t) => t.id.equals(id))).get()` (returns null if empty).
* `Stream<UserProfile?> watchUser(String id)`
  * Query: `(select(userProfiles)..where((t) => t.id.equals(id))).watchSingleOrNull()`
* `Future<void> setPremiumStatus(String id, {required bool isPremium, DateTime? premiumExpiry})`
  * Query: `(update(userProfiles)..where((t) => t.id.equals(id))).write(UserProfilesCompanion(isPremium: Value(isPremium), premiumExpiry: Value(premiumExpiry)))`
* `Future<void> setWeightUnit(String id, String unit)`
  * Query: `(update(userProfiles)..where((t) => t.id.equals(id))).write(UserProfilesCompanion(weightUnit: Value(unit)))`
* `Future<void> setDefaultRestSeconds(String id, int seconds)`
  * Query: `(update(userProfiles)..where((t) => t.id.equals(id))).write(UserProfilesCompanion(defaultRestSeconds: Value(seconds)))`

#### 1.3.2 ExercisesDao
Defined in [exercises_dao.dart](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/lib/core/database/daos/exercises_dao.dart):
* `Future<List<Exercise>> getAllExercises()`
  * Query: `select(exercises).get()`
* `Future<Exercise> getExerciseById(int id)`
  * Query: `(select(exercises)..where((t) => t.id.equals(id))).getSingle()`
* `Future<List<Exercise>> searchExercises(String query)`
  * Query: `(select(exercises)..where((t) => t.name.like('%$sanitized%'))..orderBy([(t) => OrderingTerm.asc(t.name)])).get()`
* `Future<bool> exerciseNameExists(String name)`
  * Query: `SELECT 1 FROM exercises WHERE LOWER(name) = LOWER(?) LIMIT 1`
* `Future<List<Exercise>> filterByBodyPart(String bodyPart)`
  * Query: `(select(exercises)..where((t) => t.bodyPart.equals(bodyPart))).get()`
* `Future<List<Exercise>> filterByEquipment(String equipment)`
  * Query: `(select(exercises)..where((t) => t.equipment.equals(equipment))).get()`
* `Future<int> getExerciseCount()`
  * Query: `selectOnly(exercises)..addColumns([exercises.id.count()])`
* `Future<void> insertExercise(ExercisesCompanion exercise)`
  * Query: `into(exercises).insert(exercise)`
* `Future<void> insertExercises(List<ExercisesCompanion> list)`
  * Query: `batch((b) => b.insertAll(exercises, list, mode: InsertMode.insertOrIgnore))`
* `Future<int> createCustomExercise(String name, {required String userId, ...})`
  * Query: `into(exercises).insert(ExercisesCompanion.insert(...))`
* `Future<void> hydrateFromJson()`
  * Query: Reads catalog `exercises.json`, parses in isolate, then upserts catalog rows: `into(exercises).insert(companion, onConflict: DoUpdate((_) => companion, target: [exercises.exerciseDbId]))` inside a database transaction.

#### 1.3.3 RoutinesDao
Defined in [routines_dao.dart](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/lib/core/database/daos/routines_dao.dart):
* `Future<List<Routine>> getRoutinesForUser(String userId)`
  * Query: `(select(routines)..where((t) => t.userId.equals(userId))).get()`
* `Future<int> countRoutinesForUser(String userId)`
  * Query: `selectOnly(routines)..addColumns([routines.id.count()])..where(routines.userId.equals(userId))`
* `Stream<List<Routine>> watchRoutinesForUser(String userId)`
  * Query: `(select(routines)..where((t) => t.userId.equals(userId)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch()`
* `Stream<List<HydratedRoutine>> watchHydratedRoutinesForUser(String userId)`
  * Query: Watches changes across routines, days, routine exercises, and exercises via a custom select stream driver, executing `_getHydratedRoutines(userId)` when triggered.
* `Future<Routine> getRoutine(String id)`
  * Query: `(select(routines)..where((t) => t.id.equals(id))).getSingle()`
* `Future<Map<String, dynamic>?> exportRoutineJson(String routineId)`
  * Query: Exports routine, days, and exercises structure into a nested Map snapshot for cloud sync.
* `Future<void> importRoutineJson(Map<String, dynamic> data)`
  * Query: Performs idempotent upsert of routine Companion via `into(routines).insertOnConflictUpdate(...)`, drops previous child rows in `routine_exercises` and `routine_days` for the routine, and re-inserts new structures.
* `Future<void> renameRoutine(String id, String name)`
  * Query: `(update(routines)..where((t) => t.id.equals(id))).write(RoutinesCompanion(name: Value(name), updatedAt: Value(DateTime.now())))` followed by enqueuing routine upsert.
* `Future<void> deleteRoutine(String id)`
  * Query: Deletes all days and exercises related to the routine, then deletes the routine row from `routines` inside a database transaction. Enqueues a cloud tombstone.
* `Future<void> addExerciseToRoutine(String routineId, int exerciseId, {int defaultSets = 3})`
  * Query: Appends a routine exercise row to the routine's first day and updates the routine's `updatedAt` field. Enqueues routine upsert.
* `Future<String> createRoutine({required String userId, required String name, required List<RoutineDraftExercise> exercises})`
  * Query: Inserts a new routine, routine day, and its exercises. Enqueues routine upsert.
* `Future<void> replaceRoutineStructure({required String routineId, required String name, required List<RoutineDraftExercise> exercises})`
  * Query: Updates routine metadata, deletes old day exercises, and inserts new ones. Enqueues routine upsert.

#### 1.3.4 WorkoutsDao
Defined in [workouts_dao.dart](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/lib/core/database/daos/workouts_dao.dart):
* `Future<WorkoutSession> getSession(String id)`
  * Query: `(select(workoutSessions)..where((t) => t.id.equals(id))).getSingle()`
* `Future<WorkoutSession?> getSessionOrNull(String id)`
  * Query: `(select(workoutSessions)..where((t) => t.id.equals(id))).getSingleOrNull()`
* `Future<Map<String, dynamic>?> exportSessionJson(String sessionId)`
  * Query: Selects session, exercises, and sets, then exports them as a self-contained nested JSON map.
* `Future<void> importSessionJson(Map<String, dynamic> data)`
  * Query: Upserts the workout session row using `into(workoutSessions).insertOnConflictUpdate(...)`, deletes old child sets and exercises, and inserts the new ones from the snapshot.
* `Future<List<WorkoutSession>> getSessionsForUser(String userId)`
  * Query: `(select(workoutSessions)..where((t) => t.userId.equals(userId))).get()`
* `Future<void> insertSession(WorkoutSessionsCompanion session)`
  * Query: `into(workoutSessions).insert(session)`
* `Future<void> updateSession(WorkoutSessionsCompanion session)`
  * Query: `update(workoutSessions).replace(session)`
* `Future<void> deleteSession(String id)`
  * Query: Deletes all sets and exercises belonging to the session, and then deletes the session row itself.
* `Stream<int> watchWorkoutCountForUser(String userId)`
  * Query: Watches count of completed sessions for a user.
* `Stream<List<WorkoutSession>> watchSessionsForUser(String userId)`
  * Query: Watches sessions ordered descending by start time.
* `Stream<void> watchHistoryRevision(String userId)`
  * Query: Watches changes across `workoutSessions`, `workoutExercises`, and `workoutSets` via a custom select stream.
* `Stream<List<WorkoutSet>> getPreviousSessionSets(int exerciseId, String currentSessionId)`
  * Query: Queries for the sets logged in the previous completed workout session containing the exercise.
* `Future<Map<int, List<WorkoutSet>>> getPreviousSessionSetsBatch(List<int> exerciseIds, String currentSessionId)`
  * Query: Uses a custom select to fetch previous session sets for multiple exercises in a single roundtrip using subqueries to find the most recent session ID per exercise.
* `Future<List<LastSessionSetData>> getLastSessionSetsForExercise(...)`
  * Query: Custom select to fetch the most recent completed session containing the exercise, then fetches its sets.
* `Future<List<ExerciseHistoryData>> getExerciseHistory(int exerciseId)`
  * Query: Runs custom select querying daily max weight, reps, volume, best 1RM (using Epley SQL formula), and best set weight.
* `Future<List<WorkoutSessionPreview>> getSessionPreviewsForUser(...)`
  * Query: Selects sessions for the home feed, queries exercise and PR counts in batch, and fetches top exercises for each session.
* `Future<List<PrRecord>> detectAndMarkPrs(String sessionId, DateTime sessionStart)`
  * Query: Computes Epley 1RMs for completed sets in the session and marks the best set as a PR if it exceeds the historical max prior to the session start.
* `Future<void> updateHistoricalWorkout(ActiveWorkoutState state)`
  * Query: Updates session total volume, deletes existing exercises/sets, re-inserts exercises and sets from current state, and re-calculates PRs.

#### 1.3.5 SyncOutboxDao
Defined in [sync_outbox_dao.dart](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/lib/core/database/daos/sync_outbox_dao.dart):
* `Future<void> enqueue({required String entityType, required String entityId, required String userId, required String payload, String op = 'upsert', DateTime? updatedAt})`
  * Query: Runs in transaction: deletes any existing outbox rows matching the entity, then inserts a new `SyncOutboxCompanion` row.
* `Future<List<SyncOutboxRow>> nextBatch(String userId, {int limit = 200})`
  * Query: `(select(syncOutbox)..where((t) => t.userId.equals(userId))..orderBy([(t) => OrderingTerm.asc(t.createdAtMs)])..limit(limit)).get()`
* `Future<void> deleteByIds(List<int> ids)`
  * Query: `(delete(syncOutbox)..where((t) => t.id.isIn(ids))).go()`
* `Future<int> pendingCount(String userId)`
  * Query: Gets count of outbox rows for the user.
* `Stream<int> watchPendingCount(String userId)`
  * Query: Watches count of outbox rows for the user.

---

## 2. Sync Architecture

### 2.1 Sync Engine (`SyncEngine`)
Defined in [sync_engine.dart](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/lib/core/services/sync_engine.dart).

* **Trigger Strategy:**
  1. **Debounce Auto-Sync:** When changes are queued, `watchPendingCount` triggers a debounce timer (`Duration(seconds: 5)`). If there is 5 seconds of inactivity, a sync executes automatically.
  2. **Immediate Triggers:**
     - Post-Workout (when a session is finished).
     - App backgrounding/pausing (`onHide`, `onPause` app lifecycle triggers).
     - Connectivity restoration (network comes back online).
     - Manual triggers (Settings screen "Sync Now" button).
* **Sync Strategy:**
  - **Outbox Pattern:** Local database modifications are done first. A compressed JSON snapshot of the modified entity is queued in the local `SyncOutbox` table.
  - **Batch Push:** Drains the outbox in batches of 200 items, pushing them to Supabase `sync_objects` table.
  - **FIFO Pull Restoration:** Restores user data from the cloud using the `pull(userId)` command. It reads `sync_objects` from the backend and calls individual import methods (`importSessionJson`, `importRoutineJson`, or `_applyPreferences`).
* **Conflict Resolution:**
  - Server-side database trigger `trg_sync_objects_lww` applies **Last-Write-Wins** via `updated_at`. Stale writes (older timestamp) are ignored server-side.
* **Failure Handling:**
  - Network timeouts (`20 seconds`) are caught. Failed transfers leave items in the local queue, and the status changes to `offline`. It retries on the next sync event.

### 2.2 Sync Remote (`SupabaseSyncRemote`)
Defined in [sync_remote.dart](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/lib/core/services/sync_remote.dart).

Exposes backend operations:
```dart
class SupabaseSyncRemote implements SyncRemote {
  SupabaseSyncRemote(this._client);

  final SupabaseClient _client;
  static const _table = 'sync_objects';

  @override
  Future<void> pushBatch(List<SyncObject> objects) async {
    if (objects.isEmpty) return;
    final rows = [
      for (final o in objects)
        {
          'id': o.id,
          'user_id': o.userId,
          'entity_type': o.entityType,
          'entity_id': o.entityId,
          'updated_at':
              DateTime.fromMillisecondsSinceEpoch(o.updatedAtMs, isUtc: true)
                  .toIso8601String(),
          'deleted': o.deleted,
          'payload': o.payload,
        }
    ];
    await _client.from(_table).upsert(rows);
  }

  @override
  Future<List<SyncObject>> pull(String userId) async {
    final rows = await _client
        .from(_table)
        .select('id, user_id, entity_type, entity_id, updated_at, deleted, payload')
        .eq('user_id', userId)
        .order('updated_at');
    return [
      for (final r in (rows as List).cast<Map<String, dynamic>>())
        SyncObject(
          id: r['id'] as String,
          userId: r['user_id'] as String,
          entityType: r['entity_type'] as String,
          entityId: r['entity_id'] as String,
          updatedAtMs:
              DateTime.parse(r['updated_at'] as String).millisecondsSinceEpoch,
          deleted: (r['deleted'] as bool?) ?? false,
          payload: (r['payload'] as String?) ?? '',
        )
    ];
  }
}
```

### 2.3 Payload Compression (`SyncCodec`)
Defined in [sync_codec.dart](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/lib/core/services/sync_codec.dart).

Entity JSON maps are compressed using gzip and encoded in base64:
```dart
class SyncCodec {
  const SyncCodec._();

  static String encode(Map<String, dynamic> data) {
    final jsonBytes = utf8.encode(jsonEncode(data));
    final gzipped = gzip.encode(jsonBytes);
    return base64Encode(gzipped);
  }

  static Map<String, dynamic> decode(String payload) {
    try {
      final gzipped = base64Decode(payload);
      final jsonBytes = gzip.decode(gzipped);
      return jsonDecode(utf8.decode(jsonBytes)) as Map<String, dynamic>;
    } catch (_) {
      return jsonDecode(payload) as Map<String, dynamic>;
    }
  }
}
```

### 2.4 User Profiles Sync (`ProfileSyncService`)
Defined in [profile_sync_service.dart](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/lib/core/services/profile_sync_service.dart).

Tracks user identity and display name updates. On onboarding or login, it fetches the remote profile and caches it locally. Writes are queued locally in SharedPreferences if the remote push fails.

---

## 3. App Launch & Reinstall Flow

### 3.1 Startup Chain (`main.dart`)
Initialization order inside [main.dart](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/lib/main.dart):
1. **Flutter bindings:** `WidgetsFlutterBinding.ensureInitialized()`
2. **Image Cache adjustments:** Limits cache to 256 images/80 MiB.
3. **Crash reporting:** `SentryFlutter.init` wraps startup.
4. **URL Strategy:** `usePathUrlStrategy()`
5. **Supabase init:** `Supabase.initialize(...)` (fetches config at compile-time).
6. **Local Database init & Warm-up query:**
   ```dart
   db = AppDatabase();
   await db.customSelect('SELECT 1').getSingle(); // Warm-up query
   ```
7. **Premium service:** `PremiumService(db)` initialized.
8. **App run:** `runApp(ProviderScope(...))`
9. **Post-launch maintenance (async):**
   - Calls `exercisesDao.hydrateFromJson()` to populate default exercise library.
   - Deletes orphaned sessions (`deleteOrphanedSessions`) if a user is signed in.

### 3.2 Navigation and Resolution (`splash_screen.dart`)
Startup routing inside [splash_screen.dart](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/lib/features/auth/presentation/screens/splash_screen.dart):
1. Waits for 900ms brand delay.
2. Checks for current authenticated user: `ref.read(authProvider)`.
3. If user is **null** (unauthenticated): Redirects immediately to `/auth`.
4. If user is **not null**:
   - Starts auto-sync outbox watcher: `engine.startAutoSync(user.id)`
   - Starts connectivity watcher: `engine.startConnectivityWatch(user.id)`
   - Triggers async pull: `unawaited(engine.pull(user.id))`
   - Triggers preferences enqueue and recovery: `unawaited(engine.enqueuePreferences(user.id))`
   - Runs profile resolution: `ref.read(profileSyncProvider).resolveOnLogin`
   - If profile needs onboarding, redirects to `/onboarding`, else redirects to `/`.

### 3.3 Auth Screen logic (`auth_screen.dart`)
Auth flow inside [auth_screen.dart](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/lib/features/auth/presentation/screens/auth_screen.dart):
- "Continue with Google" calls `authRepositoryProvider.signInWithGoogle()`.
- Success triggers native Supabase sign-in, which emits an `AuthState` change.
- GoRouter's refresh listenable catches the auth state change and redirects from `/auth` to `/` (HomeScreen).

---

## 4. The Reinstall Scenario (The Bug)

**Scenario:** User has 50 workouts and 4 routines. They delete the app. They reinstall. They sign in with the same Google account.

### 4.1 Step-by-Step execution
1. **App starts:** `main()` executes, initializes Supabase and creates a new empty local Drift database.
2. **First-launch redirect:** Since there is no cached Supabase session, `user` is null. `SplashScreen` redirects the user to `/auth`.
3. **User Signs in:** User signs in via Google OAuth. Supabase authenticates them successfully.
4. **The Redirection:** GoRouter's refresh stream detects the sign-in event and triggers the router redirect logic:
   ```dart
   // Redirect authenticated users away from auth screen
   if (isSignedIn && isAuthRoute) return '/';
   ```
   The router redirects the user directly to `/` (HomeScreen).
5. **The Bug — Missing Sync Trigger:** Because the user goes directly from `/auth` to `/` (HomeScreen), **the `SplashScreen` is completely bypassed.**
6. **Data stays empty:** The calls to `engine.startAutoSync`, `engine.startConnectivityWatch`, and `engine.pull(user.id)` are **only defined in the splash screen.** Since the splash screen is bypassed, no data is pulled from Supabase. The local Drift database remains completely empty, and the user is shown an empty home state.
7. **The Fix/Recovery:** The next time the user force-closes the app and opens it again, the app starts at `/splash`. Since they are already signed in, the splash screen code executes and triggers `engine.pull(user.id)`. The workouts and routines are finally pulled from Supabase and populated in Drift, causing them to suddenly appear on the HomeScreen.

---

## 5. Supabase Cloud Schema

### 5.1 Tables and Constraints

#### profiles
Defined in [profiles.sql](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/docs/supabase/profiles.sql):
```sql
create table if not exists public.profiles (
  id           uuid        primary key references auth.users (id) on delete cascade,
  display_name text        not null,
  email        text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
```

#### sync_objects
Defined in [sync_objects.sql](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/docs/supabase/sync_objects.sql):
```sql
create table if not exists public.sync_objects (
  id          text        primary key,          -- "<entity_type>:<entity_id>"
  user_id     uuid        not null references auth.users (id) on delete cascade,
  entity_type text        not null,
  entity_id   text        not null,
  updated_at  timestamptz not null default now(),
  deleted     boolean     not null default false,
  payload     text        not null default ''   -- gzip + base64 of entity JSON
);

create index if not exists idx_sync_objects_user_type
  on public.sync_objects (user_id, entity_type);
```

#### deletion_requests
Defined in [account_deletion.sql](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/docs/supabase/account_deletion.sql):
```sql
create table if not exists public.deletion_requests (
  id          uuid        primary key default gen_random_uuid(),
  email       text        not null,
  note        text,
  status      text        not null default 'pending',  -- pending | done | rejected
  created_at  timestamptz not null default now()
);
```

### 5.2 Row Level Security (RLS) Policies

#### profiles
- **SELECT:** `profiles_select_own`
  ```sql
  create policy "profiles_select_own" on public.profiles for select using (auth.uid() = id);
  ```
- **INSERT:** `profiles_insert_own`
  ```sql
  create policy "profiles_insert_own" on public.profiles for insert with check (auth.uid() = id);
  ```
- **UPDATE:** `profiles_update_own`
  ```sql
  create policy "profiles_update_own" on public.profiles for update using (auth.uid() = id) with check (auth.uid() = id);
  ```
- **DELETE:** `profiles_delete_own`
  ```sql
  create policy "profiles_delete_own" on public.profiles for delete using (auth.uid() = id);
  ```

#### sync_objects
- **SELECT:** `sync_select_own`
  ```sql
  create policy "sync_select_own" on public.sync_objects for select using (auth.uid() = user_id);
  ```
- **INSERT:** `sync_insert_own`
  ```sql
  create policy "sync_insert_own" on public.sync_objects for insert with check (auth.uid() = user_id);
  ```
- **UPDATE:** `sync_update_own`
  ```sql
  create policy "sync_update_own" on public.sync_objects for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
  ```
- **DELETE:** `sync_objects_delete_own`
  ```sql
  create policy "sync_objects_delete_own" on public.sync_objects for delete using (auth.uid() = user_id);
  ```

#### deletion_requests
- **INSERT:** `deletion_requests_insert_any`
  ```sql
  create policy "deletion_requests_insert_any" on public.deletion_requests for insert with check (true);
  ```
- No select/update/delete policies are defined for regular users.

### 5.3 Edge Functions

- **delete-account** (Deno, defined in [index.ts](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/supabase/functions/delete-account/index.ts)):
  - Validates the caller's JWT using `supabase.auth.getUser()`.
  - Service-role client purges user rows from `sync_objects` and `profiles`.
  - Deletes the authenticated identity row from `auth.users` via `admin.auth.admin.deleteUser(uid)`.

### 5.4 Realtime
- **Realtime status:** Realtime is **not enabled** on any table to prevent connections from exceeding free-tier limits.
- The app does not listen to Realtime changes.

---

## 6. Load & Scalability Assessment

### 6.1 Supabase Free Tier Limits
- **Database Size:** 500 MB (standard Supabase free-tier storage).
- **Concurrent Realtime Connections:** 200 (not used by GymLog).
- **API Request Rate:** rate-limited.
- **Edge Function Executions:** 2 million/month limit.

### 6.2 Data Volume Estimation
- **Row Mapping:** Because GymLog uses a single consolidated `sync_objects` schema, a complete workout session is serialized, compressed (gzip), and stored as a single base64 string.
  - **1 Workout Session:** Exactly **1 row** in `sync_objects` (entity type: `session`).
  - **1 Routine:** Exactly **1 row** in `sync_objects` (entity type: `routine`).
  - **Preferences:** Exactly **1 row** in `sync_objects` (entity type: `preferences`).
- **Estimation (3 Years of Daily Workouts):**
  - Daily workouts over 3 years: 3 × 365 = 1,095 sessions.
  - Estimated routines: 10 routines.
  - Preferences: 1 preferences row.
  - **Total Rows on Supabase:** ~1,106 rows.
  - **Average Row Size:** A raw session JSON of ~3 KB compresses to ~1 KB base64 payload. Total row footprint on Postgres (with indices) is approximately **1.2 KB**.
  - **Total Postgres Database Size for 1 User:** 1,106 × 1.2 KB = **~1.3 MB**.
  - **Scalability Ceiling:** A single 500 MB free-tier instance can comfortably host **350+ heavy daily users**.

### 6.3 Query Patterns & Indices
- **Hot-Paths:**
  - `pull(userId)`: Reads all synced objects for a user:
    ```sql
    SELECT id, user_id, entity_type, entity_id, updated_at, deleted, payload 
    FROM public.sync_objects 
    WHERE user_id = $1 
    ORDER BY updated_at;
    ```
  - `pushBatch(objects)`: Upserts modified objects:
    ```sql
    INSERT INTO public.sync_objects (id, user_id, entity_type, entity_id, updated_at, deleted, payload)
    VALUES (...)
    ON CONFLICT (id) DO UPDATE ...;
    ```
- **Index Review:**
  - Compound index: `idx_sync_objects_user_type` on `(user_id, entity_type)`.
  - **Missing Index:** The `pull` query uses `WHERE user_id = $1 ORDER BY updated_at`. A compound index on `(user_id, updated_at)` is recommended to optimize ordering and avoid filesorts during data recovery.

---

## 7. The Sync Trigger Map

| User Action | Local DB Action | Cloud Sync Trigger? | Immediate or Deferred? | Tables Affected |
|---|---|---|---|---|
| **Finish workout** | INSERT into `workout_sessions`, `workout_exercises`, `workout_sets` | **Yes** | Immediate | `workout_sessions`, `workout_exercises`, `workout_sets`, `sync_outbox` |
| **Edit workout** | UPDATE `workout_sessions`, DELETE + INSERT `workout_exercises`, `workout_sets` | **No** (Local-only. Outbox row is never enqueued) | N/A | `workout_sessions`, `workout_exercises`, `workout_sets` |
| **Delete workout** | DELETE from `workout_sessions` & cascades | **No** (Local-only. Outbox row is never enqueued) | N/A | `workout_sessions`, `workout_exercises`, `workout_sets` |
| **Create routine** | INSERT into `routines`, `routine_days`, `routine_exercises` | **Yes** | Deferred (Debounced 5s) | `routines`, `routine_days`, `routine_exercises`, `sync_outbox` |
| **Edit routine** | UPDATE `routines` structure | **Yes** | Deferred (Debounced 5s) | `routines`, `routine_days`, `routine_exercises`, `sync_outbox` |
| **Delete routine** | DELETE from `routines` & cascades | **Yes** | Deferred (Debounced 5s) | `routines`, `routine_days`, `routine_exercises`, `sync_outbox` |
| **Sign in** | INSERT/UPDATE profile in `user_profiles` | **Yes** | Immediate (Attempts remote upsert) | `user_profiles` |
| **App backgrounded** | Enqueues preferences in `sync_outbox` | **Yes** | Immediate | `sync_outbox` |
| **App foregrounded** | N/A | **Yes** (If connection is active) | Immediate | `sync_outbox` |

---

## 8. Known Issues & TODOs

### 8.1 Unawaited Futures
- [premium_service.dart:81](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/lib/core/services/premium_service.dart#L81) — `unawaited(refresh());`
- [premium_service.dart:124](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/lib/core/services/premium_service.dart#L124) — `if (state == AppLifecycleState.resumed) unawaited(refresh());`
- [premium_service.dart:201](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/lib/core/services/premium_service.dart#L201) — `unawaited(_syncToLocalCache(info));`
- [splash_screen.dart:51](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/lib/features/auth/presentation/screens/splash_screen.dart#L51) — `unawaited(engine.pull(user.id));`
- [splash_screen.dart:52](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/lib/features/auth/presentation/screens/splash_screen.dart#L52) — `unawaited(engine.loadLastSynced());`
- [splash_screen.dart:53](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/lib/features/auth/presentation/screens/splash_screen.dart#L53) — `unawaited(engine.enqueuePreferences(user.id));`
- [active_workout_provider.dart:31](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/lib/features/workout/presentation/providers/active_workout_provider.dart#L31) — `unawaited(store.clear());`
- [active_workout_provider.dart:38](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/lib/features/workout/presentation/providers/active_workout_provider.dart#L38) — `unawaited(store.save(s));`
- [active_workout_provider.dart:234](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/lib/features/workout/presentation/providers/active_workout_provider.dart#L234) — `unawaited(engine.syncNow(userId, reason: 'post_workout'));`
- [main.dart:103](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/lib/main.dart#L103) — `unawaited(premiumService.initialize(userId: ...));`
- [main.dart:124](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/lib/main.dart#L124) — `unawaited(_postLaunchMaintenance(db));`
- [premium_paywall.dart:164](file:///c:/Users/Atharva%20Patil/Documents/projects/gymlog/lib/shared/widgets/premium_paywall.dart#L164) — `unawaited(_refreshTrialEligibility());`

### 8.2 Missing Sync Coverage on Workout Mutations
- **Workout Edits:** `saveEditedWorkout` in `active_workout_provider.dart` saves edits locally to the Drift database but fails to queue a `session` snapshot to `sync_outbox`. Edits are not synced to the cloud.
- **Workout Deletions:** `deleteSession` in `workout_actions_provider.dart` and `workouts_dao.dart` deletes the workout session and its child records locally, but it does not write a deletion tombstone to the outbox (`entityType = 'session', op = 'delete'`). Consequently, deleted workouts remain stored on Supabase and reappear if the user reinstalls the app.

### 8.3 Reinstall / Sign-In Sync Bug
- **Redirect bypass:** When a user completes Google Sign-In on a fresh install, GoRouter immediately redirects them from `/auth` to `/` (HomeScreen). Because this route transition bypasses the `SplashScreen` logic, the initial sync engine listeners, state restoration, and cloud data pull (`engine.pull`) are never executed. The user sees an empty home state until they manually restart the app.
