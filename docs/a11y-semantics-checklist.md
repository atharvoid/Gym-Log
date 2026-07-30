# Accessibility & semantics checklist

Every rule here comes from a real defect found in this repository during audit
section C30. The offending code is cited in each rule, because a rule with no
corpse attached gets skipped.

Apply this to any widget you add or touch. It is not a separate pass.

> **Nothing in this file has been verified on a device.** There is no Flutter
> SDK in the audit environment. Everything below is derived from reading the
> framework's semantics contract and this codebase. Rules marked **CONFIRM ON
> DEVICE** need a TalkBack/VoiceOver run before anyone claims they are done.

---

## 1. Naming

### 1.1 Never derive an accessible name from a unit

`BrandedLineChart` built its screen-reader summary as `'$yAxisUnit chart'`.
`yAxisUnit` is `'kg'` or `'min'`. A unit is not a metric name, so the chart
announced itself as a "kg chart", and every caller that omitted the parameter
- which was all of them - fell back to the hardcoded "Volume chart", including
Profile's duration and reps charts.

A name says *what this is*. If you find yourself composing one out of a field
that exists for another purpose, add the field you actually need.

### 1.2 A new naming parameter is optional with a neutral fallback

`metricLabel` defaults to `'Chart'`, not to a guess. Two reasons: a required
parameter breaks every call site at once (that mistake cost two non-compiling
commits during X1), and a confident wrong name is worse than a vague right
one. "Chart" tells the user little; "Volume chart" on a duration graph tells
them something false.

### 1.3 A control must keep its name in every state

`PrimaryButton` took its name from the child `Text`, which is **replaced** by a
`CircularProgressIndicator` while `isLoading`. The app's primary CTA therefore
had no accessible name at all in its busy state - announced as "button,
dimmed" - at exactly the moment a blind user needs to know which action is
running.

When a widget swaps its content, name it from the outside, and say what state
it is in: `label: isLoading ? '$label, in progress' : label`.

---

## 2. The wrapper pattern

The single most common defect in this codebase: a `Semantics(label: ...)`
wrapped around a widget that already publishes its own text node. The screen
reader then gets two focus stops per control and reads the name twice. Found in
`TogglePill`, `SegmentedControl`, `ActiveWorkoutBar`, the nav tabs, and the
chart's data-table toggle.

### 2.1 The full wrapper form

```dart
Semantics(
  container: true,        // this is ONE stop in the traversal
  button: true,           // or header/image/textField as appropriate
  label: '...',           // the wrapper owns the name
  enabled: handler != null,
  excludeSemantics: true, // children must not publish duplicate nodes
  onTap: handler,         // MANDATORY - see 2.2
  child: ...,
)
```

### 2.2 `excludeSemantics` and `onTap` travel together

**This rule exists because I broke the nav bar with the commit that was
supposed to fix it.**

`excludeSemantics: true` discards the *entire* child subtree's semantics - and
that includes the tap action published by the `GestureDetector`, `InkWell` or
`ElevatedButton` inside it. The annotation node is left declaring `button: true`
with no action behind it, so it announces correctly and then ignores
TalkBack's double-tap.

If you exclude the subtree, re-declare `onTap` on the wrapper. Taking the
subtree's voice also takes its hands.

### 2.3 One handler, shared by the gesture and the semantics action

```dart
final VoidCallback? handleTap = onTap == null
    ? null
    : () { HapticFeedback.lightImpact(); onTap!(); };
```

Build the handler once and pass the same reference to both the `InkWell` and
the `Semantics`. If the semantics path gets its own inline closure, the two
drift - most often the accessible path silently loses the haptic, so activating
the control with a screen reader feels different from tapping it.

Inside a collection-`for` there is nowhere to hold that local. Extract a
private widget rather than duplicating the closure; that is why `_Segment`
exists in `segmented_control.dart`.

---

## 3. State must be declared honestly

### 3.1 Do not declare `button: true` on something that cannot be activated

`SegmentedControl` passed `onTap: null` to the selected segment's `InkWell`
while still declaring it a button, so a screen reader offered "double tap to
activate" on a control that does nothing. Set `enabled: false` when the handler
is null.

### 3.2 `selected` needs `inMutuallyExclusiveGroup`

For tabs and segmented controls, `inMutuallyExclusiveGroup: true` is what makes
the platform read `selected` as "selected" rather than "checked", and tells the
user these options are a radio set.

### 3.3 Give position in a set

"Home, selected" does not say where you are. Use the platform convention:
`'Home, tab 1 of 3'`. Applied to the nav bar and to segmented controls.

---

## 4. Live regions

### 4.1 Use one for values that change in response to the user

`BrandedLineChart`'s value header is `Semantics(liveRegion: true)`, so scrubbing
the chart announces each newly selected point. Without it, the interaction is
invisible to a screen-reader user: the value changes and nothing is said.

### 4.2 Never use one for a clock

`ActiveWorkoutBar` shows an elapsed timer that ticks once a second. A live
region there would interrupt the user with the running time every second,
forever. The time is a snapshot inside the bar's label instead - read when the
user lands on the bar, which is when they want it.

The test: does this change because the *user* did something, or because time
passed?

---

## 5. Loading and decorative content

### 5.1 Loading states must not be silent - **CONFIRM ON DEVICE**

`skeleton.dart` renders bones as bare `Container`s with no semantics, so the
entire loading state is silent: a screen-reader user hears nothing between
navigating and the content arriving, with no way to tell a slow load from an
empty screen.

The skeleton subtree should be wrapped so it announces the fact of loading once
(and the individual bones excluded), rather than each bone being either silent
or noisy. **Not yet implemented** - booked as C30-F6 for section B22, which
owns loading states.

### 5.2 Purely decorative visuals get `ExcludeSemantics`

Icons that duplicate an adjacent label, gradient bars, pulse dots. If it
carries no information a screen reader can use, exclude it rather than leaving
it to publish an empty node.

---

## 6. Always offer a non-visual path to the data

`BrandedLineChart` ships a "View data table" toggle that renders every point as
`Semantics(container: true, label: 'Date: $date, Value: $value')` under a
container labelled `'Data table, N rows'`.

This is the pattern to copy for any chart. A trend line is not perceivable by a
screen-reader user no matter how good its summary is; the summary conveys shape,
the table conveys the numbers, and both are needed.

---

## 7. Motion and haptics

### 7.1 Honor reduce-motion, and honor it everywhere

Read it with `MediaQuery.disableAnimationsOf(context)`. This codebase is
consistent and should stay that way: chart animation `Duration.zero`, nav
underline instant, `SkeletonPulse` returns its child unanimated, the segmented
highlight jumps instead of sliding, `TogglePill` transitions collapse,
`_ActiveIndicator` becomes a steady dot.

A single animated widget that ignores the setting undoes the work of all the
others for a user with vestibular sensitivity.

### 7.2 The haptic map

Discrete selection -> `HapticFeedback.selectionClick()`. Primary CTA ->
`mediumImpact()`. Pill toggle -> `lightImpact()`. Keep the haptic inside the
shared handler from 2.3 so the accessible path gets it too.

---

## 8. Text scaling - **BLOCKED, do not mark clean**

`app.dart` clamps text scale with `textScaler.clamp(maxScaleFactor: 1.4)`,
which silently caps users who have set 200% in system settings. Raising the
clamp requires first checking every dense surface for overflow at 2.0.

Owned by audit section C31. Until it is resolved, no screen may be scored clean
on text scaling.

---

## Reviewing your own change

1. Walk it with the screen reader off, reading only the semantics you declared.
   Does the announcement identify the control, its state, and what activating
   it does?
2. Count the focus stops. One control should be one stop.
3. For every `excludeSemantics`, find the `onTap`.
4. For every state the widget can be in - loading, disabled, selected, empty -
   confirm it still has a name.
