# Phase 1: Fix muscle split bar hardcoded purple; use settings theme accent - Research

**Researched:** 2026-08-09
**Domain:** Flutter theming / ThemeExtension accent reactivity (routine detail UI)
**Confidence:** HIGH (every claim verified directly in the workspace codebase)

## Summary

The routines screen's muscle split bar (`MuscleLoadBar`, rendered inside
`routine_detail_screen.dart`) paints with a **static, hardcoded 6-step purple
ramp** (`AppColors.muscleSplitPalette`) instead of the user-selected accent
palette. This is the last live-surface consumer of that static palette — the
sibling widget `MuscleSplitSection` (workout detail) was already migrated to
`context.accent.muscleSplitRamp`, and the entire reactive-accent
infrastructure (Riverpod notifier → `ThemeData` ThemeExtension → `context.accent`)
is complete, registered, and tested. The fix is a **2-line change** in one file
(swap the palette constant for `context.accent.muscleSplitRamp` + add one
import); no new packages, no build_runner, no schema changes.

**Primary recommendation:** In `lib/shared/widgets/body/muscle_load_bar.dart:49`,
replace `const palette = AppColors.muscleSplitPalette;` with
`final palette = context.accent.muscleSplitRamp;` and import
`package:gymlog/core/theme/dynamic_accent_theme.dart`. Add a golden test
(6 accent palettes) + a color-assertion widget test.

**Note:** the default accent is **Volt** (`ThemePalette.fallback =>
higgsfield`, theme_palette.dart:224), so users not on Purple will see the bar
change color — this is the intended behaviour, not a regression.

## Project Constraints (from AGENTS.md)

| Directive | Source | Impact on this phase |
|-----------|--------|----------------------|
| No hardcoded accent colors on live surfaces — use `context.accent` | AGENTS.md Definition of Done | THE fix; also enforced by `scripts/verify.ps1` migrated-screen grep |
| New/changed UI surfaces have/update a **golden in every affected accent theme** | AGENTS.md DoD | MuscleLoadBar has **no** golden today → must add `test/golden/muscle_load_bar_golden_test.dart` (6 palettes) |
| Run `.\scripts\verify.ps1` before done (format, analyze --fatal-infos --fatal-warnings, custom_lint, flutter test) | AGENTS.md DoD / CI | Gate for this phase — no build_runner needed (no schema/provider/model change) |
| Never use npm build/test; Flutter project | AGENTS.md Notes | n/a — pure Dart change |
| Read `docs/DESIGN_NORTH_STAR.md` before visual work | AGENTS.md Notes | Verified — §2 "One Accent, Applied Everywhere via `context.accent`" (lines 31-37) is the governing rule this fix enforces |

## Phase Requirements

| ID | Description | Research Support |
| --- | --- | --- |
| REQ-1 | Muscle split bar (routine detail) colors follow the user's selected settings accent palette | `context.accent.muscleSplitRamp` is registered on ThemeData (app_theme.dart:62-63); reference implementation exists in muscle_split_section.dart:19-22 |
| REQ-2 | Live palette switch re-renders the bar without restart | `context.accent` reads `Theme.of(this).extension<AccentColors>()` (dynamic_accent_theme.dart:167-175) → any ThemeData change rebuilds; provider switch already covered by existing tests (screens_theme_test.dart) |
| REQ-3 | No purple remnants / no static palette usage on the surface | Grep gate: after fix, `AppColors.muscleSplitPalette` has no live-surface consumers (only `MuscleColorService` fallback param stays, backwards-compatible) |
| REQ-4 | Existing semantics/a11y contract of the bar is unchanged | a11y_wrapper_single_node_test.dart:47-74 asserts combined node; fix touches only colors, not semantics |

## Root Cause

**File: `lib/shared/widgets/body/muscle_load_bar.dart`, line 49**

```dart
const palette = AppColors.muscleSplitPalette;
```

This static palette is defined at **`lib/core/theme/app_colors.dart:226-233`**:

```dart
/// Muscle-split data-viz fallback palette. Matches the live Purple ramp ...
static const muscleSplitPalette = [
  Color(0xFF7F00FF), // <- hardcoded purple, index 0 = dominant
  Color(0xFF9329FF),
  Color(0xFFA852FF),
  Color(0xFFBC7AFF),
  Color(0xFFD1A3FF),
  Color(0xFFE5CCFF),
];
```

That palette feeds **both** visuals of the bar:
- the stacked `CustomPaint` segments — `muscle_load_bar.dart:91-94` → `_LoadBarPainter` (`colors[i]`, painted at :186);
- the legend swatch dots — `muscle_load_bar.dart:103-108`.

`AppColors` itself is explicitly documented as **"LAYER 1 — BRAND ACCENT:
REACTIVE … is read via `context.accent.*` — NOT from this file"
(app_colors.dart:8-16)** and the Design North Star forbids hex colors on live
surfaces (DESIGN_NORTH_STAR.md:35). The muscle load bar was authored in commit
`f01ed45` ("feat(routines): muscle load bar replaces scrolling chip strip") and
never migrated to the reactive ramp, while the identical widget in
`muscle_split_section.dart` was.

Chromium trace/assert: grep across `lib/` for `muscleSplitPalette` (before fix)
yields exactly 4 sites — the definition (app_colors.dart:226) and
`muscle_load_bar.dart:49` + `MuscleColorService` fallbacks (:33/:53/:71, which
only trigger when a `ramp` argument is absent — no live call site does that
today). So the load bar is the **only** live surface still purple.

## Recommended Fix (concrete, minimal diff)

**File: `lib/shared/widgets/body/muscle_load_bar.dart`**

1. Add import (top of file, after `app_colors.dart` import):

```dart
import '../../../core/theme/dynamic_accent_theme.dart';
```

2. Replace line 49:

```diff
-    const palette = AppColors.muscleSplitPalette;
+    final palette = context.accent.muscleSplitRamp;
```

That is the entire change. Both existing uses (`palette[i.clamp(...)]` at lines
91-94 and 105-108) switch to the reactive ramp automatically; the clamp keeps
the 6-step behavior for >6 groups; the legend and painted segments use the same
palette so they stay in sync.

No other file changes required. Confirmed NOT needed:
- **build_runner** — no Drift/Riverpod/Freezed model changes (AGENTS.md rule).
- `app_colors.dart` import stays — `SurfaceContextX` (`context.surface`,
  app_colors.dart:314-320) is used at muscle_load_bar.dart:95-96 — the import
  was and remains required.

### Why `context.accent` works inside this widget

- `MuscleLoadBar` is a plain `StatelessWidget` (muscle_load_bar.dart:22). The
  accent extension is not Riverpod-bound: `context.accent` → `Theme.of(context)
  .extension<AccentColors>()` (dynamic_accent_theme.dart:167-175). `Theme.of`
  registers an inherited dependency → when the user picks a new accent, the
  root `MaterialApp` rebuilds `ThemeData` (dynamic_accent_theme.dart:10-16) and
  every descendant — including this stateless widget — rebuilds with the new
  ramp. No provider watch, no ConsumerWidget upgrade needed.

## Accent/Theme API Reference (verified)

| API | Location | Purpose |
| --- | --- | --- |
| `context.accent` (extension `AccentColorsContextX`) | dynamic_accent_theme.dart:167-175 | Read the live accent from any widget; falls back to `AccentColors.fallback` when no theme extension (tests) |
| `AccentColors.muscleSplitRamp` — `List<Color>` | dynamic_accent_theme.dart:73-74 | **6-step data-viz ramp, index 0 = dominant (deepest)**. Hand-tuned per accent `theme_palette.dart:116/134/155/173/191/209` |
| `AccentColors.base/.light/.dark/.muted/.glow/.onAccent` | dynamic_accent_theme.dart:63-78 | Token set; `onAccent` = label color on full-saturation base |
| `AccentColors.tint` / `.selectionBorder` | dynamic_accent_theme.dart:108-111 | 14% / 35% saturation helpers — use these, not alpha literals |
| `AccentColors.fallback` / `purpleFallback` | dynamic_accent_theme.dart:120-126 | Pre-theme default; now follows `ThemePalette.fallback` (Volt) |
| `dynamicAccentThemeProvider` / `accentTokensProvider` | dynamic_accent_theme.dart:49-57 | Riverpod state: the notifier holds the `ThemePalette` enum; writes SharedPreferences key `accent_palette` (:24) |
| `initialAccentPaletteProvider` | dynamic_accent_theme.dart:30-32 | Seeded by `Bootstrap` (bootstrap.dart:417) from persisted key before first frame |
| `buildAppTheme(tokens, palette:)` with `extensions: [AccentColors.fromTokens(...)]` | app_theme.dart:62-63 | Registration point that makes `context.accent` resolvable |
| `ThemePalette.fromStorage(key)` | theme_palette.dart:244-267 | Legacy key migration (purple/copper/teal/red + premium 6) → neon set. **Note:** old 'purple' maps to `neonPurple` |
| `MuscleColorService.rankedSplit(..., ramp:)` | muscle_color_service.dart:25-48 | Reference pattern: dominant muscle gets ramp[0], lighter per lesser share. `ramp: null` → static palette fallback (backward compatible, keep as-is) |
| Reference implementation (copy this pattern) | `lib/features/workout/presentation/widgets/workout_detail/muscle_split_section.dart:19-22` | `MuscleColorService.rankedSplit(counts, ramp: context.accent.muscleSplitRamp)` |

**6 selectable palettes** (theme_palette.dart:72-78): neonPurple, higgsfield
(Volt), white, neonCyan, neonMagenta, blazeOrange. Every one defines a
`muscleSplitRamp` — no palette lacks a ramp (verified lines 116, 134, 155, 173,
191, 209).

## Files to Modify

| File | Change |
| --- | --- |
| `lib/shared/widgets/body/muscle_load_bar.dart` | Add import + swap palette constant (lines 3, 49) — the fix |
| `test/golden/muscle_load_bar_golden_test.dart` (new) | Golden across all 6 palettes (alchemist `allThemesGroup`/`themedScenario` from `test/golden/golden_test_helpers.dart`) — required by AGENTS.md DoD for changed surface |
| `test/muscle_load_bar_accent_test.dart` (new) | Widget test: pump `MuscleLoadBar` under `gymlogApp(ThemePalette.neonPurple, …)`, assert legend dot colors == `ThemePalette.neonPurple.tokens.muscleSplitRamp`; assert **no** `Color(0xFF7F00FF)` present anywhere; empty-entries → `SizedBox.shrink` guard |

**Do NOT modify:** `app_colors.dart` (keep `muscleSplitPalette` as backward-
compat fallback for `MuscleColorService`), `theme_palette.dart`,
`dynamic_accent_theme.dart`, `app_theme.dart`, `muscle_summary.dart`,
`muscle_map.dart` (already accent-driven — muscle_map.dart:59-71), or
`routine_detail_screen.dart` (works unchanged; `_MusclesWorkedStrip` at
:571-594 needs no gallery touch).

## Validation Architecture

**Test framework:** `flutter_test` widget tests + `alchemist` golden pipeline
(see test/golden/). No new dependencies. Quick run: `flutter test test/muscle_load_bar_accent_test.dart test/golden/muscle_load_bar_golden_test.dart`;
full gate: `.\scripts\verify.ps1`.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | Gap? |
| --- | --- | --- | --- | --- |
| REQ-1 | Bar mirrors active accent palette | widget (color asserts) | `flutter test test/muscle_load_bar_accent_test.dart -x` | ❌ new file (Wave 0) |
| REQ-1 | Bar renders in all 6 accents (visual) | golden | `flutter test test/golden/muscle_load_bar_golden_test.dart -x` | ❌ new file (Wave 0) |
| REQ-3 | No hardcoded purple / static palette on surface | static grep + assertion | `Select-String -Path lib -Pattern "muscleSplitPalette"` → only `app_colors.dart` + `muscle_color_service.dart` allowed; sulfated assertion in widget test | ❌ add to verify.ps1 optionally |
| REQ-4 | Single semantics node preserved | existing | `flutter test test/a11y_wrapper_single_node_test.dart -x` | ✅ existing (no changes needed) |

### Wave 0 (must be written before/with the fix)

- `test/golden/muscle_load_bar_golden_test.dart` — pattern from
  `test/golden/muscle_map_golden_test.dart` + `golden_test_helpers.dart`:
  `goldenTestGroup('MuscleLoadBar all the themes', allThemesGroup(...))`.
  Regenerate goldens with `flutter test --update-goldens`.
- `test/muscle_load_bar_accent_test.dart` — use `gymlogApp(ThemePalette.X, …)`
  (full theme incl. extension); legend dot lookup: `find.byWidgetPredicate((w)
  => w is Container && w.decoration is BoxDecoration && (w.decoration as
  BoxDecoration).shape == BoxShape.circle)`.

### What cannot be unit tested
- Live palette-switch re-render mid-session (needs full app + SharedPreferences
  mutation; existing `screens_theme_test.dart` covers accent switching at app-
  level). Manual QA: Settings → Appearance → pick a palette → open a routine →
  bar matches.
- Painter internals (`_LoadBarPainter` is private; assert via rendered
  legend/segment presence, not painter fields).

## Common Pitfalls

1. **Forgetting the import**: `context.accent` requires
   `import 'package:gymlog/core/theme/dynamic_accent_theme.dart';` —
   muscle_load_bar.dart does not currently import it. Missing import → compile
   error (immediately visible in `flutter analyze`).
2. **Sneaky static fallback**: do NOT "helpfully" replace `palette` with
   `AppColors.muscleSplitPalette` anywhere else, or leave a second consumer —
   the grep gate (verify.ps1) and this research show the base pattern is
   `context.accent.*`, with statics allowed only in radio-fallback contexts
   (dynamic_accent_theme.dart fallback).
3. **Golden flakiness**: bar is deterministic in size (SizedBox height 8 +
   Wrap legend); golden tests need `scenarioConstraints` width — copy the 400px
   from `allThemesGroup` (golden_test_helpers.dart:38); no
   `tester.binding.setSurfaceSize` needed (legend is a Wrap, bar has fixed
   height 8).
4. **Don’t touch the painter's rounding logic** — `_LoadBarPainter` has
   deliberate gap/rounding absorption (lines 167-189); color swap only.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
| --- | --- | --- |
| Accent palette per widget | Repeat hex constants | `context.accent.*` tokens (registered ThemeData extension) |
| Muscle-viz color mapping | Sort/clamp logic per widget | `MuscleColorService.rankedSplit` (+ ramp param) — muscle_split_section.dart:19-22 |
| Golden test scaffolding | Custom screenshot code | existing `alchemist` `GoldenTestScenario`/`themedScenario` helpers |

## Security Domain

`security_enforcement` is not explicitly disabled → section included. This is a
presentation-only color fix.

| ASVS Category | Applies | Control |
| --- | --- | --- |
| V2-V4, V6-V8 | No | No new auth, session, access, crypto, comms, or storage paths |

| Threat Pattern | STRIDE | Mitigation |
| --- | --- | --- |
| None introduced | — | Only `List<Color>` selection from `ThemeExtension`; no user input, no persistence change |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
| --- | --- | --- | --- | --- |
| Flutter/Dart | analyze, test, format | ✓ | Flutter 3.44.0 / Dart 3.12.0 (stable) | — |
| `.\scripts\verify.ps1` | DoD gate | ✓ (present, mirrors ci.yml) | — | `dart format` + `flutter analyze` + `dart run custom_lint` + `flutter test` |
| build_runner | NOT required | n/a | — | — |

No external services; nothing blocking.

## Architecture Responsibility Map

| Capability | Primary Tier | Secondary | Rationale |
| --- | --- | --- | --- |
| Accent palette state + persistence | Core theme (dynamic_accent_theme.dart + SharedPreferences) | — | Riverpod notifier → ThemeData rebuild |
| Accent propagation to widgets | ThemeExtension on `Theme.of(context)` | — | Inherited-widget rebuild — reactive by construction |
| Muscle-viz color assignment | `MuscleColorService` (core/services) | — | Single source of mapping logic; widget passes ramp from context |
| Bar/legend rendering | `MuscleLoadBar` widget layer | — | Presentation only; consumes ramp via `context.accent` |

## Sources

### Primary (VERIFIED — workspace code)
- `lib/shared/widgets/body/muscle_load_bar.dart` (root cause at :49)
- `lib/core/theme/app_colors.dart:223-233` (static palette)
- `lib/core/theme/dynamic_accent_theme.dart:62-170` (`muscleSplitRamp`, `context.accent`)
- `lib/core/theme/theme_palette.dart:56-59, 72-78, 106-218, 224-267` (6 ramps,
  fallback, key migration)
- `lib/core/theme/app_theme.dart:62-63` (ThemeExtension registration)
- `lib/features/workout/presentation/widgets/workout_detail/muscle_split_section.dart:19-22` (reference pattern)
- `lib/features/routines/presentation/screens/routine_detail_screen.dart:569-594` (call site)
- `test/a11y_wrapper_single_node_test.dart`, `test/golden/golden_test_helpers.dart`, `test/screens_theme_test.dart`, `test/golden/muscle_map_golden_test.dart`
- `scripts/verify.ps1:22-62` (migrated-screen AppColors gate), `docs/DESIGN_NORTH_STAR.md:31-37`, `docs/LOOP_LOG.md` H16

### Secondary (web)
- None — repository-internal theming; external docs would duplicate
  code-verified facts. External research seam skipped (nothing external to verify).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
| --- | --- | --- | --- |
| A1 | Phase's implied requirement is "bar renders in selected settings accent" (ROADMAP says TBD) | Phase Requirements | Low — matches the bug report and existing design rules |
| A2 | Default theme is Volt (higgsfield) → bar will turn Volt for users who never selected a palette | Summary/Notes | Cosmetic — user-visible but intended; no data impact |
| A3 | No other live surface uses `muscleSplitPalette` | Root Cause | Verified by grep across lib/ — only the fallback service + the load bar |

## Open Questions

1. **Should `muscle_load_bar.dart` be added to verify.ps1's migrated-screen
   list?** After the fix the file contains zero `AppColors.` usages; adding it
   is a free hardening win but changes the gate file. Recommendation: add it
   to the list (one line) as a follow-up task in the plan.
2. **Golden regeneration**: no existing goldens touch the bar (verified), so
   only new goldens; if the CI golden baseline runs all — run with
   `--update-goldens` on the two new files only.

## Metadata

**Confidence breakdown:**
- Fix location: HIGH — single consumer verified via grep + code trace.
- Theme API: HIGH — ramp field, extension registration, and fallback all read
  directly from source.
- Pitfalls: HIGH — derived from the repo's own conventions and verify.ps1.

**Research date:** 2026-08-09
**Valid until:** 2026-09-08 (stable codebase; re-verify only if a future phase
touches the theming layer)