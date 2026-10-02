# DELT Design System & Token Specification (DESIGN.md)

> **Status:** Production Authoritative  
> **Brand Name:** DELT  
> **Package Name:** `gymlog`  
> **Canvas Philosophy:** OLED-first true black (`#000000`) with surgical tonal surface hierarchy and one reactive neon accent. "Quiet instrument, loud result."

This is the single authoritative visual, interaction and information-truth rule
set. `docs/CONVENTIONS.md` owns architecture and naming; its UI examples defer
here. `docs/DESIGN_NORTH_STAR.md` points here instead of duplicating rules.
The upgrade audit describes problems; `docs/upgrade/PROTOCOL.md` governs the
process. Historical screenshots and scores are evidence, not token definitions.
Source tokens in `app_colors.dart`, `theme_palette.dart`, `app_text.dart` and
`app_theme.dart` implement these rules; report discrepancies rather than
silently treating stale documentation as an exception.

---

## 1. Brand Identity & Naming Rules

1. **Brand Name:** The consumer-facing brand name is **DELT** (displayed as `DELT` or `Delt`).
2. **Watermark Standard:** All social share cards, exports, and viral distribution assets must feature the DELT wordmark:
   - **Styling:** `DELT` wordmark with micro-caps tracked subtitle (e.g. `DELT · IRON RECORD`).
   - **Opacity:** ~60% white (`AppColors.textSecondary` / `0x99FFFFFF`) — never invisible (~35%) and never shouting (100%).
   - **Render Size:** 28–32px cap-height in 1080×1920 renders (~9.5–11pt in 360×640 logical canvas).
   - **Position:** Anchored safely above the bottom platform exclusion zone (y <= 1540px in 1080×1920, or y <= 513pt in 360×640).

---

## 2. Color Palette & Token Discipline

### 2.1 OLED True-Black Canvas & Surface Ladder
Depth is created via tonal surface steps and subtle near-black gradients, **never** drop shadows or skeuomorphic borders.

| Token | Hex / Value | Purpose |
|---|---|---|
| `bgBase` | `#000000` | Pure void base background |
| `surface1` (`bgSurface` / `surfaceCard`) | `#0D0D0D` | Default card fill |
| `surface2` (`surfaceRaised` / `bgSheet`) | `#141414` | Elevated cards, charts, modals |
| `surface3` | `#1C1C1C` | Inputs, secondary buttons, neutral pills |
| `surface4` (`elevated`) | `#242424` | Menus, tooltips, action sheets |
| `borderSubtle` | `0x0FFFFFFF` (6% white) | Default card borders |
| `borderDefault` | `0x1AFFFFFF` (10% white) | Interactive elements |
| `borderEmphasis` | `0x2EFFFFFF` (18% white) | Focused / selected elements |

### 2.2 Card Surface Gradient
```dart
static const cardGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF0E0E11), Color(0xFF09090B)],
);
```

### 2.3 The 6 Reactive Accent Palettes
The user selects one accent palette in Settings (`context.accent`). The active accent governs focal CTAs, active highlights, and progress series.

1. **Volt / Higgsfield (Default):**
   - `base`: `#C8FF00` (Electric chartreuse) | `light`: `#EAFF66` | `dark`: `#9FCC00` | `muted`: `0x24C8FF00` (14%) | `glow`: `0x1FC8FF00` (12%)
2. **Neon Purple:**
   - `base`: `#C400FF` | `light`: `#D966FF` | `dark`: `#9900CC` | `muted`: `0x24C400FF` | `glow`: `0x1FC400FF`
3. **Ice White:**
   - `base`: `#EAF2FF` (Ice-chrome cool tint) | `light`: `#FFFFFF` | `dark`: `#B9C9E0` | `muted`: `0x24EAF2FF` | `glow`: `0x1FEAF2FF`
4. **Neon Cyan:**
   - `base`: `#00F0FF` | `light`: `#7FF7FF` | `dark`: `#00C0CC` | `muted`: `0x2400F0FF` | `glow`: `0x1F00F0FF`
5. **Neon Magenta:**
   - `base`: `#FF006E` | `light`: `#FF66AA` | `dark`: `#CC0058` | `muted`: `0x24FF006E` | `glow`: `0x1FFF006E`
6. **Blaze Orange:**
   - `base`: `#FF6600` | `light`: `#FFA366` | `dark`: `#CC5200` | `muted`: `0x24FF6600` | `glow`: `0x1FFF6600`

### 2.4 The Solid Accent Fill Rule
> **Solid Accent Fill → Near-Black Label.**
> Any button or control with `context.accent.base` background **must** use `context.accent.onAccent` (`#0A0A0A`) for text and icons — **never** white (`AppColors.textPrimary`).

### 2.5 Immutable Semantic Gold (PR Anchor)
- **Reward Gold (`kRewardGold` / `AppColors.rewardGold`):** `#E6C84A`.
- **Coexistence Rule:** Gold is reserved **exclusively** for the PR marker (the trophy icon, PR badge, or milestone label). All other brand highlights, progress bars, and metrics use the reactive `context.accent`. This prevents chromatic clash with Volt or Ice White.

### 2.6 Fixed Semantic Accents
- `accentSuccess` (`#34C759`): Completed sets / positive confirmations.
- `accentWarning` (`#FF9F0A`): Warm-up sets / warnings.
- `accentReward` (`#E6C84A`): PR celebration gold.
- `error` (`#FF3B30`): Destructive actions.

### 2.7 Text Opacity Ladder
- `textPrimary`: `#FFFFFF` (100% white) — Headings, hero numbers, exercise names.
- `textSecondary`: `0x99FFFFFF` (60% white) — Subtitles, dates, DELT watermark.
- `textTertiary`: `0x99FFFFFF` (60% white) — Column headers, chart ticks, placeholders, reassurance and secondary metadata. Same luminance floor as secondary; distinguish roles by size, weight and placement rather than faint ink.
- `textDisabled`: `0x33FFFFFF` (20% white) — Inactive elements.

---

## 3. Typography & Figure Styling

- **Font Family:** Bundled Inter through `AppText` and `buildAppTheme`. Keep `GoogleFonts.inter()` centralized in those theme helpers.
- **Bundled Font Files:** `Inter-Regular.ttf` (w400), `Inter-SemiBold.ttf` (w600), `Inter-Bold.ttf` (w700). Only weights 400, 600, 700 are supported.
- **Tabular Figures (`kTabular`):**
  - **Mandatory** on all numbers (weights, reps, times, volumes, deltas):
    ```dart
    fontFeatures: const [FontFeature.tabularFigures()]
    ```
- **Number Hierarchy:**
  - Hero figure is massive (e.g. 56–72pt in 360×640 logical, or 168–216px in 1080×1920 render).
  - Units (`KG`, `LBS`, `REPS`) are scaled down to 35–45% of the number's cap-height and baseline-aligned.
- **Micro-Caps Tracking:**
  - Column headers, kicker tags, and watermark metadata use `10px`–`12px`, `FontWeight.w600`, with `letterSpacing: 0.8` to `1.2`. Always uppercase strings.

---

## 4. Geometry, Radii & Spacing

### 4.1 Radii (`AppRadius`)
- Cards & Thumbnails: `10px` (`AppRadius.card`)
- Primary CTAs & Buttons: `14px` (`AppRadius.buttonPrimary`)
- Badges & Pills: `8px` (`AppRadius.badge`)
- Sheets: `12px` (`AppRadius.sheet`)
- Inputs / Data-entry: `0px` (`AppRadius.input` — intentional sharp design)

### 4.2 Spacing (`AppSpacing`)
- Base unit is 4pt:
  - `x1`: 4pt, `x2`: 8pt, `x3`: 12pt, `x4`: 16pt, `x5`: 20pt, `x6`: 24pt, `x8`: 32pt, `x10`: 40pt, `x12`: 48pt.

---

## 5. Story Canvas & Safe-Zone Specification

For 9:16 social sharing (Instagram Stories, TikTok, Reels, Snap):
- **Master Render Dimensions:** `1080 × 1920` px.
- **Logical Flutter Canvas:** `360 × 640` pt rendered at `pixelRatio: 3.0`.
- **Instagram Story Exclusion Safe Zones:**
  - **Top Inset:** `250px` render (`83.3pt` logical) reserved for profile header, story timer, and close button.
  - **Bottom Inset:** `380px` render (`126.7pt` logical) reserved for reply bar, link sticker, and story tools.
  - **Safe Usable Zone:** Vertical span from `y = 84pt` to `y = 513pt` (`250px` to `1540px`).
  - **Watermark Anchor:** Placed precisely at `y = 495pt` to `508pt` (just above the 127pt bottom danger zone).

---

## 6. Signature Visual Motifs & Restraint Rules

1. **"Quiet Instrument, Loud Result":** The card is a trophy / poster, not an app dashboard. Limit visible elements to 5–7 per card.
2. **Witness Row Grammar:** Always format credibility metrics cleanly:
   `+DELTA · BW [X] KG · [DATE]` separated by hairline dots or mid-dots.
3. **No Cheesy Graphics:** No cartoon flames, no party-popper emojis, no rainbow gradients.
4. **Privacy Defaults:** Lifter name and bodyweight default to **OFF** (`showName: false`, `showBodyweight: false`). Date defaults to **ON** (`showDate: true`).

---

## 7. Inviolable Engineering Rule

> **All share-card code must use tokens from `DESIGN.md`, with no hardcoded colors, magic numbers, or arbitrary fonts.**

## 8. Information Truth and Contrast

- Store weights and weighted volume in kilograms; use `core/utils/units.dart`
  exactly once for display. Visible and spoken values share the selected unit.
  Metres, seconds and rep counts never enter weight conversion.
- Completed weighted sets contribute weight × reps; rep-only sets contribute
  reps; timed sets contribute logged seconds; distance sets contribute metres
  and logged seconds. Elapsed time is separate from logged hold time. Mixed
  summary precedence remains volume, reps, distance, logged time.
- Label Epley results **Estimated 1RM**. Show the actual logged set separately
  when evidence exists; say unavailable otherwise. Never display an estimate
  as the weight lifted for multiple reps. Missing estimates remain absent.
- Volume and duration deltas are neutral descriptions with direction and
  comparison context. Reserve success/error colors for actual completion,
  confirmation or failure; more/less training is not better/worse by default.
- Separate logged facts, estimates and suggestions. Do not invent recovery,
  training benefit, personalization or saved-state claims.
- Measure alpha-composed text against its actual backing, including accent
  and status tints, across all palettes. Meaningful normal text requires 4.5:1;
  large text and meaningful non-text controls require 3:1. Chart-axis aliases
  follow `textTertiary`. Disabled appearance also exposes disabled semantics.
- All six selectable accents retain the dark OLED surface ladder. Ice White
  is an accent; draft light surface tokens are not a qualified product mode.

## 9. Interaction and Qualification

- Keep one focal filled CTA per view. Repeating controls use raised neutral
  surfaces and accent glyphs. Explore program-card CTAs may use filled accent
  per self-contained card; if three compete above the fold, use `surface4`
  with accent on the icon. Filter chips stay neutral.
- Use shared motion primitives and `AppMotion.effective`; preserve reduced
  motion. Entry animation is for bounded content, not virtualized list items.
  Keep feedback proportionate to events; no decorative pulsing chrome.
- Preserve visible alternatives to gestures and meaningful semantics. Android
  touch targets are at least 48dp (44pt on iOS). Qualify 390×844 and 1.6× text,
  empty, low-data and error states with real-font goldens in affected palettes.
  Device screen readers and haptics remain unverified until tested.
- Existing haptic intent: medium for primary actions and valid set completion,
  selection click for selections, heavy for destructive confirmations and
  successful finish. PR recognition retains its heavy/medium sequence and
  rest-end its double cue. The legacy TogglePill light-impact exception is
  recorded, not permission to spread it.
- `scripts/verify.ps1` is mandatory. Screenshots do not certify native billing,
  durable save, performance, devices or pushed CI. Record gaps in the ledger;
  do not commit before local verification passes.
