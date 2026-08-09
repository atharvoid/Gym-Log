import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../../core/providers/supabase_client_provider.dart';
import '../../../core/services/workout_draft_store.dart';

sealed class AuthFailure implements Exception {
  const AuthFailure();
}

final class AuthNetworkFailure extends AuthFailure {
  const AuthNetworkFailure();
}

final class AuthConfigurationFailure extends AuthFailure {
  const AuthConfigurationFailure({
    required this.diagnosticCode,
  });

  final String diagnosticCode;
}

final class AuthProviderFailure extends AuthFailure {
  const AuthProviderFailure();
}

final class AuthCancelled extends AuthFailure {
  const AuthCancelled();
}

final class AuthTimeoutFailure extends AuthFailure {
  const AuthTimeoutFailure();
}

final class AuthUnknownFailure extends AuthFailure {
  const AuthUnknownFailure();
}

class AuthRepository {
  final SupabaseClientResolver _resolveClient;
  final WorkoutDraftStore _draftStore;

  /// Fixed-client construction. Behaves exactly as this class always has;
  /// kept so existing call sites (including tests with fakes) compile and
  /// run unchanged.
  AuthRepository(SupabaseClient? client, [WorkoutDraftStore? draftStore])
      : _resolveClient = (() => client),
        _draftStore = draftStore ?? WorkoutDraftStore();

  /// Resolver-backed construction: the client is looked up on EVERY call.
  ///
  /// Provider wiring must use this form. This object is created inside a
  /// memoised provider, so capturing the client at construction time would
  /// freeze whatever was true during startup. usually "not initialised
  /// yet". and silently disable the entire auth path for the process
  /// lifetime: authStateChanges would be a permanently empty stream and no
  /// auth event could ever propagate. Resolving per call lets the same
  /// instance work before, during, and after cloud init. See
  /// supabase_client_provider.dart.
  AuthRepository.withResolver(this._resolveClient,
      [WorkoutDraftStore? draftStore])
      : _draftStore = draftStore ?? WorkoutDraftStore();

  /// The live Supabase client, or null when the cloud is unavailable.
  SupabaseClient? get _client => _resolveClient();

  /// Tracks an in-flight Google sign-in. The `google_sign_in` plugin keeps a
  /// single global pending operation and throws
  /// `IllegalStateException: Concurrent operations detected: signIn, signIn`
  /// if `signIn()` is called again before the first resolves (e.g. a double
  /// tap while the account picker is open). Coalescing onto one future makes
  /// any extra call a no-op until the current attempt finishes.
  Future<void>? _googleSignInInFlight;

  /// Abort signal for the current attempt. Completing it makes the in-flight
  /// operation resolve with [AuthCancelled] so the UI can return to idle even
  /// when the platform flow never surfaces (e.g. a Google sheet that never
  /// opens). Cleared together with [_googleSignInInFlight].
  Completer<void>? _signInCanceller;

  /// Upper bound on a single sign-in attempt (~31 s). A stuck platform or
  /// network call must not leave the "Signing in…" state spinning forever.
  static const Duration _signInTimeout = Duration(seconds: 31);

  /// Returns when sign-in has either completed or been dismissed by the user.
  /// User cancellation is NOT an error. it resolves normally so the UI can
  /// simply re-enable the button without showing a failure message.
  ///
  /// The attempt is bounded by [_signInTimeout] so a stuck platform or
  /// network call cannot leave the "Signing in…" state spinning forever; the
  /// caller surfaces the resulting [AuthTimeoutFailure] and can offer a retry.
  Future<void> signInWithGoogle() {
    if (_client == null) return Future.value();
    final inFlight = _googleSignInInFlight;
    if (inFlight != null) return inFlight;

    final canceller = Completer<void>();
    final attempt = _performGoogleSignIn(canceller).timeout(
      _signInTimeout,
      onTimeout: () => throw const AuthTimeoutFailure(),
    );
    _signInCanceller = canceller;
    _googleSignInInFlight = attempt;
    attempt.whenComplete(() {
      _googleSignInInFlight = null;
      _signInCanceller = null;
    });
    return attempt;
  }

  /// Aborts the in-flight sign-in, if any. Safe to call with no attempt
  /// running; completing a completed canceller is ignored.
  void cancelGoogleSignIn() {
    final canceller = _signInCanceller;
    if (canceller != null && !canceller.isCompleted) {
      canceller.complete();
    }
  }

  Future<void> _performGoogleSignIn(Completer<void> canceller) async {
    final client = _client;
    if (client == null) return;

    // Races a platform operation against the cancel signal. The canceller
    // completes normally (no error) and the value transition converts it into
    // the user-facing cancellation, keeping the in-flight operation from being
    // observed as an unhandled async error when no race is attached (web path).
    Future<T> abortable<T>(Future<T> operation) => Future.any([
          operation,
          canceller.future.then<T>((_) => throw const AuthCancelled()),
        ]);

    try {
      // Use web OAuth for web platform
      if (kIsWeb) {
        await client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'http://127.0.0.1:8080/',
        );
        return;
      }

      // Use native Google Sign-In for mobile platforms. The server client id
      // is a public OAuth identifier, centralized + overridable in Env.
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: Env.googleServerClientId,
      );

      final googleUser = await abortable(googleSignIn.signIn());
      if (googleUser == null) {
        // User dismissed the picker. a deliberate choice, not a failure.
        throw const AuthCancelled();
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        // Never log account details (email/name/id are PII). The actionable
        // signal is the misconfiguration itself.
        debugPrint('[GoogleSignIn] No ID token returned. check that '
            'GOOGLE_SERVER_CLIENT_ID matches the Google Cloud OAuth client.');
        throw const AuthConfigurationFailure(
          diagnosticCode: 'google_android_configuration',
        );
      }

      await abortable(client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      ));
    } catch (e) {
      if (e is AuthFailure) {
        rethrow;
      }
      final errStr = e.toString();
      if (errStr.contains('sign_in_canceled') ||
          errStr.contains('canceled') ||
          errStr.contains('cancelled')) {
        throw const AuthCancelled();
      }
      if (e is SocketException ||
          errStr.contains('SocketException') ||
          errStr.contains('NetworkException') ||
          errStr.contains('network_error')) {
        throw const AuthNetworkFailure();
      }
      if (errStr.contains('10:') || errStr.contains('DEVELOPER_ERROR')) {
        throw const AuthConfigurationFailure(
          diagnosticCode: 'google_android_configuration',
        );
      }
      if (e is AuthException) {
        throw const AuthProviderFailure();
      }
      throw const AuthUnknownFailure();
    }
  }

  Future<void> signOut() async {
    await _draftStore.clear();
    final client = _client;
    // A cloud sign-out that fails must be visible to callers: the user asked
    // to end their session and a swallowed failure leaves a live cloud
    // session that signs them back in on next launch. Callers decide whether
    // to surface or (deliberately) proceed offline.
    if (client != null) {
      await client.auth.signOut();
    }
  }

  User? get currentUser => _client?.auth.currentUser;

  Session? get currentSession => _client?.auth.currentSession;

  Stream<AuthState> get authStateChanges =>
      _client?.auth.onAuthStateChange ?? const Stream.empty();
}
