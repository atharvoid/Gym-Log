import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/providers/premium_provider.dart';
import 'package:gymlog/core/providers/settings_provider.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/routines/domain/ai_import_models.dart';
import 'package:gymlog/features/routines/presentation/providers/ai_routine_import_provider.dart';
import 'package:gymlog/shared/layout/adaptive.dart';
import 'package:gymlog/shared/widgets/exercise_gif_widget.dart';
import 'package:gymlog/shared/widgets/premium_paywall.dart';
import 'package:gymlog/shared/widgets/ui/app_action_chip.dart';
import 'package:gymlog/shared/widgets/ui/app_button_shell.dart';
import 'package:gymlog/shared/widgets/ui/app_snack_bar.dart';
import 'package:gymlog/shared/widgets/ui/app_status_tag.dart';
import 'package:gymlog/shared/widgets/ui/primary_button.dart';

/// Interactive review and reconciliation screen for AI-imported routines.
/// Serves as the human-in-the-loop verification gate against hallucinated lifts.
class AiRoutineReviewScreen extends ConsumerStatefulWidget {
  const AiRoutineReviewScreen({super.key});

  @override
  ConsumerState<AiRoutineReviewScreen> createState() =>
      _AiRoutineReviewScreenState();
}

class _AiRoutineReviewScreenState extends ConsumerState<AiRoutineReviewScreen> {
  late TextEditingController _titleController;
  int _activeDayIndex = 0;

  @override
  void initState() {
    super.initState();
    final routine = ref.read(aiRoutineImportProvider).reconciledRoutine;
    _titleController =
        TextEditingController(text: routine?.routineName ?? 'Imported Routine');
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _swapOrSearchExercise(int dayIndex, int exIndex) async {
    HapticFeedback.lightImpact();
    final selected = await context.push<Exercise>('/exercises/select');
    if (selected == null || !mounted) return;

    final current = ref
        .read(aiRoutineImportProvider)
        .reconciledRoutine!
        .days[dayIndex]
        .exercises[exIndex];

    final updated = current.copyWith(
      matchedExerciseId: selected.id,
      matchedExerciseName: selected.name,
      matchedEquipment: selected.equipment,
      matchedBodyPart: selected.bodyPart,
      matchedGifUrl: selected.gifUrl,
      status: ReconciliationStatus.verified,
      confidenceScore: 1.0,
      suggestions: const [],
    );

    ref
        .read(aiRoutineImportProvider.notifier)
        .updateExercise(dayIndex, exIndex, updated);
  }

  Future<void> _addExercise(int dayIndex) async {
    HapticFeedback.lightImpact();
    final selected = await context.push<Exercise>('/exercises/select');
    if (selected == null || !mounted) return;

    ref.read(aiRoutineImportProvider.notifier).addExercise(dayIndex, selected);
  }

  Future<void> _editReps(
      int dayIndex, int exIndex, String currentRepsDisplay) async {
    HapticFeedback.selectionClick();
    final controller = TextEditingController(text: currentRepsDisplay);
    final newReps = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final surface = ctx.surface;
        final accent = ctx.accent;
        return AlertDialog(
          backgroundColor: surface.surface2,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardAll),
          title: Text(
            'Target Reps',
            style: AppText.sheetTitle(color: surface.textPrimary),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            cursorColor: accent.base,
            style: AppText.body(color: surface.textPrimary),
            decoration: InputDecoration(
              hintText: 'e.g. 8-10, 12, 30s HOLD',
              hintStyle: AppText.body(color: surface.textSecondary),
              filled: true,
              fillColor: surface.surface3,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: AppRadius.cardAll,
                borderSide: BorderSide(color: surface.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.cardAll,
                borderSide: BorderSide(color: surface.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.cardAll,
                borderSide: BorderSide(color: accent.base, width: 1.5),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: AppText.button(color: surface.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: Text(
                'Save',
                style: AppText.button(color: accent.base)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (newReps != null && newReps.isNotEmpty && mounted) {
      final current = ref
          .read(aiRoutineImportProvider)
          .reconciledRoutine!
          .days[dayIndex]
          .exercises[exIndex];
      ref.read(aiRoutineImportProvider.notifier).updateExercise(
            dayIndex,
            exIndex,
            current.copyWith(rawReps: newReps),
          );
    }
  }

  Future<void> _handleSave() async {
    HapticFeedback.mediumImpact();
    ref
        .read(aiRoutineImportProvider.notifier)
        .updateRoutineName(_titleController.text);

    final user = ref.read(authProvider);
    final userId = user?.id ?? 'local_user';
    final isPremium = ref.read(isPremiumProvider);
    final db = ref.read(databaseProvider);
    final count = await db.routinesDao.countRoutinesForUser(userId);

    if (isAtFreeRoutineLimit(isPremium: isPremium, routineCount: count)) {
      if (mounted) {
        await showPremiumPaywall(context, source: PaywallSource.routineLimit);
      }
      return;
    }

    final routineId =
        await ref.read(aiRoutineImportProvider.notifier).saveRoutine();

    if (routineId != null && mounted) {
      showAppSnackBar(
        context,
        message: 'Routine imported successfully.',
        variant: AppSnackBarVariant.success,
      );
      ref.read(aiRoutineImportProvider.notifier).reset();
      // Navigate to the created routine detail screen
      context.go('/routines/$routineId');
    } else if (mounted) {
      final error = ref.read(aiRoutineImportProvider).errorMessage ??
          'Failed to save routine. Please try again.';
      showAppSnackBar(
        context,
        message: error,
        variant: AppSnackBarVariant.error,
      );
    }
  }

  String _formatWeightDisplay(double weightKg, String unit) {
    final isLbs = unit.toLowerCase() == 'lbs' || unit.toLowerCase() == 'lb';
    final val =
        isLbs ? ((weightKg / 0.45359237) * 2).roundToDouble() / 2 : weightKg;
    final str = val % 1 == 0 ? val.toInt().toString() : val.toString();
    return '$str $unit';
  }

  String _formatRepsDisplay(ReconciledExercise ex) {
    if (ex.rawReps != null && ex.rawReps!.trim().isNotEmpty) {
      final raw = ex.rawReps!.trim();
      final lower = raw.toLowerCase();
      if (lower.contains('hold') ||
          lower.contains('sec') ||
          lower.endsWith('s') ||
          lower.contains('rep') ||
          lower.contains('amrap')) {
        return raw;
      }
      return '$raw reps';
    }
    if (ex.defaultReps != null) {
      return '${ex.defaultReps} reps';
    }
    return 'Set reps';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiRoutineImportProvider);
    final routine = state.reconciledRoutine;
    final surface = context.surface;
    final accent = context.accent;
    final weightUnit = ref.watch(weightUnitProvider);

    if (routine == null) {
      return Scaffold(
        backgroundColor: surface.bgBase,
        body: Center(
          child: Text(
            'No routine data to review.',
            style: AppText.body(color: surface.textSecondary),
          ),
        ),
      );
    }

    final safeDayIndex = _activeDayIndex.clamp(0, routine.days.length - 1);
    final activeDay = routine.days[safeDayIndex];

    return Scaffold(
      backgroundColor: surface.bgBase,
      appBar: AppBar(
        backgroundColor: surface.bgBase,
        scrolledUnderElevation: 0,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          tooltip: 'Close',
          icon: Icon(Icons.close_rounded, color: surface.textPrimary),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Review Routine',
          style: AppText.sheetTitle(color: surface.textPrimary),
        ),
        centerTitle: false,
      ),
      body: AdaptiveContent(
        child: Column(
          children: [
            // ── Routine name input matching RoutineEditorScreen ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Semantics(
                label: 'Routine name',
                child: TextField(
                  controller: _titleController,
                  maxLength: 50,
                  textCapitalization: TextCapitalization.words,
                  cursorColor: accent.base,
                  style: AppText.sheetTitle(color: surface.textPrimary)
                      .copyWith(fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Routine name',
                    counterText: '',
                    hintStyle: AppText.sheetTitle(color: surface.textSecondary)
                        .copyWith(fontWeight: FontWeight.w500),
                    filled: true,
                    fillColor: surface.surface2,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.cardAll,
                      borderSide: BorderSide(color: surface.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.cardAll,
                      borderSide: BorderSide(color: surface.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.cardAll,
                      borderSide: BorderSide(color: accent.base, width: 1.5),
                    ),
                  ),
                  onChanged: (val) {
                    ref
                        .read(aiRoutineImportProvider.notifier)
                        .updateRoutineName(val);
                  },
                ),
              ),
            ),

            // Multi-day tabs if program has multiple days
            if (routine.isMultiDay)
              Container(
                height: 38,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: routine.days.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final day = routine.days[idx];
                    final isSelected = idx == safeDayIndex;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _activeDayIndex = idx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? accent.muted : surface.surface2,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                isSelected ? accent.base : surface.borderSubtle,
                          ),
                        ),
                        child: Text(
                          day.dayName,
                          style: AppText.button(
                            color: isSelected
                                ? accent.light
                                : surface.textSecondary,
                          ).copyWith(fontSize: 13),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Exercises Reorderable List
            Expanded(
              child: activeDay.exercises.isEmpty
                  ? Center(
                      child: Text(
                        'No exercises in this day.',
                        style: AppText.body(color: surface.textSecondary),
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      // +1 item: the last slot is the "Add Exercise" button
                      itemCount: activeDay.exercises.length + 1,
                      buildDefaultDragHandles: false,
                      onReorderStart: (_) => HapticFeedback.selectionClick(),
                      onReorderItem: (oldIdx, newIdx) {
                        // Protect the trailing "Add Exercise" item from being reordered
                        if (oldIdx >= activeDay.exercises.length) return;
                        HapticFeedback.mediumImpact();
                        final clampedNew =
                            newIdx > activeDay.exercises.length - 1
                                ? activeDay.exercises.length - 1
                                : newIdx;
                        ref
                            .read(aiRoutineImportProvider.notifier)
                            .reorderExercises(
                              safeDayIndex,
                              oldIdx,
                              clampedNew,
                            );
                      },
                      itemBuilder: (context, index) {
                        if (index == activeDay.exercises.length) {
                          return _buildAddExerciseButton(safeDayIndex);
                        }

                        final ex = activeDay.exercises[index];
                        return _buildExerciseCard(
                          key: ValueKey('ex_${safeDayIndex}_$index'),
                          ex: ex,
                          dayIndex: safeDayIndex,
                          exIndex: index,
                          weightUnit: weightUnit,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      // ── Dedicated, full-width Save Routine button ──
      bottomNavigationBar: Container(
        color: surface.bgBase,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SafeArea(
          top: false,
          child: PrimaryButton(
            label: 'Save Routine',
            icon: Icons.check_rounded,
            isLoading: state.isLoading,
            onPressed: routine.days.any((d) => d.exercises.isNotEmpty)
                ? _handleSave
                : null,
          ),
        ),
      ),
    );
  }

  /// Builds the non-reorderable "Add Exercise" button matching RoutineEditorScreen
  Widget _buildAddExerciseButton(int dayIndex) {
    return Padding(
      key: const ValueKey('add_exercise_button'),
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.buttonSecondary),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.buttonSecondary),
          onTap: () => _addExercise(dayIndex),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: context.surface.borderSubtle),
              borderRadius: BorderRadius.circular(AppRadius.buttonSecondary),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppButtonShell(
              label: 'Add Exercise',
              style: AppText.button(
                color: context.surface.textPrimary.withValues(alpha: 0.90),
              ).copyWith(fontSize: 15),
              icon: Icons.add_rounded,
              iconSize: 18,
              iconColor: context.surface.textPrimary.withValues(alpha: 0.90),
              minHeight: 48,
              expand: true,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard({
    required Key key,
    required ReconciledExercise ex,
    required int dayIndex,
    required int exIndex,
    required String weightUnit,
  }) {
    final surface = context.surface;
    final accent = context.accent;

    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          decoration: BoxDecoration(
            gradient: surface.isLight
                ? AppColors.cardGradientLight
                : AppColors.cardGradient,
            border: Border.all(color: surface.borderSubtle),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Stack(
            children: [
              // Left accent bar
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 2,
                child: Container(
                  color: ex.isVerified
                      ? AppColors.success.withValues(alpha: 0.5)
                      : accent.base.withValues(alpha: 0.35),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Row 1: Drag handle, thumbnail, exercise name + subtitle, and remove button
                    Row(
                      children: [
                        ReorderableDragStartListener(
                          index: exIndex,
                          child: Semantics(
                            label: 'Reorder ${ex.displayName}',
                            child: Container(
                              width: 32,
                              height: 44,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.drag_indicator_rounded,
                                size: 20,
                                color:
                                    surface.textPrimary.withValues(alpha: 0.30),
                              ),
                            ),
                          ),
                        ),
                        ClipRRect(
                          borderRadius: AppRadius.thumbnailAll,
                          child: ex.matchedGifUrl != null &&
                                  ex.matchedGifUrl!.isNotEmpty
                              ? ExerciseGifWidget(
                                  gifUrl: ex.matchedGifUrl,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  animate: false,
                                  borderRadius: AppRadius.thumbnailAll,
                                )
                              : Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: surface.surface2,
                                    borderRadius: AppRadius.thumbnailAll,
                                  ),
                                  child: Icon(
                                    Icons.fitness_center_rounded,
                                    size: 20,
                                    color: surface.textTertiary,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ex.displayName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    AppText.rowLabel(color: surface.textPrimary)
                                        .copyWith(fontSize: 14.5, height: 1.2),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ex.isUnmatched
                                    ? 'Custom Exercise • "${ex.rawName}"'
                                    : [
                                        if ((ex.matchedEquipment ?? '')
                                            .isNotEmpty)
                                          ex.matchedEquipment!,
                                        if ((ex.matchedBodyPart ?? '')
                                            .isNotEmpty)
                                          ex.matchedBodyPart!,
                                      ].join(' • '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.caption(
                                    color: surface.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove ${ex.displayName}',
                          constraints:
                              const BoxConstraints(minWidth: 48, minHeight: 48),
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: surface.textPrimary.withValues(alpha: 0.40),
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ref
                                .read(aiRoutineImportProvider.notifier)
                                .removeExercise(dayIndex, exIndex);
                          },
                        ),
                      ],
                    ),

                    // Row 2: Status pill on left, Stepper & Reps & Weight on right
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 44, right: 8, top: 6),
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          // Status badge (Verified / Suggested / Custom)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildStatusPill(ex),
                              if (ex.isDefaultedSets) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: surface.surface3,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'sets defaulted',
                                    style: AppText.caption(
                                            color: surface.textTertiary)
                                        .copyWith(fontSize: 10),
                                  ),
                                ),
                              ],
                            ],
                          ),

                          // Metrics: Sets Stepper + Interactive Reps Pill + Optional Weight
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _StepperButton(
                                icon: Icons.remove_rounded,
                                label: 'Decrease sets',
                                enabled: ex.sets > 1,
                                onTap: () => ref
                                    .read(aiRoutineImportProvider.notifier)
                                    .updateExercise(
                                      dayIndex,
                                      exIndex,
                                      ex.copyWith(
                                        sets: ex.sets - 1,
                                        isDefaultedSets: false,
                                      ),
                                    ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  '${ex.sets} sets',
                                  style:
                                      AppText.body(color: surface.textPrimary)
                                          .copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    fontFeatures: kTabular,
                                  ),
                                ),
                              ),
                              _StepperButton(
                                icon: Icons.add_rounded,
                                label: 'Increase sets',
                                enabled: ex.sets < 15,
                                onTap: () => ref
                                    .read(aiRoutineImportProvider.notifier)
                                    .updateExercise(
                                      dayIndex,
                                      exIndex,
                                      ex.copyWith(
                                        sets: ex.sets + 1,
                                        isDefaultedSets: false,
                                      ),
                                    ),
                              ),
                              const SizedBox(width: 8),

                              // Reps Chip (tap to edit) — interactive control with edit signifier and border
                              AppActionChip(
                                label: _formatRepsDisplay(ex),
                                signifier: ActionSignifier.edit,
                                visualHeight: 28,
                                minTouchTarget: 44,
                                onTap: () => _editReps(
                                  dayIndex,
                                  exIndex,
                                  ex.rawReps ??
                                      (ex.defaultReps != null
                                          ? '${ex.defaultReps}'
                                          : ''),
                                ),
                              ),

                              // Optional Weight — inert readout with flat tint, strictly NO border
                              if (ex.defaultWeightKg != null) ...[
                                const SizedBox(width: 6),
                                AppStatusTag(
                                  label: _formatWeightDisplay(
                                    ex.defaultWeightKg!,
                                    weightUnit,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Row 3: Notes (if any)
                    if (ex.notes != null && ex.notes!.isNotEmpty)
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 44, right: 8, top: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: surface.surface2,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: surface.borderSubtle),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.notes_rounded,
                                  size: 12, color: accent.base),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  ex.notes!,
                                  style: AppText.caption(
                                      color: surface.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Row 4: Suggestions chips & Search Library
                    if (ex.suggestions.isNotEmpty ||
                        ex.isSuggested ||
                        ex.isUnmatched)
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 44, right: 8, top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (ex.suggestions.isNotEmpty &&
                                (ex.isSuggested || ex.isUnmatched)) ...[
                              Text(
                                'Suggested catalog matches:',
                                style:
                                    AppText.caption(color: surface.textTertiary)
                                        .copyWith(fontSize: 11),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: ex.suggestions.map((s) {
                                  return AppActionChip(
                                    label: s.name,
                                    leadingIcon: Icons.auto_awesome_rounded,
                                    signifier: ActionSignifier.navigation,
                                    isSelected: true,
                                    visualHeight: 28,
                                    minTouchTarget: 44,
                                    borderRadius:
                                        const BorderRadius.all(Radius.circular(16)),
                                    onTap: () {
                                      ref
                                          .read(
                                              aiRoutineImportProvider.notifier)
                                          .linkExercise(dayIndex, exIndex, s);
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 6),
                            ],
                            InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () =>
                                  _swapOrSearchExercise(dayIndex, exIndex),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 2, horizontal: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.search_rounded,
                                        size: 13, color: accent.base),
                                    const SizedBox(width: 4),
                                    Text(
                                      ex.isSuggested
                                          ? 'Choose different exercise'
                                          : 'Search in Exercise Library',
                                      style: AppText.caption(color: accent.base)
                                          .copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11.5),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(ReconciledExercise ex) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (ex.status) {
      case ReconciliationStatus.verified:
        bg = AppColors.success.withValues(alpha: 0.12);
        fg = AppColors.success;
        label = 'Verified Match';
        icon = Icons.check_circle_rounded;
        break;
      case ReconciliationStatus.suggested:
        bg = AppColors.warning.withValues(alpha: 0.12);
        fg = AppColors.warning;
        label = 'Suggested Match';
        icon = Icons.help_outline_rounded;
        break;
      case ReconciliationStatus.unmatched:
        bg = context.surface.surface3;
        fg = context.surface.textSecondary;
        label = 'Custom Exercise';
        icon = Icons.info_outline_rounded;
        break;
    }

    return AppStatusTag(
      label: label,
      leadingIcon: icon,
      backgroundColor: bg,
      textColor: fg,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      borderRadius: const BorderRadius.all(Radius.circular(6)),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _StepperButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      excludeSemantics: true,
      onTap: enabled
          ? () {
              HapticFeedback.selectionClick();
              onTap();
            }
          : null,
      label: label,
      child: GestureDetector(
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onTap();
              }
            : null,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: surface.surface2,
                borderRadius: BorderRadius.circular(AppRadius.badge),
                border: Border.all(color: surface.borderSubtle),
              ),
              child: Icon(
                icon,
                size: 15,
                color: enabled
                    ? surface.textPrimary
                    : surface.textSecondary.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
