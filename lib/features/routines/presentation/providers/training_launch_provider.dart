import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/database/daos/routines_dao.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/routines/program_membership.dart';
import 'package:gymlog/core/models/measurement_type.dart';
import 'package:gymlog/core/utils/formatters.dart';
import 'package:gymlog/core/utils/units.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/workout/domain/active_workout_state.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

final trainingClockProvider =
    Provider<DateTime Function()>((ref) => DateTime.now);
final chosenRoutineProvider =
    StateNotifierProvider<ChosenRoutineNotifier, AsyncValue<String?>>((ref) {
  final notifier =
      ChosenRoutineNotifier(ref.watch(authProvider)?.id ?? 'local');
  notifier.load();
  return notifier;
});

class ChosenRoutineNotifier extends StateNotifier<AsyncValue<String?>> {
  ChosenRoutineNotifier(String account)
      : _key = 'training_routine:$account',
        super(const AsyncLoading());
  final String _key;
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(_key);
      if (mounted) state = AsyncData(id);
    } catch (e, stack) {
      if (mounted) state = AsyncError(e, stack);
    }
  }

  Future<void> choose(String id) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_key, id)) {
      throw StateError('Choice write failed');
    }
    if (mounted) state = AsyncData(id);
  }
}

class ProgramSuggestion {
  const ProgramSuggestion(
      this.routine, this.previousRoutineName, this.programName);
  final HydratedRoutine routine;
  final String previousRoutineName;
  final String programName;
}

ProgramSuggestion? nextProgramSuggestion(List<HydratedRoutine> routines,
    List<WorkoutSessionPreview> history, String? chosenId) {
  final byId = {for (final r in routines) r.routine.id: r};
  final chosen = byId[chosenId];
  final selectedProgram =
      decodeProgramMembership(chosen?.routine.notes)?.programSlug;
  final completed = history.where((p) => p.session.endedAt != null).toList()
    ..sort((a, b) => b.session.endedAt!.compareTo(a.session.endedAt!));
  for (final session in completed) {
    final previous = byId[session.session.routineId];
    final membership = decodeProgramMembership(previous?.routine.notes);
    if (previous == null ||
        membership == null ||
        (selectedProgram != null &&
            selectedProgram != membership.programSlug)) {
      continue;
    }
    final members = routines
        .where((r) =>
            decodeProgramMembership(r.routine.notes)?.programSlug ==
            membership.programSlug)
        .toList();
    if (members.length != membership.totalRoutines) return null;
    final days = {
      for (final r in routines)
        if (decodeProgramMembership(r.routine.notes)?.programSlug ==
            membership.programSlug)
          decodeProgramMembership(r.routine.notes)!.orderIndex: r
    };
    // No inference from legacy names/timestamps, missing days or inconsistent imports.
    if (membership.totalRoutines < 2 ||
        days.length != membership.totalRoutines ||
        days.values.any((r) =>
            decodeProgramMembership(r.routine.notes)!.totalRoutines !=
            membership.totalRoutines) ||
        List.generate(membership.totalRoutines, (i) => i)
            .any((i) => !days.containsKey(i))) {
      return null;
    }
    final next = days[(membership.orderIndex + 1) % membership.totalRoutines];
    if (next == null || next.exerciseIds.isEmpty) return null;
    return ProgramSuggestion(
        next, previous.routine.name, membership.programLabel);
  }
  return null;
}

bool isInactiveReturn(List<WorkoutSessionPreview> history, DateTime now) {
  DateTime? latest;
  for (final p in history) {
    final ended = p.session.endedAt;
    if (ended != null && (latest == null || ended.isAfter(latest))) {
      latest = ended;
    }
  }
  return latest != null && now.difference(latest) >= const Duration(days: 14);
}

String trainingAgeLabel(DateTime? last, DateTime now) {
  if (last == null) return 'No sessions logged for this routine';
  final days = DateTime.utc(now.year, now.month, now.day)
      .difference(DateTime.utc(last.year, last.month, last.day))
      .inDays;
  if (days < 0) {
    return 'Last trained on ${DateFormat('d MMM yyyy').format(last)}';
  }
  if (days == 0) return 'Last trained today';
  if (days == 1) return 'Last trained yesterday';
  return 'Last trained $days days ago';
}

enum LaunchResult { started, resume, unavailable, busy }

String? launchSetText(MeasurementType type, LastSessionSetData set, String unit,
    {bool spoken = false}) {
  switch (type) {
    case MeasurementType.weightAndReps:
      if (set.weightKg == null || set.reps == null) return null;
      return spoken
          ? '${formatWeight(set.weightKg!, unit)} ${unit == 'lbs' ? 'pounds' : 'kilograms'} for ${set.reps} reps'
          : '${formatWeight(set.weightKg!, unit)} ${unitLabel(unit)} × ${set.reps}';
    case MeasurementType.repsOnly:
      return set.reps == null ? null : '${set.reps} reps';
    case MeasurementType.duration:
      if (set.reps == null) return null;
      return spoken
          ? '${set.reps} seconds'
          : MeasurementFormatter.formatSet(
              measurementType: type, reps: set.reps);
    case MeasurementType.distance:
      if (set.weightKg == null) return null;
      return spoken
          ? '${set.weightKg! == set.weightKg!.roundToDouble() ? set.weightKg!.toInt() : set.weightKg} metres${set.reps != null ? ', ${set.reps} seconds' : ''}'
          : MeasurementFormatter.formatSet(
              measurementType: type, weightKg: set.weightKg, reps: set.reps);
    case MeasurementType.unknown:
      return null;
  }
}

final trainingRoutineLoaderProvider =
    Provider<Future<HydratedRoutineDetail?> Function(String)>(
        (ref) => (id) async {
              final user = ref.read(authProvider);
              if (user == null) return null;
              return ref
                  .read(databaseProvider)
                  .routinesDao
                  .getHydratedRoutineDetail(id, userId: user.id);
            });
final trainingLauncherProvider =
    Provider<TrainingLauncher>(TrainingLauncher.new);

class TrainingLauncher {
  TrainingLauncher(this._ref);
  final Ref _ref;
  bool _busy = false;
  Future<LaunchResult> startRoutine(String id) => _start(id);
  Future<LaunchResult> startFreestyle() => _start(null);
  Future<LaunchResult> _start(String? id) async {
    if (_busy) return LaunchResult.busy;
    if (_ref.read(activeWorkoutProvider) != null) return LaunchResult.resume;
    _busy = true;
    try {
      final account = _ref.read(authProvider)?.id;
      final detail = id == null
          ? null
          : await _ref.read(trainingRoutineLoaderProvider)(id);
      if (_ref.read(authProvider)?.id != account) {
        return LaunchResult.unavailable;
      }
      // Another launch surface can resume/start while the database lookup awaits.
      if (_ref.read(activeWorkoutProvider) != null) return LaunchResult.resume;
      if (id != null && (detail == null || detail.exercises.isEmpty)) {
        return LaunchResult.unavailable;
      }
      await _ref.read(activeWorkoutProvider.notifier).startWorkout(
          routineId: id,
          name: detail?.routine.name,
          initialExercises:
              detail == null ? null : seedExercisesFromRoutine(detail));
      return LaunchResult.started;
    } finally {
      _busy = false;
    }
  }
}
