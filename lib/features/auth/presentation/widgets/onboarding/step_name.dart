import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/features/auth/presentation/providers/onboarding_draft_provider.dart';
import 'package:gymlog/shared/widgets/ui/primary_button.dart';

class StepName extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const StepName({super.key, required this.onNext});

  @override
  ConsumerState<StepName> createState() => _StepNameState();
}

class _StepNameState extends ConsumerState<StepName> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final currentName = ref.read(onboardingDraftProvider).name;
    _controller = TextEditingController(text: currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    final surface = context.surface;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          Text(
            'Welcome to GymLog',
            style: AppText.caption(color: surface.textSecondary).copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'What should we\ncall you?',
            style: AppText.screenTitle(color: surface.textPrimary).copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "This is how you'll show up across GymLog — and it follows you to every device.",
            style: AppText.body(color: surface.textSecondary).copyWith(
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: _controller.text.isEmpty,
            maxLength: 40,
            cursorColor: accent.base,
            style: AppText.body(color: surface.textPrimary).copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              final val = _controller.text.trim();
              if (val.isNotEmpty) {
                ref.read(onboardingDraftProvider.notifier).updateName(val);
                widget.onNext();
              }
            },
            onChanged: (val) {
              ref.read(onboardingDraftProvider.notifier).updateName(val.trim());
            },
            decoration: InputDecoration(
              hintText: 'Your name',
              counterText: '',
              hintStyle: AppText.body(color: surface.textSecondary).copyWith(
                fontSize: 18,
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: surface.borderSubtle, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: accent.light, width: 1),
              ),
            ),
          ),
          const Spacer(),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) {
              final isValid = value.text.trim().isNotEmpty;
              return PrimaryButton(
                label: 'Continue',
                onPressed: isValid ? widget.onNext : null,
                icon: Icons.arrow_forward_rounded,
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
