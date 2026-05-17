import 'package:flutter/material.dart';
import 'package:gymlog/core/theme/app_colors.dart';

class SetRow extends StatefulWidget {
  final int setNumber;
  final double? previousWeight;
  final int? previousReps;
  final VoidCallback onComplete;

  const SetRow({
    super.key,
    required this.setNumber,
    this.previousWeight,
    this.previousReps,
    required this.onComplete,
  });

  @override
  State<SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<SetRow> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;
  String _type = ''; // '' = normal, 'W' = warmup, 'D' = dropset
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.previousWeight?.toStringAsFixed(1) ?? '',
    );
    _repsController = TextEditingController(
      text: widget.previousReps?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _cycleType() {
    setState(() {
      if (_type.isEmpty) {
        _type = 'W';
      } else if (_type == 'W') {
        _type = 'D';
      } else {
        _type = '';
      }
    });
  }

  void _toggleComplete() {
    setState(() {
      _isCompleted = !_isCompleted;
    });
    if (_isCompleted) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isCompleted
        ? AppColors.success.withOpacity(0.15)
        : Colors.transparent;

    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Set number
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                '${widget.setNumber}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Type badge
          GestureDetector(
            onTap: _cycleType,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _type.isEmpty ? '-' : _type,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Weight input
          SizedBox(
            width: 60,
            child: TextField(
              controller: _weightController,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: widget.previousWeight?.toStringAsFixed(1) ?? 'kg',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                border: InputBorder.none,
                filled: true,
                fillColor: AppColors.bgElevated,
                contentPadding: const EdgeInsets.all(8),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // × separator
          const Text(
            '×',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 4),

          // Reps input
          SizedBox(
            width: 50,
            child: TextField(
              controller: _repsController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: widget.previousReps?.toString() ?? 'reps',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                border: InputBorder.none,
                filled: true,
                fillColor: AppColors.bgElevated,
                contentPadding: const EdgeInsets.all(8),
              ),
            ),
          ),
          const Spacer(),

          // Checkmark button
          IconButton(
            icon: Icon(
              _isCompleted ? Icons.check_circle : Icons.circle_outlined,
              color: _isCompleted ? AppColors.success : AppColors.textMuted,
            ),
            onPressed: _toggleComplete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
