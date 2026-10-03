import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/database/daos/routines_dao.dart';
import 'package:gymlog/core/database/daos/workouts_dao.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/shared/widgets/ui/app_card.dart';
import 'package:gymlog/shared/widgets/ui/app_status_tag.dart';
import 'package:gymlog/shared/widgets/ui/primary_button.dart';
import 'package:gymlog/shared/widgets/ui/app_snack_bar.dart';
import 'package:gymlog/features/workout/presentation/providers/active_workout_provider.dart';
import '../providers/routines_provider.dart';
import '../providers/training_launch_provider.dart';
import '../providers/training_plan_provider.dart';
import 'training_utility_button.dart';

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

Future<void> showTrainingChooser(BuildContext context,
        {bool forSession = false}) =>
    showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _TrainingChooser(forSession: forSession));

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

  @override
  Widget build(BuildContext context) {
    final resolution = ref.watch(trainingPlanResolutionProvider);
    final active = ref.watch(activeWorkoutProvider);
    final s = context.surface;
    final resolved = resolution.valueOrNull;
    final next = resolved?.next;
    final emptyLibrary =
        ref.watch(hydratedRoutinesProvider).valueOrNull?.isEmpty == true;
    final longLarge = next != null &&
        next.routine.name.length > 45 &&
        MediaQuery.textScalerOf(context).scale(14) >= 21;
    final activeName = (active?.name ?? '').trim();
    final resumeName = activeName.isEmpty ? 'workout' : activeName;
    Widget primary(String label, VoidCallback action,
            {Key? key, String? semanticLabel}) =>
        PrimaryButton(
            key: key,
            label: label,
            semanticLabel: semanticLabel,
            onPressed: action,
            isLoading: _starting);
    final unavailable = next != null && next.exerciseIds.isEmpty;
    Widget nextStart() => primary(
        unavailable
            ? 'Add exercises'
            : next!.routine.name.length > 45
                ? 'Start workout'
                : 'Start ${next.routine.name}',
        unavailable
            ? () => context.push('/routines/edit?id=${next.routine.id}')
            : () => _start(next.routine.id),
        key: const ValueKey('chosen-routine-start'),
        semanticLabel: unavailable
            ? 'Add exercises to ${next.routine.name}'
            : 'Start ${next.routine.name}');
    return AppCard(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      LayoutBuilder(builder: (context, constraints) {
        final tag = AppStatusTag(
            label: active == null ? 'Up next' : 'In progress',
            backgroundColor: context.accent.muted,
            textColor: context.accent.base);
        final change = TextButton(
            key: const ValueKey('change-training-routine'),
            style: TextButton.styleFrom(
                foregroundColor: s.textPrimary,
                minimumSize: const Size(48, 48)),
            onPressed: () => showTrainingChooser(context),
            child: Text('Training plan', style: AppText.button()));
        if (MediaQuery.textScalerOf(context).scale(14) >= 21 ||
            constraints.maxWidth < 290) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tag,
                if (!widget.compact)
                  Align(alignment: Alignment.centerRight, child: change)
              ]);
        }
        return Row(children: [
          Expanded(child: Align(alignment: Alignment.centerLeft, child: tag)),
          if (!widget.compact) change
        ]);
      }),
      if (active != null) ...[
        Text('Workout in progress',
            style: AppText.meta(color: s.textSecondary)),
        const SizedBox(height: 8),
        Text(resumeName, style: AppText.titleLarge(color: s.textPrimary)),
        const SizedBox(height: 16),
        primary('Resume $resumeName', () => _start(null)),
        const SizedBox(height: 20),
        Align(
            alignment: Alignment.centerLeft,
            child: AppStatusTag(
                label: 'For later',
                backgroundColor: context.accent.muted,
                textColor: context.accent.base)),
        const SizedBox(height: 8),
      ],
      if (resolution.isLoading) ...[
        Text('Loading your training plan',
            style: AppText.sheetTitle(color: s.textPrimary)),
        const SizedBox(height: 12),
        const LinearProgressIndicator(),
      ] else if (resolution.hasError) ...[
        Semantics(
            liveRegion: true,
            child: Text("Couldn't load your training plan",
                style: AppText.sheetTitle(color: s.textPrimary))),
        Text('Your plan has not changed. Try loading again.',
            style: AppText.body(color: s.textSecondary)),
        TextButton(
            onPressed: () {
              ref.invalidate(hydratedRoutinesProvider);
              ref.invalidate(programCompletionsProvider);
              ref.read(trainingPlanProvider.notifier).load();
            },
            child: const Text('Try again')),
      ] else if (next != null) ...[
        Text(next.routine.name,
            style: longLarge
                ? AppText.sheetTitle(color: s.textPrimary)
                : AppText.titleLarge(color: s.textPrimary)),
        if (longLarge && active == null) ...[
          const SizedBox(height: 16),
          nextStart(),
          const SizedBox(height: 12),
        ],
        if (resolved?.programName != null) ...[
          const SizedBox(height: 4),
          Text(resolved!.programName!,
              style: AppText.body(color: s.textSecondary)),
        ],
        const SizedBox(height: 8),
        if (longLarge && resolved!.following)
          Semantics(
              label: resolved.reason,
              child: ExcludeSemantics(
                  child: Text('Next in your saved program order',
                      style: AppText.body(color: s.textSecondary))))
        else
          Text(resolved!.reason!, style: AppText.body(color: s.textSecondary)),
        const SizedBox(height: 8),
        _PlannedCounts(routine: next),
        const SizedBox(height: 16),
        if (active == null && !longLarge) nextStart(),
      ] else ...[
        Text(
            resolved?.problem == null
                ? 'Your next session starts here'
                : 'Choose your next workout',
            style: AppText.titleLarge(color: s.textPrimary)),
        const SizedBox(height: 8),
        Text(
            resolved?.problem ??
                'Follow a saved program, repeat a routine, or log a workout your way.',
            style: AppText.body(color: s.textSecondary)),
        const SizedBox(height: 16),
        if (active == null)
          emptyLibrary
              ? primary('Start workout', () => _start(null))
              : primary(
                  'Choose training plan', () => showTrainingChooser(context)),
        TextButton(
            key: widget.browseKey,
            onPressed: widget.onBrowsePrograms ??
                () => context.push('/routines/explore'),
            child: const Text('Browse programs')),
      ],
      if (active == null && !emptyLibrary) ...[
        const SizedBox(height: 12),
        TrainingUtilityButton(
            label: 'Train something else',
            icon: Icons.swap_horiz_rounded,
            onPressed: () => showTrainingChooser(context, forSession: true)),
      ],
    ]));
  }
}

class _PlannedCounts extends ConsumerWidget {
  const _PlannedCounts({required this.routine});
  final HydratedRoutine routine;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(routineDetailProvider(routine.routine.id));
    final exercises = routine.exerciseIds.length;
    final sets = exercises == 0
        ? 0
        : detail.valueOrNull?.exercises
            .fold<int>(0, (n, e) => n + e.config.defaultSets);
    return Text(
        '$exercises ${exercises == 1 ? 'exercise' : 'exercises'}${sets == null ? '' : ' · $sets planned sets'}',
        style: AppText.meta(color: context.surface.textSecondary)
            .copyWith(fontFeatures: kTabular));
  }
}

class _TrainingChooser extends ConsumerStatefulWidget {
  const _TrainingChooser({required this.forSession});
  final bool forSession;
  @override
  ConsumerState<_TrainingChooser> createState() => _TrainingChooserState();
}

class _TrainingChooserState extends ConsumerState<_TrainingChooser> {
  String _query = '';
  int _page = 0;
  bool _saving = false;
  String? _error;
  bool? _repeatOverride;
  Future<void> _choose(
      HydratedRoutine? routine, List<HydratedRoutine> routines) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.forSession) {
        HapticFeedback.mediumImpact();
        // Starting this workout never writes the persistent training preference.
        final launcher = ref.read(trainingLauncherProvider);
        final result = await (routine == null
            ? launcher.startFreestyle()
            : launcher.startRoutine(routine.routine.id));
        if (!mounted) return;
        if (result == LaunchResult.started || result == LaunchResult.resume) {
          final router = GoRouter.of(context);
          Navigator.pop(context);
          router.push('/workout/active');
        } else {
          setState(() {
            _saving = false;
            _error = result == LaunchResult.busy
                ? 'A workout is starting. Please wait.'
                : 'This routine is unavailable. Choose another.';
          });
        }
      } else {
        final repeat = _repeatOverride ??
            (ref.read(trainingPlanProvider).valueOrNull != null &&
                ref.read(trainingPlanProvider).valueOrNull?.followsProgram ==
                    false);
        final notifier = ref.read(trainingPlanProvider.notifier);
        final selected = planForRoutine(routine!, routines, repeat: repeat);
        final members = selected.programSlug == null
            ? null
            : orderedProgram(routines, selected.programSlug!);
        final completed = members == null
            ? <WorkoutSessionPreview>[]
            : await ref.read(trainingCompletionLookupProvider)(
                members.map((r) => r.routine.id).toList());
        if (!mounted) return;
        if (!identical(notifier, ref.read(trainingPlanProvider.notifier))) {
          throw StateError('Account changed during plan selection');
        }
        completed
            .sort((a, b) => b.session.endedAt!.compareTo(a.session.endedAt!));
        final tied = completed.length > 1 &&
            completed[0].session.endedAt == completed[1].session.endedAt &&
            completed[0].session.routineId != completed[1].session.routineId;
        await notifier.choose(routine, routines,
            repeat: repeat,
            startAfter: tied ? completed[0].session.endedAt : null);
        if (mounted) Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = widget.forSession
              ? "Couldn't start the workout. Try again."
              : "Couldn't save your plan. Try again.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(hydratedRoutinesProvider);
    final plan = ref.watch(trainingPlanProvider).valueOrNull;
    final repeat = _repeatOverride ?? (plan != null && !plan.followsProgram);
    final next = ref.watch(trainingPlanResolutionProvider).valueOrNull?.next;
    final routines = library.valueOrNull ?? <HydratedRoutine>[];
    final matches = routines
        .where((r) => '${r.routine.name} ${r.routine.sourceProgramName ?? ''}'
            .toLowerCase()
            .contains(_query.toLowerCase()))
        .toList();
    final page =
        _page.clamp(0, matches.isEmpty ? 0 : (matches.length - 1) ~/ 4);
    final s = context.surface;
    return Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Container(
            constraints: BoxConstraints(
                maxHeight: (MediaQuery.sizeOf(context).height -
                        MediaQuery.viewInsetsOf(context).bottom) *
                    .9),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: s.surface2, borderRadius: AppRadius.sheetTop),
            child: SafeArea(
              top: false,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text(
                              widget.forSession
                                  ? 'For this session'
                                  : 'Training plan',
                              style: AppText.sectionHeading(
                                  color: s.textPrimary))),
                      IconButton(
                          tooltip: 'Close routine chooser',
                          onPressed:
                              _saving ? null : () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded))
                    ]),
                    Text(
                        widget.forSession
                            ? MediaQuery.viewInsetsOf(context).bottom > 0
                                ? 'Your plan stays selected.'
                                : 'For today only. Your training plan stays selected.'
                            : MediaQuery.viewInsetsOf(context).bottom > 0
                                ? 'Saved order follows completed workouts.'
                                : 'Follow a program after each completed workout, or repeat a routine.',
                        style: AppText.meta(color: s.textSecondary)),
                    const SizedBox(height: 12),
                    TextField(
                        enabled: !_saving,
                        decoration: const InputDecoration(
                            labelText: 'Search your routines',
                            prefixIcon: Icon(Icons.search_rounded)),
                        onChanged: (value) => setState(() {
                              _query = value;
                              _page = 0;
                            })),
                    const SizedBox(height: 12),
                    if (_saving) ...[
                      Semantics(
                          liveRegion: true,
                          child: Text(
                              widget.forSession
                                  ? 'Starting workout'
                                  : 'Saving training plan',
                              style: AppText.meta(color: s.textSecondary))),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                    ],
                    if (_error != null) ...[
                      Semantics(
                          liveRegion: true,
                          child: Text(_error!,
                              style: AppText.meta(color: s.textPrimary))),
                      const SizedBox(height: 8),
                    ],
                    Flexible(
                        child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!widget.forSession &&
                                routines.any((r) =>
                                    planForRoutine(r, routines).followsProgram))
                              Material(
                                  color: Colors.transparent,
                                  child: SwitchListTile.adaptive(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text('Repeat one routine',
                                          style: AppText.body(
                                              color: s.textPrimary)),
                                      subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                repeat
                                                    ? 'Routine choices repeat after completion.'
                                                    : 'Program days follow saved order; standalone routines repeat.',
                                                style: AppText.meta(
                                                    color: s.textSecondary)),
                                            Text(
                                                'Tap a routine to save. Close without choosing to cancel.',
                                                style: AppText.meta(
                                                    color: s.textSecondary)),
                                          ]),
                                      thumbColor:
                                          WidgetStatePropertyAll(s.textPrimary),
                                      trackColor:
                                          WidgetStatePropertyAll(s.surface3),
                                      trackOutlineColor: WidgetStatePropertyAll(
                                          s.textSecondary),
                                      value: repeat,
                                      onChanged: _saving
                                          ? null
                                          : (value) => setState(
                                              () => _repeatOverride = value))),
                            if (library.isLoading)
                              const LinearProgressIndicator(),
                            if (library.hasError) ...[
                              Text('Routine choices unavailable',
                                  style: AppText.body(color: s.textPrimary)),
                              TextButton(
                                  onPressed: () =>
                                      ref.invalidate(hydratedRoutinesProvider),
                                  child: const Text('Try again')),
                            ],
                            if (!library.isLoading &&
                                !library.hasError &&
                                matches.isEmpty)
                              Text(
                                  routines.isEmpty
                                      ? 'No saved routines yet'
                                      : 'No matching routines',
                                  style: AppText.body(color: s.textSecondary)),
                            if (!widget.forSession &&
                                !library.isLoading &&
                                !library.hasError &&
                                routines.isEmpty)
                              TrainingUtilityButton(
                                  label: 'Browse programs',
                                  icon: Icons.explore_rounded,
                                  onPressed: () {
                                    final router = GoRouter.of(context);
                                    Navigator.pop(context);
                                    router.push('/routines/explore');
                                  }),
                            for (final r in matches.skip(page * 4).take(4)) ...[
                              _ChoiceRow(
                                  key: ValueKey('choose-${r.routine.id}'),
                                  startsWorkout: widget.forSession,
                                  title: r.routine.name,
                                  subtitle: r.exerciseIds.isEmpty
                                      ? 'Empty routine · add exercises first'
                                      : widget.forSession
                                          ? '${r.exerciseIds.length} exercises · ${r.routine.id == next?.routine.id ? 'Up next' : 'For today only'}'
                                          : planForRoutine(r, routines,
                                                      repeat: repeat)
                                                  .followsProgram
                                              ? 'Follow ${r.routine.sourceProgramName ?? 'saved program'} · ${r.routine.id == next?.routine.id ? 'Up next' : 'saved order'}'
                                              : 'Repeat this routine · ${r.exerciseIds.length} ${r.exerciseIds.length == 1 ? 'exercise' : 'exercises'}',
                                  selected: !widget.forSession &&
                                      r.routine.id == plan?.anchorId &&
                                      repeat == !plan!.followsProgram,
                                  onTap: _saving || r.exerciseIds.isEmpty
                                      ? null
                                      : () => _choose(r, routines)),
                              const SizedBox(height: 8),
                            ],
                            if (matches.length > 4)
                              Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                        '${page * 4 + 1} to ${(page * 4 + 4).clamp(0, matches.length)} of ${matches.length}',
                                        style: AppText.meta(
                                            color: s.textSecondary)),
                                    Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                              tooltip: 'Previous choices',
                                              onPressed: page == 0 || _saving
                                                  ? null
                                                  : () => setState(
                                                      () => _page = page - 1),
                                              icon: const Icon(
                                                  Icons.chevron_left_rounded)),
                                          IconButton(
                                              tooltip: 'More choices',
                                              onPressed: (page + 1) * 4 >=
                                                          matches.length ||
                                                      _saving
                                                  ? null
                                                  : () => setState(
                                                      () => _page = page + 1),
                                              icon: const Icon(
                                                  Icons.chevron_right_rounded)),
                                        ]),
                                  ]),
                            if (widget.forSession) ...[
                              const SizedBox(height: 12),
                              Text(
                                  'Completing a day from your program continues from that day. Other workouts leave its order unchanged.',
                                  style: AppText.meta(color: s.textSecondary)),
                              const SizedBox(height: 12),
                              TrainingUtilityButton(
                                  label: 'Start without a routine',
                                  icon: Icons.add_rounded,
                                  onPressed: _saving
                                      ? null
                                      : () => _choose(null, routines)),
                            ],
                          ]),
                    )),
                  ]),
            )));
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.selected,
      this.startsWorkout = false,
      required this.onTap});
  final String title, subtitle;
  final bool selected;
  final bool startsWorkout;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: context.surface.surface3,
        borderRadius: AppRadius.cardAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardAll,
          child: Semantics(
            button: true,
            label: startsWorkout ? 'Start this workout for this session' : null,
            selected: selected,
            enabled: onTap != null,
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Icon(
                      startsWorkout
                          ? Icons.play_arrow_rounded
                          : selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                      color: onTap == null
                          ? context.surface.textDisabled
                          : context.accent.base),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(title,
                            style: AppText.sheetTitle(
                                color: context.surface.textPrimary)),
                        const SizedBox(height: 4),
                        Text(subtitle,
                            style: AppText.meta(
                                color: context.surface.textSecondary)),
                      ])),
                ])),
          ),
        ),
      );
}
