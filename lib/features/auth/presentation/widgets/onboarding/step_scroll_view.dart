import 'package:flutter/material.dart';

/// Scrollable wrapper for onboarding steps.
///
/// Steps are `Padding > Column` with Spacers that push the CTA to the bottom.
/// On short viewports or large text scales the Column can exceed the screen
/// and RenderFlex-overflow — the Spacers can only distribute surplus, never
/// deficit. This wrapper preserves the fill-the-viewport behaviour on tall
/// screens (Column stretched to the viewport via `IntrinsicHeight` + a
/// min-height) while letting the whole step scroll when content genuinely
/// doesn't fit.
class StepScrollView extends StatelessWidget {
  final Widget child;

  const StepScrollView({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        // No bounce: an overflowing step must never rubber-band-reveal itself
        // (same reasoning as the auth screen's ClampingScrollPhysics).
        physics: const ClampingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(child: child),
        ),
      ),
    );
  }
}
