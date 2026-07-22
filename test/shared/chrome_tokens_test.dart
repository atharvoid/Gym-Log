import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/chrome_tokens.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/core/theme/theme_palette.dart';

void main() {
  group('ChromeTokens', () {
    test('ChromeTokens produces expected default values', () {
      const tokens = ChromeTokens(
        background: Color(0xFF000000),
        navBackground: Color(0xFF000000),
        activeBarBg: Color(0xFF141414),
        sheetBg: Color(0xFF141414),
        separator: Color(0x0FFFFFFF),
        textSecondary: Color(0x99FFFFFF),
      );

      expect(tokens.background, AppColors.bgBase);
      expect(tokens.navBackground, AppColors.bgBase);
      expect(tokens.activeBarBg, AppColors.surface2);
      expect(tokens.sheetBg, AppColors.surface2);
      expect(tokens.separator, AppColors.borderSubtle);
      expect(tokens.textSecondary, AppColors.textSecondary);
    });
  });

  group('ChromeContextX', () {
    testWidgets('context.chrome returns ChromeTokens in dark theme',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: [
              AccentColors.fromTokens(
                  ThemePalette.neonPurple.tokens, ThemePalette.neonPurple),
            ],
          ),
          home: const _ChromeReader(),
        ),
      );
      await tester.pump();

      // Verify the _ChromeReader captured non-null tokens.
      final state = tester.state<_ChromeReaderState>(
        find.byType(_ChromeReader),
      );
      expect(state.tokens, isNotNull);
      expect(state.tokens!.background, equals(AppColors.bgBase));
      expect(state.tokens!.navBackground, equals(AppColors.bgBase));
      expect(state.tokens!.separator, equals(AppColors.borderSubtle));
    });

    testWidgets('ChromeTokens do NOT equal AppColors.bgBaseLight in dark mode',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: [
              AccentColors.fromTokens(
                  ThemePalette.neonPurple.tokens, ThemePalette.neonPurple),
            ],
          ),
          home: const _ChromeReader(),
        ),
      );
      await tester.pump();

      final state = tester.state<_ChromeReaderState>(
        find.byType(_ChromeReader),
      );
      expect(state.tokens!.background, isNot(AppColors.bgBaseLight));
      expect(state.tokens!.navBackground, isNot(AppColors.bgBaseLight));
    });
  });
}

/// Helper widget that reads ChromeTokens from context and stores them.
class _ChromeReader extends StatefulWidget {
  const _ChromeReader();
  @override
  State<_ChromeReader> createState() => _ChromeReaderState();
}

class _ChromeReaderState extends State<_ChromeReader> {
  ChromeTokens? tokens;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    tokens = context.chrome;
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
