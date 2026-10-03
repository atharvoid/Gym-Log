import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gymlog/core/database/daos/routines_dao.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/routines/program_membership.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'routines_provider.dart';

/// Persist intent, never a mutable next-day cursor. Completion remains in SQLite.
class TrainingPlan {
  const TrainingPlan(
      {required this.anchorId,
      this.programSlug,
      this.needsChoice = false,
      this.startAfter});
  final String anchorId;
  final String? programSlug;
  final bool needsChoice;

  /// Explicit owner choice after an ambiguous import, not an advancing cursor.
  final DateTime? startAfter;
  bool get followsProgram => programSlug != null;
  String encode() => jsonEncode({
        'version': 1,
        'anchor': anchorId,
        'mode': followsProgram ? 'program' : 'repeat',
        'program': programSlug,
        if (startAfter != null)
          'startAfter': startAfter!.toUtc().toIso8601String(),
      });
  static TrainingPlan decode(String value) {
    final data = jsonDecode(value) as Map<String, dynamic>;
    if (data['version'] != 1 ||
        data['anchor'] is! String ||
        (data['anchor'] as String).isEmpty ||
        !['repeat', 'program'].contains(data['mode']) ||
        (data['mode'] == 'program' &&
            (data['program'] is! String ||
                (data['program'] as String).isEmpty))) {
      throw const FormatException('Invalid training plan');
    }
    return TrainingPlan(
        anchorId: data['anchor'] as String,
        programSlug:
            data['mode'] == 'program' ? data['program'] as String : null,
        startAfter: data['startAfter'] == null
            ? null
            : DateTime.parse(data['startAfter'] as String));
  }
}

List<HydratedRoutine>? orderedProgram(
    List<HydratedRoutine> routines, String slug) {
  final members = routines
      .where(
          (r) => decodeProgramMembership(r.routine.notes)?.programSlug == slug)
      .toList();
  if (members.isEmpty) return null;
  final total =
      decodeProgramMembership(members.first.routine.notes)!.totalRoutines;
  if (total < 2 || members.length != total) return null;
  final positions = <int>{};
  final days = <String>{};
  for (final r in members) {
    final m = decodeProgramMembership(r.routine.notes)!;
    if (m.totalRoutines != total ||
        m.orderIndex < 0 ||
        m.orderIndex >= total ||
        !positions.add(m.orderIndex) ||
        !days.add(m.routineSlug)) {
      return null;
    }
  }
  members.sort((a, b) => decodeProgramMembership(a.routine.notes)!
      .orderIndex
      .compareTo(decodeProgramMembership(b.routine.notes)!.orderIndex));
  return members;
}

TrainingPlan planForRoutine(
    HydratedRoutine routine, List<HydratedRoutine> library,
    {bool repeat = false}) {
  final membership = decodeProgramMembership(routine.routine.notes);
  final valid = membership != null &&
      orderedProgram(library, membership.programSlug) != null;
  return TrainingPlan(
      anchorId: routine.routine.id,
      programSlug: valid && !repeat ? membership.programSlug : null);
}

final trainingPlanProvider =
    StateNotifierProvider<TrainingPlanNotifier, AsyncValue<TrainingPlan?>>(
        (ref) {
  final notifier = TrainingPlanNotifier(ref.watch(authProvider)?.id ?? 'local',
      () => ref.read(hydratedRoutinesProvider.future));
  notifier.load();
  return notifier;
});

class TrainingPlanNotifier extends StateNotifier<AsyncValue<TrainingPlan?>> {
  TrainingPlanNotifier(this.account, this.library,
      {Future<SharedPreferences> Function()? preferences})
      : preferences = preferences ?? SharedPreferences.getInstance,
        super(const AsyncLoading());
  final String account;
  final Future<List<HydratedRoutine>> Function() library;
  final Future<SharedPreferences> Function() preferences;
  String get key => 'training_plan:v1:$account';
  int _request = 0;
  Future<void> load() async {
    final request = ++_request;
    try {
      final prefs = await preferences();
      final encoded = prefs.getString(key);
      TrainingPlan? plan;
      if (encoded != null) {
        plan = TrainingPlan.decode(encoded);
      } else {
        final legacy = prefs.getString('training_routine:$account');
        if (legacy != null) {
          final routines = await library();
          HydratedRoutine? selected;
          for (final r in routines) {
            if (r.routine.id == legacy) selected = r;
          }
          if (selected == null) {
            plan = TrainingPlan(anchorId: legacy, needsChoice: true);
          } else {
            final m = decodeProgramMembership(selected.routine.notes);
            final ambiguous = (m != null &&
                    orderedProgram(routines, m.programSlug) == null) ||
                (m == null &&
                    (selected.routine.sourceProgramName != null ||
                        selected.routine.notes.contains(kProgramMetaTag)));
            plan = ambiguous
                ? TrainingPlan(anchorId: legacy, needsChoice: true)
                : planForRoutine(selected, routines);
            if (!ambiguous) {
              if (!mounted || request != _request) return;
              if (!await prefs.setString(key, plan.encode())) {
                throw StateError('Training plan migration failed');
              }
            }
          }
        }
      }
      if (mounted && request == _request) state = AsyncData(plan);
    } catch (e, stack) {
      if (mounted && request == _request) state = AsyncError(e, stack);
    }
  }

  Future<void> choose(HydratedRoutine routine, List<HydratedRoutine> routines,
      {DateTime? startAfter, bool repeat = false}) async {
    final request = ++_request;
    final selected = planForRoutine(routine, routines, repeat: repeat);
    final plan = TrainingPlan(
        anchorId: selected.anchorId,
        programSlug: selected.programSlug,
        startAfter: startAfter);
    final prefs = await preferences();
    if (!mounted || request != _request) return;
    if (!await prefs.setString(key, plan.encode())) {
      throw StateError('Training plan write failed');
    }
    if (mounted && request == _request) state = AsyncData(plan);
  }
}

final latestCompletedWorkoutsProvider =
    StreamProvider<List<WorkoutSessionPreview>>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) return Stream.value([]);
  return ref
      .watch(databaseProvider)
      .workoutsDao
      .watchLatestCompletedPreviews(user.id);
});

/// Fresh account-scoped lookup for choosing a program other than the current one.
final trainingCompletionLookupProvider =
    Provider<Future<List<WorkoutSessionPreview>> Function(List<String>)>((ref) {
  final user = ref.watch(authProvider);
  final dao = ref.watch(databaseProvider).workoutsDao;
  return (ids) => user == null
      ? Future.value([])
      : dao.watchLatestCompletedPreviews(user.id, routineIds: ids).first;
});

final programCompletionsProvider =
    StreamProvider<List<WorkoutSessionPreview>>((ref) {
  final user = ref.watch(authProvider);
  final plan = ref.watch(trainingPlanProvider).valueOrNull;
  final routines = ref.watch(hydratedRoutinesProvider).valueOrNull;
  if (user == null || plan?.programSlug == null || routines == null) {
    return Stream.value([]);
  }
  final members = orderedProgram(routines, plan!.programSlug!);
  return ref.watch(databaseProvider).workoutsDao.watchLatestCompletedPreviews(
      user.id,
      routineIds: members?.map((r) => r.routine.id).toList() ?? []);
});

class TrainingPlanResolution {
  const TrainingPlanResolution(
      {this.next,
      this.programName,
      this.reason,
      this.problem,
      this.following = false});
  final HydratedRoutine? next;
  final String? programName;
  final String? reason;
  final String? problem;
  final bool following;
}

TrainingPlanResolution resolveTrainingPlan(TrainingPlan? plan,
    List<HydratedRoutine> routines, List<WorkoutSessionPreview> completions) {
  if (plan == null) return const TrainingPlanResolution();
  HydratedRoutine? anchor;
  for (final r in routines) {
    if (r.routine.id == plan.anchorId) anchor = r;
  }
  if (plan.needsChoice || anchor == null) {
    return const TrainingPlanResolution(
        problem: 'Your saved training plan needs a choice.');
  }
  if (!plan.followsProgram) {
    return TrainingPlanResolution(
        next: anchor, reason: 'Repeating your chosen routine');
  }
  final members = orderedProgram(routines, plan.programSlug!);
  if (members == null ||
      !members.any((r) => r.routine.id == anchor!.routine.id)) {
    return const TrainingPlanResolution(
        problem: 'Saved program order is incomplete. Choose a training plan.');
  }
  final history = completions
      .where((p) =>
          p.session.endedAt != null &&
          (plan.startAfter == null ||
              p.session.endedAt!.isAfter(plan.startAfter!)) &&
          members.any((r) => r.routine.id == p.session.routineId))
      .toList()
    ..sort((a, b) => b.session.endedAt!.compareTo(a.session.endedAt!));
  if (history.length > 1 &&
      history[0].session.endedAt == history[1].session.endedAt &&
      history[0].session.routineId != history[1].session.routineId) {
    return const TrainingPlanResolution(
        problem:
            'Two program workouts finished at the same time. Choose the next workout explicitly.');
  }
  final previous = history.isEmpty
      ? null
      : members
          .firstWhere((r) => r.routine.id == history.first.session.routineId);
  final next = previous == null
      ? anchor
      : members[(members.indexOf(previous) + 1) % members.length];
  return TrainingPlanResolution(
      next: next,
      following: true,
      programName:
          decodeProgramMembership(members.first.routine.notes)!.programLabel,
      reason: previous == null
          ? 'Selected starting workout'
          : 'After ${previous.routine.name} in your saved order');
}

final trainingPlanResolutionProvider =
    Provider<AsyncValue<TrainingPlanResolution>>((ref) {
  final plan = ref.watch(trainingPlanProvider);
  final library = ref.watch(hydratedRoutinesProvider);
  final completions = ref.watch(programCompletionsProvider);
  for (final value in <AsyncValue<dynamic>>[
    plan,
    library,
    if (plan.valueOrNull?.followsProgram == true) completions
  ]) {
    if (value.hasError) return AsyncError(value.error!, value.stackTrace!);
    if (value.isLoading) return const AsyncLoading();
  }
  return AsyncData(resolveTrainingPlan(
      plan.valueOrNull, library.requireValue, completions.valueOrNull ?? []));
});
