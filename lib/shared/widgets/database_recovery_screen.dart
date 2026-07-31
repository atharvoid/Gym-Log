import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/core/database/database.dart';

/// Full-screen fallback shown when the local database fails to open (e.g. a
/// corrupted file). Offers a single destructive recovery path: wipe and
/// recreate the local database.
class DatabaseRecoveryScreen extends StatefulWidget {
  final Object error;
  const DatabaseRecoveryScreen({super.key, required this.error});

  @override
  State<DatabaseRecoveryScreen> createState() =>
      _DatabaseRecoveryScreenState();
}

class _DatabaseRecoveryScreenState extends State<DatabaseRecoveryScreen> {
  bool _busy = false;
  String? _errorMessage;

  Future<void> _reset() async {
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      await resetCorruptDatabase();
      if (mounted) {
        // Restart is handled by the caller reloading the app root; here we
        // simply signal completion by popping busy state. In practice the
        // app is relaunched by the platform after this call in main.dart's
        // error boundary.
        setState(() => _busy = false);
      }
    } catch (e) {
      debugPrint('resetCorruptDatabase failed: $e');
      if (mounted) {
        setState(() {
          _busy = false;
          _errorMessage =
              'Could not reset your local data. Please close the app and try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    return Scaffold(
      backgroundColor: surface.bgBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.storage_rounded,
                  size: 40, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Something went wrong',
                  style: AppText.sheetTitle(color: surface.textPrimary)),
              const SizedBox(height: 8),
              Text(
                "GymLog couldn't open your local data. You can reset it to "
                'get back into the app — your cloud-synced data (if any) will '
                'still be there.',
                textAlign: TextAlign.center,
                style: AppText.body(color: surface.textSecondary),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(_errorMessage!,
                    textAlign: TextAlign.center,
                    style: AppText.caption(color: AppColors.error)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _busy ? null : _reset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.buttonPrimary)),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text('Reset Local Data', style: AppText.button()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
