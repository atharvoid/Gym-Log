import 'package:flutter/material.dart';
import 'package:gymlog/core/models/pr_card_data.dart';
import 'share_card_monument.dart';
import 'share_card_sticker.dart';
import 'share_card_technical.dart';

enum ShareCardVariant {
  monument,
  technical,
  sticker;

  String get displayName => switch (this) {
        ShareCardVariant.monument => 'Monument',
        ShareCardVariant.technical => 'Technical',
        ShareCardVariant.sticker => 'Sticker',
      };
}

/// Unified entry point for rendering DELT 9:16 Social Share Cards.
///
/// Ensures strict fixed logical sizing (360×640) and disables device text scaling
/// via `TextScaler.noScaling` so that renders on any device or off-screen pipeline
/// are pixel-identical to the 1080×1920 target asset.
class DeltShareCard extends StatelessWidget {
  final PrCardData data;
  final ShareCardVariant variant;

  const DeltShareCard({
    super.key,
    required this.data,
    this.variant = ShareCardVariant.monument,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardChild;
    switch (variant) {
      case ShareCardVariant.monument:
        cardChild = ShareCardMonument(data: data);
        break;
      case ShareCardVariant.technical:
        cardChild = ShareCardTechnical(data: data);
        break;
      case ShareCardVariant.sticker:
        cardChild = ShareCardSticker(data: data);
        break;
    }

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        size: const Size(360, 640),
        textScaler: TextScaler.noScaling,
      ),
      child: SizedBox(
        width: 360,
        height: 640,
        child: cardChild,
      ),
    );
  }
}
