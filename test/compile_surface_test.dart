// Compile-surface gate.
//
// Importing main.dart forces the test compiler to build the ENTIRE app
// graph (router → every screen → every widget/provider/DAO). Any type
// error anywhere in lib/ fails this suite even without an Android SDK
// on the CI machine. The test body is intentionally trivial.

import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/main.dart' as app;
import 'package:gymlog/shared/widgets/premium_paywall.dart';
import 'package:gymlog/features/workout/presentation/widgets/pr_celebration_overlay.dart';

void main() {
  test('full app graph compiles', () {
    // Reference symbols so the imports cannot be tree-shaken away.
    expect(app.main, isA<Function>());
    expect(showPremiumPaywall, isA<Function>());
    expect(showPrCelebration, isA<Function>());
  });
}
