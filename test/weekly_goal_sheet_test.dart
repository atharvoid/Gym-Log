import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_stats_provider.dart';
import 'package:gymlog/features/profile/presentation/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('showWeeklyGoalSheet', () {
    setUpAll(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('selecting a day updates weeklyGoalProvider and closes sheet',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                final goal = ref.watch(weeklyGoalProvider);
                return Scaffold(
                  body: Column(
                    children: [
                      Text('goal:$goal', key: const Key('goal-label')),
                      TextButton(
                        onPressed: () => showWeeklyGoalSheet(context, ref),
                        child: const Text('Open'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('goal:3'), findsOneWidget);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // The sheet title and day buttons are present.
      expect(find.text('Weekly goal'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      // Choose 5 days/week.
      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();

      // Sheet should close and provider should update.
      expect(find.text('Weekly goal'), findsNothing);
      expect(find.text('goal:5'), findsOneWidget);
    });
  });
}
