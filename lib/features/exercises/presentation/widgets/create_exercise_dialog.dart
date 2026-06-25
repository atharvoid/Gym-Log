import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/exercises/muscle_taxonomy.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import '../providers/exercises_provider.dart';

/// Opens the "Create custom exercise" dialog. Returns the newly-created
/// [Exercise] (so a selection flow can pop straight back with it), or null if
/// the user cancelled.
Future<Exercise?> showCreateExerciseDialog({
  required BuildContext context,
  String? initialName,
}) {
  HapticFeedback.selectionClick();
  return showDialog<Exercise>(
    context: context,
    useRootNavigator: true,
    builder: (_) => _CreateExerciseDialog(initialName: initialName),
  );
}

/// Equipment choices offered for custom exercises. Values are stored verbatim
/// in `exercises.equipment` and matched (lower-cased) by the library's
/// equipment filter, so they intentionally mirror the catalog's vocabulary.
const _equipmentOptions = <String>[
  'Barbell',
  'Dumbbell',
  'Machine',
  'Cable',
  'Bodyweight',
  'Kettlebell',
  'Resistance Band',
  'Smith Machine',
  'Other',
];

/// Maps a taxonomy parent muscle to the coarse `bodyPart` region the library
/// filters on, so a custom exercise lands under the right Muscle filter.
String _regionForMuscle(String muscle) {
  switch (muscle) {
    case 'Chest':
      return 'chest';
    case 'Back':
      return 'back';
    case 'Shoulders':
      return 'shoulders';
    case 'Biceps':
    case 'Triceps':
      return 'arms';
    case 'Forearms':
      return 'forearms';
    case 'Quadriceps':
    case 'Hamstrings':
    case 'Glutes':
    case 'Adductors':
    case 'Abductors':
    case 'Calves':
    case 'Hip Flexors':
      return 'legs';
    case 'Core':
      return 'core';
    case 'Neck':
      return 'neck';
    default:
      final r = MuscleTaxonomy.regionOf(muscle);
      return r == 'other' ? 'full body' : r;
  }
}

class _CreateExerciseDialog extends ConsumerStatefulWidget {
  final String? initialName;
  const _CreateExerciseDialog({this.initialName});

  @override
  ConsumerState<_CreateExerciseDialog> createState() =>
      _CreateExerciseDialogState();
}

class _CreateExerciseDialogState extends ConsumerState<_CreateExerciseDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initialName?.trim() ?? '');
  String _muscle = MuscleTaxonomy.parents.first; // 'Chest'
  String _equipment = _equipmentOptions.first; // 'Barbell'
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_saving) return;
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give your exercise a name.');
      return;
    }
    final user = ref.read(authProvider);
    if (user == null) {
      setState(() => _error = "You're signed out — sign in to add exercises.");
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final dao = ref.read(databaseProvider).exercisesDao;

    if (await dao.exerciseNameExists(name)) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '"$name" is already in your library.';
      });
      return;
    }

    final id = await dao.createCustomExercise(
      name,
      userId: user.id,
      bodyPart: _regionForMuscle(_muscle),
      target: _muscle,
      equipment: _equipment,
    );
    final created = await dao.getExerciseById(id);

    ref.invalidate(exerciseListProvider);
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    Navigator.of(context).pop(created);
  }

  Future<void> _pick({
    required String title,
    required List<String> options,
    required String current,
    required ValueChanged<String> onSelected,
  }) async {
    final v = await _showOptionSheet(
        context: context, title: title, options: options, current: current);
    if (v != null && mounted) setState(() => onSelected(v));
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    return Dialog(
      backgroundColor: AppColors.surface2,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardAll),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New exercise', style: AppText.sectionHeading()),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              maxLength: 60,
              cursorColor: accent.base,
              style: AppText.value(),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _create(),
              decoration: InputDecoration(
                hintText: 'Exercise name',
                hintStyle: AppText.body(color: AppColors.textTertiary),
                counterStyle: AppText.caption(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.surface3,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: AppRadius.inputAll,
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.inputAll,
                  borderSide: BorderSide(color: accent.light, width: 1.5),
                ),
              ),
            ),
            _label('PRIMARY MUSCLE'),
            _SelectField(
              value: _muscle,
              onTap: () => _pick(
                title: 'Primary Muscle',
                options: MuscleTaxonomy.parents,
                current: _muscle,
                onSelected: (v) => _muscle = v,
              ),
            ),
            const SizedBox(height: 14),
            _label('EQUIPMENT'),
            _SelectField(
              value: _equipment,
              onTap: () => _pick(
                title: 'Equipment',
                options: _equipmentOptions,
                current: _equipment,
                onSelected: (v) => _equipment = v,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'An animated demo isn’t added for custom exercises yet — the rest '
              'tracks exactly like any other lift.',
              style: AppText.caption(color: AppColors.textTertiary)
                  .copyWith(height: 1.4),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 15, color: AppColors.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(_error!,
                        style: AppText.statLabel(color: AppColors.error)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: Text('Cancel',
                      style: AppText.button(color: AppColors.textSecondary)),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: _saving ? null : _create,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.textPrimary),
                        )
                      : Text('Create',
                          style: AppText.button(color: accent.light)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 14),
        child: Text(text,
            style: AppText.columnHeader(color: AppColors.textSecondary)),
      );
}

/// Tappable select field that opens a branded option sheet — the app's sheet
/// language, not a stock Material dropdown overlay.
class _SelectField extends StatelessWidget {
  final String value;
  final VoidCallback onTap;
  const _SelectField({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: value,
      child: Material(
        color: AppColors.surface3,
        borderRadius: AppRadius.inputAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(child: Text(value, style: AppText.value())),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Branded option picker (scrollable so long lists never overflow).
Future<String?> _showOptionSheet({
  required BuildContext context,
  required String title,
  required List<String> options,
  required String current,
}) {
  HapticFeedback.lightImpact();
  return showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => Container(
      decoration: const BoxDecoration(
        color: AppColors.surface2,
        borderRadius: AppRadius.sheetTop,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderEmphasis,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Text(title, style: AppText.cardTitle()),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final o in options)
                        _OptionRow(
                          label: o,
                          selected: o == current,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.of(sheetCtx).pop(o);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _OptionRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _OptionRow(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(label,
                    style: AppText.body(
                        color:
                            selected ? accent.light : AppColors.textPrimary)),
              ),
              if (selected)
                Icon(Icons.check_rounded, size: 18, color: accent.base),
            ],
          ),
        ),
      ),
    );
  }
}
