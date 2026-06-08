# GymLog — Custom Routine Screen: Atomic Fix Prompts (v2 → v3)

> **For Claude Code.** Feed this file in full, or one atomic block at a time. Each block is self-contained: it tells you exactly WHERE the bug is, WHY it is wrong (industry + design-system rule), and HOW to fix it down to the pixel/parameter. Do not freelance — match the acceptance criteria literally.

---

## 0. Global Context (read once before starting)

- **Screen under repair:** Routine detail screen reached by tapping a custom routine in the Routines section.
- **Design system:** "Luminous Engine" — OLED true-black base (`#000000`), electric purple primary accent (`#8A4DFF` / iteratively `#7C3AED`), Inter for general UI, **Space Grotesk for high-impact numerics**.
- **Core rule violated repeatedly: the "No-Line" rule.** Containers are NEVER defined by 1px solid strokes. They are defined by **tonal background elevation** — i.e. `bgSurface` sitting on `bgBase`, where `bgSurface` is ~6–10% lighter than `bgBase`. The only acceptable stroke is a "ghost border" at 10–20% opacity for accessibility edge cases (e.g. high-contrast mode).
- **Out of scope:** The literal string `"Custom Routine"` in the AppBar title — this is user-set, not a UI defect. Do not touch the title text.
- **Definition of done for the screen:** Every atomic task below passes its acceptance criteria. Composite UI/UX target score: **≥ 8.5/10** (up from current 6.5/10).

---

# CATEGORY A — CRITICAL CHART BUGS (do these FIRST)

These make the screen look broken. Ship nothing else until they are fixed.

---

## A1. Fix Y-axis label collision at the top of the chart

**Severity:** Critical (visible bug, looks like a crash)
**Where:** `TotalVolumeChart` — Y-axis tick renderer.

**Current behavior:** The labels `2047` (the actual peak data value) and `2000` (the topmost gridline scale label) are rendered at almost the exact same Y-pixel and visually overlap into an unreadable smear.

**Root cause:** The Y-axis maximum is being set equal to (or just slightly above) the dataset's max value, AND the chart is rendering both a "highest gridline tick" label and a "highest data point" label in the same row. Two label sources are colliding.

**Industry rule:**
- **Material Design 3 — Data Visualization:** "Provide breathing room above the highest data point. The Y-axis maximum should exceed the data max by 10–15%."
- **Apple HIG — Charts:** "Avoid placing labels within 8pt of each other."
- **Edward Tufte — basic dataviz:** never let two text labels overlap.

**Exact fix:**
1. Compute `yMax = ceil((dataMax * 1.15) / niceStep) * niceStep` where `niceStep` is the nearest "nice" interval (100, 200, 250, 500, 1000).
2. Use only ONE label source on the Y-axis: the gridline ticks. Remove the standalone "peak data value" label that is currently rendered at the data point's pixel Y-position.
3. If the peak value must be shown, show it as a **tooltip on tap** on the topmost data point — never as a permanent axis label.
4. Compute gridlines as 4 evenly spaced steps: `[0, yMax*0.25, yMax*0.5, yMax*0.75, yMax]`.
5. Round each label using a "nice number" formatter so the user sees `0, 500, 1000, 1500, 2000` not `0, 511.75, 1023.5, …`.

**Acceptance criteria:**
- No two Y-axis labels share a pixel row.
- The top label is the chart maximum (e.g. `2500`), not a data value (`2047`).
- There is at least 12dp of clear vertical space between the topmost gridline and the topmost rendered data point.

---

## A2. Fix X-axis duplicate date labels (`May 23 May 23`, `Jun 7 Jun 7`)

**Severity:** Critical (data viz bug — the chart looks broken to the user)
**Where:** `TotalVolumeChart` — X-axis tick renderer + data aggregation.

**Current behavior:** The X-axis reads: `May 23   May 23   Jun 6   Jun 7   Jun 7`. Two sessions occurred on May 23 and two on Jun 7 — the renderer prints the date label once per session, producing adjacent duplicates.

**Root cause:** The chart's X-axis is "session-indexed" (one tick per workout session) rather than "date-indexed" (one tick per calendar day), AND the tick label formatter has no deduplication step.

**Exact fix:**
1. **Aggregate data by calendar day** *before* rendering. For each day with sessions, sum the total volumes of all sessions that day into a single data point: `{ date: '2026-06-07', volume: session1.volume + session2.volume }`. This is the canonical fix.
2. Render one X-axis tick per unique date.
3. If aggregation is impossible because the design requires per-session granularity:
   - Keep the multiple data points but render only one date label per unique day (deduplicate `xLabels`).
   - Add a small bracket or subtle "1 / 2" sub-label to indicate "session 1 of 2 on this day."
4. The X-axis must scale to **date space**, not **session ordinal space**. Two sessions on the same day should plot at the same X coordinate (or extremely close, e.g. 4px apart with the bracket treatment).

**Acceptance criteria:**
- No two adjacent X-axis labels are identical strings.
- If two sessions occurred on the same day, they are visually grouped (same X, or a tight cluster with a single date label).
- Hovering / tapping a multi-session day shows both sessions in the tooltip.

---

## A3. Switch chart from smooth Bezier curve to linear interpolation

**Severity:** High (misleading data viz)
**Where:** `TotalVolumeChart` — line renderer.

**Current behavior:** The chart connects data points with a smooth spline. Between actual measured points, the curve bulges above/below real values, implying continuous change between workouts that never happened.

**Root cause:** Chart library default. (e.g. `curve: 'cardinal'`, `tension: 0.4`, `smooth: true`.)

**Industry rule:** *Information Visualization* (Munzner): for discrete, time-sampled data with no underlying continuous process, **use straight-line segments**. Smooth curves are appropriate for genuinely continuous functions (temperature over time), not for stepwise behavior (workouts on specific days).

**Exact fix:**
- Set the line renderer to **linear interpolation**.
  - Chart.js: `tension: 0` (or `cubicInterpolationMode: 'default'` with `tension: 0`).
  - ECharts: `smooth: false`.
  - D3: `d3.curveLinear`.
  - Recharts: `type="linear"`.
  - Plotly: `line.shape = 'linear'`.

**Acceptance criteria:**
- Lines between data points are straight segments.
- No curve overshoots or undershoots a data point.

---

## A4. Y-axis must start at 0 (not 518)

**Severity:** High (visual distortion — exaggerates trend)
**Where:** `TotalVolumeChart` — Y-axis scale.

**Current behavior:** Y-axis minimum equals the dataset minimum (518). The chart looks "zoomed in," which exaggerates the visual delta between the lowest and highest values.

**Industry rule:**
- **Apple HIG / Material Design / Tufte:** Bar charts MUST start at 0. Line charts SHOULD start at 0 unless there is a strong reason (e.g. stock prices over a narrow band).
- For **fitness volume data**, the user's mental model includes "I lifted nothing before I started." Starting at 0 is honest.

**Exact fix:**
- Set `yMin = 0`.
- Combined with A1's `yMax = ceil((dataMax * 1.15) / niceStep) * niceStep`, recompute ticks as `[0, yMax*0.25, yMax*0.5, yMax*0.75, yMax]`.

**Acceptance criteria:**
- Y-axis bottom label reads `0`.
- The chart no longer looks "zoomed in" — there is visible empty space below the lowest data point.

---

## A5. Reduce area-fill opacity so gridlines are visible through it

**Severity:** Medium (data legibility)
**Where:** `TotalVolumeChart` — area fill below the line.

**Current behavior:** The purple gradient fill under the line is opaque enough to obscure the dashed horizontal gridlines in the lower portion of the chart. The user cannot read values through the fill.

**Industry rule:** Charting best practice — area fills supplement gridlines, they do not replace them. **Max opacity for an area fill: 25%.** Ideal: linear vertical gradient from `0.25` at the top to `0.05` at the bottom.

**Exact fix:**
- Implement a vertical linear gradient:
  - Top stop: `rgba(138, 77, 255, 0.25)` (purple at 25% alpha).
  - Bottom stop: `rgba(138, 77, 255, 0.02)` (essentially transparent at the axis).
- Ensure dashed gridlines render **above** the area fill in the z-order (or use `globalCompositeOperation` accordingly).
- Gridline color: `rgba(255, 255, 255, 0.08)` dashed `4 4`.

**Acceptance criteria:**
- All four gridlines are visible from left edge to right edge of the chart, including where they pass through the densest part of the area fill.
- The fill is still visible enough to add depth — not flat-zero opacity.

---

# CATEGORY B — DESIGN-SYSTEM VIOLATIONS (No-Line rule)

Two visible 1px borders above the fold. Both must go.

---

## B1. Remove the border on the "Edit Routine" button — use tonal elevation

**Severity:** High (direct design-system violation)
**Where:** `EditRoutineButton` component.

**Current behavior:** The Edit Routine button is defined by a visible ~1px stroked outline against the OLED black background. This is a textbook No-Line violation.

**Industry / design-system rule:**
- "Luminous Engine" No-Line rule: containers are defined by tonal background elevation, not strokes.
- Apple HIG, Material 3, and Fluent 2 all permit tonal-elevation surfaces; the Luminous Engine has *banned* strokes for container definition.

**Exact fix:**
1. Remove `border` / `BorderSide` / `OutlinedButton` entirely from this button.
2. Replace with a filled button using `bgSurface` color:
   - Background: `#141414` (≈ 8% white on OLED black) — call this `surfaceElevated1`.
   - Hover/pressed: lift to `#1C1C1C` (`surfaceElevated2`).
3. Keep the same pill shape (`borderRadius: 999`) and the same dimensions as the Start Routine button so visual rhythm is preserved.
4. Text color: `#E9E9EE` (off-white at ~92% opacity), NOT pure white — to subordinate it to the primary CTA.
5. Text weight: see B3.

**Acceptance criteria:**
- No stroke anywhere on the button at any state (default, hover, pressed, focused).
- The button reads as a darker pill resting on the black background — distinct from the surface but with no outline.
- Tap target: 48dp minimum height (WCAG 2.5.5).

---

## B2. Remove the border on the "All Time" filter dropdown — use tonal elevation

**Severity:** High (direct design-system violation)
**Where:** `TimeRangeDropdown` / `AllTimeFilter` component, top-right of the chart header.

**Current behavior:** The dropdown is bounded by a visible ~1px stroked outline.

**Exact fix:**
1. Remove the stroke.
2. Apply background `surfaceElevated1` (`#141414`).
3. Border radius: `12dp` (or match the pill family if it should be pill-shaped).
4. Internal padding: `8dp vertical, 12dp horizontal`.
5. Caret icon: `#9CA3AF` (muted gray), 16dp.
6. Label "All Time": Inter Medium 14sp, color `#E9E9EE`.

**Acceptance criteria:**
- No stroke on the dropdown.
- Visually distinct from the OLED background via lightness alone.
- Tap target ≥ 44dp.

---

## B3. Subordinate the "Edit Routine" button text weight to the primary CTA

**Severity:** Medium (visual hierarchy)
**Where:** `EditRoutineButton` text style.

**Current behavior:** "Edit Routine" is set in the same bold weight as "Start Routine," making the two buttons read as co-primary actions rather than primary + secondary.

**Industry rule:**
- **Apple HIG — Buttons:** Primary action = filled + bold; secondary action = tonal/outlined + **medium or regular** weight.
- **Material Design 3:** Primary FilledButton uses Label/Large/SemiBold; secondary TonalButton uses Label/Large/Medium.

**Exact fix:**
- "Start Routine" text: Inter **SemiBold (600)**, 16sp, white `#FFFFFF`.
- "Edit Routine" text: Inter **Medium (500)**, 16sp, color `#E9E9EE`.

**Acceptance criteria:**
- Direct visual comparison shows "Start Routine" is heavier than "Edit Routine."
- A blurred screenshot still resolves which button is the primary CTA.

---

# CATEGORY C — UX RESTORATIONS

Information lost between v1 and v2. Restore it.

---

## C1. Restore the AppBar subtitle (exercise count + last performed)

**Severity:** High (regression from v1)
**Where:** AppBar of the routine detail screen.

**Current behavior:** AppBar has only the title. v1 had a subtitle ("4 exercises · Last performed Jun 6") which has been removed.

**Industry rule:**
- **Apple HIG — Navigation:** "Provide context at every level of navigation."
- **Material Design — Top App Bar:** subtitle slot is the canonical location for context.

**Exact fix:**
- Restore a two-line AppBar:
  - **Line 1 (title):** the routine name. Inter SemiBold 22sp, white.
  - **Line 2 (subtitle):** `{exerciseCount} exercises · Last performed {relativeTime}`. Inter Regular 13sp, color `#9CA3AF`.
- Use **relative time** (`2 days ago`, `yesterday`, `last week`), not absolute dates, unless the gap exceeds 30 days — then fall back to absolute (`May 23`).
- If `lastPerformed` is null (never started): show just `{exerciseCount} exercises`.

**Acceptance criteria:**
- Subtitle is visible on first render.
- Subtitle updates after a workout is completed (`Last performed: just now`).
- Subtitle text never wraps; it truncates with ellipsis if absurdly long.

---

## C2. Add set sequence numbers next to type chips

**Severity:** High (information loss — user cannot tell which set is which)
**Where:** Exercise card → set table → "Set" column.

**Current behavior:** The "Set" column shows only type chips (Drop / Fail / Warm). The set ordinal (1, 2, 3) is gone. The user cannot tell whether the Drop set was set 1, 2, or 3.

**Exact fix:**
1. Render each row in the Set column as: `{setNumber}  {typeChip}` — two visual elements on a single row.
   - Set number: Space Grotesk Medium 16sp, color `#E9E9EE`, fixed 24dp width column-internal slot (so all numbers align).
   - 8dp gap.
   - Type chip: existing chip component.
2. If a set has no special type (a standard working set), render just the number with no chip OR a subtle "Work" chip — pick one and apply consistently across the app. Recommendation: **no chip for standard sets**, chips only for special sets (Warm, Drop, Fail, AMRAP, etc.). This makes special sets stand out.

**Acceptance criteria:**
- Every row in the Set column starts with a numeral (1, 2, 3…).
- Chips only render for non-standard set types.
- Numerals align vertically across rows.

---

## C3. Sort warm-up sets to the top, working/special sets after

**Severity:** Medium (logical ordering)
**Where:** Exercise card → set list ordering.

**Current behavior:** The order shown is Drop → Fail → Warm. Warm-up sets are physically performed **first** in a workout, so a warm-up at the bottom of the list is either a display bug or a data-entry mistake the UI is not flagging.

**Exact fix:**
- Define a canonical sort order for set types: `Warm → Work → Drop → Fail → Cool` (or whatever the full type taxonomy is — confirm with the data model).
- Sort sets within each exercise by `(typeOrder, executionTimestamp)` so warm-ups always lead.
- If the user has manually reordered sets in the editor, **respect their order** — only apply default sorting on data entry / first render.

**Acceptance criteria:**
- For a Dumbbell Bench Press with sets [Drop, Fail, Warm], the rendered order is [Warm, Drop, Fail].
- Set numbers (from C2) reflect this canonical order: Warm = 1, Drop = 2, Fail = 3.

---

## C4. Add a one-time onboarding tooltip or persistent legend for chip colors

**Severity:** Medium (learnability)
**Where:** Exercise card → first appearance of set type chips.

**Current behavior:** Three colored chips (purple Drop, red-orange Fail, amber Warm) appear with no explanation of what they mean. A new user has no way to learn the conventions.

**Exact fix — pick ONE of these patterns, not both:**

**Option A (preferred): A small "?" affordance next to the table header that opens a bottom sheet legend.**
- "?" icon, 16dp, muted gray, tap target 44dp.
- Bottom sheet shows each chip + a 1-line description:
  - **Warm** — Warm-up set, lower intensity to prepare the body.
  - **Work** — Standard working set.
  - **Drop** — Drop set, weight reduced mid-set to extend the rep range.
  - **Fail** — Set taken to muscular failure.

**Option B: One-time onboarding tooltip.**
- The first time a user sees a chip, anchor a small purple-bordered popover to it: "Tap to learn about set types." Dismissable, never shown again (persist in user preferences).

**Acceptance criteria:**
- A new user can discover the meaning of every chip color without reading external documentation.
- The discovery affordance does not clutter the screen on subsequent visits.

---

# CATEGORY D — TABLE CORRECTIONS

The set table inside each exercise card.

---

## D1. Right-align all numeric values (kg, Reps)

**Severity:** High (table design fundamental)
**Where:** Set table → kg and Reps columns (data rows AND header rows).

**Current behavior:** Numeric values `30, 30, 30` (kg) and `12, 10, 8` (Reps) are center-aligned. Different digit widths fail to align — `100` and `8` would not share a decimal column.

**Industry rule:** **Universal across Material, Fluent, Apple, IBM Carbon, GitHub Primer:** numeric columns are right-aligned (or decimal-aligned). Center-aligning numerics is a known mistake.

**Exact fix:**
- Both column data cells and column headers: `textAlign: right`.
- Right-align with a consistent right gutter of **16dp** from the column boundary.
- For numerics, use **tabular figures** (`font-feature-settings: "tnum"` for CSS, `FontFeature.tabularFigures()` for Flutter, `numericVariant: tabularNumbers` for SwiftUI) so digit widths are uniform.

**Acceptance criteria:**
- 100 and 8 in the same column align on their last digit.
- The header label (e.g. `kg`) sits flush-right above its data column.

---

## D2. Header alignment must match column data alignment

**Severity:** Medium (consistency)
**Where:** Set table → header row.

**Current behavior:** "Set" left-aligned, "kg" appears center-ish, "Reps" appears right-ish — alignment is inconsistent across the header row.

**Exact fix:**
- "Set" column: left-aligned header AND data.
- "kg" column: right-aligned header AND data (per D1).
- "Reps" column: right-aligned header AND data (per D1).
- All headers: Inter Medium 12sp, color `#9CA3AF`, letter-spacing `0.04em`.

**Acceptance criteria:**
- A vertical line drawn through any column passes through both the header text edge AND the data text edge at the same horizontal coordinate.

---

## D3. Decide and lock the case for the "kg" header

**Severity:** Low (consistency polish)
**Where:** Set table → "kg" column header.

**Current behavior:** "Set" and "Reps" are Title Case, "kg" is lowercase. Visually it reads as an oversight.

**Decision (apply this — no debate):**
- **Use `Kg` (Title Case)** in the header for visual consistency with sibling headers.
- The lowercase `kg` convention is correct in body copy where the unit follows a number (e.g. `30 kg`), but in a header label divorced from a number, `Kg` reads cleaner alongside `Set` and `Reps`.
- Apply globally: any header label gets Title Case; any inline unit annotation following a number stays lowercase (`30 kg`, `8 reps`).

**Acceptance criteria:**
- Table headers: `Set`, `Kg`, `Reps`.
- Subtitle copy unchanged: `Last: 30 kg × 8 reps • 3 sets` (lowercase in context).

---

## D4. Increase row vertical padding to 14dp

**Severity:** Low (mobile ergonomics)
**Where:** Set table → row spacing.

**Current behavior:** Rows feel cramped on mobile.

**Exact fix:**
- Each table row: `paddingTop: 14dp, paddingBottom: 14dp`.
- Minimum row height: 56dp (covers tap targets if rows ever become tappable).
- Inter-row separation by spacing only — **no divider lines** (No-Line rule).

**Acceptance criteria:**
- Adjacent set rows have ~12dp of clear vertical space between text baselines.
- No horizontal divider lines anywhere in the table.

---

# CATEGORY E — TYPOGRAPHY

---

## E1. Use Space Grotesk for high-impact numeric data

**Severity:** Medium (design-system adherence)
**Where:** All large numerics in the set table (`30`, `12`, `10`, `8`) and any large stat numerals on this screen.

**Current behavior:** Large numerics appear to be in Inter (a humanist sans, soft).

**Design-system rule:** "Luminous Engine" specifies Space Grotesk for "high-impact numerical data." Space Grotesk has slightly engineered/futuristic letterforms that read as precise — appropriate for fitness measurements.

**Exact fix:**
- Set table data cells (kg, Reps): Space Grotesk Medium 22sp, color `#FFFFFF`, tabular figures.
- Y-axis labels in chart: Space Grotesk Regular 11sp, color `#9CA3AF`, tabular figures.
- Subtitle numerics like `30 kg × 8 reps • 3 sets`: **keep Inter** here because the numerics are inline with running text — Space Grotesk only for "hero" numerals.
- Body copy and labels: stay on Inter.

**Acceptance criteria:**
- Visual A/B against the previous build shows tighter, more engineered numerics in the set table.
- The same font family is used for all "hero" numerics across the app.

---

## E2. Remove the visible "Time Range" label or demote to a screen-reader-only label

**Severity:** Medium (visual clutter)
**Where:** Chart header row.

**Current behavior:** The row reads `Total Volume (kg)` … `Time Range` … `All Time ▾`. The middle "Time Range" text is muted and crammed between two higher-contrast elements. It is redundant — the "All Time" button already communicates its purpose.

**Exact fix — pick ONE:**

**Option A (preferred):** Delete the visible "Time Range" text node entirely. Add an `accessibilityLabel` / `aria-label` of `"Time range filter"` to the dropdown itself so screen readers still get the context.

**Option B:** If the design lead insists on a visible label, **stack** the label above the dropdown instead of inline. `Time Range` (12sp muted) on top, dropdown below. Don't cram three elements in one row on a narrow mobile screen.

**Acceptance criteria:**
- After the fix, the chart header reads as two visual elements only: `Total Volume (kg)` left, `All Time ▾` right.
- Accessibility label preserved on the dropdown for screen readers.

---

# CATEGORY F — VISUAL POLISH

---

## F1. Apply corner radius to exercise thumbnail images

**Severity:** Low (visual consistency)
**Where:** Exercise card → leading thumbnail image.

**Current behavior:** The thumbnail container has rounded corners, but the underlying image is square with hard corners. There's a visible mismatch.

**Exact fix:**
- Apply `borderRadius: 12dp` to the **image itself** (clip), not just the container.
- Container: optional 1dp ghost border at `rgba(255,255,255,0.04)` (effectively invisible — only present for high-contrast mode); otherwise no border.
- Thumbnail size: 56×56dp.

**Acceptance criteria:**
- Image corners exactly match container corners.
- No visible square-image-inside-rounded-container effect.

---

## F2. Reconsider stacked full-width Start + Edit buttons

**Severity:** Medium (layout efficiency)
**Where:** Top of the routine detail screen — primary + secondary CTAs.

**Current behavior:** Two full-width pill buttons stacked vertically eat a large vertical band above the chart. The chart is pushed down and the first fold of the screen feels button-heavy.

**Exact fix — pick ONE pattern:**

**Option A (preferred — visual hierarchy):**
- "Start Routine" stays full-width filled purple.
- "Edit Routine" becomes a smaller secondary tonal button, **right-aligned and ~40% width**, sitting below the Start button. The remaining left space contains a thin metadata strip: e.g. last performed date or total time estimate.

**Option B (most space-efficient):**
- "Start Routine" stays as the only full-width primary.
- "Edit" moves to a text button in the **AppBar trailing area**, next to the three-dot menu. Tap target 48dp.

**Option C (status quo, only if A and B are rejected):**
- Keep both stacked full-width but reduce button height to `52dp` (currently appears ~64dp). Reduce inter-button gap to `8dp`. Avoids dominating the fold.

**Acceptance criteria:**
- The chart is visible without scrolling on a 360×640dp viewport (smallest supported phone).
- "Start Routine" remains unambiguously the primary action regardless of which option is chosen.

---

## F3. Increase chart internal top-padding

**Severity:** Low
**Where:** `TotalVolumeChart` plot area.

**Current behavior:** The Y-axis label region runs flush to the top of the chart, contributing to the A1 collision.

**Exact fix:**
- Internal top padding inside the chart container: `24dp`.
- Internal left padding (reserved for Y-axis labels): `40dp` to accommodate 4-digit numbers (`2500`) without truncation.
- Internal bottom padding (X-axis labels): `28dp`.
- Internal right padding: `12dp`.

**Acceptance criteria:**
- The topmost gridline label has 12dp+ clear space above it.
- Y-axis labels are never clipped on the left edge.

---

# CATEGORY G — INFORMATION-ARCHITECTURE ADDITIONS

Take this screen from functional to motivating. Optional but high-leverage.

---

## G1. Add a "Volume delta since first session" callout

**Severity:** Low (delight / motivation)
**Where:** Below the chart, above the exercise list.

**Current behavior:** No motivational layer. The user has clearly progressed — first session 518 kg, latest session ~2000+ kg — but the UI doesn't surface this win.

**Exact fix:**
- Render a compact pill or small card:
  - Icon: trending-up, purple.
  - Label: `Volume up 295% since May 23` (or `Best session: 2,047 kg on Jun 6`).
- Compute delta as `(latestVolume - firstVolume) / firstVolume * 100`, rounded to nearest integer.
- If delta is negative, show in muted color, label: `Volume down 12% since {date}` — no shame, just data.
- If only one session exists, hide the pill.

**Acceptance criteria:**
- Pill renders only when ≥ 2 sessions exist.
- Tap on pill opens a more detailed progress view (optional; if not built, pill is read-only).

---

## G2. Three-dot menu tap target

**Severity:** Low (accessibility)
**Where:** AppBar trailing three-dot menu.

**Current behavior:** Icon-only button; tap target may be smaller than WCAG 2.5.5's 44×44pt minimum.

**Exact fix:**
- Wrap the icon in a `44×44dp` minimum touch area (`IconButton` with `padding: 12dp` around a 20dp icon).
- Hit slop expanded to ensure edge-of-screen tap reliability.

**Acceptance criteria:**
- Tap target ≥ 44×44dp on all densities.
- Visual icon remains 20dp — only the hit area grows.

---

# FINAL CHECKLIST (run before declaring done)

- [ ] A1 — Y-axis top labels no longer collide.
- [ ] A2 — No duplicate X-axis labels.
- [ ] A3 — Chart uses linear interpolation, not splines.
- [ ] A4 — Y-axis starts at 0.
- [ ] A5 — Gridlines visible through the area fill.
- [ ] B1 — Edit Routine button has no border.
- [ ] B2 — All Time dropdown has no border.
- [ ] B3 — Edit Routine text is medium weight, not bold.
- [ ] C1 — AppBar subtitle restored with exercise count + relative last-performed time.
- [ ] C2 — Set numbers visible alongside type chips.
- [ ] C3 — Warm-up sets appear before working/special sets.
- [ ] C4 — Chip-color discovery affordance present (legend or onboarding).
- [ ] D1 — kg and Reps columns are right-aligned with tabular figures.
- [ ] D2 — Headers align with their column data.
- [ ] D3 — Header reads `Set / Kg / Reps`.
- [ ] D4 — Row vertical padding is 14dp.
- [ ] E1 — Space Grotesk applied to hero numerics.
- [ ] E2 — "Time Range" label removed or restructured.
- [ ] F1 — Thumbnail image corners match container corners.
- [ ] F2 — Button stack reduced or restructured.
- [ ] F3 — Chart internal padding restored.
- [ ] G1 — Volume delta callout added (if ≥ 2 sessions).
- [ ] G2 — Three-dot menu tap target ≥ 44dp.

**Target score after all fixes: ≥ 8.5/10 overall.**

---

## Notes for the implementer

- Do NOT modify the literal string `"Custom Routine"` in the AppBar title — it is a user-set value, not a defect.
- When in doubt between two visual options, **fewer lines, more tonal elevation, more breathing room**. The "Luminous Engine" aesthetic is restraint + precision + electric purple as the only loud color.
- Test on a 360dp-wide viewport (smallest supported). If something breaks at 360dp, it will break in production.
- After every category is done, take a screenshot and self-audit against the checklist before moving to the next.
