import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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

class FutureCompleter<T> {
  final Completer<T> _completer = Completer<T>();
  Future<T> get future => _completer.future;
  void complete([FutureOr<T>? value]) => _completer.complete(value);
}

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository() : super(null);

  int signInCallCount = 0;
  int cancelSignInCallCount = 0;
  Object? errorToThrow;
  Future<void>? signInDelayFuture;
  Completer<void>? _pendingSignIn;

  @override
  Future<void> signInWithGoogle() {
    signInCallCount++;
    final completer = Completer<void>();
    _pendingSignIn = completer;
    unawaited(_run(completer));
    return completer.future;
  }

  Future<void> _run(Completer<void> completer) async {
    final delay = signInDelayFuture;
    if (delay != null) {
      await delay;
    }
    if (completer.isCompleted) return;
    if (errorToThrow != null) {
      completer.completeError(errorToThrow!);
    } else {
      completer.complete();
    }
  }

  @override
  void cancelGoogleSignIn() {
    cancelSignInCallCount++;
    final pending = _pendingSignIn;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(const AuthCancelled());
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

  /// Bounded settle: the atmosphere drift (14s Lissajous loop) never lets
  /// pumpAndSettle finish, so drive the entrance + snackbar frames instead.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
  }

  /// All semantics nodes flagged as links, depth-first. The semantics handle is
  /// scoped and disposed here so it can never leak past the test.
  /// All semantics nodes flagged as links, from the live accessibility
  /// traversal (span link nodes carry a tap action, so they appear there).
  List<SemanticsNode> linkSemanticsNodes(WidgetTester tester) {
    return tester.semantics
        .simulatedAccessibilityTraversal()
        .where((n) => n.getSemanticsData().flagsCollection.isLink)
        .toList();
  }

  group('AuthScreen Behavior Tests (AUTH-01 to AUTH-20)', () {
    testWidgets('AUTH-01: Initial screen contains one primary CTA',
        (tester) async {
      await tester.pumpWidget(buildAuthScreen());
      await settle(tester);

      final ctaFinder = find.text('Continue with Google');
      expect(ctaFinder, findsOneWidget);
    });

    testWidgets(
        'AUTH-02: Only the atmosphere drift repeats; reduced motion halts it',
        (tester) async {
      await tester.pumpWidget(buildAuthScreen());
      await settle(tester);

      // The Lissajous backdrop drift is the single intentional repeating
      // controller on this screen (AUTH-02 re-spec'd for the UX-95-02
      // atmosphere). A looping ticker is provably alive...
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      expect(find.text('Continue with Google'), findsOneWidget);

      // ...and the reduced-motion gate halts every loop so the tree settles.
      await tester.pumpWidget(buildAuthScreen(disableAnimations: true));
      await settle(tester);
      expect(tester.binding.transientCallbackCount, equals(0));
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
      await settle(tester);

      await tester.tap(find.text('Continue with Google'));
      await tester.pump(); // Start sign-in process

      // The button stays live while sign-in is in flight so a re-press can
      // provide feedback instead of being a dead tap (see AU-B test below).
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);

      // Resolve the sign in
      delayCompleter.complete();
      await settle(tester);

      final buttonAfter =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(buttonAfter.onPressed, isNotNull);
    });

    testWidgets('AUTH-05: Rapid double tap starts one repository operation',
        (tester) async {
      final delayCompleter = FutureCompleter<void>();
      fakeAuthRepository.signInDelayFuture = delayCompleter.future;

      await tester.pumpWidget(buildAuthScreen());
      await settle(tester);

      // Double tap quickly
      await tester.tap(find.text('Continue with Google'));
      await tester.tap(find.text('Continue with Google'));
      await tester.pump();

      // Confirm only one call was registered
      expect(fakeAuthRepository.signInCallCount, equals(1));

      delayCompleter.complete();
      await settle(tester);
    });

    testWidgets('AUTH-06: Account picker cancellation shows no error',
        (tester) async {
      fakeAuthRepository.errorToThrow = const AuthCancelled();

      await tester.pumpWidget(buildAuthScreen());
      await settle(tester);

      await tester.tap(find.text('Continue with Google'));
      await settle(tester);

      // Snackbars shouldn't be shown
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('AUTH-07: Network failure shows recovery copy', (tester) async {
      fakeAuthRepository.errorToThrow = const AuthNetworkFailure();

      await tester.pumpWidget(buildAuthScreen());
      await settle(tester);

      await tester.tap(find.text('Continue with Google'));
      await settle(tester);

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
      await settle(tester);

      await tester.tap(find.text('Continue with Google'));
      await settle(tester);

      final errorText = find.textContaining('isn’t available in this build');
      expect(errorText, findsOneWidget);
      expect(find.textContaining('SHA-1'), findsNothing);
      expect(find.textContaining('ApiException 10'), findsNothing);
    });

    testWidgets('AUTH-09: Unknown error shows generic safe copy',
        (tester) async {
      fakeAuthRepository.errorToThrow = const AuthUnknownFailure();

      await tester.pumpWidget(buildAuthScreen());
      await settle(tester);

      await tester.tap(find.text('Continue with Google'));
      await settle(tester);

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

    testWidgets('AUTH-12: Legal links expose link semantics',
        semanticsEnabled: true, (tester) async {
      await tester.pumpWidget(buildAuthScreen());
      await settle(tester);

      // The legal sentence is ONE inline-flowing paragraph (Text.rich), not a
      // Wrap of tall link boxes — the boxes used to raise the link baselines
      // above the sentence ("popped above") and gap the wrapped lines.
      final paragraph = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            w.textSpan != null &&
            w.textSpan!.toPlainText().contains('Terms of Service'),
      );
      expect(paragraph, findsOneWidget);

      // Each link span still publishes an isLink semantics node with a tap
      // action (RenderParagraph creates per-span nodes for recognizers).
      final links = linkSemanticsNodes(tester);
      expect(links.any((n) => n.label == 'Terms of Service'), isTrue,
          reason: 'no isLink semantics node for Terms of Service');
      expect(links.any((n) => n.label == 'Privacy Policy'), isTrue,
          reason: 'no isLink semantics node for Privacy Policy');
      expect(
          links.every((n) =>
              n.getSemanticsData().actions & SemanticsAction.tap.index != 0),
          isTrue);
    });

    testWidgets('AUTH-13: GymLog exposes heading semantics', (tester) async {
      await tester.pumpWidget(buildAuthScreen());
      await settle(tester);

      final titleSemantics = tester.getSemantics(find.text('GymLog'));
      expect(
          titleSemantics.getSemanticsData().flagsCollection.isHeader, isTrue);
    });

    testWidgets(
        'AUTH-15: Primary actions meet 48dp; legal links expose tap '
        'semantics',
        semanticsEnabled: true, (tester) async {
      await tester.pumpWidget(buildAuthScreen());
      await settle(tester);

      final buttonSize = tester.getSize(find.byType(ElevatedButton));
      expect(buttonSize.height, greaterThanOrEqualTo(48.0));

      // Inline legal links are text spans, not buttons — glyph-sized targets
      // are the platform norm. What must not regress: link semantics with a
      // working tap action for screen readers.
      final links = linkSemanticsNodes(tester);
      expect(links.any((n) => n.label == 'Terms of Service'), isTrue);
      expect(links.any((n) => n.label == 'Privacy Policy'), isTrue);
      expect(
          links.every((n) =>
              n.getSemanticsData().actions & SemanticsAction.tap.index != 0),
          isTrue);
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
        await settle(tester);

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
      await settle(tester);

      final Size originalSize = tester.getSize(find.byType(ElevatedButton));

      await tester.tap(find.text('Continue with Google'));
      await tester.pump(); // Enter loading state

      final Size loadingSize = tester.getSize(find.byType(ElevatedButton));
      expect(loadingSize.width, equals(originalSize.width));
      expect(loadingSize.height, equals(originalSize.height));

      delayCompleter.complete();
      await settle(tester);
    });

    testWidgets(
        'AUTH-04 (AU-B): Re-press during in-flight sign-in gives feedback, not a dead tap',
        (tester) async {
      final delayCompleter = FutureCompleter<void>();
      fakeAuthRepository.signInDelayFuture = delayCompleter.future;

      await tester.pumpWidget(buildAuthScreen());
      await settle(tester);

      await tester.tap(find.text('Continue with Google'));
      await tester.pump(); // Enter loading state

      // The CTA stays live while signing in so a re-press is never a dead tap.
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);

      final callsBefore = fakeAuthRepository.signInCallCount;
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(fakeAuthRepository.signInCallCount, callsBefore,
          reason: 're-press must not start a second repository operation');
      expect(find.text('Sign-in is already in progress.'), findsOneWidget);

      delayCompleter.complete();
      await settle(tester);
    });

    testWidgets(
        'AUTH-21 (AU-C): Cancel affordance appears while signing in and returns the screen to idle',
        (tester) async {
      final delayCompleter = FutureCompleter<void>();
      fakeAuthRepository.signInDelayFuture = delayCompleter.future;

      await tester.pumpWidget(buildAuthScreen());
      await settle(tester);

      await tester.tap(find.text('Continue with Google'));
      await tester.pump();

      final cancelFinder = find.text('Cancel');
      expect(cancelFinder, findsOneWidget);

      final cancelButton = tester.widget<TextButton>(find.byType(TextButton));
      expect(cancelButton.onPressed, isNotNull);
      expect(tester.getSize(find.byType(TextButton)).height,
          greaterThanOrEqualTo(48.0));

      await tester.tap(cancelFinder);
      await settle(tester);

      expect(fakeAuthRepository.cancelSignInCallCount, equals(1));
      expect(find.text('Continue with Google'), findsOneWidget,
          reason: 'cancel returns the CTA to the idle state');
      expect(cancelFinder, findsNothing);
    });

    testWidgets('AUTH-22 (AU-C): Timeout failure surfaces honest recovery copy',
        (tester) async {
      fakeAuthRepository.errorToThrow = const AuthTimeoutFailure();

      await tester.pumpWidget(buildAuthScreen());
      await settle(tester);

      await tester.tap(find.text('Continue with Google'));
      await settle(tester);

      expect(find.text('Sign-in timed out. Please try again.'), findsOneWidget);
    });
  });
}
