import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/theme/app_theme.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:gymlog/features/routines/presentation/providers/ai_routine_import_provider.dart';
import 'package:gymlog/features/routines/presentation/screens/ai_routine_import_screen.dart';

Widget createTestWidget({
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: buildAppTheme(ThemePalette.neonPurple.tokens),
      home: const AiRoutineImportScreen(),
    ),
  );
}

void main() {
  testWidgets(
      'AiRoutineImportScreen renders segmented control and photo mode initially',
      (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('AI Routine Import'), findsOneWidget);
    expect(find.text('Photo / Image'), findsOneWidget);
    expect(find.text('Paste Text'), findsOneWidget);
    expect(find.text('Upload a Photo or Screenshot'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('Analyze Routine'), findsOneWidget);
  });

  testWidgets(
      'AiRoutineImportScreen switches to Paste Text mode and shows text field',
      (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Paste Text'));
    await tester.pumpAndSettle();

    expect(find.text('Paste Workout Routine'), findsOneWidget);
    expect(find.text('Paste'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets(
      'AiRoutineImportScreen shows error banner when errorMessage is populated',
      (tester) async {
    final container = ProviderContainer();
    container.read(aiRoutineImportProvider.notifier).state =
        const AiRoutineImportState(
      status: AiImportStatus.error,
      errorMessage: 'Service timeout. Please try again.',
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildAppTheme(ThemePalette.neonPurple.tokens),
          home: const AiRoutineImportScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Service timeout. Please try again.'), findsOneWidget);
  });
}
