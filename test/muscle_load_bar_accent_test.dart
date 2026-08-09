import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:gymlog/shared/widgets/body/muscle_load_bar.dart';

import 'golden/golden_test_helpers.dart';

/// MuscleLoadBar must paint from the active accent's `muscleSplitRamp`
/// (context.accent), never from the legacy static purple palette.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const purpleRampStart = Color(0xff7f00ff);

  MuscleLoadBar buildBar({
    List<MuscleLoadEntry> entries = const [
      MuscleLoadEntry('chest', 0.6),
      MuscleLoadEntry('back', 0.3),
      MuscleLoadEntry('legs', 0.1),
    ],
  }) {
    return MuscleLoadBar(
      entries: entries,
      primaryGroups: const {'chest'},
      secondaryGroups: const {'back', 'legs'},
      gender: 'male',
    );
  }

  List<Color> legendDotColors(WidgetTester tester) {
    return find
        .byWidgetPredicate((w) {
          return w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).shape == BoxShape.circle &&
              (w.decoration as BoxDecoration).color != null;
        })
        .evaluate()
        .map((e) =>
            ((e.widget as Container).decoration! as BoxDecoration).color!)
        .toList();
  }

  testWidgets('legend dots equal the higgsfield (Volt, app default) ramp',
      (tester) async {
    await tester.pumpWidget(gymlogApp(ThemePalette.higgsfield, buildBar()));

    expect(
      legendDotColors(tester),
      ThemePalette.higgsfield.tokens.muscleSplitRamp.sublist(0, 3),
    );
  });

  testWidgets('legend dots equal the neonPurple ramp', (tester) async {
    await tester.pumpWidget(gymlogApp(ThemePalette.neonPurple, buildBar()));

    expect(
      legendDotColors(tester),
      ThemePalette.neonPurple.tokens.muscleSplitRamp.sublist(0, 3),
    );
  });

  testWidgets('no legend dot uses the legacy static purple literal',
      (tester) async {
    await tester.pumpWidget(gymlogApp(ThemePalette.neonPurple, buildBar()));

    expect(legendDotColors(tester).contains(purpleRampStart), isFalse);
  });

  testWidgets('legend caps at 3 items and shows +N overflow text',
      (tester) async {
    await tester.pumpWidget(gymlogApp(
      ThemePalette.higgsfield,
      buildBar(entries: const [
        MuscleLoadEntry('chest', 0.25),
        MuscleLoadEntry('back', 0.2),
        MuscleLoadEntry('legs', 0.15),
        MuscleLoadEntry('arms', 0.12),
        MuscleLoadEntry('shoulders', 0.1),
        MuscleLoadEntry('biceps', 0.08),
        MuscleLoadEntry('triceps', 0.06),
        MuscleLoadEntry('forearms', 0.04),
      ]),
    ));

    expect(tester.takeException(), isNull);
    expect(
      legendDotColors(tester),
      ThemePalette.higgsfield.tokens.muscleSplitRamp.sublist(0, 3),
    );
    expect(find.text('+5'), findsOneWidget);
  });

  testWidgets('empty entries render nothing', (tester) async {
    await tester.pumpWidget(gymlogApp(
      ThemePalette.higgsfield,
      const MuscleLoadBar(
        entries: [],
        primaryGroups: {},
        secondaryGroups: {},
        gender: 'male',
      ),
    ));

    expect(find.textContaining('%'), findsNothing);
    expect(legendDotColors(tester), isEmpty);
  });
}
