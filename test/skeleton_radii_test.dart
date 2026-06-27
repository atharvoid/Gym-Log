import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/shared/widgets/ui/skeleton.dart';
import 'package:gymlog/features/routines/presentation/screens/routine_detail_screen.dart';
import 'package:gymlog/features/routines/presentation/providers/routines_provider.dart';
import 'package:gymlog/features/workout/presentation/screens/workout_screen.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/auth/data/auth_repository.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:drift/native.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show SupabaseClient, User, Session, AuthState;

class MockAuthRepository extends AuthRepository {
  MockAuthRepository(super._client);
  @override
  Future<void> signInWithGoogle() async {}
  @override
  Future<void> signOut() async {}
  @override
  User? get currentUser => null;
  @override
  Session? get currentSession => null;
  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();
}

void main() {
  late AppDatabase db;
  late SupabaseClient supabaseClient;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    supabaseClient = SupabaseClient('https://example.com', 'key');
    mockAuthRepository = MockAuthRepository(supabaseClient);
  });

  tearDown(() async {
    supabaseClient.auth.stopAutoRefresh();
    await db.close();
  });

  testWidgets('WorkoutHistoryCardSkeleton thumbnail uses AppRadius.thumbnail',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WorkoutHistoryCardSkeleton(),
        ),
      ),
    );

    // Find the thumbnail SkeletonBoxes (there are 2 of them)
    final boxes = tester.widgetList<SkeletonBox>(find.byType(SkeletonBox));
    final thumbnailBoxes =
        boxes.where((b) => b.width == 52 && b.height == 52).toList();
    expect(thumbnailBoxes, isNotEmpty);
    for (final box in thumbnailBoxes) {
      expect(box.radius, AppRadius.thumbnail);
    }
  });

  testWidgets('RoutineDetailScreen skeleton uses correct tokenized radii',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          authProvider.overrideWithValue(null),
          databaseProvider.overrideWithValue(db),
          routineDetailProvider('r1')
              .overrideWith((ref) => const Stream.empty()),
        ],
        child: const MaterialApp(
          home: RoutineDetailScreen(routineId: 'r1'),
        ),
      ),
    );

    await tester.pump();

    final boxes = tester.widgetList<SkeletonBox>(find.byType(SkeletonBox));

    // Chart bone: height: 198
    final chartBone = boxes.firstWhere((b) => b.height == 198);
    expect(chartBone.radius, AppRadius.card);

    // Exercise block bones: height: 120
    final blockBones = boxes.where((b) => b.height == 120).toList();
    expect(blockBones, isNotEmpty);
    for (final bone in blockBones) {
      expect(bone.radius, AppRadius.card);
    }

    // Start routine button bone in bottomNav: height: 52
    final buttonBone =
        boxes.firstWhere((b) => b.height == 52 && b.width == null);
    expect(buttonBone.radius, AppRadius.buttonPrimary);
  });

  testWidgets('WorkoutScreen routines skeleton uses correct tokenized radii',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          authProvider.overrideWithValue(null),
          databaseProvider.overrideWithValue(db),
          // We force routines to load indefinitely to show the skeleton
          hydratedRoutinesProvider.overrideWith((ref) => const Stream.empty()),
        ],
        child: const MaterialApp(
          home: WorkoutScreen(),
        ),
      ),
    );

    await tester.pump();

    final boxes = tester.widgetList<SkeletonBox>(find.byType(SkeletonBox));

    // Glyph container: width: 44, height: 44
    final glyphBones =
        boxes.where((b) => b.width == 44 && b.height == 44).toList();
    expect(glyphBones, isNotEmpty);
    for (final bone in glyphBones) {
      expect(bone.radius, AppRadius.buttonPrimary);
    }

    // Start button: width: 68, height: 32
    final startButtonBones =
        boxes.where((b) => b.width == 68 && b.height == 32).toList();
    expect(startButtonBones, isNotEmpty);
    for (final bone in startButtonBones) {
      expect(bone.radius, AppRadius.buttonPrimary);
    }
  });
}
