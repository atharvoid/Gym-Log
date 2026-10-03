import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/database/daos/routines_dao.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/models/measurement_type.dart';
import 'package:gymlog/core/providers/settings_provider.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/features/home/presentation/providers/home_provider.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';
import 'package:gymlog/shared/widgets/ui/primary_button.dart';
import 'package:gymlog/shared/widgets/ui/app_snack_bar.dart';
import '../providers/routines_provider.dart';
import '../providers/training_launch_provider.dart';

Future<void> launchTraining(
    BuildContext context, WidgetRef ref, String? id) async {
  try {
    final launcher = ref.read(trainingLauncherProvider);
    final result = await (id == null
        ? launcher.startFreestyle()
        : launcher.startRoutine(id));
    if (!context.mounted) return;
    if (result == LaunchResult.started || result == LaunchResult.resume) {
      context.push('/workout/active');
    } else if (result == LaunchResult.unavailable) {
      ref.invalidate(hydratedRoutinesProvider);
      showAppSnackBar(context,
          message:
              'This routine is unavailable or has no exercises. Choose another routine.');
    }
  } catch (_) {
    if (context.mounted) {
      showAppSnackBar(context,
          message: "Couldn't start the workout. Try again.");
    }
  }
}

Future<void> showTrainingChooser(BuildContext context) =>
    showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _TrainingChooser());

class TrainingLaunchpad extends ConsumerStatefulWidget {
  const TrainingLaunchpad(
      {super.key, this.browseKey, this.onBrowsePrograms, this.compact = false});
  final Key? browseKey;
  final VoidCallback? onBrowsePrograms;
  final bool compact;
  @override
  ConsumerState<TrainingLaunchpad> createState() => _TrainingLaunchpadState();
}

class _TrainingLaunchpadState extends ConsumerState<TrainingLaunchpad> {
  bool _starting = false;
  Future<void> _start(String? id) async {
    if (_starting) return;
    setState(() => _starting = true);
    await launchTraining(context, ref, id);
    if (mounted) setState(() => _starting = false);
  }

  Widget _primary(String label, VoidCallback action, {Key? key}) =>
      PrimaryButton(
          key: key, label: label, isLoading: _starting, onPressed: action);
  Widget _change({bool primary = false}) {
    if (widget.compact) {
      return Text(primary ? 'Choose on Home.' : 'Chosen on Home',
          style: AppText.meta(color: context.surface.textSecondary));
    }
    return primary
        ? _primary('Choose routine', () => showTrainingChooser(context))
        : TextButton.icon(
            key: const ValueKey('change-training-routine'),
            onPressed: () => showTrainingChooser(context),
            style: TextButton.styleFrom(
                foregroundColor: context.surface.textSecondary,
                minimumSize: const Size(48, 48)),
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const Text('Change'));
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(hydratedRoutinesProvider);
    final choice = ref.watch(chosenRoutineProvider);
    final history = ref.watch(workoutHistoryProvider);
    final active = ref.watch(activeWorkoutProvider);
    final now = ref.watch(trainingClockProvider)();
    final knownHistory = !history.isInitialLoad && !history.hasError;
    final returnAfterBreak =
        knownHistory && isInactiveReturn(history.items, now);
    final s = context.surface;
    final freestyleLabel = knownHistory && history.items.isEmpty
        ? 'Start workout'
        : 'Log a different workout';
    Widget freestyle() =>
        TextButton(onPressed: () => _start(null), child: Text(freestyleLabel));
    Widget message(String title, String body, Widget action) =>
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppText.titleLarge(color: s.textPrimary)),
          const SizedBox(height: AppSpacing.x3),
          Text(body, style: AppText.body(color: s.textSecondary)),
          const SizedBox(height: AppSpacing.x4),
          action,
        ]);
    final routines = library.valueOrNull ?? <HydratedRoutine>[];
    final id = choice.valueOrNull;
    HydratedRoutine? chosen;
    for (final r in routines) {
      if (r.routine.id == id) chosen = r;
    }
    if (active != null) {
      final activeName = (active.name ?? '').trim();
      final name = activeName.isEmpty ? 'workout' : activeName;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Workout in progress',
            style: AppText.caption(color: s.textSecondary)),
        const SizedBox(height: AppSpacing.x2),
        Text(name, style: AppText.titleLarge(color: s.textPrimary)),
        const SizedBox(height: AppSpacing.x4),
        _primary('Resume $name', () => _start(null)),
        const SizedBox(height: AppSpacing.x4),
        Text('HOME ROUTINE · FOR LATER',
            style: AppText.caption(color: s.textSecondary)),
        if (chosen != null) ...[
          Row(children: [
            Expanded(
                child: Text(chosen.routine.name,
                    style: AppText.sheetTitle(color: s.textPrimary))),
            _change(),
          ]),
          Text(trainingAgeLabel(chosen.lastTrained, now),
              style: AppText.meta(color: s.textSecondary)),
          if (chosen.exerciseIds.isEmpty)
            Text('This routine has no exercises',
                style: AppText.body(color: s.textSecondary)),
        ] else if (!library.hasError && !library.isLoading) ...[
          if (id != null || choice.hasError)
            Text('Routine choice unavailable',
                style: AppText.meta(color: s.textSecondary)),
          if (widget.compact)
            _change(primary: true)
          else
            TextButton(
                onPressed: () => showTrainingChooser(context),
                child: const Text('Choose routine')),
        ],
        if (library.hasError)
          Semantics(
              liveRegion: true,
              child: Text("Couldn't load your routines",
                  style: AppText.body(color: s.textSecondary))),
        if (library.hasError)
          TextButton(
              onPressed: () => ref.invalidate(hydratedRoutinesProvider),
              child: const Text('Try again')),
        if (library.isLoading || choice.isLoading)
          Text('Loading your routine choice',
              style: AppText.meta(color: s.textSecondary)),
      ]);
    }
    if (library.isLoading || choice.isLoading) {
      return message(
          'Loading your training choice',
          'Your saved routine will appear when available.',
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const LinearProgressIndicator(),
            if (widget.compact) freestyle(),
          ]));
    }
    if (library.hasError || choice.hasError) {
      if (widget.compact && !library.hasError) {
        return Semantics(
            liveRegion: true,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text("Home routine couldn't load",
                      style: AppText.meta(color: s.textSecondary)),
                  TextButton(
                      onPressed: () =>
                          ref.read(chosenRoutineProvider.notifier).load(),
                      child: const Text('Try again')),
                  freestyle(),
                ]));
      }
      return Semantics(
          liveRegion: true,
          child: message(
              library.hasError
                  ? "Couldn't load your routines"
                  : "Couldn't load your training choice",
              library.hasError
                  ? 'Try loading your saved routines again.'
                  : widget.compact
                      ? 'Choose your Home routine on Home, or try loading again.'
                      : 'Choose a routine to save a new choice, or try loading again.',
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (!library.hasError) _change(primary: true),
                if (library.hasError)
                  _primary('Try again',
                      () => ref.invalidate(hydratedRoutinesProvider))
                else
                  TextButton(
                      onPressed: () =>
                          ref.read(chosenRoutineProvider.notifier).load(),
                      child: const Text('Try again')),
                if (widget.compact) freestyle(),
              ])));
    }
    if (routines.isEmpty && id == null) {
      return message(
          knownHistory && history.items.isEmpty
              ? 'Your first session starts here'
              : 'No saved routine to start',
          'Log a workout, or add a routine to train from a plan.',
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (widget.compact)
              _primary(
                  'Browse programs',
                  widget.onBrowsePrograms ??
                      () => context.push('/routines/explore'))
            else
              _primary(freestyleLabel, () => _start(null)),
            TextButton(
                key: widget.browseKey,
                onPressed: widget.compact
                    ? () => _start(null)
                    : widget.onBrowsePrograms ??
                        () => context.push('/routines/explore'),
                child:
                    Text(widget.compact ? freestyleLabel : 'Browse programs')),
          ]));
    }
    if (chosen != null && chosen.exerciseIds.isEmpty) {
      final empty = chosen;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text('HOME ROUTINE',
                  style: AppText.caption(color: s.textSecondary))),
          if (!widget.compact) _change()
        ]),
        Text(empty.routine.name,
            style: AppText.titleLarge(color: s.textPrimary)),
        const SizedBox(height: AppSpacing.x2),
        Text(trainingAgeLabel(empty.lastTrained, now),
            style: AppText.meta(color: s.textSecondary)),
        const SizedBox(height: AppSpacing.x4),
        Text('Your chosen routine has no exercises',
            style: AppText.sheetTitle(color: s.textPrimary)),
        const SizedBox(height: AppSpacing.x2),
        Text(
            widget.compact
                ? 'Add exercises to this routine, or choose another on Home.'
                : 'Add exercises to this routine, or choose another.',
            style: AppText.body(color: s.textSecondary)),
        const SizedBox(height: AppSpacing.x4),
        _primary('Add exercises',
            () => context.push('/routines/edit?id=${empty.routine.id}')),
        if (widget.compact) freestyle(),
      ]);
    }
    if (chosen == null) {
      if (widget.compact) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                  id == null
                      ? 'No Home routine chosen'
                      : 'Home routine unavailable',
                  style: AppText.meta(color: s.textSecondary)),
              Text('Choose on Home.',
                  style: AppText.meta(color: s.textSecondary)),
              if (!routines.any((r) => r.exerciseIds.isNotEmpty))
                TextButton(
                    key: widget.browseKey,
                    onPressed: widget.onBrowsePrograms ??
                        () => context.push('/routines/explore'),
                    child: const Text('Browse programs')),
              freestyle(),
            ]);
      }
      final title = id == null
          ? widget.compact
              ? 'No Home routine chosen'
              : 'Choose a routine for today'
          : widget.compact
              ? 'Home routine unavailable'
              : 'Chosen routine unavailable';
      return message(
          title,
          widget.compact
              ? 'Choose your Home routine on Home. You can start any saved routine below, or log a different workout.'
              : id == null
                  ? 'Choose a saved plan. Nothing is selected automatically.'
                  : 'Choose another saved routine, or log a different workout.',
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (routines.any((r) => r.exerciseIds.isNotEmpty))
              _change(primary: true),
            if (!routines.any((r) => r.exerciseIds.isNotEmpty))
              TextButton(
                  key: widget.browseKey,
                  onPressed: widget.onBrowsePrograms ??
                      () => context.push('/routines/explore'),
                  child: const Text('Browse programs')),
            if (widget.compact) freestyle(),
          ]));
    }
    final detail = ref.watch(routineDetailProvider(chosen.routine.id));
    final lastSets = ref.watch(routineLastSetsProvider(chosen.routine.id));
    final selected = chosen;
    final planned = detail.valueOrNull?.exercises.fold<int>(
        0,
        (sum, e) =>
            sum + (e.config.defaultSets > 0 ? e.config.defaultSets : 1));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (returnAfterBreak) ...[
        Text('Train at your own pace',
            style: AppText.body(color: s.textPrimary)),
        const SizedBox(height: AppSpacing.x2),
      ],
      if (widget.compact) ...[
        Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('HOME ROUTINE',
                    style: AppText.caption(color: s.textSecondary)),
                Text(chosen.routine.name,
                    style: AppText.sectionHeading(color: s.textPrimary)),
              ])),
          _change(),
        ]),
      ] else ...[
        Row(children: [
          Expanded(
              child: Text('HOME ROUTINE',
                  style: AppText.caption(color: s.textSecondary))),
          _change()
        ]),
        Text(chosen.routine.name,
            style: AppText.screenTitle(color: s.textPrimary)),
      ],
      if (!widget.compact &&
          (chosen.routine.sourceProgramName?.isNotEmpty ?? false)) ...[
        const SizedBox(height: AppSpacing.x2),
        Text(chosen.routine.sourceProgramName!,
            style: AppText.body(color: s.textSecondary)),
      ],
      if (!widget.compact) ...[
        const SizedBox(height: AppSpacing.x2),
        Text(
            '${chosen.exerciseIds.length} ${chosen.exerciseIds.length == 1 ? 'exercise' : 'exercises'}${!widget.compact && planned != null ? ' · $planned planned ${planned == 1 ? 'set' : 'sets'}' : ''}',
            style: AppText.body(color: s.textSecondary)),
      ],
      if (!widget.compact && chosen.muscleTags.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.x2),
        Text(chosen.muscleTags.join(' · '),
            style: AppText.body(color: s.textPrimary)),
      ],
      const SizedBox(height: AppSpacing.x2),
      Text(trainingAgeLabel(chosen.lastTrained, now),
          style: AppText.meta(color: s.textSecondary)),
      if (!widget.compact) ...[
        const SizedBox(height: AppSpacing.x4),
        _previousContext(detail, lastSets),
      ],
      const SizedBox(height: AppSpacing.x4),
      _primary(
          'Start ${chosen.routine.name}', () => _start(selected.routine.id),
          key: const ValueKey('chosen-routine-start')),
    ]);
  }

  Widget _previousContext(AsyncValue<HydratedRoutineDetail?> detail,
      AsyncValue<Map<String, List<LastSessionSetData>>> sets) {
    final s = context.surface;
    String? result, spoken, exerciseName;
    if (detail.hasValue && sets.hasValue) {
      for (final e
          in detail.valueOrNull?.exercises ?? <HydratedRoutineExercise>[]) {
        final logged = sets.requireValue['${e.exercise.id}'] ?? [];
        if (logged.isEmpty) continue;
        final set = logged.firstWhere((s) => s.setType != 'warmup',
            orElse: () => logged.first);
        final type = MeasurementType.resolve(
            explicitValue: e.exercise.measurementType,
            equipment: e.exercise.equipment,
            exerciseName: e.exercise.name);
        final unit = ref.watch(exerciseUnitProvider(e.exercise.id));
        result = launchSetText(type, set, unit);
        if (result == null) continue;
        spoken = launchSetText(type, set, unit, spoken: true);
        exerciseName =
            '${e.exercise.name}${set.setType == 'warmup' ? ' · warm-up' : ''}';
        break;
      }
    }
    final text = detail.hasError || sets.hasError
        ? 'Previous-set context unavailable'
        : detail.isLoading || sets.isLoading
            ? 'Loading previous-set context'
            : result == null
                ? 'No previous logged set for this plan'
                : 'Logged set · $exerciseName';
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.x4),
        decoration:
            BoxDecoration(color: s.bgSurface, borderRadius: AppRadius.cardAll),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(text, style: AppText.meta(color: s.textSecondary)),
          if (result != null) ...[
            const SizedBox(height: AppSpacing.x2),
            Text(result,
                semanticsLabel: spoken,
                style: AppText.sheetTitle(color: s.textPrimary)
                    .copyWith(fontFeatures: kTabular)),
          ],
        ]));
  }
}

class _TrainingChooser extends ConsumerStatefulWidget {
  const _TrainingChooser();
  @override
  ConsumerState<_TrainingChooser> createState() => _TrainingChooserState();
}

class _TrainingChooserState extends ConsumerState<_TrainingChooser> {
  String _query = '';
  int _page = 0;
  bool _saving = false;
  String? _error;
  Future<void> _choose(String id) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(chosenRoutineProvider.notifier).choose(id);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = "Couldn't save your choice. Try again.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(hydratedRoutinesProvider);
    if (library.isLoading || library.hasError) {
      return Material(
          color: context.surface.surface2,
          borderRadius: AppRadius.sheetTop,
          child: SafeArea(
              top: false,
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                            library.hasError
                                ? 'Routine choices unavailable'
                                : 'Loading routine choices',
                            style: AppText.sectionHeading(
                                color: context.surface.textPrimary)),
                        if (library.hasError)
                          TextButton(
                              onPressed: () =>
                                  ref.invalidate(hydratedRoutinesProvider),
                              child: const Text('Try again')),
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close')),
                      ]))));
    }
    final routines = library.requireValue;
    final chosen = ref.watch(chosenRoutineProvider).valueOrNull;
    final history = ref.watch(workoutHistoryProvider);
    final suggestion =
        _query.isEmpty && !history.hasError && !history.isInitialLoad
            ? nextProgramSuggestion(routines, history.items, chosen)
            : null;
    final ordered = [...routines]..sort((a, b) =>
        (b.lastTrained ?? DateTime(0)).compareTo(a.lastTrained ?? DateTime(0)));
    final matches = ordered
        .where((r) => '${r.routine.name} ${r.routine.sourceProgramName ?? ''}'
            .toLowerCase()
            .contains(_query.toLowerCase()))
        .toList();
    if (_query.isEmpty) {
      matches.sort((a, b) => (a.routine.id == suggestion?.routine.routine.id
              ? -2
              : a.routine.id == chosen
                  ? -1
                  : 0)
          .compareTo(b.routine.id == suggestion?.routine.routine.id
              ? -2
              : b.routine.id == chosen
                  ? -1
                  : 0));
    }
    final page =
        _page.clamp(0, matches.isEmpty ? 0 : (matches.length - 1) ~/ 4);
    final visible = matches.skip(page * 4).take(4);
    final s = context.surface;
    return Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .88),
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
        decoration:
            BoxDecoration(color: s.surface2, borderRadius: AppRadius.sheetTop),
        child: SafeArea(
            top: false,
            child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Expanded(
                        child: Text('Routine on Home',
                            style:
                                AppText.sectionHeading(color: s.textPrimary))),
                    IconButton(
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Close routine chooser',
                        icon: const Icon(Icons.close_rounded))
                  ]),
                  Text(
                      'Choose the routine shown on Home. Suggestions are optional.',
                      style: AppText.meta(color: s.textSecondary)),
                  const SizedBox(height: AppSpacing.x3),
                  TextField(
                      enabled: !_saving,
                      decoration: const InputDecoration(
                          labelText: 'Search your routines',
                          prefixIcon: Icon(Icons.search_rounded)),
                      onChanged: (value) => setState(() {
                            _query = value;
                            _page = 0;
                          })),
                  const SizedBox(height: AppSpacing.x2),
                  if (matches.isEmpty)
                    Text('No matching routines',
                        style: AppText.body(color: s.textSecondary)),
                  for (final r in visible) ...[
                    Material(
                        color: Colors.transparent,
                        child: ListTile(
                            key: ValueKey('choose-${r.routine.id}'),
                            contentPadding: EdgeInsets.zero,
                            enabled: !_saving && r.exerciseIds.isNotEmpty,
                            selected: r.routine.id == chosen,
                            leading: Icon(r.routine.id == chosen
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked),
                            title: Text(r.routine.name,
                                style:
                                    AppText.sheetTitle(color: s.textPrimary)),
                            subtitle: Text(
                                r.routine.id == suggestion?.routine.routine.id
                                    ? 'Next in your program · Follows ${suggestion!.previousRoutineName} in saved order'
                                    : r.exerciseIds.isEmpty
                                        ? 'Empty plan · add exercises first'
                                        : '${r.exerciseIds.length} ${r.exerciseIds.length == 1 ? 'exercise' : 'exercises'} · ${r.routine.sourceProgramName ?? trainingAgeLabel(r.lastTrained, ref.read(trainingClockProvider)())}',
                                style: AppText.meta(color: s.textSecondary)),
                            onTap: () => _choose(r.routine.id))),
                  ],
                  if (matches.length > 4)
                    Row(children: [
                      Text(
                          '${page * 4 + 1} to ${(page * 4 + 4).clamp(0, matches.length)} of ${matches.length}',
                          style: AppText.meta(color: s.textSecondary)),
                      const Spacer(),
                      IconButton(
                          tooltip: 'Previous choices',
                          onPressed: page == 0 || _saving
                              ? null
                              : () => setState(() => _page = page - 1),
                          icon: const Icon(Icons.chevron_left_rounded)),
                      IconButton(
                          tooltip: 'More choices',
                          onPressed: (page + 1) * 4 >= matches.length || _saving
                              ? null
                              : () => setState(() => _page = page + 1),
                          icon: const Icon(Icons.chevron_right_rounded)),
                    ]),
                  if (_saving) const LinearProgressIndicator(),
                  if (_error != null)
                    Semantics(
                        liveRegion: true,
                        child: Text(_error!,
                            style: AppText.body(color: s.textPrimary))),
                ]))));
  }
}
