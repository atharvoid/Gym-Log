import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/database/daos/routines_dao.dart';
import 'package:gymlog/core/exercises/muscle_taxonomy.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/providers/premium_provider.dart';
import 'package:gymlog/core/theme/app_colors.dart';
import 'package:gymlog/core/theme/app_text.dart';
import 'package:gymlog/core/theme/dynamic_accent_theme.dart';
import 'package:gymlog/shared/layout/adaptive.dart';
import 'package:gymlog/shared/widgets/body/muscle_map.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/auth/presentation/providers/tour_provider.dart';
import 'package:gymlog/features/profile/presentation/providers/profile_provider.dart';
import 'package:gymlog/features/routines/presentation/data/explore_catalog.dart';
import 'package:gymlog/features/routines/presentation/providers/routines_provider.dart';
import 'package:gymlog/shared/widgets/premium_paywall.dart';
import 'package:gymlog/shared/widgets/tour/spotlight_tour_overlay.dart';
import 'package:gymlog/shared/widgets/ui/app_snack_bar.dart';
import 'package:gymlog/shared/widgets/ui/primary_button.dart';

/// Parses the human-readable [focus] string into parent muscle groups suitable
/// for [MuscleMap]. Non-muscle tokens (e.g. "Strength", "45 min") are dropped,
/// and "Total Body" is mapped to the full-body sentinel so the entire figure
/// lights up.
Set<String> _focusGroups(String focus) {
  return focus
      .split(' · ')
      .map((token) {
        final trimmed = token.trim();
        if (trimmed.toLowerCase() == 'total body') return 'Full Body';
        return MuscleTaxonomy.parentOf(trimmed);
      })
      .where((group) => group != 'Other')
      .toSet();
}

/// The first muscle-like token of the focus string mapped to its parent group.
/// Returns `null` when no token resolves (e.g. pure-strength focus).
String? _primaryFocusGroup(String focus) {
  for (final token in focus.split(' · ')) {
    final trimmed = token.trim();
    if (trimmed.toLowerCase() == 'total body') return 'Full Body';
    final group = MuscleTaxonomy.parentOf(trimmed);
    if (group != 'Other') return group;
  }
  return null;
}

enum _LevelFilter {
  all,
  beginner,
  intermediate,
  advanced;

  String get label => switch (this) {
        _LevelFilter.all => 'All',
        _LevelFilter.beginner => 'Beginner',
        _LevelFilter.intermediate => 'Intermediate',
        _LevelFilter.advanced => 'Advanced',
      };

  bool matches(RoutineTemplate t) => switch (this) {
        _LevelFilter.all => true,
        _LevelFilter.beginner => t.levels.contains(TemplateLevel.beginner),
        _LevelFilter.intermediate =>
          t.levels.contains(TemplateLevel.intermediate),
        _LevelFilter.advanced => t.levels.contains(TemplateLevel.advanced),
      };
}

///