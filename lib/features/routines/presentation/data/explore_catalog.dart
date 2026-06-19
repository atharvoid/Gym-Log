import 'package:flutter/material.dart';
import 'package:gymlog/core/theme/app_colors.dart';

/// [explore_catalog.dart]
/// The curated Explore catalog — the typed data behind the Explore screen,
/// deliberately split out of the screen file so (a) data and presentation are
/// separated and (b) the integrity test imports this typed list directly
/// instead of regex-scraping widget source.
///
/// EVERY exercise name below is an exact entry in the bundled Exercise Library
/// (assets/db/exercises.json), audited 2026-06-13 — no broken references, no
/// fuzzy fallbacks resolving to the wrong movement. `explore_catalog_integrity_test`
/// asserts this on every CI run.

/// One slot in a template. [name] is the EXACT canonical Exercise Library name
/// (verified to exist), so it is both the display label and the import key —
/// no fuzzy guessing, no mismatch between what the card shows and what gets
/// added. [reps] seeds the routine's per-set target.
class TemplateSlot {
  final String name;
  final int sets;
  final int reps;

  const TemplateSlot(this.name, {this.sets = 3, this.reps = 10});
}

/// Difficulty tiers — drive the colored pill on each card.
enum TemplateLevel { beginner, intermediate, advanced }

class RoutineTemplate {
  final String name;

  /// Programming family used to group the catalog (PPL, Upper/Lower, …).
  final String category;
  final TemplateLevel level;

  /// Target muscle groups, human-readable and scannable. The FIRST muscle-like
  /// token drives the card's muscle glyph (see [ExploreTemplateCard]).
  final String focus;
  final String description;
  final List<TemplateSlot> slots;

  /// Exactly one template is the editor's spotlight — promoted to the hero
  /// "Featured" card at the top of the (unfiltered) Explore screen.
  final bool featured;

  const RoutineTemplate({
    required this.name,
    required this.category,
    required this.level,
    required this.focus,
    required this.description,
    required this.slots,
    this.featured = false,
  });

  int get totalSets => slots.fold(0, (a, s) => a + s.sets);

  /// Honest estimate: ~2.8 min per working set (work + rest) + warm-up,
  /// rounded to the nearest 5 minutes.
  int get estMinutes => (((totalSets * 2.8) + 8) / 5).round() * 5;

  String get levelLabel => switch (level) {
        TemplateLevel.beginner => 'Beginner',
        TemplateLevel.intermediate => 'Intermediate',
        TemplateLevel.advanced => 'Advanced',
      };

  /// Difficulty color — ON-TOKEN (was raw #34C759 / #A78BFA / #E0A422). Maps to
  /// the semantic palette so "amber" / "green" mean one value app-wide.
  Color get levelColor => switch (level) {
        TemplateLevel.beginner => AppColors.success,
        TemplateLevel.intermediate => AppColors.accentText,
        TemplateLevel.advanced => AppColors.warning,
      };
}

/// Display order for the grouped sections.
const exploreCategoryOrder = <String>[
  'Push · Pull · Legs',
  'Upper · Lower',
  'Powerbuilding',
  'Bro Split',
  'Full Body',
];

const exploreTemplates = <RoutineTemplate>[
  // ── Push / Pull / Legs ───────────────────────────────────────────────────
  RoutineTemplate(
    name: 'Push Day',
    category: 'Push · Pull · Legs',
    level: TemplateLevel.intermediate,
    focus: 'Chest · Shoulders · Triceps',
    description: 'The classic pressing session — heavy bench first, then '
        'shoulders and triceps to finish.',
    featured: true,
    slots: [
      TemplateSlot('Bench Press (Barbell)', sets: 4, reps: 6),
      TemplateSlot('Smith Standing Military Press', sets: 3, reps: 8),
      TemplateSlot('Incline Bench Press (Barbell)', sets: 3, reps: 10),
      TemplateSlot('Lateral Raise (Cable)', sets: 3, reps: 15),
      TemplateSlot('Chest Dip', sets: 3, reps: 10),
      TemplateSlot('Cable Pushdown', sets: 3, reps: 12),
    ],
  ),
  RoutineTemplate(
    name: 'Pull Day',
    category: 'Push · Pull · Legs',
    level: TemplateLevel.intermediate,
    focus: 'Back · Biceps · Rear Delts',
    description: 'Width and thickness — pull from the floor, a vertical pull, '
        'a row, then arms.',
    slots: [
      TemplateSlot('Deadlift (Barbell)', sets: 3, reps: 5),
      TemplateSlot('Pull Up', sets: 4, reps: 8),
      TemplateSlot('Bent Over Row (Barbell)', sets: 3, reps: 8),
      TemplateSlot('Cable Pulldown', sets: 3, reps: 12),
      TemplateSlot('Reverse Fly (Dumbbell)', sets: 3, reps: 15),
      TemplateSlot('Barbell Curl', sets: 3, reps: 10),
    ],
  ),
  RoutineTemplate(
    name: 'Leg Day',
    category: 'Push · Pull · Legs',
    level: TemplateLevel.intermediate,
    focus: 'Quads · Hamstrings · Calves',
    description: 'Squat-centric lower session with a hip-hinge for the '
        'hamstrings and dedicated calf work.',
    slots: [
      TemplateSlot('Barbell Full Squat', sets: 4, reps: 6),
      TemplateSlot('Barbell Straight Leg Deadlift', sets: 3, reps: 8),
      TemplateSlot('Sled 45° Leg Press', sets: 3, reps: 12),
      TemplateSlot('Lying Leg Curl', sets: 3, reps: 12),
      TemplateSlot('Standing Calf Raise (Barbell)', sets: 4, reps: 15),
    ],
  ),
  RoutineTemplate(
    name: 'Push Day · Volume',
    category: 'Push · Pull · Legs',
    level: TemplateLevel.advanced,
    focus: 'Chest · Shoulders · Triceps',
    description: 'A higher-volume hypertrophy push — dumbbells and cables for '
        'time under tension, lighter loads, tighter rest.',
    slots: [
      TemplateSlot('Bench Press (Dumbbell)', sets: 4, reps: 10),
      TemplateSlot('Incline Bench Press (Barbell)', sets: 3, reps: 10),
      TemplateSlot('Lever Shoulder Press', sets: 3, reps: 10),
      TemplateSlot('Dumbbell Fly', sets: 3, reps: 12),
      TemplateSlot('Lateral Raise (Cable)', sets: 4, reps: 15),
      TemplateSlot('Barbell Lying Triceps Extension', sets: 3, reps: 12),
      TemplateSlot('Cable Pushdown', sets: 3, reps: 15),
    ],
  ),
  RoutineTemplate(
    name: 'Pull Day · Volume',
    category: 'Push · Pull · Legs',
    level: TemplateLevel.advanced,
    focus: 'Back · Biceps · Rear Delts',
    description: 'Back-building volume — pulldowns and rows for the lats and '
        'mid-back, then traps, rear delts and biceps.',
    slots: [
      TemplateSlot('Cable Pulldown', sets: 4, reps: 12),
      TemplateSlot('Cable Low Seated Row', sets: 4, reps: 10),
      TemplateSlot('Bent Over Row (Dumbbell)', sets: 3, reps: 10),
      TemplateSlot('Shrug (Barbell)', sets: 3, reps: 12),
      TemplateSlot('Reverse Fly (Dumbbell)', sets: 3, reps: 15),
      TemplateSlot('Bicep Curl (Dumbbell)', sets: 3, reps: 12),
      TemplateSlot('Hammer Curl (Dumbbell)', sets: 3, reps: 12),
    ],
  ),
  RoutineTemplate(
    name: 'Leg Day · Volume',
    category: 'Push · Pull · Legs',
    level: TemplateLevel.advanced,
    focus: 'Quads · Hamstrings · Glutes',
    description: 'Quad and glute hypertrophy — front squats, presses, '
        'extensions and a rope pull-through for the hips.',
    slots: [
      TemplateSlot('Front Squat (Barbell)', sets: 4, reps: 8),
      TemplateSlot('Sled 45° Leg Press', sets: 4, reps: 12),
      TemplateSlot('Leg Extension (Machine)', sets: 4, reps: 15),
      TemplateSlot('Seated Leg Curl (Machine)', sets: 4, reps: 12),
      TemplateSlot('Cable Pull Through', sets: 3, reps: 12),
      TemplateSlot('Seated Calf Raise (Machine)', sets: 4, reps: 20),
    ],
  ),
  // ── Upper / Lower ─────────────────────────────────────────────────────────
  RoutineTemplate(
    name: 'Upper Body',
    category: 'Upper · Lower',
    level: TemplateLevel.intermediate,
    focus: 'Chest · Back · Shoulders · Arms',
    description: 'Everything above the waist in one efficient session — '
        'built for an upper/lower split.',
    slots: [
      TemplateSlot('Bench Press (Barbell)', sets: 4, reps: 6),
      TemplateSlot('Bent Over Row (Barbell)', sets: 4, reps: 8),
      TemplateSlot('Smith Standing Military Press', sets: 3, reps: 8),
      TemplateSlot('Cable Pulldown', sets: 3, reps: 10),
      TemplateSlot('Bicep Curl (Dumbbell)', sets: 3, reps: 12),
      TemplateSlot('Cable Pushdown', sets: 3, reps: 12),
    ],
  ),
  RoutineTemplate(
    name: 'Lower Body',
    category: 'Upper · Lower',
    level: TemplateLevel.intermediate,
    focus: 'Quads · Hamstrings · Calves',
    description: 'The other half of the upper/lower split — squat, hinge and '
        'single-leg work, capped with calves.',
    slots: [
      TemplateSlot('Barbell Full Squat', sets: 4, reps: 6),
      TemplateSlot('Barbell Straight Leg Deadlift', sets: 3, reps: 8),
      TemplateSlot('Lunge (Dumbbell)', sets: 3, reps: 10),
      TemplateSlot('Leg Extension (Machine)', sets: 3, reps: 15),
      TemplateSlot('Seated Calf Raise (Machine)', sets: 4, reps: 15),
    ],
  ),
  // ── Powerbuilding ──────────────────────────────────────────────────────────
  RoutineTemplate(
    name: 'Upper Power',
    category: 'Powerbuilding',
    level: TemplateLevel.advanced,
    focus: 'Strength · Chest · Back · Shoulders',
    description: 'Heavy upper-body strength — low-rep presses and rows for '
        'force, a little hypertrophy work to finish.',
    slots: [
      TemplateSlot('Bench Press (Barbell)', sets: 5, reps: 5),
      TemplateSlot('Bent Over Row (Barbell)', sets: 5, reps: 5),
      TemplateSlot('Smith Standing Military Press', sets: 4, reps: 6),
      TemplateSlot('Pull Up', sets: 3, reps: 8),
      TemplateSlot('Barbell Curl', sets: 3, reps: 10),
      TemplateSlot('Tricep Pushdown With Bar', sets: 3, reps: 12),
    ],
  ),
  RoutineTemplate(
    name: 'Lower Power',
    category: 'Powerbuilding',
    level: TemplateLevel.advanced,
    focus: 'Strength · Quads · Posterior Chain',
    description: 'Squat and deadlift strength work, then leg press and good '
        'mornings to build the posterior chain.',
    slots: [
      TemplateSlot('Barbell Full Squat', sets: 5, reps: 5),
      TemplateSlot('Deadlift (Barbell)', sets: 3, reps: 5),
      TemplateSlot('Sled 45° Leg Press', sets: 3, reps: 10),
      TemplateSlot('Good Morning (Barbell)', sets: 3, reps: 10),
      TemplateSlot('Standing Calf Raise (Barbell)', sets: 4, reps: 12),
    ],
  ),
  // ── Bro Split ────────────────────────────────────────────────────────────
  RoutineTemplate(
    name: 'Chest & Triceps',
    category: 'Bro Split',
    level: TemplateLevel.intermediate,
    focus: 'Chest · Triceps',
    description: 'A dedicated chest day with triceps along for the ride — '
        'press, incline, fly, then push the arms.',
    slots: [
      TemplateSlot('Bench Press (Barbell)', sets: 4, reps: 8),
      TemplateSlot('Incline Bench Press (Barbell)', sets: 3, reps: 10),
      TemplateSlot('Dumbbell Fly', sets: 3, reps: 12),
      TemplateSlot('Chest Dip', sets: 3, reps: 10),
      TemplateSlot('Barbell Lying Triceps Extension', sets: 3, reps: 12),
      TemplateSlot('Cable Pushdown', sets: 3, reps: 15),
    ],
  ),
  RoutineTemplate(
    name: 'Back & Biceps',
    category: 'Bro Split',
    level: TemplateLevel.intermediate,
    focus: 'Back · Biceps',
    description: 'Pull-focused day — a heavy deadlift, vertical and horizontal '
        'pulls, then curls to cap it.',
    slots: [
      TemplateSlot('Deadlift (Barbell)', sets: 3, reps: 5),
      TemplateSlot('Pull Up', sets: 4, reps: 8),
      TemplateSlot('Cable Low Seated Row', sets: 3, reps: 10),
      TemplateSlot('Cable Pulldown', sets: 3, reps: 12),
      TemplateSlot('Barbell Curl', sets: 3, reps: 10),
      TemplateSlot('Incline Dumbbell Curl', sets: 3, reps: 12),
    ],
  ),
  RoutineTemplate(
    name: 'Shoulders & Core',
    category: 'Bro Split',
    level: TemplateLevel.intermediate,
    focus: 'Shoulders · Core',
    description: 'Build round delts from every angle, then brace the core '
        'with hanging and anti-extension work.',
    slots: [
      TemplateSlot('Smith Standing Military Press', sets: 4, reps: 8),
      TemplateSlot('Dumbbell Push Press', sets: 3, reps: 8),
      TemplateSlot('Lateral Raise (Cable)', sets: 4, reps: 15),
      TemplateSlot('Reverse Fly (Dumbbell)', sets: 3, reps: 15),
      TemplateSlot('Upright Row (Barbell)', sets: 3, reps: 12),
      TemplateSlot('Hanging Pike', sets: 3, reps: 15),
      TemplateSlot('Weighted Front Plank', sets: 3, reps: 40),
    ],
  ),
  RoutineTemplate(
    name: 'Arm Day',
    category: 'Bro Split',
    level: TemplateLevel.beginner,
    focus: 'Biceps · Triceps',
    description: 'Pure arms — supersets of curls and extensions for a serious '
        'pump. Short, focused, effective.',
    slots: [
      TemplateSlot('Barbell Curl', sets: 4, reps: 10),
      TemplateSlot('Cable Pushdown', sets: 4, reps: 12),
      TemplateSlot('Hammer Curl (Dumbbell)', sets: 3, reps: 12),
      TemplateSlot('Barbell Lying Triceps Extension', sets: 3, reps: 12),
      TemplateSlot('Incline Dumbbell Curl', sets: 3, reps: 15),
      TemplateSlot('EZ Bar Standing French Press', sets: 3, reps: 12),
    ],
  ),
  // ── Full Body ──────────────────────────────────────────────────────────────
  RoutineTemplate(
    name: 'Full Body Express',
    category: 'Full Body',
    level: TemplateLevel.beginner,
    focus: 'Total Body · 45 min',
    description: 'Three big compounds and two finishers — for the days when '
        'time is the limiting factor.',
    slots: [
      TemplateSlot('Barbell Full Squat', sets: 3, reps: 8),
      TemplateSlot('Bench Press (Barbell)', sets: 3, reps: 8),
      TemplateSlot('Bent Over Row (Barbell)', sets: 3, reps: 8),
      TemplateSlot('Weighted Front Plank', sets: 2, reps: 30),
      TemplateSlot('Bicep Curl (Dumbbell)', sets: 2, reps: 12),
    ],
  ),
  RoutineTemplate(
    name: 'Beginner Full Body A',
    category: 'Full Body',
    level: TemplateLevel.beginner,
    focus: 'Total Body · Foundations',
    description: 'Day A of a simple 3×/week start — squat and bench focus, '
        'one pull, a press, and a plank.',
    slots: [
      TemplateSlot('Barbell Full Squat', sets: 3, reps: 8),
      TemplateSlot('Bench Press (Barbell)', sets: 3, reps: 8),
      TemplateSlot('Cable Pulldown', sets: 3, reps: 10),
      TemplateSlot('Smith Standing Military Press', sets: 2, reps: 10),
      TemplateSlot('Weighted Front Plank', sets: 3, reps: 30),
    ],
  ),
  RoutineTemplate(
    name: 'Beginner Full Body B',
    category: 'Full Body',
    level: TemplateLevel.beginner,
    focus: 'Total Body · Foundations',
    description: 'Day B of the 3×/week start — deadlift and dumbbell pressing '
        'balanced with a row and goblet squat.',
    slots: [
      TemplateSlot('Deadlift (Barbell)', sets: 3, reps: 5),
      TemplateSlot('Bench Press (Dumbbell)', sets: 3, reps: 10),
      TemplateSlot('Cable Low Seated Row', sets: 3, reps: 10),
      TemplateSlot('Goblet Squat', sets: 3, reps: 12),
      TemplateSlot('Bicep Curl (Dumbbell)', sets: 2, reps: 12),
    ],
  ),
];

/// Grouped by category in the curated [exploreCategoryOrder]. Computed ONCE
/// (top-level `final`, lazily initialized) rather than re-grouped on every
/// widget build.
final List<({String category, List<RoutineTemplate> items})> exploreSections =
    () {
  final byCategory = <String, List<RoutineTemplate>>{};
  for (final t in exploreTemplates) {
    byCategory.putIfAbsent(t.category, () => []).add(t);
  }
  return [
    for (final c in exploreCategoryOrder)
      if (byCategory[c] != null) (category: c, items: byCategory[c]!),
  ];
}();
