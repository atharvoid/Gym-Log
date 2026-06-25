# GymLog — Design North Star

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

### 4. Typographic Hierarchy + Tabular Figures

- Google Fonts Inter for all text
- Tabular figures (`fontFeatures: [FontFeature.tabularFigures()]`) for all live numbers (timer, weights, reps, stats) — digits must never jitter
- Clear hierarchy: primary (white), secondary (60% white), tertiary (35% white), disabled (20% white)

### 5. Direct Manipulation + Gesture-First

- Swipe-down to minimize, tick to commit, drag to reorder
- Every gesture has a visible affordance — no hidden-only interactions
- Touch targets ≥ 44pt

### 6. Haptics as Feedback Texture

- `HapticFeedback.mediumImpact()` on primary CTA taps
- `HapticFeedback.selectionClick()` on segment/tab changes
- `HapticFeedback.lightImpact()` on set completion
- `HapticFeedback.heavyImpact()` on workout start

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
