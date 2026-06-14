import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/exercises/muscle_taxonomy.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/theme/app_colors.dart';
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
/// filters on (chest / back / shoulders / arms / forearms / legs / core …),
/// so a custom exercise lands under the right Muscle filter.
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
      // Falls back to the taxonomy's own region map, then 'full body'.
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

    // Uniqueness: never shadow a catalog entry (or an existing custom one).
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

    // Refresh the library list so the new exercise appears immediately.
    ref.invalidate(exerciseListProvider);

    HapticFeedback.mediumImpact();
    if (!mounted) return;
    Navigator.of(context).pop(created);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bgSheet,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New exercise',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              maxLength: 60,
              cursorColor: AppColors.accentPrimary,
              style:
                  GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 16),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: _inputDecoration('Exercise name'),
            ),
            const SizedBox(height: 4),
            _label('PRIMARY MUSCLE'),
            _Dropdown(
              value: _muscle,
              items: MuscleTaxonomy.parents,
              onChanged: (v) => setState(() => _muscle = v),
            ),
            const SizedBox(height: 14),
            _label('EQUIPMENT'),
            _Dropdown(
              value: _equipment,
              items: _equipmentOptions,
              onChanged: (v) => setState(() => _equipment = v),
            ),
            const SizedBox(height: 12),
            Text(
              'An animated demo isn’t added for custom exercises yet — the rest '
              'tracks exactly like any other lift.',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _saving ? null : () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: _saving ? null : _create,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.accentPrimary),
                        )
                      : Text(
                          'Create',
                          style: GoogleFonts.inter(
                            color: AppColors.accentText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 4),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
          ),
        ),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: AppColors.textSecondary),
        counterStyle: GoogleFonts.inter(
            color: AppColors.textSecondary, fontSize: 11),
        filled: true,
        fillColor: AppColors.surfaceRaised,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.accentPrimary, width: 1.5),
        ),
      );
}

/// Dark, on-brand dropdown used for the muscle + equipment selectors.
class _Dropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  const _Dropdown(
      {required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary),
          style:
              GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
          items: [
            for (final item in items)
              DropdownMenuItem(value: item, child: Text(item)),
          ],
          onChanged: (v) {
            if (v != null) {
              HapticFeedback.selectionClick();
              onChanged(v);
            }
          },
        ),
      ),
    );
  }
}
