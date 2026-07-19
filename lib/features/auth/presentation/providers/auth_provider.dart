import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  try {
    return AuthRepository(Supabase.instance.client);
  } catch (_) {
    return AuthRepository(null);
  }
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final authProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  final repoUser = ref.watch(authRepositoryProvider).currentUser;
  final user = authState.value?.session?.user ?? repoUser;

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
