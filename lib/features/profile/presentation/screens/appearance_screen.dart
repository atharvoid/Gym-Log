import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/core/theme/theme_palette.dart';

/// Appearance — the settings sub-screen that houses the accent-color picker.
///
/// NAV PATH: Profile → Settings → Appearance → Accent Color. Its only job for
/// now is the accent picker; unrelated settings do not belong here.
///
/// UX CONTRACT (deliberate, per design): a curated grid of named swatches with
/// NO live preview pane, NO apply button, and NO cancel. Tapping a swatch is
/// the entire interaction — it applies through [dynamicAccentThemeProvider]
/// immediately (so the nav bar / header / charts recolor within a frame),
/// persists the choice, and fires a selection haptic. The user simply taps and
/// leaves.
class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reactive: rebuilds the selected-state ring the instant the accent flips.
    final selected = ref.watch(dynamicAccentThemeProvider);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final surface = context.surface;

    return Scaffold(
      backgroundColor: surface.bgBase,
      appBar: AppBar(
        backgroundColor: surface.bgBase,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: Icon(Icons.arrow_back_rounded,
              size: 24, color: surface.textPrimary),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: () {
            if (context.canPop()) context.pop();
          },
        ),
        title: Text('Appearance', style: AppText.sheetTitle()),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            AppSpacing.screenH, 8, AppSpacing.screenH, 24 + bottomInset),
        children: [
          Semantics(
            header: true,
            child: Text('ACCENT COLOR',
                style: AppText.columnHeader(color: surface.textSecondary)),
          ),
          const SizedBox(height: 8),
          Text(
            'Sets the accent used across buttons, the active tab, charts, and '
            'highlights. Tap a color — it applies instantly.',
            style: AppText.caption(color: surface.textTertiary)
                .copyWith(height: 1.45),
          ),
          const SizedBox(height: 22),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 20,
            crossAxisSpacing: 12,
            childAspectRatio: 0.78,
            children: [
              for (final palette in ThemePalette.values)
                _AccentSwatchTile(
                  palette: palette,
                  selected: palette == selected,
                  onTap: () {
                    if (palette == selected) return;
                    HapticFeedback.selectionClick();
                    ref
                        .read(dynamicAccentThemeProvider.notifier)
                        .setPalette(palette);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A single named accent option: full-saturation circle + name caption. The
/// selected option carries a white ring, a soft accent glow, and an on-accent
/// check; unselected options sit flat with a hairline border.
class _AccentSwatchTile extends StatelessWidget {
  final ThemePalette palette;
  final bool selected;
  final VoidCallback onTap;

  const _AccentSwatchTile({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final swatch = palette.swatch;
    final surface = context.surface;
    return Semantics(
      button: true,
      selected: selected,
      label: palette.a11yName,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: swatch,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? surface.textPrimary : surface.borderSubtle,
                  width: selected ? 2.5 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: swatch.withValues(alpha: 0.45),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: selected
                  ? Icon(Icons.check_rounded,
                      size: 28, color: palette.tokens.onAccent)
                  : null,
            ),
            const SizedBox(height: 10),
            Text(
              palette.displayName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption(
                color: selected ? surface.textPrimary : surface.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
