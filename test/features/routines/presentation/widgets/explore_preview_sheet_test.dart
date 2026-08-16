import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/theme/app_theme.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:gymlog/features/routines/presentation/data/explore_catalog.dart';
import 'package:gymlog/features/routines/presentation/data/routine_index.dart';
import 'package:gymlog/features/routines/presentation/widgets/explore_cards.dart';
import 'package:gymlog/features/routines/presentation/widgets/explore_preview_sheet.dart';
import 'package:gymlog/shared/widgets/body/muscle_map.dart';

void main() {
  final sampleRoutine = ExploreRoutine(
    slug: 'ppl-6day-gym/push-a',
    programSlug: 'ppl-6day-gym',
    programName: 'Push / Pull / Legs - 6 Days/Week',
    programLabel: 'PPL 6d',
    name: 'Push A',
    dayIndex: 0,
    routinesInProgram: 6,
    focus: 'Chest · Shoulders · Triceps',
    category: 'Hypertrophy',
    levels: const [TemplateLevel.intermediate],
    equipment: ProgramEquipment.fullGym,
    slots: const [
      TemplateSlot('Bench Press (Barbell)', sets: 4, reps: '3-5'),
      TemplateSlot('Overhead Press (Barbell)', sets: 3, reps: '6-8'),
      TemplateSlot('Incline Dumbbell Press', sets: 3, reps: '8-12'),
      TemplateSlot('Incline Treadmill Intervals',
          sets: 1, reps: '15 min', isConditioningNote: true),
    ],
    isFromFeaturedProgram: true,
  );

  Widget wrapWithTheme(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: buildAppTheme(ThemePalette.neonPurple.tokens),
        home: Scaffold(body: child),
      ),
    );
  }

  group('RoutinePreviewSheet', () {
    testWidgets('renders routine details, exercises, and muscle map',
        (tester) async {
      var addCalled = false;

      await tester.pumpWidget(
        wrapWithTheme(
          RoutinePreviewSheet(
            routine: sampleRoutine,
            isOwned: false,
            onAdd: () => addCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Title and subtitle
      expect(find.text('Push A'), findsOneWidget);
      expect(
          find.text('Day 1 of PPL 6d · Chest · Shoulders · Triceps'),
          findsOneWidget);

      // Facts
      expect(find.text('3 exercises'), findsOneWidget);
      expect(find.text('Intermediate'), findsOneWidget);
      expect(find.text('Full Gym'), findsOneWidget);

      // MuscleMap
      expect(find.byType(MuscleMap), findsOneWidget);

      // Scroll to view exercises and CTA
      await tester.scrollUntilVisible(
        find.text('Bench Press (Barbell)'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Bench Press (Barbell)'), findsOneWidget);
      expect(find.text('4 × 3-5'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Overhead Press (Barbell)'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Overhead Press (Barbell)'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('LOG MANUALLY'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('LOG MANUALLY'), findsOneWidget);

      // CTA button
      expect(find.text('Add to My Routines'), findsOneWidget);
      await tester.tap(find.text('Add to My Routines'));
      await tester.pumpAndSettle();
      expect(addCalled, isTrue);
    });

    testWidgets('shows View in My Routines when isOwned is true',
        (tester) async {
      var viewCalled = false;

      await tester.pumpWidget(
        wrapWithTheme(
          RoutinePreviewSheet(
            routine: sampleRoutine,
            isOwned: true,
            onAdd: () {},
            onView: () => viewCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('View in My Routines'), findsOneWidget);
      await tester.tap(find.text('View in My Routines'));
      await tester.pumpAndSettle();
      expect(viewCalled, isTrue);
    });
  });

  group('ExploreRoutineCard', () {
    testWidgets('tapping card triggers onTap preview callback', (tester) async {
      var previewOpened = false;
      var quickAddCalled = false;

      await tester.pumpWidget(
        wrapWithTheme(
          ExploreRoutineCard(
            routine: sampleRoutine,
            onAdd: () => quickAddCalled = true,
            onTap: () => previewOpened = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Push A'), findsOneWidget);

      // Tap card body
      await tester.tap(find.text('Push A'));
      await tester.pumpAndSettle();
      expect(previewOpened, isTrue);
      expect(quickAddCalled, isFalse);

      // Tap quick add button
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      expect(quickAddCalled, isTrue);
    });
  });
}
