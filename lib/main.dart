import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/database/database.dart';
import 'core/providers/database_provider.dart';

void main() async {
  // 1. Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Set URL strategy for web (use path-based routing, not hash)
  usePathUrlStrategy();

  // 3. Load environment variables
  await dotenv.load(fileName: '.env');

  // 4. Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    publishableKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // 5. Pre-initialize database and seed exercise library on first launch
  final db = AppDatabase();
  await db.customSelect('SELECT 1').getSingle(); // Warm-up query

  await db.exercisesDao.hydrateFromJson(); // One-time JSON hydration

  final user = Supabase.instance.client.auth.currentUser;
  if (user != null) {
    await db.workoutsDao.deleteOrphanedSessions(user.id);
  }

  // 6. Run app with shared database instance
  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const GymLogApp(),
    ),
  );
}
