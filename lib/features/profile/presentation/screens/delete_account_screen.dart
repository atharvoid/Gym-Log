import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymlog/core/services/account_deletion_service.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';

/// Irreversible account deletion. Reached from Settings (not buried). The user
/// reads exactly what is destroyed vs preserved, types DELETE to confirm, and
/// the final button initiates the permanent purge.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirm = TextEditingController();
  bool _deleting = false;

  static const _confirmWord = 'DELETE';

  bool get _canDelete =>
      _confirm.text.trim().toUpperCase() == _confirmWord && !_deleting;

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (!_canDelete) return;
    HapticFeedback.heavyImpact();
    setState(() => _deleting = true);

    final outcome =
        await ref.read(accountDeletionServiceProvider).deleteAccount();

    if (!mounted) return;

    // Local wipe always signs the user out. Show the confirmation snackbar on
    // the current scaffold first, then navigate — the current route's Scaffold
    // remains mounted long enough for the message to be visible.
    if (outcome.localWiped) {
      final router = GoRouter.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Your account and data have been permanently deleted.',
            style: AppText.button(),
          ),
          backgroundColor: AppColors.bgSurface,
          behavior: SnackBarBehavior.floating,
        ),
      );
      router.go('/auth');
    } else {
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Deletion failed. Please try again.',
            style: AppText.button(),
          ),
          backgroundColor: AppColors.bgSurface,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: !_deleting,
        child: Scaffold(
          backgroundColor: AppColors.bgBase,
          appBar: AppBar(
            backgroundColor: AppColors.bgBase,
            scrolledUnderElevation: 0,
            titleSpacing: 0,
            leading: IconButton(
              tooltip: 'Back',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: const Icon(Icons.arrow_back_ios_new,
                  size: 18, color: AppColors.textPrimary),
              onPressed: _deleting ? null : () => context.pop(),
            ),
            title: Text('Delete account', style: AppText.sheetTitle()),
          ),
          body: AbsorbPointer(
            absorbing: _deleting,
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.delete_forever_rounded,
                        color: AppColors.error, size: 26),
                  ),
                  const SizedBox(height: 16),
                  MergeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'This is permanent',
                          style: AppText.sectionHeading(),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Deleting your account cannot be undone. Once you confirm, your '
                          'data will be permanently deleted — there is no recovery.',
                          style: AppText.body(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const _SectionCard(
                    title: 'What will be permanently deleted',
                    tone: AppColors.error,
                    icon: Icons.remove_circle_outline_rounded,
                    lines: [
                      'Your sign-in account and profile on our servers.',
                      'Any workout, routine, or preference data synced to the cloud.',
                      'All workout history, routines, and custom exercises stored on '
                          'this device.',
                    ],
                  ),
                  const SizedBox(height: 14),
                  const _SectionCard(
                    title: 'What stays yours',
                    tone: AppColors.success,
                    icon: Icons.check_circle_outline_rounded,
                    lines: [
                      'Any CSV files you exported to your phone (Downloads / Files) '
                          'are your property — they are never touched or removed.',
                    ],
                  ),

                  const SizedBox(height: 26),
                  Text(
                    'Type $_confirmWord to confirm',
                    style: AppText.columnHeader(),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _confirm,
                    autocorrect: false,
                    enableSuggestions: false,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _canDelete ? _delete() : null,
                    onChanged: (_) => setState(() {}),
                    cursorColor: AppColors.error,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: _confirmWord,
                      hintStyle: GoogleFonts.inter(
                          color: AppColors.textDisabled, letterSpacing: 1.5),
                      filled: true,
                      fillColor: AppColors.surfaceRaised,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(
                            color: AppColors.error, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _canDelete ? _delete : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        disabledBackgroundColor:
                            AppColors.error.withValues(alpha: 0.18),
                        foregroundColor: Colors.white,
                        disabledForegroundColor:
                            Colors.white.withValues(alpha: 0.5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999)),
                      ),
                      child: _deleting
                          ? const CupertinoActivityIndicator(color: Colors.white)
                          : Text(
                              'Delete my account permanently',
                              style: AppText.button(),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: _deleting ? null : () => context.pop(),
                      child: Text(
                        'Cancel',
                        style: AppText.button(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Color tone;
  final IconData icon;
  final List<String> lines;

  const _SectionCard({
    required this.title,
    required this.tone,
    required this.icon,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tone.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: tone),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: AppText.rowLabel()),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7, right: 8),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(line, style: AppText.body()),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
