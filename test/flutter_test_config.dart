import 'dart:async';
import 'package:alchemist/alchemist.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Disable runtime font fetching to ensure all tests use local assets
  GoogleFonts.config.allowRuntimeFetching = false;

  return AlchemistConfig.runWithConfig(
    config: const AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(
        enabled: true,
      ),
    ),
    run: testMain,
  );
}
