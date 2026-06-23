import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/bootstrap/bootstrap.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

/// Shown at launch when the local database fails its integrity check.
///
/// First principle: a corrupt database must be a user-facing decision, not a
/// silent crash. The user is offered an explicit reset; after the reset they
/// relaunch into a clean, empty database (cloud data restores on next sign-in
/// for Pro users).
class DatabaseRecoveryScreen extends StatefulWidget {
  const DatabaseRecoveryScreen({super.key});

  @override
  State<DatabaseRecoveryScreen> createState() => _DatabaseRecoveryScreenState();
}

class _DatabaseRecoveryScreenState extends State<DatabaseRecoveryScreen> {
  bool _resetting = false;
  bool _done = false;

  Future<void> _reset() async {
    HapticFeedback.mediumImpact();
    setState(() => _resetting = true);
    try {
      await Bootstrap.resetDatabaseFile();
      if (mounted) {
        setState(() {
          _resetting = false;
          _done = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _resetting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.surface3,
                  borderRadius: AppRadius.badgeAll,
                ),
                child: const Icon(
                  Icons.storage_rounded,
                  color: AppColors.textSecondary,
                  size: 26,
                ),
              ),
              const SizedBox(height: AppSpacing.x5),
              Text(
                _done ? 'Reset complete' : 'Local data needs a reset',
                textAlign: TextAlign.center,
                style: AppText.sectionHeading(),
              ),
              const SizedBox(height: AppSpacing.x2),
              Text(
                _done
                    ? 'Reopen GymLog to continue. If you are signed in, your\n'
                        'cloud history will restore automatically.'
                    : 'Your local data appears corrupted. Reset to continue?\n'
                        'Signed-in Pro users restore their history from the cloud.',
                textAlign: TextAlign.center,
                style: AppText.body(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.x6),
              if (_done)
                _RecoveryAction(
                  label: 'Reopen GymLog',
                  primary: true,
                  onTap: () => SystemNavigator.pop(),
                )
              else ...[
                _RecoveryAction(
                  label: _resetting ? 'Resetting…' : 'Reset local data',
                  primary: true,
                  onTap: _resetting ? null : _reset,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RecoveryAction extends StatelessWidget {
  final String label;
  final bool primary;
  final VoidCallback? onTap;

  const _RecoveryAction({
    required this.label,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 240,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primary ? AppColors.accentPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(
              primary ? AppRadius.buttonPrimary : AppRadius.buttonSecondary,
            ),
            border: primary
                ? null
                : Border.all(color: AppColors.borderSubtle, width: 1),
          ),
          child: Text(
            label,
            style: AppText.button(
              color: primary ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
