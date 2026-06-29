import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

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

  Future<void> save(ActiveWorkoutState? state) async {
    if (state == null) {
      await _storage.delete(key: _kDraftKey);
      return;
    }
    // Only save new live sessions, never history-edits.
    if (state.originalSessionId != null) return;

    try {
      final Map<String, dynamic> data = {
        'id': state.id,
        'startTime': state.startTime.millisecondsSinceEpoch,
        'routineId': state.routineId,
        'name': state.name,
        'exercises': [for (final ex in state.exercises) _exToJson(ex)],
      };
      await _storage.write(key: _kDraftKey, value: jsonEncode(data));
    } catch (e) {
      debugPrint('[WorkoutDraftStore] save failed: $e');
    }
  }

  Future<ActiveWorkoutState?> load() async {
    try {
      final value = await _storage.read(key: _kDraftKey);
      if (value == null) return null;

      final Map<String, dynamic> data =
          jsonDecode(value) as Map<String, dynamic>;
      final int startMillis = data['startTime'] as int;

      return ActiveWorkoutState(
        id: data['id'] as String,
        startTime: DateTime.fromMillisecondsSinceEpoch(startMillis),
        routineId: data['routineId'] as String?,
        name: data['name'] as String?,
        exercises: [
          for (final rawEx in data['exercises'] as List)
            _exFromJson(rawEx as Map<String, dynamic>),
        ],
      );
    } catch (e) {
      debugPrint('[WorkoutDraftStore] load failed: $e');
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
      id: (m['id'] as String?)?.isNotEmpty == true
          ? m['id'] as String
          : const Uuid().v4(),
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

WorkoutExerciseState _exFromJson(Map<String, dynamic> m) =>
    WorkoutExerciseState(
      id: m['id'] as String? ?? '',
      exerciseId: (m['exerciseId'] as num).toInt(),
      name: m['name'] as String? ?? '',
      sets: [
        for (final s in (m['sets'] as List? ?? const []))
          _setFromJson(s as Map<String, dynamic>),
      ],
    );
