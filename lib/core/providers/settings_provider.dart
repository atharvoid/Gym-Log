import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global weight unit ('kg' | 'lbs'). Backed by user_profiles.weightUnit,
/// so it survives reinstalls alongside the rest of the profile.
final weightUnitProvider = Provider<String>((ref) {
  final profile = ref.watch(currentUserProfileProvider).valueOrNull;
  final unit = profile?.weightUnit;
  return unit == 'lbs' ? 'lbs' : 'kg';
});

/// Default rest-timer duration. Backed by user_profiles.defaultRestSeconds.
final defaultRestSecondsProvider = Provider<int>((ref) {
  final profile = ref.watch(currentUserProfileProvider).valueOrNull;
  return profile?.defaultRestSeconds ?? 90;
});

/// Writes for the Settings screen.
final settingsActionsProvider = Provider<SettingsActions>(SettingsActions.new);

class SettingsActions {
  final Ref _ref;
  SettingsActions(this._ref);

  Future<void> setWeightUnit(String unit) async {
    final user = _ref.read(authProvider);
    if (user == null) return;
    await _ref.read(databaseProvider).userDao.setWeightUnit(user.id, unit);
  }

  Future<void> setDefaultRestSeconds(int seconds) async {
    final user = _ref.read(authProvider);
    if (user == null) return;
    await _ref
        .read(databaseProvider)
        .userDao
        .setDefaultRestSeconds(user.id, seconds);
  }
}

// ── Per-exercise unit overrides ───────────────────────────────────────────────

/// Map of exerciseId → 'kg' | 'lbs'. Lets an athlete log dumbbell work in
/// lbs while everything else stays kg. Presentation-only; storage is kg.
class UnitOverridesNotifier extends StateNotifier<Map<int, String>> {
  static const _key = 'exercise_unit_overrides';

  UnitOverridesNotifier() : super(const {}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || !mounted) return;
    try {
      final decoded = (jsonDecode(raw) as Map<String, dynamic>)
          .map((k, v) => MapEntry(int.parse(k), v as String));
      state = decoded;
    } catch (_) {/* corrupt prefs — start clean */}
  }

  Future<void> setOverride(int exerciseId, String? unit) async {
    final next = Map<int, String>.from(state);
    if (unit == null) {
      next.remove(exerciseId);
    } else {
      next[exerciseId] = unit;
    }
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(next.map((k, v) => MapEntry(k.toString(), v))));
  }
}

final unitOverridesProvider =
    StateNotifierProvider<UnitOverridesNotifier, Map<int, String>>(
        (ref) => UnitOverridesNotifier());

/// Effective unit for one exercise: override first, global second.
final exerciseUnitProvider = Provider.family<String, int>((ref, exerciseId) {
  final overrides = ref.watch(unitOverridesProvider);
  return overrides[exerciseId] ?? ref.watch(weightUnitProvider);
});
