import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  Future<void> signInWithGoogle() async {
    // Use web OAuth for web platform
    if (kIsWeb) {
      await _client.auth.signInWithOAuth(
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

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google Sign-In was cancelled');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      // Never log account details (email/name/id are PII). The actionable
      // signal is the misconfiguration itself.
      debugPrint('[GoogleSignIn] No ID token returned — check that '
          'GOOGLE_SERVER_CLIENT_ID matches the Google Cloud OAuth client.');
      throw Exception('No ID Token found');
    }

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;

  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
