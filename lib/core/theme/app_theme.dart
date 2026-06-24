import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text.dart';
import 'dynamic_accent_theme.dart';
import 'theme_palette.dart';

/// [app_theme.dart]
/// GymLog Design System — AMOLED-first, data over decoration.
/// Every theme text style carries Inter tabular figures. Cards carry a 1px
/// subtle white border (no shadows — invisible on AMOLED black).
///
/// ACCENT IS RUNTIME: the theme is built from a [ThemePaletteTokens] set via
/// [buildAppTheme]. The root MaterialApp watches the active palette and rebuilds
/// the theme on change, so colorScheme.primary, the input focus ring, buttons,
/// switches, and progress indicators all follow the accent for free. Explicit
/// accent consumers read the live tokens via `context.accent` (see
/// dynamic_accent_theme.dart). Surfaces / text / semantic colors never change.
///
/// ON-ACCENT: the label that sits on a full-saturation [base] fill comes from
/// tokens.onAccent (white for colored palettes, near-black for the neutral
/// palette) — never a hardcoded white, so the white palette stays legible.
///
/// BRIGHTNESS: the White palette drives a LIGHT ThemeData (Brightness.light,
/// ColorScheme.light) with a inverted surface luminance hierarchy. All other
/// palettes use the AMOLED dark theme. Screen surfaces should read from
/// `context.surface` (SurfaceContextX) rather than hardcoded AppColors.* to
/// stay correct under both brightness modes.

TextStyle _ct({
  required double fontSize,
  required FontWeight fontWeight,
  Color? color,
  double? letterSpacing,
}) =>
    GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      fontFeatures: kTabular,
    );

/// Builds the app theme for a given accent token set. Call this from the root
/// MaterialApp with the active palette's tokens.
///
/// When [palette] is [ThemePalette.white], returns a LIGHT ThemeData with
/// the inverted surface hierarchy from [SurfaceTokens.light].
ThemeData buildAppTheme(ThemePaletteTokens tokens, {ThemePalette palette = ThemePalette.neonPurple}) {
  final isLight = palette.isLightSurface;
  final s = isLight ? SurfaceTokens.light : SurfaceTokens.dark;

  return ThemeData(
      useMaterial3: true,
      brightness: isLight ? Brightness.light : Brightness.dark,
      fontFamily: GoogleFonts.inter().fontFamily,

      // Live accent tokens, readable anywhere via `context.accent`.
      extensions: <ThemeExtension<dynamic>>[
        AccentColors.fromTokens(tokens, palette),
      ],

      colorScheme: isLight
          ? ColorScheme.light(
              surface: s.bgBase,
              surfaceContainerHighest: s.bgSurface,
              primary: tokens.base,
              onPrimary: tokens.onAccent,
              secondary: tokens.light,
              onSecondary: s.bgBase,
              error: AppColors.error,
              onSurface: s.textPrimary,
              onSurfaceVariant: s.textSecondary,
              outline: s.borderSubtle,
            )
          : ColorScheme.dark(
              surface: AppColors.bgBase,
              surfaceContainerHighest: AppColors.bgSurface,
              primary: tokens.base,
              onPrimary: tokens.onAccent,
              secondary: tokens.light,
              onSecondary: AppColors.bgBase,
              error: AppColors.error,
              onSurface: AppColors.textPrimary,
              onSurfaceVariant: AppColors.textSecondary,
              outline: AppColors.borderSubtle,
            ),

      scaffoldBackgroundColor: s.bgBase,
      cardColor: s.bgSurface,
      dividerColor: s.borderSubtle,

      appBarTheme: AppBarTheme(
        backgroundColor: s.bgBase,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        systemOverlayStyle: (isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light)
            .copyWith(statusBarColor: Colors.transparent),
        iconTheme: IconThemeData(color: s.textPrimary),
        titleTextStyle: _ct(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: s.textPrimary,
        ),
      ),

      // Bottom sheets → 20px top corners, Surface 2.
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: s.surface2,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      ),

      // Cards → 16px radius + 1px subtle border (no shadow).
      cardTheme: CardThemeData(
        elevation: 0,
        color: s.bgSurface,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardAll,
          side: BorderSide(color: s.borderSubtle),
        ),
      ),

      // Inputs → Surface 3 fill, border, accent focus ring.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: s.surface3,
        border: OutlineInputBorder(
          borderRadius: AppRadius.inputAll,
          borderSide: BorderSide(color: s.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputAll,
          borderSide: BorderSide(color: s.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputAll,
          borderSide: BorderSide(color: tokens.base, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: _ct(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: s.textTertiary,
        ),
      ),

      // Primary CTA → 12px slightly rounded, accent fill, on-accent text, 52px.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.base,
          foregroundColor: tokens.onAccent,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(0, 52),
          shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.buttonPrimaryAll),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          textStyle: _ct(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.light,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: _ct(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: s.textPrimary),
      ),

      // Switches default to the accent when on.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? tokens.onAccent
              : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? tokens.base : null,
        ),
      ),

      // Bare CircularProgressIndicators (no explicit color) follow the accent.
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.base,
      ),

      textTheme: TextTheme(
        // Headers / titles
        displayLarge: _ct(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: s.textPrimary),
        headlineLarge: _ct(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: s.textPrimary),
        headlineMedium: _ct(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: s.textPrimary),
        titleLarge: _ct(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: s.textPrimary),

        // Component labels / values
        titleMedium: _ct(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: s.textPrimary),
        titleSmall: _ct(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: s.textPrimary),

        // Body
        bodyLarge: _ct(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: s.textPrimary),
        bodyMedium: _ct(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: s.textSecondary),
        bodySmall: _ct(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: s.textSecondary),

        // Labels
        labelLarge: _ct(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: s.textSecondary),
        labelMedium: _ct(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: s.textSecondary),
        labelSmall: _ct(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: s.textTertiary),
      ),
    );
}

// ── High-contrast variant ───────────────────────────────────────────────────
// Selected automatically by MaterialApp when the OS "increase contrast" setting
// is on. Brightens secondary text and makes borders clearly visible.
const _hcSecondary = Color(0xFFD2D2D7);
const _hcBorder = Color(0xFF8A8A8E);

const _hcSecondaryLight = Color(0xFF3A3A3C);
const _hcBorderLight = Color(0xFF8A8A8E);

/// High-contrast variant of [buildAppTheme] for the given accent tokens.
ThemeData buildHighContrastTheme(ThemePaletteTokens tokens, {ThemePalette palette = ThemePalette.neonPurple}) {
  final base = buildAppTheme(tokens, palette: palette);
  final isLight = palette.isLightSurface;
  final hcSecondary = isLight ? _hcSecondaryLight : _hcSecondary;
  final hcBorder = isLight ? _hcBorderLight : _hcBorder;
  return base.copyWith(
    dividerColor: hcBorder,
    colorScheme: base.colorScheme.copyWith(
      onSurfaceVariant: hcSecondary,
      outline: hcBorder,
    ),
    textTheme: base.textTheme.copyWith(
      bodyMedium: base.textTheme.bodyMedium?.copyWith(color: hcSecondary),
      bodySmall: base.textTheme.bodySmall?.copyWith(color: hcSecondary),
      labelLarge: base.textTheme.labelLarge?.copyWith(color: hcSecondary),
      labelMedium: base.textTheme.labelMedium?.copyWith(color: hcSecondary),
      labelSmall: base.textTheme.labelSmall?.copyWith(color: hcSecondary),
    ),
  );
}

/// Default-accent theme. Used by surfaces that build before the provider scope
/// exists (e.g. the DB-recovery MaterialApp). Normal screens use the reactive
/// [buildAppTheme] wired in app.dart.
final appTheme = buildAppTheme(ThemePalette.fallback.tokens, palette: ThemePalette.fallback);
final appHighContrastTheme =
    buildHighContrastTheme(ThemePalette.fallback.tokens, palette: ThemePalette.fallback);
