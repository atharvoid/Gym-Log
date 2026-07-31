import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/services/account_deletion_service.dart';
import 'package:gymlog/core/services/workout_export_service.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_provider.dart';
import 'package:gymlog/shared/layout/adaptive.dart';
import 'package:share_plus/share_plus.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirmController = TextEditingController();
  bool _deleting = false;
  bool _exporting = false;

  static const _confirmPhrase = 'DELETE';

  bool get _canDelete =>
      _confirmController.text.trim().toUpperCase() == _confirmPhrase;

  @override
  void initState() {
    super.initState();
    _confirmController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _exportFirst() async {
    final user = ref.read(authProvider);
    if (user == null || _exporting) return;
    setState(() => _exporting = true);
    try {
      final db = ref.read(databaseProvider);
      final service = WorkoutExportService(db);
      final file = await service.exportUserDataToCsv(user.id);
      if (!mounted) return;
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        subject: 'GymLog data export',
      ));
    } catch (_) {
      if (mounted) _snack('Export failed. Please try again.');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _snack(String message) {
    final surface = context.surface;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message, style: AppText.meta(color: surface.textPrimary)),
        backgroundColor: surface.surface3,
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<void> _delete() async {
    if (!_canDelete || _deleting) return;
    HapticFeedback.heavyImpact();
    setState(() => _deleting = true);

    final user = ref.read(authProvider);
    if (user == null) {
      setState(() => _deleting = false);
      return;
    }

    try {
      final db = ref.read(databaseProvider);
      final service = AccountDeletionService(db: db);
      await service.deleteAccount(userId: user.id);
      await ref.read(authProvider.notifier).signOut();
      if (mounted) context.go('/');
    } catch (_) {
      if (mounted) {
        _snack('Something went wrong. Please try again.');
        setState(() => _deleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;

    return PopScope(
      canPop: !_deleting,
      child: Scaffold(
        backgroundColor: surface.bgBase,
        appBar: AppBar(
          backgroundColor: surface.bgBase,
          scrolledUnderElevation: 0,
          elevation: 0,
          leading: IconButton(
            tooltip: 'Back',
            icon: Icon(Icons.arrow_back_rounded, color: surface.textPrimary),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: _deleting ? null : () => context.pop(),
          ),
          title: Text('Delete Account',
              style: AppText.sheetTitle(color: surface.textPrimary)),
        ),
        // C32: this route (/settings/delete-account) is pushed outside
        // AppShell and never opted into the AdaptiveContent width cap -- the
        // warning copy, confirm field, and destructive button stretched
        // edge-to-edge on tablets/foldables.
        body: AdaptiveContent(
          child: AbsorbPointer(
            absorbing: _deleting,
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  if (profile != null) ...[
                    const SizedBox(height: 8),
                    Icon(Icons.warning_amber_rounded,
                        color: AppColors.destructive, size: 40),
                    const SizedBox(height: 16),
                    Text(
                      'This action is permanent',
                      style: AppText.sectionHeading(color: surface.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Deleting your account permanently removes your profile, '
                      'routines, workout history, and personal records. This '
                      'cannot be undone.',
                      style: AppText.body(color: surface.textSecondary)
                          .copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: surface.surface2,
                        borderRadius: AppRadius.cardAll,
                        border: Border.all(color: surface.borderSubtle),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.download_rounded,
                              size: 20, color: surface.textSecondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Export your data first',
                                    style: AppText.rowLabel(
                                        color: surface.textPrimary)),
                                const SizedBox(height: 3),
                                Text(
                                  'Save a copy of your workout history before '
                                  'you go.',
                                  style: AppText.caption(
                                      color: surface.textSecondary),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton(
                                  onPressed: _exporting ? null : _exportFirst,
                                  style: OutlinedButton.styleFrom(
                                    side:
                                        BorderSide(color: surface.borderDefault),
                                    minimumSize: const Size(0, 40),
                                  ),
                                  child: _exporting
                                      ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: surface.textPrimary),
                                        )
                                      : Text('Export Data',
                                          style: AppText.button(
                                              color: surface.textPrimary)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Type $_confirmPhrase to confirm',
                      style: AppText.rowLabel(color: surface.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'Type $_confirmPhrase to confirm deletion',
                      child: TextField(
                        controller: _confirmController,
                        textCapitalization: TextCapitalization.characters,
                        style: AppText.body(color: surface.textPrimary),
                        decoration: InputDecoration(
                          hintText: _confirmPhrase,
                          filled: true,
                          fillColor: surface.surface2,
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
                            borderSide: BorderSide(
                                color: AppColors.destructive, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _canDelete && !_deleting ? _delete : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.destructive,
                          disabledBackgroundColor:
                              AppColors.destructive.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.buttonPrimaryAll,
                          ),
                        ),
                        child: _deleting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text('Permanently Delete Account',
                                style: AppText.button(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: _deleting ? null : () => context.pop(),
                        child: Text(
                          'Cancel',
                          style: AppText.button(color: surface.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
