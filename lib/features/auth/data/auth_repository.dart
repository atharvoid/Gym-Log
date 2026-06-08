import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

    // Use native Google Sign-In for mobile platforms
    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: '90567853200-0o67mbmlv5qluq95q1courn77lddhcui.apps.googleusercontent.com',
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google Sign-In was cancelled');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      debugPrint('DEBUG [GoogleSignIn]: ID Token is null. Account details: email=${googleUser.email}, displayName=${googleUser.displayName}, id=${googleUser.id}, serverAuthCode=${googleUser.serverAuthCode}');
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
