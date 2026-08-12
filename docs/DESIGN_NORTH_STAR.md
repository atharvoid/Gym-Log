# GymLog — Design North Star

> **Status:** Active / Production Authoritative
> **Owner:** Core Engineering
> **Last verified SHA:** `aef17b09305ebf0455244c3c04159577f37e0a84`
> **Last reviewed date:** 2026-07-22
> **Next review date:** 2026-10-22

> The visual identity of GymLog. Read this before any visual work. It replaces
> the deleted `STITCH_DESIGN_SYSTEM.md` (which described a different app).

---

## Identity in One Sentence

GymLog is an **OLED-black** canvas with **one electric accent** at a time — calm,
precise, premium. Content floats on pure black; depth comes from tonal surface
layers, never decorative borders.

---

## Principles

### 1. OLED-True Black Canvas

- Base background is `#000000` — pure void
- Surface hierarchy builds upward: `surface1 (#0D0D0D)` → `surface2 (#141414)` → `surface3 (#1C1C1C)` → `surface4 (#242424)`
- Card depth via near-black gradient fills, not borders or shadows
- This is non-negotiable — it's the foundation of the premium feel

### 2. One Accent, Applied Everywhere via `context.accent`

- The user picks one of 6 palettes (Purple, Cyan, Magenta, Electric Indigo, White, Higgsfield)
- Every accent-colored surface reads from `context.accent.base` / `.light` / `.dark` / `.muted` / `.glow` / `.onAccent`
- **Never** hardcode `AppColors.accentPrimary` / `indigoTint` / any hex color on a live surface
- `onAccent` is near-black (`#0A0A0A`) on **every** palette — dark label on saturated fill (Apple's tinted-button treatment)
- Semantic colors (success green, warning amber, reward gold, error red) are **fixed** — they never follow the accent

### 3. Calm, Not Flashy

- Matte fills over "shiny" gradients
- No pulsing glow as chrome — glow is reserved for atmospheric effects only
- Solid accent fill appears on **one** focal CTA per view, not on repeating controls
- Repeating controls (list items, filter chips) use **neutral-raised** treatment: `surface3`/`surface4` fill + bold neutral label + accent only on the leading glyph

> **Catalog-card carve-out (W3, 12 Aug 2026):** the Explore Programs screen's
> card CTAs are an exception to "one focal CTA per view" — each card is a
> self-contained conversion unit, so every card's primary action ("Add" /
> "View") carries the FULL `accent.base` fill with `accent.onAccent` label, per
> the "solid accent → black label" rule (Accent Palette Tokens section below). Selection is the ONLY
> accepted dilution of this exception: if CardCTA density on a 400×800 viewport
> reads as a "coupon flyer" (three or more filled CTAs visibly competing above
> the fold), the documented fallback is `surface4` fill + `textPrimary` label
> with the accent reserved for the icon. The feature card rating is locked by
> `test/golden/explore_screen_golden_test.dart`.
> 
> Filter chips (level + equipment rows) are NOT affected — they stay
> neutral-raised (`surface4` + accent `selectionBorder` on selected), never
> `accent.muted` (that token is reserved for content tinting, e.g. muscle
> tags). Locked by `test/explore_filters_layout_test.dart`.

### 4. Typographic Hierarchy + Tabular Figures

- Google Fonts Inter for all text
- Tabular figures (`fontFeatures: [FontFeature.tabularFigures()]`) for all live numbers (timer, weights, reps, stats) — digits must never jitter
- Clear hierarchy: primary (white), secondary (60% white), tertiary (35% white), disabled (20% white)

### 5. Direct Manipulation + Gesture-First

- Swipe-down to minimize, tick to commit, drag to reorder
- Every gesture has a visible affordance — no hidden-only interactions
- Touch targets ≥ 44pt

### 6. Haptics as Feedback Texture

- `HapticFeedback.mediumImpact()` on primary CTA taps, including workout start (`PrimaryButton`, `StartButton`) — corrected 1 Aug 2026; this section used to say `heavyImpact()` on workout start, which no call site in the app actually implements
- `HapticFeedback.selectionClick()` on segment/tab changes and most other selection changes
- `HapticFeedback.mediumImpact()` on a valid set completion (not `lightImpact()` as previously documented here); `HapticFeedback.heavyImpact()` on a rejected completion tap (missing weight/reps)
- `HapticFeedback.heavyImpact()` is otherwise reserved for destructive confirmations (delete, database reset), a successful (non-PR) workout finish (`ActiveWorkoutScreen._retryFinish`) — corrected 1 Aug 2026; a duplicate, premature firing of this same cue at sheet-open time (before Cancel or a save failure could still happen) was removed from `finish_summary_sheet.dart` the same day — and the rest timer's end-of-rest double-buzz
- Personal records get their own escalated sequence, undocumented until now: `HapticFeedback.heavyImpact()` when the celebration appears, then `HapticFeedback.mediumImpact()` roughly 240ms later as the card settles (`pr_celebration_overlay.dart`)

**Known exception:** `TogglePill` fires `lightImpact()` for its own selection changes instead of `selectionClick()`, unlike every other segmented/tab-style control in the app. Not yet reconciled — flagged in `toggle_pill.dart`.

---

## Quality Gates

These are the **sensors** that enforce "premium." They run in CI and locally.

| Dimension | Verifiable Gate |
|---|---|
| **Theme correctness** | Golden tests per accent for every key surface. Zero diff to approved baseline. |
| **No hardcoded accent** | `custom_lint` rule / grep: fail if `AppColors.accent*` is used outside static-fallback files. |
| **Motion** | Standard durations/curves only (200–300ms, `Curves.easeOutCubic`). No jank frames in profile. |
| **Touch targets & a11y** | Widget tests assert ≥44pt targets. Text scales to 1.3× without clipping. |
| **Empty/loading/error states** | Every screen has all three, each golden-tested. |

---

## Surface Tokens

The app uses `context.surface` for brightness-mode-aware surface colors:

| Token | Dark (AMOLED) | Purpose |
|---|---|---|
| `bgBase` | `#000000` | Screen background |
| `bgSurface` | `#0D0D0D` | Default card |
| `surface2` | `#141414` | Elevated cards, charts, modals |
| `surface3` | `#1C1C1C` | Inputs, secondary buttons |
| `surface4` | `#242424` | Menus, action sheets, tooltips |
| `borderSubtle` | `white 6%` | Default card border |
| `borderDefault` | `white 10%` | Interactive element border |
| `borderEmphasis` | `white 18%` | Focused/selected |

---

## Accent Palette Tokens

Each of the 6 user-selectable palettes exposes:

| Token | Job |
|---|---|
| `base` | Primary action color (CTA fill, active states, selected borders) |
| `light` | Accent text, hairlines, chart date header (WCAG-safer on black) |
| `dark` | Pressed / depressed states |
| `muted` | Tinted card / chart-fill background (~14% alpha) |
| `glow` | Atmospheric effects (~12% alpha) |
| `onAccent` | Text/icon ON the full-saturation base (near-black on ALL palettes) |

---

## The One Rule for Accent-Filled Controls

> **Solid accent fill → black label.** Any control whose background is `context.accent.base`
> MUST render its label and icon in `context.accent.onAccent` (near-black) — never
> `AppColors.textPrimary` (white). White-on-accent is invisible on light palettes
> (White, Cyan, Higgsfield) and looks wrong everywhere else.

---

## Identity Assets — Source of Truth (E51, 1 Aug 2026)

- `gymlog_app_icon.png` (repo root) is the master app icon artwork. The
  platform-embedded icons (`ios/Runner/Assets.xcassets/AppIcon.appiconset/*`,
  `android/app/src/main/res/mipmap-*/ic_launcher.png`) were generated from it
  by hand — there is no `flutter_launcher_icons` (or equivalent) dependency
  in `pubspec.yaml` wiring them together. Any future update to the root PNG
  must be manually re-exported to every platform size, or the shipped icon
  will silently drift from the master artwork.
- `android_backup/` at the repo root is a stale, fully duplicated Android
  Gradle project (its own `build.gradle`, `settings.gradle`, gradle
  wrapper, `.iml`) sitting beside the real `android/`. It is not referenced
  by any build script or CI config found in this audit. Do not edit it —
  it is a kill-list candidate, not a second build target.
- `play_store_screenshots/` and `screenshots/` were last captured
  2026-07-08, before most of this audit's motion, haptic, and token fixes
  landed. Treat them as stale reference material, not proof of current
  UI, until they are recaptured against a current build.
