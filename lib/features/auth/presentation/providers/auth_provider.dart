import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final authProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value?.session?.user ??
      Supabase.instance.client.auth.currentUser;

  // Keep Sentry scope in sync with auth state without capturing PII.
  if (user != null) {
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(id: user.id));
      scope.setTag('platform', defaultTargetPlatform.name);
    });
  } else {
    Sentry.configureScope((scope) => scope.setUser(null));
  }

  return user;
});

extension AuthProviderX on WidgetRef {
  bool get isSignedIn => watch(authProvider) != null;
}
