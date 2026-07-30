import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/supabase_client_provider.dart';
import '../../data/auth_repository.dart';

/// The auth repository.
///
/// Safe to read at any point in the app lifecycle: the repository resolves
/// the Supabase client per call rather than capturing it here, where a
/// startup-time read would cache "unavailable" for the rest of the process
/// and turn authStateChanges into a permanently empty stream. See
/// supabase_client_provider.dart.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository.withResolver(ref.read(supabaseClientProvider)),
);

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
