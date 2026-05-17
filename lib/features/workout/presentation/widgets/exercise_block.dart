import 'package:flutter/material.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'set_row.dart';

class ExerciseBlock extends StatefulWidget {
  final int exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final int numSets;
  final VoidCallback onRemove;
  final VoidCallback onReplace;
  final VoidCallback onAddNote;

  const ExerciseBlock({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.numSets,
    required this.onRemove,
    required this.onReplace,
    required this.onAddNote,
  });

  @override
  State<ExerciseBlock> createState() => _ExerciseBlockState();
}

class _ExerciseBlockState extends State<ExerciseBlock> {
  late int _numSets;

  @override
  void initState() {
    super.initState();
    _numSets = widget.numSets;
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        color: AppColors.bgSurface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text(
                'Replace Exercise',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onReplace();
              },
            ),
            ListTile(
              title: const Text(
                'Add Note',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onAddNote();
              },
            ),
            ListTile(
              title: const Text(
                'Remove Exercise',
                style: TextStyle(color: AppColors.danger),
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onRemove();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.exerciseName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.muscleGroup,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: _showMenu,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            color: AppColors.border,
          ),

          // Sets list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _numSets,
            itemBuilder: (context, index) {
              return SetRow(
                setNumber: index + 1,
                previousWeight: 50.0 + (index * 2.5),
                previousReps: 10,
                onComplete: () {},
              );
            },
          ),

          // Divider
          Container(
            height: 1,
            color: AppColors.border,
          ),

          // Add set button
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextButton(
              onPressed: () {
                setState(() {
                  _numSets++;
                });
              },
              child: const Text(
                '+ Add Set',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
