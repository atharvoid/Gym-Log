import 'package:flutter/widgets.dart';

/// Central motion policy helper.
/// Returns [Duration.zero] when the user has enabled OS reduced-motion
/// ([MediaQuery.disableAnimationsOf]).
class AppMotion {
  static Duration effective(
    BuildContext context,
    Duration duration,
  ) {
    return MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
  }
}
