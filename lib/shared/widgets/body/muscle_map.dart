import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gymlog/core/exercises/body_map.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';

/// A themed, gender-aware body-map that dims un-worked muscles and highlights
/// worked muscle groups in the live accent color.
///
/// The map is built from the vendored `body-highlighter` assets. Each overlay
/// part shares the same viewBox as its base silhouette and is tinted via
/// [BlendMode.srcIn], so layers register pixel-exactly without manual
/// positioning.
class MuscleMap extends StatelessWidget {
  /// Worked parent muscle groups painted at full accent intensity.
  final Set<String> primaryGroups;

  /// Worked parent muscle groups painted at a lower accent intensity.
  final Set<String> secondaryGroups;

  /// `'male'`, `'female'`, or `'prefer_not_to_say'`. The latter falls back to
  /// the male silhouette because the upstream asset set has no neutral body.
  final String gender;

  /// Whether to show both front and back silhouettes. `false` renders a compact
  /// front-only map (useful for small preview cards).
  final bool showBack;

  /// Whether to show the "Primary / Secondary" legend below the map.
  final bool showLegend;

  const MuscleMap({
    super.key,
    required this.primaryGroups,
    this.secondaryGroups = const {},
    this.gender = 'male',
    this.showBack = true,
    this.showLegend = false,
  });

  bool get _isFemale => gender == 'female';

  double _aspectRatio(BodySide side) {
    // Reconciled from assets/body/manifest.json viewBoxes.
    if (_isFemale) {
      return side == BodySide.front ? 734 / 1538 : 774 / 1448;
    }
    return 724 / 1448;
  }

  String _baseAsset(BodySide side) {
    final prefix = side == BodySide.front ? 'body_front' : 'body_back';
    return 'assets/body/$prefix${_isFemale ? '_female' : ''}.svg';
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    final surface = context.surface;

    final primaryParts = partsForGroups(primaryGroups, gender: gender);
    final secondaryParts = partsForGroups(
      secondaryGroups.difference(primaryGroups),
      gender: gender,
    );

    final baseColor = surface.surface3;
    final primaryColor = accent.base;
    final secondaryColor = Color.alphaBlend(
      accent.base.withValues(alpha: 0.45),
      surface.surface3,
    );

    final frontRatio = _aspectRatio(BodySide.front);
    final backRatio = _aspectRatio(BodySide.back);
    final totalRatio = showBack ? frontRatio + backRatio : frontRatio;

    final sortedPrimary = primaryGroups.toList()..sort();
    final label = sortedPrimary.isEmpty
        ? 'No muscles highlighted'
        : 'Muscles worked: ${sortedPrimary.join(', ')}';

    Widget map = RepaintBoundary(
      child: AspectRatio(
        aspectRatio: totalRatio,
        child: Row(
          children: [
            Flexible(
              flex: (frontRatio * 1000).round(),
              child: AspectRatio(
                aspectRatio: frontRatio,
                child: _BodySideStack(
                  baseAsset: _baseAsset(BodySide.front),
                  side: BodySide.front,
                  isFemale: _isFemale,
                  primaryParts: primaryParts,
                  secondaryParts: secondaryParts,
                  baseColor: baseColor,
                  primaryColor: primaryColor,
                  secondaryColor: secondaryColor,
                ),
              ),
            ),
            if (showBack)
              Flexible(
                flex: (backRatio * 1000).round(),
                child: AspectRatio(
                  aspectRatio: backRatio,
                  child: _BodySideStack(
                    baseAsset: _baseAsset(BodySide.back),
                    side: BodySide.back,
                    isFemale: _isFemale,
                    primaryParts: primaryParts,
                    secondaryParts: secondaryParts,
                    baseColor: baseColor,
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (showLegend) {
      map = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          map,
          const SizedBox(height: 12),
          _Legend(
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
          ),
        ],
      );
    }

    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: map,
      ),
    );
  }
}

class _BodySideStack extends StatelessWidget {
  final String baseAsset;
  final BodySide side;
  final bool isFemale;
  final Set<(BodySide, String)> primaryParts;
  final Set<(BodySide, String)> secondaryParts;
  final Color baseColor;
  final Color primaryColor;
  final Color secondaryColor;

  const _BodySideStack({
    required this.baseAsset,
    required this.side,
    required this.isFemale,
    required this.primaryParts,
    required this.secondaryParts,
    required this.baseColor,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final partWidgets = <Widget>[];

    for (final part in secondaryParts.where((p) => p.$1 == side)) {
      partWidgets.add(_PartLayer(
        asset: _partAsset(side, part.$2),
        color: secondaryColor,
      ));
    }
    for (final part in primaryParts.where((p) => p.$1 == side)) {
      partWidgets.add(_PartLayer(
        asset: _partAsset(side, part.$2),
        color: primaryColor,
      ));
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        SvgPicture.asset(
          baseAsset,
          fit: BoxFit.contain,
          colorFilter: ColorFilter.mode(baseColor, BlendMode.srcIn),
          semanticsLabel: '',
          excludeFromSemantics: true,
        ),
        ...partWidgets,
      ],
    );
  }

  String _partAsset(BodySide side, String slug) {
    final genderDir = isFemale ? 'female' : 'male';
    final viewDir = side == BodySide.front ? 'front' : 'back';
    return 'assets/body/parts/$viewDir/$genderDir/$slug.svg';
  }
}

class _PartLayer extends StatelessWidget {
  final String asset;
  final Color color;

  const _PartLayer({required this.asset, required this.color});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      semanticsLabel: '',
      excludeFromSemantics: true,
    );
  }
}

class _Legend extends StatelessWidget {
  final Color primaryColor;
  final Color secondaryColor;

  const _Legend({required this.primaryColor, required this.secondaryColor});

  @override
  Widget build(BuildContext context) {
    final surface = context.surface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LegendDot(color: primaryColor),
        const SizedBox(width: 6),
        Text('Primary', style: AppText.caption(color: surface.textSecondary)),
        const SizedBox(width: 16),
        _LegendDot(color: secondaryColor),
        const SizedBox(width: 6),
        Text('Secondary', style: AppText.caption(color: surface.textSecondary)),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
