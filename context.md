# GymLog — Windsurf Pro Master Build Prompt
> Paste this entire file as context into Windsurf Pro at session start.
> Reference: GYMLOG_WINDSURF_MASTER_PROMPT.md

---

## 0. HOW TO USE THIS PROMPT

This is a complete build specification. Windsurf must:
1. Read ALL sections before writing any code
2. Execute via PARALLEL MICRO-TRACKS (defined in Section 8)
3. Generate a `docs/` entry for every module completed
4. Never skip a section — each one has non-negotiable requirements
5. After each track completes, run `flutter analyze` — zero issues before proceeding

---

## 1. PROJECT CONTEXT — WHAT EXISTS

**Project:** GymLog — Flutter workout tracker (Hevy clone, no social features)  
**Location:** Current working directory (open in Windsurf)  
**Status:** ~15% complete — scaffold only

### What is already built:
- Flutter project initialized, `flutter analyze` passes with zero issues
- Drift (SQLite ORM) schema defined: `Exercises`, `WorkoutSessions`, `WorkoutSets`, `Routines`, `RoutineExercises`
- Riverpod state management wired with `@riverpod` code generation
- go_router: 5 tabs (Log, History, Routines, Analytics, Profile) + `/workout/active` modal route
- `AppShell` with persistent `ActiveWorkoutBar` across tab switches
- `AppColors` token system (zinc-950 dark theme)
- `ActiveWorkoutState` (Freezed model) + `ActiveWorkoutProvider`
- Log screen: placeholder UI with "Start Workout" button, dummy routine cards
- Python seed script at `scripts/seed_exercises.py` (partially broken — fix in Track A)
- All other screens are Text-only stubs

### What does NOT exist yet (everything below must be built):
- Real UI on any screen except partial Log screen
- Working Active Workout session with SetRow interactions
- Exercise browser with real data
- Routine builder (CRUD)
- History screen
- Analytics / charts
- Google Sign-In
- Freemium gating logic
- Payment integration (DodoPayments + NowPayments crypto)
- Exercise data pipeline (ExerciseDB API → local SQLite)
- GIF/image caching
- PR detection
- Rest timer
- Documentation

---

## 2. DESIGN SYSTEM — NEO BRUTALISM DARK

**Theme:** Dark Neo Brutalism. Not standard Material. Raw, bold, intentional.

### Core Principles:
- **Hard borders:** 2px solid borders on all interactive elements, cards, inputs
- **Offset shadows:** `BoxShadow(offset: Offset(3,3), color: AppColors.accent)` — no blur, no spread
- **Bold typography:** Heavy font weights (700–900) for headings, 500 for body
- **No gradients. No rounded softness.** Border radius max 4px on most elements, 0px on cards
- **High contrast:** Near-black surfaces, stark white text, punchy accent colors
- **Chunky interactive targets:** Buttons are tall (52px min), inputs are bold-bordered

### Color Tokens — update `lib/core/theme/app_colors.dart`:
```dart
abstract class AppColors {
  // Surfaces
  static const bgBase       = Color(0xFF0A0A0A); // true black
  static const bgSurface    = Color(0xFF141414); // cards
  static const bgElevated   = Color(0xFF1E1E1E); // inputs, elevated
  static const border       = Color(0xFFFFFFFF); // white borders — neo brutalism
  static const borderMuted  = Color(0xFF333333); // subtle dividers

  // Text
  static const textPrimary  = Color(0xFFFAFAFA);
  static const textSecondary= Color(0xFFA0A0A0);
  static const textMuted    = Color(0xFF606060);

  // Accent — primary interactive color
  static const accent       = Color(0xFFFFE500); // brutal yellow
  static const accentFg     = Color(0xFF0A0A0A); // text ON accent bg
  
  // Secondary accents
  static const accentGreen  = Color(0xFF00FF87); // set completed
  static const accentRed    = Color(0xFFFF3B3B); // danger/delete
  static const accentPurple = Color(0xFFB14EFF); // PR highlight

  // Semantic
  static const success      = Color(0xFF00FF87);
  static const danger       = Color(0xFFFF3B3B);
  static const warning      = Color(0xFFFFE500);
  static const pr           = Color(0xFFB14EFF);
}
```

### Typography — `lib/core/theme/app_typography.dart`:
```dart
// Use Google Fonts: Space Grotesk (headings) + IBM Plex Mono (numbers/timer)
// Add to pubspec: google_fonts: ^6.2.1
abstract class AppTypography {
  static TextStyle display(BuildContext ctx) => GoogleFonts.spaceGrotesk(
    fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );
  static TextStyle heading(BuildContext ctx) => GoogleFonts.spaceGrotesk(
    fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static TextStyle body(BuildContext ctx) => GoogleFonts.spaceGrotesk(
    fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary,
  );
  static TextStyle mono(BuildContext ctx) => GoogleFonts.ibmPlexMono(
    fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary,
  );
  static TextStyle label(BuildContext ctx) => GoogleFonts.spaceGrotesk(
    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary,
    letterSpacing: 0.8,
  );
}
```

### Reusable UI Primitives — build ALL in `lib/shared/widgets/ui/`:

**`BrutalCard`** — the standard card container:
```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.bgSurface,
    border: Border.all(color: AppColors.border, width: 2),
    boxShadow: [BoxShadow(offset: Offset(3,3), color: AppColors.accent, blurRadius: 0)],
  ),
  child: child,
)
```

**`BrutalButton`** — primary action button:
```dart
// Yellow fill, black text, hard border, offset shadow on press lifts
// On tap: shadow disappears, offset becomes 0 (press effect)
```

**`BrutalInput`** — text/number input:
```dart
// Hard white border 2px, bgElevated fill, no border radius
// Focus: border turns accent yellow
```

**`BrutalBadge`** — small type indicator (W, D, F for set types):
```dart
// 22x22 container, border 2px, letter centered, bold
```

**`BrutalChip`** — filter chip:
```dart
// Selected: accent yellow fill, black text
// Unselected: transparent fill, white border, white text
```

---

## 3. COMPLETE FEATURE SPECIFICATION

### 3.1 — Authentication (Google via Supabase)

**Package:** `supabase_flutter: ^2.5.0` only. No Firebase. No separate google_sign_in.

**Flow:**
1. Cold launch → `SplashScreen` (2s, GymLog wordmark brutal style)
2. Check `Supabase.instance.client.auth.currentSession` — if valid → `/log`
3. If null → `AuthScreen`
4. AuthScreen: GymLog logo, tagline, single "Continue with Google" button
5. On success → sync user profile to local Drift `UserProfiles` table → `/log`

**Implementation:**

`lib/features/auth/data/auth_repository.dart`:
```dart
/// [auth_repository.dart]
/// Purpose: Supabase Google OAuth + session management
/// Dependencies: supabase_flutter, Drift UserProfiles table

class AuthRepository {
  final _client = Supabase.instance.client;

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'gymlog://auth-callback',
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;
}
```

`lib/features/auth/presentation/providers/auth_provider.dart`:
```dart
@riverpod
class Auth extends _$Auth {
  @override
  User? build() {
    // Listen to auth state changes
    ref.listen(authStateProvider, (_, next) {
      state = next.session?.user;
    });
    return Supabase.instance.client.auth.currentUser;
  }

  Future<void> signInWithGoogle() =>
      ref.read(authRepositoryProvider).signInWithGoogle();

  Future<void> signOut() =>
      ref.read(authRepositoryProvider).signOut();
}

@riverpod
Stream<AuthState> authState(AuthStateRef ref) =>
    Supabase.instance.client.auth.onAuthStateChange;

// Convenience getter
extension AuthProviderX on WidgetRef {
  bool get isSignedIn => watch(authProvider) != null;
}
```

`lib/main.dart` — init before runApp:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  runApp(const ProviderScope(child: GymLogApp()));
}
```

`lib/features/auth/presentation/screens/auth_screen.dart`:
```dart
// Layout:
// - Scaffold bgBase
// - Center column:
//   - GymLog wordmark (Space Grotesk 800, 48px)
//   - Tagline: "Your gym. Your data." textSecondary
//   - Spacer
//   - BrutalButton: "Continue with Google"
//     → calls ref.read(authProvider.notifier).signInWithGoogle()
//   - Small text: "Free to use. No account required beyond Google login."
```

**Supabase dashboard config (Windsurf MCP does this automatically):**
- Enable Google OAuth provider
- Add redirect URL: `gymlog://auth-callback`
- Create `user_profiles` table mirroring local Drift schema
- RLS policy: users can only read/write their own row

**`android/app/build.gradle` — add deep link scheme:**
```gradle
manifestPlaceholders = [
  'appAuthRedirectScheme': 'gymlog'
]
```

**`ios/Runner/Info.plist` — add:**
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array><string>gymlog</string></array>
  </dict>
</array>
```

**Files:**
- `lib/features/auth/data/auth_repository.dart`
- `lib/features/auth/presentation/providers/auth_provider.dart`
- `lib/features/auth/presentation/screens/splash_screen.dart`
- `lib/features/auth/presentation/screens/auth_screen.dart`
- Update `lib/core/router/router.dart` auth guard (unchanged from original)
- Update `lib/main.dart` with Supabase.initialize

---

### 3.2 — Exercise Data Pipeline

**Source:** `https://oss.exercisedb.dev` (ExerciseDB open-source)  
**Strategy:**
- One-time fetch on first launch (or manual refresh in settings)
- Full exercise JSON stored in local SQLite via Drift
- GIF/images: NOT bundled — loaded on demand from API, cached to device storage
- Offline: show placeholder SVG muscle diagram if no internet

**Updated `Exercises` table:**
```dart
class Exercises extends Table {
  IntColumn  get id               => integer().autoIncrement()();
  TextColumn get exerciseDbId     => text().unique()(); // API's own ID
  TextColumn get name             => text()();
  TextColumn get bodyPart         => text()();          // chest, back, legs...
  TextColumn get equipment        => text()();
  TextColumn get target           => text()();          // primary muscle
  TextColumn get gifUrl           => text()();          // API gif URL
  TextColumn get secondaryMuscles => text()();          // JSON array string
  TextColumn get instructions     => text()();          // JSON array string
  BoolColumn get isCustom         => boolean().withDefault(const Constant(false))();
  TextColumn get createdBy        => text().nullable()(); // userId for custom exercises
  DateTimeColumn get seededAt     => dateTime().nullable()();
}
```

**Seeding service — `lib/features/exercises/data/exercise_seed_service.dart`:**
```dart
// 1. On first launch: fetch all from https://oss.exercisedb.dev/exercises?limit=1500&offset=0
// 2. Paginate if needed (check total count first)
// 3. Batch insert into Drift Exercises table (500 at a time)
// 4. Store seeding timestamp in SharedPreferences
// 5. Show progress indicator during seeding ("Loading exercise library... 847/1324")
// 6. Never re-seed unless user manually triggers in Settings
```

**GIF caching — `lib/features/exercises/data/gif_cache_service.dart`:**
```dart
// Use: cached_network_image package
// Cache duration: permanent (until app uninstall)
// Placeholder: flutter_svg muscle diagram SVG
// Error fallback: muscle icon from lucide
```

**Exercise Browser screen — `lib/features/exercises/presentation/screens/exercise_browser_screen.dart`:**
- Full-screen modal (opened from workout session and routine builder)
- Search bar (brutal style, prominent)
- Filter row: Body Part chips | Equipment chips | Muscle chips (horizontal scroll)
- Exercise list: `ExerciseListTile` with name, target muscle, equipment badge
- Tap → `ExerciseDetailScreen` (GIF, muscle diagram, instructions, history for this exercise)
- Long-press or "+" button → select and return to caller

---

### 3.3 — Active Workout Session (CORE FEATURE)

This is the most important screen. Build it pixel-perfect.

**Route:** `/workout/active` — full-screen modal, `gestureEnabled: false`

**`active_workout_screen.dart` layout:**

```
┌─────────────────────────────────────┐
│ [✕ Discard]  0:23:14   [Finish →]  │  ← Header bar (not AppBar)
├─────────────────────────────────────┤
│ Bench Press                    [⋯] │  ← ExerciseBlock
│ Previous: 80kg × 10             │
│ ┌──┬────────┬──┬──────┬──────┐  │
│ │ 1│  [W]  │80│  ×  │  10  │ ✓│  ← SetRow
│ │ 2│       │80│  ×  │  10  │ ✓│
│ │ 3│       │85│  ×  │   8  │  │
│ └──┴────────┴──┴──────┴──────┘  │
│         [+ Add Set]              │
├─────────────────────────────────────┤
│ Squat                          [⋯] │
│  ... (same pattern)                 │
├─────────────────────────────────────┤
│      [+ Add Exercise]               │  ← Bottom FAB
└─────────────────────────────────────┘
```

**`SetRow` widget — exact spec:**
- Layout: `[set#] [type] [weight] [×] [reps] [✓]`
- Set number: 28x28 circle, borderMuted, textMuted
- Type badge: 28x28 `BrutalBadge` — tap cycles Normal → Warmup(W) → Dropset(D) → Failure(F) → Normal
- Weight input: 70px wide, `BrutalInput`, numeric keyboard, shows last session value as grey hint
- `×` separator: textMuted, not interactive
- Reps input: 60px wide, `BrutalInput`, numeric keyboard
- Checkmark button: 36x36, on tap → entire row background = `accentGreen.withOpacity(0.12)`, icon turns green
- Completed row: weight/reps inputs become read-only, dimmed
- Swipe left to delete (with red background reveal)
- Long press set number → change type menu

**`ExerciseBlock` widget:**
- Exercise name: heading style, bold
- Previous best hint: "Previous: 80kg × 10" in textMuted, italic — fetched from DB
- 3-dot menu: Replace Exercise, Add Note, Delete Exercise (with confirmation)
- Reorder handle (drag icon on left edge)
- Sets are `ReorderableListView` within each block

**Header bar:**
- Timer: `IBM Plex Mono`, large, counts up from 0:00:00
- Workout name: editable inline (tap → `TextField` appears)
- Finish button: `BrutalButton` yellow, opens confirmation bottom sheet with workout summary
- Discard button: `IconButton`, opens confirmation dialog

**Bottom sheet on Finish:**
- Workout name (editable)
- Duration, total volume (kg), total sets
- PR badges for any new PRs detected
- "Save Workout" button
- "Keep Going" button

**Provider updates needed in `ActiveWorkoutProvider`:**
```dart
// Ensure these actions exist:
void startWorkout({String? routineId, String? name})
Future<void> finishWorkout() // → writes to Drift WorkoutSessions + WorkoutSets
void discardWorkout()
void addExercise(Exercise exercise)
void removeExercise(int exerciseIndex)
void reorderExercise(int from, int to)
void addSet(int exerciseIndex)
void removeSet(int exerciseIndex, int setIndex)
void updateWeight(int ei, int si, double value)
void updateReps(int ei, int si, int value)
void toggleSetComplete(int ei, int si) // → detect PR here
void cycleSetType(int ei, int si)
```

**PR Detection logic:**
```dart
// On toggleSetComplete: 
// Query DB for max weight×reps (Epley 1RM) for this exerciseId ever
// If current set's estimated 1RM > historical max → isPr = true
// Show purple PR badge on that SetRow instantly
double epley1RM(double weight, int reps) => weight * (1 + reps / 30.0);
```

**Rest Timer:**
- Auto-starts when a set is marked complete
- Default: 90 seconds (configurable per exercise in routine)
- Overlay: slides up from bottom, shows countdown, vibrates on complete
- Tap to dismiss early
- `lib/features/workout/presentation/widgets/rest_timer_overlay.dart`

---

### 3.4 — Exercise History per Exercise

`ExerciseDetailScreen` (accessed from exercise browser):
- Header: exercise name, GIF (cached), target muscle badge
- Tab: "About" (instructions list) | "History" (past sets) | "Charts" (1RM over time)
- History tab: grouped by workout date, shows all sets logged
- Charts tab: fl_chart line chart of estimated 1RM over last N sessions

---

### 3.5 — Routines (Full CRUD)

**Routines screen:**
- Grid of `RoutineCard` widgets (2 columns)
- FAB: "New Routine"
- Free tier: max 3 routines — show lock icon on 4th slot with "Go Premium" tap

**`RoutineCard`:**
- Name, day count, exercise count, last performed date
- `BrutalCard` style with accent shadow
- Tap → `RoutineDetailScreen`
- Long press → quick actions (Edit, Duplicate, Delete)

**`RoutineEditorScreen`:**
- Editable routine name at top
- List of days (e.g. "Day 1 — Push", "Day 2 — Pull")
- Each day expandable: shows exercises
- Add exercise to day → opens `ExerciseBrowserScreen`
- Per exercise: default sets, default reps, default weight, rest timer
- Reorder days + exercises via drag handles
- Save button (brutal yellow)

**Starting a workout from routine:**
- Tap routine card → "Start Workout" sheet
- Pre-populates `ActiveWorkoutProvider` with routine exercises and default sets

---

### 3.6 — Workout History

**History screen:**
- Calendar view toggle (monthly calendar with dots on workout days) + list view
- List: grouped by week ("This week", "Last week", "May 2026")
- `WorkoutHistoryCard`: date, duration, volume, exercise names
- Tap → `WorkoutDetailScreen`: full breakdown of every set logged
- Swipe to delete workout (with confirmation)

**`WorkoutDetailScreen`:**
- Header: date, duration, total volume, PRs count
- Each exercise block (read-only version of ExerciseBlock)
- Note if any (workout-level note)

---

### 3.7 — Analytics & Charts (PREMIUM-GATED partially)

**Tab layout:** filter row at top (1W | 1M | 3M | 6M | 1Y | All)

**Free tier:** last 3 months of data visible. Older data blurred with "Upgrade" overlay.

**Charts to build (all fl_chart):**

1. **Volume over time** — bar chart, weekly bars, total kg
2. **Workout frequency** — bar chart, workouts per week
3. **1RM progression per exercise** — line chart, select exercise from dropdown
4. **Muscle group heatmap** — SVG body figure with muscle groups colored by frequency
5. **Personal Records table** — sortable list: exercise | weight | reps | date
6. **Streak tracker** — current streak, longest streak, total workouts

**Chart widget pattern:**
```dart
// Each chart: BrutalCard wrapper, title row, fl_chart widget
// Axes: IBM Plex Mono labels
// Line color: accent yellow
// Bars: accent yellow fill with white border 1px
// Grid lines: borderMuted, dashed
```

---

### 3.8 — Custom Exercises

- Accessed from Exercise Browser ("Create Custom" button)
- Form: name, body part, equipment, primary muscle, secondary muscles, notes
- Stored in Drift with `isCustom = true`, `createdBy = userId`
- **Free tier:** max 7 custom exercises — show counter "5/7 used"
- Premium: unlimited

---

### 3.9 — Freemium Gating System

**`lib/core/services/entitlement_service.dart`:**
```dart
// Reads subscription status from local storage (updated after payment)
// Exposes:
bool get isPremium
int get maxRoutines        // free: 3, premium: unlimited (9999)
int get maxCustomExercises // free: 7, premium: unlimited
int get historyMonths      // free: 3, premium: unlimited
bool get canAccessAnalytics // free: basic only, premium: full

// Gates:
bool canCreateRoutine(int currentCount)
bool canCreateCustomExercise(int currentCount)
bool canViewHistoryDate(DateTime date)
```

**Gate UI pattern — `BrutalPaywall` widget:**
```dart
// Overlay on locked content:
// Blurred background (ImageFilter.blur)
// Center card: lock icon, feature name, "Go Premium" BrutalButton
// Dismissible? No — must upgrade or go back
```

**Where gates appear:**
- Routines tab: 4th routine card = locked placeholder
- Custom exercises: counter shown, input disabled at limit
- Analytics: older data blurred
- History: cutoff line with "Upgrade to see full history"

---

### 3.10 — Paywall & Subscription Screen

**Route:** `/premium` — full screen (not modal)

**Layout:**
```
GymLog Premium
──────────────
✓ Unlimited Routines
✓ Unlimited Custom Exercises  
✓ Full Graph History
✓ Advanced Analytics
✓ All future features

[Monthly — $2/mo]   ← BrutalButton, border
[Yearly — $18/yr ★ BEST VALUE]  ← BrutalButton, yellow fill

── or pay with crypto ──
[Pay with Crypto]   ← secondary button

Already subscribed? [Restore Purchase]
```

**`lib/features/premium/presentation/screens/paywall_screen.dart`**

---

### 3.11 — DodoPayments Integration

**Package:** Use `http` package for REST API calls  
**Docs:** https://docs.dodopayments.com  
**Files:** `lib/features/premium/data/dodo_payment_service.dart`

```dart
class DodoPaymentService {
  // 1. Create checkout session via DodoPayments API
  // POST /subscriptions with product_id (monthly or yearly)
  // Returns checkout URL
  
  // 2. Launch URL via url_launcher package
  // await launchUrl(checkoutUrl, mode: LaunchMode.externalApplication)
  
  // 3. Handle return deep link (configure app scheme: gymlog://)
  // On success deep link → verify with DodoPayments webhook or polling
  // On confirm → update EntitlementService to isPremium = true
  // Store: expiry date, subscription ID in flutter_secure_storage
  
  static const monthlyProductId = 'YOUR_DODO_MONTHLY_PRODUCT_ID';
  static const yearlyProductId  = 'YOUR_DODO_YEARLY_PRODUCT_ID';
}
```

**Required pubspec additions:**
```yaml
url_launcher: ^6.2.0
flutter_secure_storage: ^9.0.0
```

---

### 3.12 — NowPayments (Crypto) Integration

**Docs:** https://nowpayments.io  
**File:** `lib/features/premium/data/crypto_payment_service.dart`

```dart
class CryptoPaymentService {
  // 1. POST to NowPayments API: create invoice
  // /v1/invoice with price_amount, price_currency, order_id
  // Returns invoice_url
  
  // 2. Open invoice_url in external browser
  
  // 3. Poll payment status or use IPN webhook
  // GET /v1/payment/{payment_id} — check status = 'finished'
  
  // 4. On confirmed → same flow as DodoPayments: update entitlement
  
  // Show bottom sheet: "Select crypto" (BTC, ETH, USDT, SOL options)
  // Each chip tap → creates invoice for that currency
}
```

---

### 3.13 — Profile Screen

- User avatar (from Google), name, email
- Stats summary: total workouts, total volume lifted (all-time), days active
- Settings section:
  - Weight unit toggle (kg / lbs) — stored in SharedPreferences
  - Default rest timer duration slider
  - Theme (Dark only for now, but structure for future)
  - "Refresh Exercise Library" — triggers re-seed
  - "Export Data" (CSV export of all workouts)
  - "Delete Account" (clears all local data + signs out)
- Premium badge if subscribed (with expiry date)
- "Upgrade to Premium" button if free tier
- Sign out button (bottom, danger color)

---

### 3.14 — Plate Calculator (bonus, in Active Workout)

Accessible from 3-dot menu on any set:
```
Target weight: [100 kg]
Bar weight: [20 kg]
Each side: 25kg + 15kg + 5kg
[Visual bar diagram with plates colored]
```
`lib/features/workout/presentation/widgets/plate_calculator_sheet.dart`

---

## 4. COMPLETE FILE STRUCTURE

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── database/
│   │   ├── database.dart              (Drift @DriftDatabase)
│   │   ├── database.g.dart            (generated)
│   │   ├── tables/
│   │   │   ├── exercises_table.dart
│   │   │   ├── workouts_table.dart
│   │   │   ├── sets_table.dart
│   │   │   ├── routines_table.dart
│   │   │   ├── routine_exercises_table.dart
│   │   │   └── user_profiles_table.dart   ← NEW
│   │   └── daos/
│   │       ├── exercises_dao.dart
│   │       ├── workouts_dao.dart
│   │       ├── routines_dao.dart
│   │       ├── analytics_dao.dart
│   │       └── user_dao.dart              ← NEW
│   ├── router/
│   │   └── router.dart                (updated with auth guard)
│   ├── theme/
│   │   ├── app_theme.dart             (updated for neo brutalism)
│   │   ├── app_colors.dart            (updated tokens)
│   │   └── app_typography.dart        ← NEW
│   ├── services/
│   │   └── entitlement_service.dart   ← NEW
│   └── providers/
│       ├── database_provider.dart
│       └── entitlement_provider.dart  ← NEW
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── splash_screen.dart
│   │       │   └── auth_screen.dart
│   │       └── providers/
│   │           └── auth_provider.dart
│   │
│   ├── exercises/
│   │   ├── data/
│   │   │   ├── exercise_repository.dart
│   │   │   ├── exercise_seed_service.dart  ← NEW (ExerciseDB fetch)
│   │   │   └── gif_cache_service.dart      ← NEW
│   │   ├── domain/
│   │   │   └── exercise_model.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── exercise_browser_screen.dart
│   │       │   └── exercise_detail_screen.dart
│   │       ├── widgets/
│   │       │   ├── exercise_list_tile.dart
│   │       │   ├── muscle_diagram.dart
│   │       │   └── filter_chip_row.dart
│   │       └── providers/
│   │           └── exercise_providers.dart
│   │
│   ├── workout/
│   │   ├── data/
│   │   │   └── workout_repository.dart
│   │   ├── domain/
│   │   │   ├── active_workout_state.dart   (updated)
│   │   │   └── workout_model.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── log_screen.dart         (updated)
│   │       │   ├── active_workout_screen.dart ← BUILD THIS
│   │       │   └── workout_detail_screen.dart ← NEW
│   │       ├── widgets/
│   │       │   ├── set_row.dart               ← BUILD THIS
│   │       │   ├── exercise_block.dart         ← BUILD THIS
│   │       │   ├── rest_timer_overlay.dart     ← NEW
│   │       │   ├── workout_finish_sheet.dart   ← NEW
│   │       │   ├── active_workout_bar.dart     (update style)
│   │       │   └── plate_calculator_sheet.dart ← NEW
│   │       └── providers/
│   │           └── active_workout_provider.dart (update)
│   │
│   ├── routines/
│   │   ├── data/
│   │   │   └── routine_repository.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── routines_screen.dart       ← BUILD THIS
│   │       │   ├── routine_detail_screen.dart ← NEW
│   │       │   └── routine_editor_screen.dart ← BUILD THIS
│   │       ├── widgets/
│   │       │   ├── routine_card.dart
│   │       │   └── routine_day_block.dart
│   │       └── providers/
│   │           └── routine_providers.dart
│   │
│   ├── history/
│   │   ├── data/
│   │   │   └── history_repository.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── history_screen.dart        ← BUILD THIS
│   │       │   └── workout_detail_screen.dart
│   │       ├── widgets/
│   │       │   ├── workout_history_card.dart
│   │       │   └── workout_calendar.dart
│   │       └── providers/
│   │           └── history_providers.dart
│   │
│   ├── analytics/
│   │   ├── data/
│   │   │   └── analytics_repository.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── analytics_screen.dart      ← BUILD THIS
│   │       ├── widgets/
│   │       │   ├── volume_chart.dart
│   │       │   ├── frequency_chart.dart
│   │       │   ├── one_rm_chart.dart
│   │       │   ├── muscle_heatmap.dart
│   │       │   └── pr_table.dart
│   │       └── providers/
│   │           └── analytics_providers.dart
│   │
│   ├── premium/
│   │   ├── data/
│   │   │   ├── dodo_payment_service.dart      ← NEW
│   │   │   └── crypto_payment_service.dart    ← NEW
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── paywall_screen.dart        ← NEW
│   │       ├── widgets/
│   │       │   └── brutal_paywall_overlay.dart ← NEW
│   │       └── providers/
│   │           └── premium_providers.dart
│   │
│   └── profile/
│       └── presentation/
│           └── screens/
│               └── profile_screen.dart        ← BUILD THIS
│
└── shared/
    ├── widgets/
    │   ├── ui/
    │   │   ├── brutal_card.dart           ← NEW
    │   │   ├── brutal_button.dart         ← NEW
    │   │   ├── brutal_input.dart          ← NEW
    │   │   ├── brutal_badge.dart          ← NEW
    │   │   ├── brutal_chip.dart           ← NEW
    │   │   └── brutal_bottom_sheet.dart   ← NEW
    │   ├── app_shell.dart                 (update style)
    │   ├── bottom_nav_bar.dart            (update style)
    │   └── active_workout_bar.dart        (update style)
    └── utils/
        ├── weight_formatter.dart
        ├── formulas.dart
        └── date_utils.dart

docs/                                      ← GENERATE AS YOU BUILD
├── 00_project_overview.md
├── 01_architecture.md
├── 02_design_system.md
├── 03_database_schema.md
├── 04_auth_flow.md
├── 05_exercise_pipeline.md
├── 06_active_workout.md
├── 07_routines.md
├── 08_history.md
├── 09_analytics.md
├── 10_freemium_entitlements.md
├── 11_payments_dodo.md
├── 12_payments_crypto.md
└── 13_profile_settings.md
```

---

## 5. COMPLETE PUBSPEC.YAML DEPENDENCIES

```yaml
dependencies:
  flutter:
    sdk: flutter

  # DB
  drift: ^2.18.0
  drift_flutter: ^0.2.0
  sqlite3_flutter_libs: ^0.5.0

  # State
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0

  # Navigation
  go_router: ^14.0.0

  # Auth
  supabase_flutter: ^2.5.0
  flutter_secure_storage: ^9.0.0

  # Exercise data / media
  cached_network_image: ^3.3.0
  flutter_svg: ^2.0.0
  gif_view: ^0.4.0

  # Charts
  fl_chart: ^0.68.0

  # Typography
  google_fonts: ^6.2.1

  # Payments
  url_launcher: ^6.2.0
  in_app_purchase: ^3.1.x       # for future App Store if needed

  # Utils
  intl: ^0.19.0
  uuid: ^4.4.0
  collection: ^1.18.0
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0
  shared_preferences: ^2.2.0
  connectivity_plus: ^5.0.0     # for internet check before GIF load
  vibration: ^1.9.0             # rest timer haptics
  path_provider: ^2.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  drift_dev: ^2.18.0
  riverpod_generator: ^2.4.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  flutter_lints: ^4.0.0
  custom_lint: ^0.6.0
  riverpod_lint: ^2.3.0
```

---

## 6. DATABASE SCHEMA (COMPLETE — DRIFT)

```dart
// user_profiles_table.dart
class UserProfiles extends Table {
  TextColumn get id          => text()(); // Google UID
  TextColumn get email       => text()();
  TextColumn get displayName => text()();
  TextColumn get photoUrl    => text().nullable()();
  BoolColumn get isPremium   => boolean().withDefault(const Constant(false))();
  DateTimeColumn get premiumExpiry => dateTime().nullable()();
  TextColumn get weightUnit  => text().withDefault(const Constant('kg'))();
  IntColumn  get defaultRestSeconds => integer().withDefault(const Constant(90))();
  DateTimeColumn get createdAt => dateTime()();
}

// exercises_table.dart (updated — see Section 3.2)

// routines_table.dart
class Routines extends Table {
  TextColumn get id         => text().clientDefault(() => const Uuid().v4())();
  TextColumn get userId     => text()();
  TextColumn get name       => text()();
  TextColumn get notes      => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

// routine_days_table.dart
class RoutineDays extends Table {
  TextColumn get id        => text().clientDefault(() => const Uuid().v4())();
  TextColumn get routineId => text().references(Routines, #id)();
  TextColumn get name      => text()();
  IntColumn  get orderIndex => integer()();
}

// routine_exercises_table.dart (updated)
class RoutineExercises extends Table {
  TextColumn get id           => text().clientDefault(() => const Uuid().v4())();
  TextColumn get routineDayId => text().references(RoutineDays, #id)();
  IntColumn  get exerciseId   => integer().references(Exercises, #id)();
  IntColumn  get orderIndex   => integer()();
  IntColumn  get defaultSets  => integer().withDefault(const Constant(3))();
  IntColumn  get defaultReps  => integer().nullable()();
  RealColumn get defaultWeightKg => real().nullable()();
  IntColumn  get restSeconds  => integer().nullable()();
}

// workout_sessions_table.dart
class WorkoutSessions extends Table {
  TextColumn  get id        => text().clientDefault(() => const Uuid().v4())();
  TextColumn  get userId    => text()();
  TextColumn  get routineId => text().nullable()();
  TextColumn  get name      => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt   => dateTime().nullable()();
  TextColumn  get notes     => text().withDefault(const Constant(''))();
  RealColumn  get totalVolumeKg => real().withDefault(const Constant(0))();
  BoolColumn  get synced    => boolean().withDefault(const Constant(false))();
}

// workout_exercises_table.dart
class WorkoutExercises extends Table {
  TextColumn get id        => text().clientDefault(() => const Uuid().v4())();
  TextColumn get sessionId => text().references(WorkoutSessions, #id)();
  IntColumn  get exerciseId => integer().references(Exercises, #id)();
  IntColumn  get orderIndex => integer()();
  TextColumn get notes     => text().nullable()();
}

// workout_sets_table.dart
class WorkoutSets extends Table {
  TextColumn  get id                 => text().clientDefault(() => const Uuid().v4())();
  TextColumn  get workoutExerciseId  => text().references(WorkoutExercises, #id)();
  IntColumn   get exerciseId         => integer()(); // denormalized for faster analytics queries
  IntColumn   get orderIndex         => integer()();
  TextColumn  get setType            => text().withDefault(const Constant('normal'))();
  RealColumn  get weightKg           => real()();
  IntColumn   get reps               => integer()();
  RealColumn  get rpe                => real().nullable()();
  BoolColumn  get isPr               => boolean().withDefault(const Constant(false))();
  RealColumn  get estimated1rm       => real().nullable()(); // stored for fast queries
  DateTimeColumn get completedAt     => dateTime()();
}
```

---

## 7. NAVIGATION & AUTH GUARD

```dart
// router.dart — complete routes
final router = GoRouter(
  redirect: (context, state) {
    final isSignedIn = ref.read(authProvider).isSignedIn;
    final isAuthRoute = state.matchedLocation.startsWith('/auth') 
                     || state.matchedLocation == '/';
    if (!isSignedIn && !isAuthRoute) return '/auth';
    if (isSignedIn && isAuthRoute) return '/log';
    return null;
  },
  routes: [
    GoRoute(path: '/', redirect: (_, __) => '/auth'),
    GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/log',       builder: (_, __) => const LogScreen()),
        GoRoute(path: '/history',   builder: (_, __) => const HistoryScreen()),
        GoRoute(path: '/routines',  builder: (_, __) => const RoutinesScreen()),
        GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
        GoRoute(path: '/profile',   builder: (_, __) => const ProfileScreen()),
      ],
    ),
    GoRoute(
      path: '/workout/active',
      pageBuilder: (_, __) => const MaterialPage(
        fullscreenDialog: true,
        child: ActiveWorkoutScreen(),
      ),
    ),
    GoRoute(
      path: '/exercise/:id',
      builder: (_, s) => ExerciseDetailScreen(
        exerciseId: int.parse(s.pathParameters['id']!),
      ),
    ),
    GoRoute(path: '/exercise/browser', builder: (_, __) => const ExerciseBrowserScreen()),
    GoRoute(path: '/routine/new',      builder: (_, __) => const RoutineEditorScreen()),
    GoRoute(path: '/routine/:id/edit', builder: (_, s) => RoutineEditorScreen(routineId: s.pathParameters['id'])),
    GoRoute(path: '/premium',          builder: (_, __) => const PaywallScreen()),
    GoRoute(path: '/workout/:id',      builder: (_, s) => WorkoutDetailScreen(workoutId: s.pathParameters['id']!)),
  ],
);
```

---

## 8. EXECUTION STRATEGY — PARALLEL MICRO-TRACKS

Execute in this exact sequence. Each track is atomic — complete it fully before starting the next. Within each track, build files in the listed order.

### TRACK 0 — Foundation Fixes (do first, blocks everything else)
**Goal:** Clean slate, zero errors, design system live
```
0.1  Update pubspec.yaml with complete deps list → flutter pub get
0.2  Rebuild app_colors.dart with neo brutalism tokens
0.3  Build app_typography.dart (Space Grotesk + IBM Plex Mono)
0.4  Build all BrutalUI primitives: brutal_card, brutal_button, brutal_input, brutal_badge, brutal_chip, brutal_bottom_sheet
0.5  Update app_theme.dart to use new tokens + typography
0.6  Update bottom_nav_bar.dart with brutal style
0.7  Update AppShell with brutal style
0.8  Run: flutter pub get → dart run build_runner build → flutter analyze
     MUST be zero issues before Track 1
```

### TRACK 1 — Auth (blocks all user-specific data)
```
1.1  Add UserProfiles table to Drift schema + UserDAO
1.2  Run build_runner
1.3  auth_repository.dart (Google Sign-In logic)
1.4  auth_provider.dart (@riverpod)
1.5  splash_screen.dart
1.6  auth_screen.dart (brutal style, Google button)
1.7  Update router.dart with auth guard
1.8  flutter analyze → zero issues
```

### TRACK 2 — Exercise Data Pipeline (blocks workout + routines features)
```
2.1  Update Exercises table in Drift schema
2.2  Run build_runner  
2.3  exercises_dao.dart (full CRUD + search + filter queries)
2.4  exercise_seed_service.dart (ExerciseDB fetch + progress)
2.5  gif_cache_service.dart
2.6  exercise_repository.dart
2.7  exercise_providers.dart
2.8  exercise_list_tile.dart widget
2.9  filter_chip_row.dart widget
2.10 exercise_browser_screen.dart
2.11 exercise_detail_screen.dart
2.12 Wire seed service to first-launch in main.dart
2.13 flutter analyze → zero issues
```

### TRACK 3 — Active Workout (core feature)
```
3.1  Update WorkoutExercises + WorkoutSets tables → run build_runner
3.2  workouts_dao.dart (full write + read queries)
3.3  workout_repository.dart
3.4  Update active_workout_state.dart (Freezed, complete actions)
3.5  Update active_workout_provider.dart (all actions + PR detection)
3.6  set_row.dart widget (exact spec from Section 3.3)
3.7  exercise_block.dart widget
3.8  rest_timer_overlay.dart
3.9  workout_finish_sheet.dart
3.10 plate_calculator_sheet.dart
3.11 active_workout_screen.dart (full implementation)
3.12 Update log_screen.dart (wire "Start Workout" button)
3.13 Update active_workout_bar.dart style + navigation
3.14 flutter analyze → zero issues
```

### TRACK 4 — Routines
```
4.1  Add RoutineDays table → run build_runner
4.2  routines_dao.dart
4.3  routine_repository.dart
4.4  routine_providers.dart
4.5  routine_card.dart widget
4.6  routine_day_block.dart widget
4.7  routines_screen.dart (with freemium gate at 3 limit)
4.8  routine_editor_screen.dart
4.9  routine_detail_screen.dart
4.10 Wire "Start from Routine" → ActiveWorkoutProvider
4.11 flutter analyze → zero issues
```

### TRACK 5 — History
```
5.1  history_repository.dart (grouped queries by week)
5.2  history_providers.dart
5.3  workout_history_card.dart widget
5.4  workout_calendar.dart widget (table_calendar package)
5.5  history_screen.dart
5.6  workout_detail_screen.dart (read-only workout view)
5.7  flutter analyze → zero issues
```

### TRACK 6 — Analytics
```
6.1  analytics_dao.dart (aggregation queries: volume/week, 1RM/exercise, frequency)
6.2  analytics_repository.dart
6.3  analytics_providers.dart
6.4  volume_chart.dart (fl_chart bar)
6.5  frequency_chart.dart (fl_chart bar)
6.6  one_rm_chart.dart (fl_chart line)
6.7  pr_table.dart
6.8  analytics_screen.dart (with freemium gate: 3M free, blur older)
6.9  flutter analyze → zero issues
```

### TRACK 7 — Freemium + Paywall
```
7.1  entitlement_service.dart
7.2  entitlement_provider.dart
7.3  brutal_paywall_overlay.dart widget
7.4  Wire gates into: routines_screen, custom exercises, analytics_screen, history_screen
7.5  dodo_payment_service.dart
7.6  crypto_payment_service.dart  
7.7  premium_providers.dart
7.8  paywall_screen.dart
7.9  flutter analyze → zero issues
```

### TRACK 8 — Profile + Polish
```
8.1  user_dao.dart
8.2  profile_screen.dart (full implementation per spec)
8.3  Settings: weight unit toggle wired to weight_formatter.dart
8.4  "Refresh Exercise Library" wired to exercise_seed_service
8.5  Sign out flow
8.6  Final flutter analyze → zero issues
8.7  flutter run — smoke test all 5 tabs
```

### TRACK 9 — Documentation
```
After each track above, generate the corresponding docs/ file.
Each doc must contain:
  - Purpose of this module
  - File locations
  - Key classes/methods with descriptions
  - Data flow diagram (ASCII)
  - Dependencies
  - Known limitations
  - How to extend
```

---

## 9. CODE QUALITY RULES — NON-NEGOTIABLE

Every file Windsurf generates MUST follow:

1. **No hardcoded colors** — only `AppColors.*`
2. **No hardcoded strings** — user-visible strings in `lib/core/l10n/strings.dart`
3. **No business logic in widgets** — all logic in providers/repositories
4. **All async operations** — show loading state (brutal spinner or skeleton)
5. **All error states handled** — show `BrutalCard` error with retry button
6. **All lists empty-state handled** — show appropriate empty illustration + CTA
7. **Const constructors everywhere** possible
8. **Private methods** prefixed with `_`
9. **Each file** has a top comment block:
   ```dart
   /// [filename.dart]
   /// Purpose: Brief description
   /// Dependencies: [list key deps]
   /// Last modified: Track N, Step N.x
   ```
10. **Max 300 lines per file** — if over, split into smaller files
11. After EVERY track: `flutter analyze` must return "No issues found!"

---

## 10. DOCUMENTATION FORMAT

Each `docs/XX_module.md` file must follow:

```markdown
# Module: [Name]
**Track:** N | **Files:** list | **Status:** Complete/WIP

## Purpose
One paragraph.

## Architecture
ASCII data flow.

## Key Files
| File | Role |
|------|------|

## Database Tables Used
List tables + queries.

## State Management
Providers used, what they expose.

## UI Components
List widgets, what they render.

## Freemium Gates
Any gates in this module.

## Known Limitations
Honest list.

## How to Extend
Step-by-step for common additions.
```

---

## 11. FIRST ACTION

Start immediately with **Track 0, Step 0.1**.  
Do not ask clarifying questions — all decisions are in this document.  
After each step, confirm completion with: `✓ Step N.x complete — [brief what was done]`  
After each track, run `flutter analyze` and show the output.  
If analyze returns errors, fix them before proceeding to the next track.

Begin now.
