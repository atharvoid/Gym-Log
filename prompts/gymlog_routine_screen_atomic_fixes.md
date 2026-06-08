# GymLog — Custom Routine Detail Screen: Atomic Fix Prompts (v3, Flutter + fl_chart)

> **For Claude Code.** Pixel-precise, stack-aware fix prompts for the GymLog routine detail screen. Feed in full or one atomic block at a time. Each block is self-contained: WHERE the bug is, WHY it is wrong, HOW to fix it down to the API/parameter, and ACCEPTANCE CRITERIA.

---

## 0. Global Context (read once before starting)

**Project:** GymLog — Flutter 3 / Dart `>=3.0.0 <4.0.0`, local-first fitness tracker.

**Stack (authoritative — confirmed from `pubspec.yaml` + source scan):**
- State: `flutter_riverpod ^2.5.0`, `riverpod_annotation ^2.3.0`
- Persistence: `drift ^2.18.0` on sqlite3, schemaVersion = 1
- Routing: `go_router ^14.0.0`, route `/routines/:id` → `RoutineDetailScreen`
- **Charts: `fl_chart ^0.68.0`** — all chart fixes target this API
- Fonts: `google_fonts ^6.2.0` — **`GoogleFonts.inter` is the ONLY font in the project for headings and body. Do NOT introduce Space Grotesk or any other font.**
- Models: `freezed` for `ActiveWorkoutState`, `WorkoutExerciseState`, `WorkoutSetState`
- Images: `cached_network_image ^3.3.0`, `gif_view ^0.4.0` (exercise GIFs from Supabase Storage public bucket)

**Theme files (do not invent tokens — reuse what exists):**
- `lib/core/theme/app_theme.dart`
- `lib/core/theme/app_colors.dart`

**Authoritative color tokens (current production values — these ARE the design):**
```
AppColors.bgBase         = #000000   OLED black, app background
AppColors.bgSurface      = #1C1C1E   elevated surfaces: cards, filled buttons, dropdowns
AppColors.accentPrimary  = #8A2BE2   electric purple — primary CTA, chart line, chart dots
AppColors.textPrimary    = #FFFFFF   high-contrast text, hero numerics
AppColors.textSecondary  = #8E8E93   muted labels, axis ticks, subtitles
AppColors.borderSubtle   = #2C2C2E   reserved for accessibility/edge cases only (NOT a default container stroke)
```

**Design discipline (agreed by user, derived from the v2 audit):**
- Containers are defined by **tonal background elevation** (`bgSurface` on `bgBase`), NOT by 1px strokes.
- `AppColors.borderSubtle` exists but is reserved — do NOT use it as a default container outline. Two visible borders on this screen (Edit Routine, All Time dropdown) are violations to be removed.
- Numeric columns use Inter with `FontFeature.tabularFigures()` for digit alignment — Inter supports this natively, no font swap needed.
- Tap targets ≥ 48 logical pixels (Material 3).
- Test at the smallest supported viewport: **360×640 logical pixels**. If it breaks at 360, it ships broken.

**Out of scope:**
- The literal string `Custom Routine` in the AppBar title — user-set, not a defect.
- `test/widget_test.dart` — known-broken on main (references `MyApp` instead of `GymLogApp`). Do not fix it here; do not let it confuse your test pass/fail signal.

**Definition of done:** Every atomic block below passes its acceptance criteria. Composite UI/UX target: **≥ 8.5/10** (up from current 6.5/10).

---

# CATEGORY A — CRITICAL CHART BUGS (fl_chart)

The volume chart is rendered with `LineChart(LineChartData(...))` from `fl_chart ^0.68.0`. Locate the chart widget under `lib/features/routines/presentation/` (likely `RoutineVolumeChart.dart` or inlined inside `RoutineDetailScreen`). All A-series fixes mutate that `LineChartData` configuration and its upstream Riverpod provider / Drift query.

---

## A1. Fix Y-axis label collision at the top of the chart

**Severity:** Critical (visible rendering bug)
**Where:** `LineChartData.maxY`, `LineChartData.titlesData.leftTitles`, and any standalone "peak data value" `Text` annotation overlaying the chart.

**Current behavior:** `2047` (peak data value) and `2000` (top gridline tick) collide into an unreadable smear at the top of the Y-axis.

**Root cause:** Two label sources collide — `maxY` is set near `dataMax` (no headroom) AND a manually placed annotation widget renders the peak value at the same pixel row as the topmost gridline tick.

**Industry rule:**
- Material Design 3 — Data Viz: top label has ≥ 10–15% headroom above peak data.
- Apple HIG — Charts: never place two labels within 8pt of each other.

**Exact fix:**

1. Compute `maxY` with headroom and snap to a "nice" round number:
   ```dart
   double _niceCeil(double v) {
     final step = v <= 100 ? 50 : v <= 500 ? 100 : v <= 2000 ? 250 : 500;
     return (v / step).ceil() * step;
   }
   final dataMax = samples.map((s) => s.volume).reduce(math.max);
   final maxY = _niceCeil(dataMax * 1.15);
   ```

2. Use **only the gridline tick labels** for the Y-axis. Delete any standalone `Text`/`Positioned` widget that draws the peak value on top of the chart.

3. Configure `leftTitles` so there are exactly 4 evenly spaced labels (`0, maxY/4, maxY/2, 3*maxY/4, maxY`):
   ```dart
   leftTitles: AxisTitles(
     sideTitles: SideTitles(
       showTitles: true,
       reservedSize: 44, // room for 4-digit numbers
       interval: maxY / 4,
       getTitlesWidget: (value, meta) => Padding(
         padding: const EdgeInsets.only(right: 8),
         child: Text(
           value.toStringAsFixed(0),
           style: GoogleFonts.inter(
             fontSize: 11,
             color: AppColors.textSecondary,
             fontFeatures: const [FontFeature.tabularFigures()],
           ),
         ),
       ),
     ),
   ),
   ```

4. If the peak data value must still be surfaced, surface it via `LineChartData.lineTouchData` (tap tooltip), NEVER as a permanent overlay label.

**Acceptance criteria:**
- No two Y-axis labels occupy overlapping pixel rows.
- Top label is the chart maximum (e.g. `2500`), not a data value (`2047`).
- ≥ 12 logical pixels of clear space between the topmost gridline and the topmost data point.

---

## A2. Fix X-axis duplicate date labels (`May 23 May 23`, `Jun 7 Jun 7`)

**Severity:** Critical (data viz bug)
**Where:** The Drift query / Riverpod provider feeding the chart, AND `LineChartData.titlesData.bottomTitles`.

**Current behavior:** Bottom axis reads `May 23  May 23  Jun 6  Jun 7  Jun 7`. The chart plots one point per session, and two sessions occurred on May 23 + two on Jun 7.

**Root cause:** The data feed is session-indexed (one row per `workout_sessions` row) instead of day-indexed. The bottom axis formatter has no deduplication.

**Exact fix — Option A (preferred: aggregate by calendar day):**

1. Locate the Drift query (likely in `lib/features/routines/data/` or a `workouts_dao.dart`). Add a method that aggregates by day for a given routine:
   ```dart
   // Drift custom select — adapt names to your actual table/column identifiers
   Future<List<DailyVolumeSample>> dailyVolumeForRoutine(String routineId) {
     return customSelect(
       '''
       SELECT
         DATE(ws.started_at) AS day,
         SUM(ws.total_volume_kg) AS volume
       FROM workout_sessions ws
       WHERE ws.routine_id = ?
       GROUP BY DATE(ws.started_at)
       ORDER BY day ASC;
       ''',
       variables: [Variable.withString(routineId)],
       readsFrom: {workoutSessions},
     ).get().then((rows) => rows.map((r) => DailyVolumeSample(
       day: DateTime.parse(r.read<String>('day')),
       volume: r.read<double>('volume'),
     )).toList());
   }
   ```
   If `total_volume_kg` isn't stored, sum `weight_kg * reps` over `workout_sets` joined to `workout_exercises` joined to `workout_sessions`.

2. Expose via a Riverpod provider: `routineDailyVolumeProvider(routineId)` → `AsyncValue<List<DailyVolumeSample>>`.

3. The chart's spots become `FlSpot(dayIndex.toDouble(), sample.volume)` — one spot per unique calendar day.

**Option B (only if product blocks aggregation):**

Keep per-session spots but deduplicate the bottom labels using a set captured outside the chart callback:
```dart
final shown = <String>{};
bottomTitles: AxisTitles(
  sideTitles: SideTitles(
    showTitles: true,
    reservedSize: 28,
    getTitlesWidget: (value, meta) {
      final label = DateFormat('MMM d').format(samples[value.toInt()].startedAt);
      if (shown.contains(label)) return const SizedBox.shrink();
      shown.add(label);
      return Text(label, style: _axisLabelStyle);
    },
  ),
),
```
Reset `shown` on every rebuild (e.g. recompute inside the `build` method, not as a class field).

**Acceptance criteria:**
- No two adjacent X-axis labels are identical strings.
- Option A: each X position represents a unique calendar day; aggregated volume is the SUM of all sessions that day.
- Option B: tap tooltip differentiates the two sessions on the same day.

---

## A3. Switch chart from smooth curve to linear interpolation

**Severity:** High (misleading data viz)
**Where:** `LineChartBarData.isCurved`.

**Current behavior:** Smooth Bezier between points implies continuous workout volume between sessions — false.

**Exact fix:**
```dart
LineChartBarData(
  isCurved: false,                // was true
  preventCurveOverShooting: true, // belt + suspenders
  spots: spots,
  color: AppColors.accentPrimary,
  barWidth: 2.5,
  isStrokeCapRound: true,
  dotData: FlDotData(
    show: true,
    getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
      radius: 4,
      color: AppColors.accentPrimary,
      strokeWidth: 0,
    ),
  ),
  belowBarData: BarAreaData(...), // see A5
),
```

**Acceptance criteria:**
- Lines between data points are straight segments.
- No overshoot/undershoot above the topmost or below the bottommost data point.

---

## A4. Y-axis must start at 0

**Severity:** High (visual distortion — exaggerates trend)
**Where:** `LineChartData.minY`.

**Current behavior:** `minY == dataMin == 518`. The chart looks zoomed-in.

**Exact fix:**
```dart
LineChartData(
  minY: 0,             // was something like samples.first.volume
  maxY: maxY,          // from A1
  // ...
)
```

**Acceptance criteria:**
- Bottom Y-axis label reads `0`.
- Visible empty space below the lowest data point.

---

## A5. Reduce area-fill opacity so gridlines read through it

**Severity:** Medium (legibility)
**Where:** `LineChartBarData.belowBarData` and `LineChartData.gridData`.

**Current behavior:** The purple gradient fill obscures the dashed horizontal gridlines in the lower portion of the chart.

**Exact fix:**
```dart
// On LineChartBarData:
belowBarData: BarAreaData(
  show: true,
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.accentPrimary.withOpacity(0.25),
      AppColors.accentPrimary.withOpacity(0.02),
    ],
  ),
),

// On LineChartData:
gridData: FlGridData(
  show: true,
  drawHorizontalLine: true,
  drawVerticalLine: false,
  horizontalInterval: maxY / 4,
  getDrawingHorizontalLine: (value) => FlLine(
    color: Colors.white.withOpacity(0.08),
    strokeWidth: 1,
    dashArray: [4, 4],
  ),
),
```

**Acceptance criteria:**
- All four horizontal gridlines visible from left to right edge of the chart, including through the densest part of the fill.
- The fill still adds visible depth — not flat zero opacity.

---

# CATEGORY B — TONAL ELEVATION (remove decorative borders)

Two visible 1px borders above the fold. Both are replaced with `AppColors.bgSurface` tonal elevation. **`AppColors.borderSubtle` is reserved for accessibility/edge cases and must NOT be reintroduced as a default outline.**

---

## B1. Remove the border on the Edit Routine button — use bgSurface

**Severity:** High
**Where:** The `Edit Routine` button, likely in `RoutineDetailScreen` or a `RoutineActions` sub-widget.

**Current behavior:** Stroked outline on the OLED background.

**Exact fix:**
```dart
SizedBox(
  width: double.infinity,
  child: Material(
    color: AppColors.bgSurface,                 // #1C1C1E
    borderRadius: BorderRadius.circular(999),   // pill, match Start Routine
    child: InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onEditTap,
      child: Container(
        height: 56,                              // same as Start Routine
        alignment: Alignment.center,
        child: Text(
          'Edit Routine',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,         // medium — see B3
            color: AppColors.textPrimary.withOpacity(0.92),
          ),
        ),
      ),
    ),
  ),
),
```
- NO border. NO outline. NO `BoxDecoration` with `border:`.
- If an `OutlinedButton` is currently used, replace it with the structure above.

**Acceptance criteria:**
- No stroke in any state (default, hover, pressed, focused).
- Button reads as a darker pill on black.
- Tap target ≥ 48 logical pixels tall.

---

## B2. Remove the border on the All Time dropdown — use bgSurface

**Severity:** High
**Where:** The time-range filter pill to the right of `Total Volume (kg)`.

**Exact fix:**
```dart
Semantics(
  label: 'Time range filter',
  button: true,
  child: Material(
    color: AppColors.bgSurface,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: openTimeRangeMenu,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentRangeLabel,                 // 'All Time' / 'This Month' / etc.
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary.withOpacity(0.92),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    ),
  ),
),
```

**Acceptance criteria:**
- No stroke.
- Visually distinct from background by lightness alone.
- Tap target ≥ 44 logical pixels.

---

## B3. Subordinate Edit Routine text weight to the primary CTA

**Severity:** Medium (visual hierarchy)
**Where:** Text styles on the two buttons.

**Exact fix:**
- `Start Routine`: `GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)`.
- `Edit Routine`: `GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary.withOpacity(0.92))`.

**Acceptance criteria:**
- Side-by-side visual comparison: Start is heavier than Edit.
- Blurred screenshot still resolves which is the primary CTA.

---

# CATEGORY C — UX RESTORATIONS

---

## C1. Restore the AppBar subtitle

**Severity:** High (regression from v1)
**Where:** `AppBar` of `RoutineDetailScreen`.

**Current behavior:** AppBar shows only the title.

**Exact fix:**
```dart
AppBar(
  backgroundColor: AppColors.bgBase,
  elevation: 0,
  scrolledUnderElevation: 0,
  leading: const BackButton(color: Colors.white),
  titleSpacing: 0,
  title: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        routine.name,
        style: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.1,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 2),
      Text(
        _routineSubtitle(routine),
        style: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    ],
  ),
  actions: [/* three-dot menu — see G2 */],
)

String _routineSubtitle(Routine r) {
  final count = r.exerciseCount;
  if (r.lastPerformedAt == null) return '$count exercises';
  return '$count exercises · Last performed ${_relative(r.lastPerformedAt!)}';
}

String _relative(DateTime t) {
  final diff = DateTime.now().difference(t);
  if (diff.inHours < 24) return 'today';
  if (diff.inDays == 1) return 'yesterday';
  if (diff.inDays < 30) return '${diff.inDays} days ago';
  return DateFormat('MMM d').format(t); // package: intl
}
```

**Acceptance criteria:**
- Subtitle visible on first render.
- Subtitle uses relative time within 30 days, absolute date beyond.
- Truncates with ellipsis if absurdly long.
- If `lastPerformedAt == null`, shows only `$count exercises`.

---

## C2. Add set sequence numbers next to type chips

**Severity:** High (information loss)
**Where:** The Set column inside each exercise card's set table.

**Current behavior:** Only the type chip renders (Drop / Fail / Warm). Set ordinal is gone.

**Exact fix:**
- Render `Row([SetNumber, gap, TypeChip?])`. Standard working sets get **no chip** — only the number — so chips become genuine signal for special sets.
```dart
Row(
  children: [
    SizedBox(
      width: 24,
      child: Text(
        '${set.indexInExercise + 1}', // 1-based
        textAlign: TextAlign.left,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    ),
    const SizedBox(width: 8),
    if (set.type != SetType.standard) TypeChip(type: set.type),
  ],
),
```

**Acceptance criteria:**
- Every Set-column row starts with a numeral.
- Chip renders only for non-standard set types (Warm, Drop, Fail, …).
- Numerals align vertically across rows.

---

## C3. Sort warm-up sets first, working/special sets after

**Severity:** Medium
**Where:** The Riverpod selector that exposes per-exercise sets to the UI (NOT the widget tree).

**Current behavior:** Display order is Drop → Fail → Warm. Warm-ups should always lead.

**Exact fix:**
1. Define canonical order on the `SetType` enum (or wherever it lives):
   ```dart
   enum SetType { warm, standard, drop, fail, cool }
   // `.index` defines display order.
   ```
2. In the Riverpod selector that returns `List<WorkoutSetState>` for an exercise:
   ```dart
   sets.sort((a, b) {
     final byType = a.type.index.compareTo(b.type.index);
     if (byType != 0) return byType;
     return a.recordedAt.compareTo(b.recordedAt);
   });
   ```
3. If the user has manually reordered sets in the editor (persisted `displayOrder` field), respect their order — apply default sort only on first hydrate.

**Acceptance criteria:**
- For an exercise with sets [Drop, Fail, Warm], the rendered order is [Warm, Drop, Fail].
- Set numbers from C2 reflect the new order (Warm=1, Drop=2, Fail=3).

---

## C4. Chip-color discovery affordance

**Severity:** Medium (learnability)
**Where:** Exercise card → above the set table header.

**Current behavior:** Three colored chips appear with no explanation.

**Exact fix (Option A — preferred):**
- Add a small `?` `IconButton` next to the `Set / Kg / Reps` header row:
  ```dart
  IconButton(
    icon: const Icon(Icons.help_outline_rounded, size: 16),
    color: AppColors.textSecondary,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    onPressed: () => _showChipLegend(context),
  ),
  ```
- `_showChipLegend` calls `showModalBottomSheet` with `backgroundColor: AppColors.bgSurface` and rows:
  - **Warm** — Warm-up set, lower intensity to prepare the body.
  - **Work** — Standard working set.
  - **Drop** — Weight reduced mid-set to extend the rep range.
  - **Fail** — Set taken to muscular failure.
- Each row uses the actual chip widget on the left and `GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)` for the description on the right.

**Acceptance criteria:**
- A new user can discover chip meanings without external docs.
- The `?` affordance does not clutter on repeat visits.

---

# CATEGORY D — TABLE CORRECTIONS

---

## D1. Right-align Kg and Reps columns with tabular figures

**Severity:** High (table fundamental)
**Where:** Set table data + header cells.

**Current behavior:** Numerics are centered; digit widths fail to align.

**Exact fix:**
```dart
// Data cell:
Text(
  '$value',
  textAlign: TextAlign.right,
  style: GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    fontFeatures: const [FontFeature.tabularFigures()],
  ),
),

// Header cell:
Text(
  'Kg', // or 'Reps' — see D3
  textAlign: TextAlign.right,
  style: GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.4,
  ),
),
```
- Right gutter from the column boundary: `16` logical pixels.
- If using a `DataTable` / `Table`, set `numeric: true` on Kg and Reps `DataColumn`s.

**Acceptance criteria:**
- `100` and `8` in the same column align on their last digit.
- Headers and data share the same right edge.

---

## D2. Header alignment must match column data alignment

**Severity:** Medium (consistency)
**Where:** Set table header row.

**Exact fix:**
- `Set` column: header AND data left-aligned.
- `Kg` and `Reps` columns: header AND data right-aligned (per D1).
- All headers share the style from D1's header cell.

**Acceptance criteria:** A vertical line drawn through any column passes through both header text edge and data text edge at the same X.

---

## D3. Lock header case to `Set / Kg / Reps`

**Severity:** Low (consistency polish)
**Where:** Set table header strings.

**Decision (apply, no debate):**
- Headers: `Set`, `Kg`, `Reps`.
- Body / inline copy stays lowercase in context: `30 kg`, `8 reps`.

**Acceptance criteria:**
- Headers visually consistent.
- Subtitle copy unchanged: `Last: 30 kg × 8 reps • 3 sets`.

---

## D4. Increase row vertical padding to 14

**Severity:** Low (mobile ergonomics)
**Where:** Set table row layout.

**Exact fix:**
- Each row: `padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 0)`.
- Minimum row height: `56` logical pixels (covers future tap-target needs).
- NO horizontal divider lines between rows — separation by spacing only.

**Acceptance criteria:**
- ≥ 12 logical pixels of clear space between adjacent row text baselines.
- No divider lines anywhere in the set table.

---

# CATEGORY E — TYPOGRAPHY POLISH (Inter only — no font swaps)

The project uses `GoogleFonts.inter` for everything. Do NOT introduce Space Grotesk or any other font.

---

## E1. Lock numeric typography to Inter Medium + tabular figures

**Severity:** Medium
**Where:** Any "hero numeric" on this screen — set table values, chart axis labels, set sequence numbers.

**Current behavior:** Already on Inter (correct), but missing `FontFeature.tabularFigures()`, so digit widths don't align across rows.

**Exact fix:**
```dart
// Hero numerics in set table (Kg, Reps cells):
GoogleFonts.inter(
  fontSize: 22,
  fontWeight: FontWeight.w500,
  color: AppColors.textPrimary,
  fontFeatures: const [FontFeature.tabularFigures()],
)

// Chart Y-axis labels:
GoogleFonts.inter(
  fontSize: 11,
  fontWeight: FontWeight.w500,
  color: AppColors.textSecondary,
  fontFeatures: const [FontFeature.tabularFigures()],
)

// Set sequence numbers (C2):
GoogleFonts.inter(
  fontSize: 16,
  fontWeight: FontWeight.w500,
  color: AppColors.textPrimary,
  fontFeatures: const [FontFeature.tabularFigures()],
)
```
- Inline numerics in running text (e.g. subtitle `30 kg × 8 reps • 3 sets`) stay on proportional figures — no change needed; proportional reads more naturally inline.

**Acceptance criteria:**
- Numbers in the same column line up vertically by digit, not by total width.
- Inter remains the only font referenced anywhere on this screen.

---

## E2. Remove or restructure the "Time Range" label

**Severity:** Medium (visual clutter)
**Where:** Chart header row.

**Current behavior:** Row reads `Total Volume (kg)` … `Time Range` … `All Time ▾` — three elements on one mobile-width row, middle muted and redundant.

**Exact fix — Option A (preferred):**
- Delete the visible `Time Range` Text widget entirely.
- Move the label to a `Semantics(label: 'Time range filter', ...)` wrapper around the dropdown (already included in B2's snippet).

**Option B (only if product insists on a visible label):**
- Stack the label above the dropdown (label-above pattern), not inline.

**Acceptance criteria:**
- Chart header reads as exactly two visual elements: `Total Volume (kg)` left, `All Time ▾` right.
- Screen readers announce "Time range filter" on focus.

---

# CATEGORY F — VISUAL POLISH

---

## F1. Apply corner radius to exercise thumbnail images

**Severity:** Low (visual consistency)
**Where:** Leading thumbnail in each exercise card. Currently uses `CachedNetworkImage` for the static thumb / `GifView` for animated frames.

**Current behavior:** Container has rounded corners; the image inside is square with hard corners → visible mismatch.

**Exact fix:**
```dart
ClipRRect(
  borderRadius: BorderRadius.circular(12),
  child: SizedBox(
    width: 56,
    height: 56,
    child: CachedNetworkImage(
      imageUrl: gifThumbUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: AppColors.bgSurface),
      errorWidget: (_, __, ___) => Container(color: AppColors.bgSurface),
    ),
  ),
),
```
- Do NOT wrap in a bordered container.
- If you currently have `Container(decoration: BoxDecoration(border: ...))`, remove it.

**Acceptance criteria:**
- Image corners exactly match container corners.
- No visible square-image-inside-rounded-container effect.

---

## F2. Reconsider stacked full-width Start + Edit buttons

**Severity:** Medium (layout efficiency)
**Where:** Top action area of `RoutineDetailScreen`.

**Current behavior:** Two full-width pill buttons stacked vertically dominate the fold and push the chart below the visible area at 360×640.

**Pick ONE — default Option A:**

**Option A — visual hierarchy (preferred):**
- `Start Routine` stays full-width, filled `AppColors.accentPrimary`, height 56.
- `Edit Routine` becomes a tonal button (`AppColors.bgSurface`), height **48**, width **~40%**, right-aligned beneath Start. The remaining ~60% on the left is empty or holds a thin metadata strip (e.g. `Last performed yesterday`).

**Option B — most space-efficient:**
- `Start Routine` becomes the only full-width primary.
- `Edit` moves to a `TextButton` in the AppBar trailing area, beside the three-dot menu, with a 48-pixel tap-target wrapper.

**Option C — minimum-change fallback (only if A and B rejected by product):**
- Keep both stacked full-width, but reduce each height to **52** and the gap to **8**.

**Acceptance criteria:**
- The chart is visible without scrolling on a 360×640 logical-pixel viewport.
- `Start Routine` remains the unambiguous primary CTA in any chosen option.

---

## F3. Increase chart internal padding

**Severity:** Low
**Where:** Chart `Padding` wrapper and `LineChartData.titlesData.*.sideTitles.reservedSize`.

**Exact fix:**
```dart
Padding(
  padding: const EdgeInsets.fromLTRB(0, 24, 12, 8),
  child: LineChart(
    LineChartData(
      // ...
      titlesData: FlTitlesData(
        show: true,
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 44, /* ... */),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 28, /* ... */),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
    ),
  ),
),
```

**Acceptance criteria:**
- The topmost gridline label has ≥ 12 logical pixels of clear space above it.
- Y-axis labels never clipped on the left edge (4-digit numbers fit comfortably).

---

# CATEGORY G — INFORMATION ARCHITECTURE ADDITIONS

---

## G1. Add a volume-delta callout

**Severity:** Low (delight / motivation)
**Where:** Between the chart and the exercise list inside `RoutineDetailScreen`.

**Current behavior:** No motivational layer despite a clear positive trend in the data.

**Exact fix:**
- New widget `RoutineProgressPill` rendered only if the daily-volume samples (from A2) length ≥ 2.
- Computes percentage delta from the first sample to the latest:
  ```dart
  final first = samples.first.volume;
  final latest = samples.last.volume;
  final delta = ((latest - first) / first * 100).round();
  ```
- Renders:
  ```dart
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.bgSurface,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          delta >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          size: 16,
          color: delta >= 0 ? AppColors.accentPrimary : AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          delta >= 0
              ? 'Volume up $delta% since ${DateFormat('MMM d').format(samples.first.day)}'
              : 'Volume down ${-delta}% since ${DateFormat('MMM d').format(samples.first.day)}',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    ),
  )
  ```

**Acceptance criteria:**
- Pill renders only with ≥ 2 daily samples.
- Computation matches the formula exactly.
- Updates when a new session completes (Riverpod invalidates → rebuild).

---

## G2. Three-dot menu tap target

**Severity:** Low (accessibility)
**Where:** AppBar trailing three-dot icon.

**Current behavior:** Bare `Icon` widget — possibly under 48×48 tap target.

**Exact fix:**
```dart
IconButton(
  icon: const Icon(Icons.more_vert_rounded, size: 24),
  color: AppColors.textPrimary,
  padding: EdgeInsets.zero,
  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
  splashRadius: 24,
  onPressed: openRoutineMenu,
),
```

**Acceptance criteria:**
- Tap target ≥ 48×48 logical pixels at all densities.
- Visual icon stays 24.

---

# FINAL CHECKLIST

- [ ] A1 — Y-axis top labels no longer collide; `maxY` padded 15%; only gridline labels render
- [ ] A2 — No duplicate X-axis labels; data aggregated by calendar day (or labels deduplicated)
- [ ] A3 — `LineChartBarData.isCurved: false`
- [ ] A4 — `LineChartData.minY: 0`
- [ ] A5 — Gridlines visible through area fill (fill alpha ≤ 0.25)
- [ ] B1 — Edit Routine button uses `AppColors.bgSurface`, no border
- [ ] B2 — All Time dropdown uses `AppColors.bgSurface`, no border
- [ ] B3 — Start = `FontWeight.w600`, Edit = `FontWeight.w500`
- [ ] C1 — AppBar subtitle restored with exercise count + relative last-performed
- [ ] C2 — Set numbers render alongside type chips; standard sets show no chip
- [ ] C3 — Warm-up sets sort first; provider-level ordering
- [ ] C4 — `?` icon opens chip legend bottom sheet
- [ ] D1 — Kg/Reps right-aligned with `FontFeature.tabularFigures()`
- [ ] D2 — Header alignment matches column data alignment
- [ ] D3 — Headers read `Set`, `Kg`, `Reps`
- [ ] D4 — Row `vertical: 14` padding, no divider lines
- [ ] E1 — Hero numerics use Inter w500 + tabular figures; no other font introduced
- [ ] E2 — `Time Range` label removed, semantics label added to dropdown
- [ ] F1 — Thumbnails wrapped in `ClipRRect(borderRadius: 12)`
- [ ] F2 — Button layout reduced per chosen option (A/B/C)
- [ ] F3 — Chart internal padding (top 24, reservedSize left 44 / bottom 28)
- [ ] G1 — Volume delta pill renders with ≥ 2 daily samples
- [ ] G2 — Three-dot menu tap target ≥ 48×48

**Target composite UI/UX score: ≥ 8.5/10.**

---

## Implementer Notes

- Do NOT modify the literal `Custom Routine` AppBar title — it is a user-set value, not a defect.
- Do NOT introduce Space Grotesk, Roboto, or any font other than Inter. The project ships GoogleFonts.inter only.
- Do NOT add new color tokens to `app_colors.dart` unless a fix explicitly requires it. Reuse `bgBase`, `bgSurface`, `accentPrimary`, `textPrimary`, `textSecondary`. `borderSubtle` is reserved.
- Do NOT touch `test/widget_test.dart` here — known-broken on main since before this task.
- Do NOT freelance refactors. If a fix would require touching the Drift schema (e.g. adding a `total_volume_kg` column), pause and ask first.
- Test at 360×640 logical pixels. If it breaks at 360, it ships broken.
