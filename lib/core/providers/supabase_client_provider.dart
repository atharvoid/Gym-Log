import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The single answer to "is Supabase usable right now?".
///
/// `Supabase.instance` THROWS a `LateInitializationError` until
/// `Supabase.initialize()` has completed, and in this app that completion
/// happens after the first frame (see `Bootstrap._postLaunchBackgroundWork`).
/// Any code that touches the singleton without guarding is therefore correct
/// only by accident of timing.
///
/// Returns the live client, or `null` when the cloud is not available — no
/// config in this build, init timed out, or init failed. `null` is a normal,
/// fully supported state: GymLog is local-first and every cloud-touching
/// service degrades to a no-op rather than an error.
///
/// ## Why a function and not a `Provider<SupabaseClient?>`
///
/// Riverpod providers memoise. A provider that computed the client during
/// early startup would cache `null` and continue returning `null` for the
/// entire process lifetime, silently converting a four-second startup window
/// into a permanently local-only session that only a relaunch could fix.
/// A plain function is evaluated fresh at every call, so it cannot go stale.
///
/// Call it at the point of use. Do not hoist the result into a field that
/// outlives a single operation.
SupabaseClient? supabaseClientOrNull() {
  try {
    return Supabase.instance.client;
  } catch (_) {
    return null;
  }
}

/// Injectable form of [supabaseClientOrNull].
///
/// Exists so tests can substitute a fake or force the unavailable path
/// without initialising Supabase. Production code may call the function
/// directly; anything constructed inside a provider should read this so the
/// seam stays available.
typedef SupabaseClientResolver = SupabaseClient? Function();

final supabaseClientProvider = Provider<SupabaseClientResolver>(
  (ref) => supabaseClientOrNull,
);
