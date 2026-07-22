import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/config/legal_links.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/features/auth/data/auth_repository.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/auth/presentation/screens/auth_screen.dart';
import 'package:drift/native.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show User, Session, AuthState;

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository() : super(null);

  int signInCallCount = 0;
  Object? errorToThrow;
  Future<void>? signInDelayFuture;

  @override
  Future<void> signInWithGoogle() async {
    signInCallCount++;
    if (signInDelayFuture != null) {
      await signInDelayFuture;
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
  }

  @override
  User? get currentUser => null;

  @override
  Session? get currentSession => null;

  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();
}

void main() {
  late AppDatabase db;
  late FakeAuthRepository fakeAuthRepository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    fakeAuthRepository = FakeAuthRepository();
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildAuthScreen({bool disableAnimations = false}) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        databaseProvider.overrideWithValue(db),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(disableAnimations: disableAnimations),
              child: const AuthScreen(),
            );
          },
        ),
      ),
    );
  }

  group('AuthScreen Behavior Tests (AUTH-01 to AUTH-20)', () {
    testWidgets('AUTH-01: Initial screen contains one primary CTA',
        (tester) async {
      await tester.pumpWidget(buildAuthScreen());
      await tester.pumpAndSettle();

      final ctaFinder = find.text('Continue with Google');
      expect(ctaFinder, findsOneWidget);
    });

    testWidgets('AUTH-02: No continuously repeating AnimationController exists',
        (tester) async {
      await tester.pumpWidget(buildAuthScreen());
      // A continuously repeating AnimationController would cause pumpAndSettle to timeout.
      // Settling successfully proves there are no looping tickers.
      final frames = await tester.pumpAndSettle();
      expect(frames, lessThan(100));
    });

    testWidgets('AUTH-03: Reduced motion renders final state with no animation',
        (tester) async {
      await tester.pumpWidget(buildAuthScreen(disableAnimations: true));
      await tester.pump();

      // With reduced motion, state is immediate on first frame and no further frames are scheduled
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets(
        'AUTH-04: Sign-in button is disabled while request is in progress',
        (tester) async {
      final delayCompleter = FutureCompleter<void>();
      fakeAuthRepository.signInDelayFuture = delayCompleter.future;

      await tester.pumpWidget(buildAuthScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue with Google'));
      await tester.pump(); // Start sign-in process

      // The button should be disabled (onPressed is null)
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);

      // Resolve the sign in
      delayCompleter.complete();
      await tester.pumpAndSettle();

      final buttonAfter =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(buttonAfter.onPressed, isNotNull);
    });

    testWidgets('AUTH-05: Rapid double tap starts one repository operation',
        (tester) async {
      final delayCompleter = FutureCompleter<void>();
      fakeAuthRepository.signInDelayFuture = delayCompleter.future;

      await tester.pumpWidget(buildAuthScreen());
      await tester.pumpAndSettle();

      // Double tap quickly
      await tester.tap(find.text('Continue with Google'));
      await tester.tap(find.text('Continue with Google'));
      await tester.pump();

      // Confirm only one call was registered
      expect(fakeAuthRepository.signInCallCount, equals(1));

      delayCompleter.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('AUTH-06: Account picker cancellation shows no error',
        (tester) async {
      fakeAuthRepository.errorToThrow = const AuthCancelled();

      await tester.pumpWidget(buildAuthScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      // Snackbars shouldn't be shown
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('AUTH-07: Network failure shows recovery copy', (tester) async {
      fakeAuthRepository.errorToThrow = const AuthNetworkFailure();

      await tester.pumpWidget(buildAuthScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(find.text('You’re offline. Check your connection and try again.'),
          findsOneWidget);
    });

    testWidgets(
        'AUTH-08: Configuration failure does not expose SHA-1 or ApiException 10',
        (tester) async {
      fakeAuthRepository.errorToThrow = const AuthConfigurationFailure(
        diagnosticCode: 'google_android_configuration',
      );

      await tester.pumpWidget(buildAuthScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      final errorText = find.textContaining('isn’t available in this build');
      expect(errorText, findsOneWidget);
      expect(find.textContaining('SHA-1'), findsNothing);
      expect(find.textContaining('ApiException 10'), findsNothing);
    });

    testWidgets('AUTH-09: Unknown error shows generic safe copy',
        (tester) async {
      fakeAuthRepository.errorToThrow = const AuthUnknownFailure();

      await tester.pumpWidget(buildAuthScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(find.text('Couldn’t sign in. Please try again.'), findsOneWidget);
    });

    test('AUTH-10 & AUTH-11: Legal URLs are defined and correct', () {
      expect(
          kTermsOfServiceUrl,
          equals(
              'https://atharvoid.github.io/Gym-Log/legal/terms-of-service.html'));
      expect(
          kPrivacyPolicyUrl,
          equals(
              'https://atharvoid.github.io/Gym-Log/legal/privacy-policy.html'));
    });

    testWidgets('AUTH-12: Legal links expose link semantics', (tester) async {
      await tester.pumpWidget(buildAuthScreen());
      await tester.pumpAndSettle();

      final termsFinder = find.text('Terms of Service');
      final privacyFinder = find.text('Privacy Policy');

      final termsSemantics = tester.getSemantics(termsFinder);
      final privacySemantics = tester.getSemantics(privacyFinder);

      expect(termsSemantics.getSemanticsData().flagsCollection.isLink, isTrue);
      expect(
          privacySemantics.getSemanticsData().flagsCollection.isLink, isTrue);
    });

    testWidgets('AUTH-13: GymLog exposes heading semantics', (tester) async {
      await tester.pumpWidget(buildAuthScreen());
      await tester.pumpAndSettle();

      final titleSemantics = tester.getSemantics(find.text('GymLog'));
      expect(
          titleSemantics.getSemanticsData().flagsCollection.isHeader, isTrue);
    });

    testWidgets('AUTH-15: All actions meet minimum 48dp target',
        (tester) async {
      await tester.pumpWidget(buildAuthScreen());
      await tester.pumpAndSettle();

      final buttonSize = tester.getSize(find.byType(ElevatedButton));
      expect(buttonSize.height, greaterThanOrEqualTo(48.0));

      final termsFinder = find.ancestor(
        of: find.text('Terms of Service'),
        matching: find.byType(GestureDetector),
      );
      final termsSize = tester.getSize(termsFinder);
      expect(termsSize.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('AUTH-16: No overflow at all required viewports',
        (tester) async {
      final viewports = [
        const Size(320, 568),
        const Size(360, 640),
        const Size(390, 844),
        const Size(430, 932),
        const Size(600, 960),
        const Size(844, 390),
      ];

      for (final size in viewports) {
        tester.view.physicalSize = size * 3.0; // scale factor
        tester.view.devicePixelRatio = 3.0;

        await tester.pumpWidget(buildAuthScreen());
        await tester.pumpAndSettle();

        // If overflow is present, Flutter throws an assertion error during paint.
        // Expect no exceptions
        expect(tester.takeException(), isNull);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    test('AUTH-18: No hardcoded C8FF00 exists in auth source', () {
      final file =
          File('lib/features/auth/presentation/screens/auth_screen.dart');
      final contents = file.readAsStringSync();
      expect(contents.contains('C8FF00'), isFalse);
      expect(contents.contains('c8ff00'), isFalse);
      expect(contents.contains('voltBase'), isFalse);
    });

    testWidgets('AUTH-20: Loading state preserves CTA dimensions',
        (tester) async {
      final delayCompleter = FutureCompleter<void>();
      fakeAuthRepository.signInDelayFuture = delayCompleter.future;

      await tester.pumpWidget(buildAuthScreen());
      await tester.pumpAndSettle();

      final Size originalSize = tester.getSize(find.byType(ElevatedButton));

      await tester.tap(find.text('Continue with Google'));
      await tester.pump(); // Enter loading state

      final Size loadingSize = tester.getSize(find.byType(ElevatedButton));
      expect(loadingSize.width, equals(originalSize.width));
      expect(loadingSize.height, equals(originalSize.height));

      delayCompleter.complete();
      await tester.pumpAndSettle();
    });
  });
}

class FutureCompleter<T> {
  final Completer<T> _completer = Completer<T>();
  Future<T> get future => _completer.future;
  void complete([FutureOr<T>? value]) => _completer.complete(value);
}
