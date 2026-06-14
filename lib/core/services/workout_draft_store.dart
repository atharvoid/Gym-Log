import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/workout/domain/active_workout_state.dart';

const _kDraftKey = 'active_workout_draft_v1';

/// Crash/kill resilience for the in-progress workout.
///
/// The active session lives only in memory until Finish, so an OS kill used to
/// lose the whole workout. This persists a lightweight snapshot to ENCRYPTED
/// device storage on every (debounced) change, and offers to resume it on the
/// next launch if it's recent. Cleared the moment a workout is finished or
/// discarded. Only NEW live sessions are persisted — editing history is not a
/// resumable "interrupted" state.
///
/// Serialization is hand-written (the state is Freezed without json codegen,
/// and the build sandbox can't run build_runner) — keep it in sync with
/// [ActiveWorkoutState] / [WorkoutExerciseState] / [WorkoutSetState].
class WorkoutDraftStore {
  WorkoutDraftStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<void> save(ActiveWorkoutState s) async {
    try {
      final payload = jsonEncode({
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'workout': _workoutToJson(s),
      });
      await _storage.write(key: _kDraftKey, value: payload);
    } catch (e) {
      if (kDebugMode) debugPrint('[WorkoutDraftStore] save failed: $e');
    }
  }

  /// Returns the saved session if one exists and is younger than [maxAge];
  /// otherwise clears it and returns null.
  Future<ActiveWorkoutState?> load(
      {Duration maxAge = const Duration(hours: 24)}) async {
    try {
      final raw = await _storage.read(key: _kDraftKey);
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt =
          DateTime.fromMillisecondsSinceEpoch(map['savedAt'] as int);
      if (DateTime.now().difference(savedAt) > maxAge) {
        await clear();
        return null;
      }
      final state =
          _workoutFromJson(map['workout'] as Map<String, dynamic>);
      // A draft with no logged work isn't worth resuming.
      if (state.exercises.isEmpty) {
        await clear();
        return null;
      }
      return state;
    } catch (e) {
      if (kDebugMode) debugPrint('[WorkoutDraftStore] load failed: $e');
      await clear();
      return null;
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _kDraftKey);
    } catch (_) {}
  }
}

final workoutDraftStoreProvider =
    Provider<WorkoutDraftStore>((_) => WorkoutDraftStore());

// ── Hand-written serialization (mirror the Freezed fields) ──────────────────

Map<String, dynamic> _setToJson(WorkoutSetState s) => {
      'id': s.id,
      'setType': s.setType,
      'weightKg': s.weightKg,
      'reps': s.reps,
      'isCompleted': s.isCompleted,
      'completedAt': s.completedAt?.millisecondsSinceEpoch,
    };

WorkoutSetState _setFromJson(Map<String, dynamic> m) => WorkoutSetState(
      id: m['id'] as String? ?? '',
      setType: m['setType'] as String? ?? 'normal',
      weightKg: (m['weightKg'] as num?)?.toDouble() ?? 0,
      reps: (m['reps'] as num?)?.toInt() ?? 0,
      isCompleted: m['isCompleted'] as bool? ?? false,
      completedAt: m['completedAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(m['completedAt'] as int),
    );

Map<String, dynamic> _exToJson(WorkoutExerciseState e) => {
      'id': e.id,
      'exerciseId': e.exerciseId,
      'name': e.name,
      'sets': [for (final s in e.sets) _setToJson(s)],
    };

WorkoutExerciseState _exFromJson(Map<String, dynamic> m) => WorkoutExerciseState(
      id: m['id'] as String? ?? '',
      exerciseId: (m['exerciseId'] as num).toInt(),
      name: m['name'] as String? ?? '',
      sets: [
        for (final s in (m['sets'] as List? ?? const []))
          _setFromJson(s as Map<String, dynamic>),
      ],
    );

Map<String, dynamic> _workoutToJson(ActiveWorkoutState s) => {
      'id': s.id,
      'startTime': s.startTime.millisecondsSinceEpoch,
      'routineId': s.routineId,
      'name': s.name,
      'exercises': [for (final e in s.exercises) _exToJson(e)],
    };

ActiveWorkoutState _workoutFromJson(Map<String, dynamic> m) => ActiveWorkoutState(
      id: m['id'] as String,
      startTime: DateTime.fromMillisecondsSinceEpoch(m['startTime'] as int),
      routineId: m['routineId'] as String?,
      name: m['name'] as String?,
      exercises: [
        for (final e in (m['exercises'] as List? ?? const []))
          _exFromJson(e as Map<String, dynamic>),
      ],
      // originalSessionId intentionally omitted — restored drafts are NEW live
      // sessions, never history edits.
    );
