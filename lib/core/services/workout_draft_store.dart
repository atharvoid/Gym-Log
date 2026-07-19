import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../../features/workout/domain/active_workout_state.dart';

const _kDraftKeyV2 = 'active_workout_draft_v2';
const _kDraftKeyV1 = 'active_workout_draft_v1';

/// Snapshot of an active rest timer for persistence in the workout draft.
class RestTimerSnapshot {
  final int totalSeconds;
  final DateTime endTime;
  final String workoutId;
  final int exerciseId;
  final String setId;

  const RestTimerSnapshot({
    required this.totalSeconds,
    required this.endTime,
    required this.workoutId,
    required this.exerciseId,
    required this.setId,
  });

  Map<String, dynamic> toJson() => {
        'totalSeconds': totalSeconds,
        'endTimestamp': endTime.millisecondsSinceEpoch,
        'workoutId': workoutId,
        'exerciseId': exerciseId,
        'setId': setId,
      };

  static RestTimerSnapshot? fromJson(Map<String, dynamic>? m) {
    if (m == null) return null;
    final total = (m['totalSeconds'] as num?)?.toInt();
    final endMillis = (m['endTimestamp'] as num?)?.toInt();
    final wId = m['workoutId'] as String? ?? '';
    final exId = (m['exerciseId'] as num?)?.toInt() ?? 0;
    final sId = m['setId'] as String? ?? '';
    if (total == null || endMillis == null) return null;
    return RestTimerSnapshot(
      totalSeconds: total,
      endTime: DateTime.fromMillisecondsSinceEpoch(endMillis),
      workoutId: wId,
      exerciseId: exId,
      setId: sId,
    );
  }
}

/// Fully versioned snapshot of an active workout draft + associated rest timer state.
class WorkoutDraftSnapshot {
  final int version;
  final String userId;
  final DateTime savedAt;
  final ActiveWorkoutState workout;
  final RestTimerSnapshot? restTimer;

  const WorkoutDraftSnapshot({
    this.version = 2,
    required this.userId,
    required this.savedAt,
    required this.workout,
    this.restTimer,
  });
}

/// Crash/kill resilience for the in-progress workout.
///
/// The active session lives only in memory until Finish, so an OS kill used to
/// lose the whole workout. This persists a lightweight snapshot to ENCRYPTED
/// device storage on every change, and offers to resume it on the
/// next launch if it's recent. Cleared the moment a workout is finished or
/// discarded. Only NEW live sessions are persisted — editing history is not a
/// resumable "interrupted" state.
class WorkoutDraftStore {
  WorkoutDraftStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// Persists a workout draft along with user identity and rest timer state.
  Future<void> save(
    ActiveWorkoutState? state, {
    String? userId,
    RestTimerSnapshot? restTimer,
  }) async {
    if (state == null) {
      await clear();
      return;
    }
    // Only save new live sessions, never history-edits.
    if (state.originalSessionId != null) return;

    try {
      final Map<String, dynamic> data = {
        'version': 2,
        'userId': userId ?? '',
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'workout': {
          'id': state.id,
          'startTime': state.startTime.millisecondsSinceEpoch,
          'routineId': state.routineId,
          'name': state.name,
          'exercises': [for (final ex in state.exercises) _exToJson(ex)],
        },
        'restTimer': restTimer?.toJson(),
      };
      await _storage.write(key: _kDraftKeyV2, value: jsonEncode(data));
    } catch (e) {
      debugPrint('[WorkoutDraftStore] save failed: $e');
    }
  }

  /// Loads the persisted draft snapshot if valid and belonging to [currentUserId].
  /// Returns null if no draft exists, draft is stale (>24h), user mismatches,
  /// or payload is corrupt (clears corrupt draft).
  Future<WorkoutDraftSnapshot?> loadSnapshot({String? currentUserId}) async {
    try {
      String? value = await _storage.read(key: _kDraftKeyV2);
      bool isV1 = false;
      if (value == null) {
        value = await _storage.read(key: _kDraftKeyV1);
        if (value != null) isV1 = true;
      }
      if (value == null) return null;

      final Map<String, dynamic> data =
          jsonDecode(value) as Map<String, dynamic>;

      if (isV1) {
        // Legacy v1 payload format
        final int startMillis = data['startTime'] as int;
        final startTime = DateTime.fromMillisecondsSinceEpoch(startMillis);
        if (DateTime.now().difference(startTime).inHours >= 24) {
          await clear();
          return null;
        }
        final workout = ActiveWorkoutState(
          id: data['id'] as String,
          startTime: startTime,
          routineId: data['routineId'] as String?,
          name: data['name'] as String?,
          exercises: [
            for (final rawEx in (data['exercises'] as List? ?? const []))
              _exFromJson(rawEx as Map<String, dynamic>),
          ],
        );
        return WorkoutDraftSnapshot(
          version: 1,
          userId: '',
          savedAt: startTime,
          workout: workout,
        );
      }

      // v2 payload format
      final version = (data['version'] as num?)?.toInt() ?? 2;
      final payloadUserId = data['userId'] as String? ?? '';
      final savedAtMillis = (data['savedAt'] as num?)?.toInt() ?? 0;
      final savedAt = DateTime.fromMillisecondsSinceEpoch(savedAtMillis);

      // Account isolation: check user ID
      if (currentUserId != null &&
          payloadUserId.isNotEmpty &&
          payloadUserId != currentUserId) {
        debugPrint(
            '[WorkoutDraftStore] Ignoring draft from different user ($payloadUserId vs $currentUserId)');
        return null;
      }

      // Stale check (>24 hours)
      if (savedAtMillis > 0 &&
          DateTime.now().difference(savedAt).inHours >= 24) {
        debugPrint('[WorkoutDraftStore] Draft expired (>24h), clearing.');
        await clear();
        return null;
      }

      final workoutMap = data['workout'] as Map<String, dynamic>?;
      if (workoutMap == null) {
        await clear();
        return null;
      }

      final int startMillis = workoutMap['startTime'] as int;
      final workout = ActiveWorkoutState(
        id: workoutMap['id'] as String,
        startTime: DateTime.fromMillisecondsSinceEpoch(startMillis),
        routineId: workoutMap['routineId'] as String?,
        name: workoutMap['name'] as String?,
        exercises: [
          for (final rawEx in (workoutMap['exercises'] as List? ?? const []))
            _exFromJson(rawEx as Map<String, dynamic>),
        ],
      );

      final restTimerSnapshot = RestTimerSnapshot.fromJson(
          data['restTimer'] as Map<String, dynamic>?);

      return WorkoutDraftSnapshot(
        version: version,
        userId: payloadUserId,
        savedAt: savedAt,
        workout: workout,
        restTimer: restTimerSnapshot,
      );
    } catch (e) {
      debugPrint(
          '[WorkoutDraftStore] Corrupted or invalid draft payload: $e. Clearing draft.');
      await clear();
      return null;
    }
  }

  /// Convenience loader returning just the [ActiveWorkoutState].
  Future<ActiveWorkoutState?> load({String? currentUserId}) async {
    final snapshot = await loadSnapshot(currentUserId: currentUserId);
    return snapshot?.workout;
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _kDraftKeyV2);
      await _storage.delete(key: _kDraftKeyV1);
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
      weightKg: m.containsKey('weightKg') && m['weightKg'] != null
          ? (m['weightKg'] as num).toDouble()
          : null,
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
      'measurementType': e.measurementType,
      'sets': [for (final s in e.sets) _setToJson(s)],
      'restSecondsOverride': e.restSecondsOverride,
    };

WorkoutExerciseState _exFromJson(Map<String, dynamic> m) {
  final mTypeRaw = m['measurementType'] as String? ?? 'weight_and_reps';
  final isRepsOnlyOrDuration =
      mTypeRaw == 'reps_only' || mTypeRaw == 'duration';
  return WorkoutExerciseState(
    id: m['id'] as String? ?? '',
    exerciseId: (m['exerciseId'] as num).toInt(),
    name: m['name'] as String? ?? '',
    measurementType: mTypeRaw,
    sets: [
      for (final s in (m['sets'] as List? ?? const []))
        () {
          final set = _setFromJson(s as Map<String, dynamic>);
          return isRepsOnlyOrDuration ? set.copyWith(weightKg: null) : set;
        }(),
    ],
    restSecondsOverride: m['restSecondsOverride'] as int?,
  );
}
