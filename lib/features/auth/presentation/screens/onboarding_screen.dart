import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/services/profile_sync_service.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/shared/widgets/ui/app_dialog.dart';
import 'package:gymlog/shared/widgets/ui/primary_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;
  bool _shouldAutofocus = true;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider);
    final meta = user?.userMetadata;
    final googleName = (meta?['full_name'] ?? meta?['name']) as String?;
    if (googleName != null && googleName.trim().isNotEmpty) {
      _nameController.text = googleName.trim();
      _shouldAutofocus = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _cancel() async {
    if (_isLoading) return;
    if (_nameController.text.trim().isNotEmpty) {
      final discard = await showAppConfirmDialog(
        context: context,
        title: 'Cancel setup?',
        message: "The name you entered won't be saved. You'll be signed out "
            'and returned to the start.',
        confirmLabel: 'Sign Out',
        cancelLabel: 'Keep Editing',
        isDestructive: true,
      );
      if (!discard) return;
    }
    await ref.read(authRepositoryProvider).signOut();
    if (mounted) context.go('/auth');
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final user = ref.read(authProvider);
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(profileSyncProvider).submitDisplayName(
            userId: user.id,
            email: user.email ?? '',
            name: name,
          );
      HapticFeedback.lightImpact();
      if (mounted) context.go('/');
    } catch (_) {
      HapticFeedback.heavyImpact();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    final surface = context.surface;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: surface.isLight
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _cancel();
        },
        child: Scaffold(
          backgroundColor: surface.bgBase,
          body: SafeArea(
            child: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: _isLoading ? null : _cancel,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_back_rounded,
                                    size: 18, color: surface.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  'Cancel',
                                  style:
                                      AppText.body(color: surface.textSecondary)
                                          .copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Welcome to GymLog',
                          style: AppText.caption(color: surface.textSecondary)
                              .copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'What should we\ncall you?',
                          style: AppText.screenTitle(color: surface.textPrimary)
                              .copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This is how you\'ll show up across GymLog — and it follows you to every device.',
                          style: AppText.body(color: surface.textSecondary)
                              .copyWith(
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 32),
                        TextField(
                          controller: _nameController,
                          focusNode: _focusNode,
                          autofocus: _shouldAutofocus,
                          maxLength: 40,
                          cursorColor: accent.base,
                          style:
                              AppText.body(color: surface.textPrimary).copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            hintText: 'Your name',
                            counterText: '',
                            hintStyle:
                                AppText.body(color: surface.textSecondary)
                                    .copyWith(
                              fontSize: 18,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                              borderSide: BorderSide(
                                  color: surface.borderSubtle, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                              borderSide:
                                  BorderSide(color: accent.light, width: 1),
                            ),
                          ),
                        ),
                        const Spacer(),
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _nameController,
                          builder: (context, value, _) {
                            final isValid = value.text.trim().isNotEmpty;
                            return PrimaryButton(
                              label: 'Get Started',
                              onPressed:
                                  isValid && !_isLoading ? _submit : null,
                              isLoading: _isLoading,
                              icon: Icons.arrow_forward_rounded,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
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
}
