@Tags(['golden'])
library;

// Full-screen Explore goldens: one per accent palette at compact width, plus
// a 1.3x text-scale variant. These lock the remediation — chips that wrap
// mid-word, clipped filter rows, invisible card boundaries and the CTA
// density decision all become visible regressions here.

import 'package:alchemist/alchemist.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/core/database/database.dart';
import 'package:gymlog/core/providers/database_provider.dart';
import 'package:gymlog/core/theme/app_theme.dart';
import 'package:gymlog/core/theme/theme_palette.dart';
import 'package:gymlog/features/auth/presentation/providers/auth_provider.dart';
import 'package:gymlog/features/routines/presentation/screens/explore_routines_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../explore_widget_test_utils.dart';

void main() {
  goldenTest(
    'Explore screen — compact, all palettes',
    fileName: 'explore_screen_all_palettes',
    builder: () => _ExploreGoldenHarness(
      child: GoldenTestGroup(
        columns: 1,
        scenarioConstraints:
            const BoxConstraints(maxWidth: 400, maxHeight: 800),
        children: [
          for (final palette in ThemePalette.values)
            GoldenTestScenario(
              name: palette.displayName,
              child: _exploreApp(palette),
            ),
        ],
      ),
    ),
  );

  goldenTest(
    'Explore screen — 1.3x text scale, neon purple',
    fileName: 'explore_screen_text_scale_1_3',
    textScaleFactor: 1.3,
    constraints: const BoxConstraints(maxWidth: 400, maxHeight: 800),
    builder: () => _ExploreGoldenHarness(
      child: GoldenTestScenario(
        name: 'textScale 1.3',
        child: _exploreApp(ThemePalette.neonPurple),
      ),
    ),
  );
}

Widget _exploreApp(ThemePalette palette) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(palette.tokens, palette: palette),
      home: const SizedBox(
        width: 400,
        height: 740,
        child: ExploreRoutinesScreen(),
      ),
    );

/// Owns the provider overrides (signed-out auth, in-memory DB) for the full
/// lifetime of the golden: the SupabaseClient's auto-refresh timer is stopped
/// synchronously in initState and the DB is closed on dispose.
class _ExploreGoldenHarness extends StatefulWidget {
  final Widget child;
  const _ExploreGoldenHarness({required this.child});

  @override
  State<_ExploreGoldenHarness> createState() => _ExploreGoldenHarnessState();
}

class _ExploreGoldenHarnessState extends State<_ExploreGoldenHarness> {
  late final AppDatabase _db;
  late final SupabaseClient _supabase;
  late final MockAuthRepository _repo;

  @override
  void initState() {
    super.initState();
    SharedPreferences.setMockInitialValues({});
    _db = AppDatabase.forTesting(NativeDatabase.memory());
    _supabase = SupabaseClient('https://example.com', 'key');
    // Stop GoTrue's periodic auto-refresh timer synchronously so no pending
    // fake timer outlives the golden test body.
    _supabase.auth.stopAutoRefresh();
    _repo = MockAuthRepository(_supabase);
  }

  @override
  void dispose() {
    _supabase.auth.stopAutoRefresh();
    _db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_repo),
        authProvider.overrideWithValue(null),
        databaseProvider.overrideWithValue(_db),
      ],
      child: widget.child,
    );
  }
}
