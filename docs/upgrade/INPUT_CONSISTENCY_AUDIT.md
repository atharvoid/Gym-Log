# Typing fields — approved correction and source audit

4 October 2026. **Owner approved implementation: “implement it”.**
The original audit and frozen approval renders are retained below. Production
source now implements the shared 10px boxed-input shape and AI heading wrap.
[Actual implemented gallery](renders/input-consistency/README.md).
Local verification passed: format, fatal analysis, custom lint and **2,382 tests**.
[Full verification log](baseline/2026-10-04/input-verify-complete.log).
Pushed CI and updated APK evidence will be recorded against the final commit.
The before-audit APK candidate was `4b3d544c4cd74b30b260c75e1e6d7789abc35b7e`.
The concurrent main checkout starts at `f12e8966` and contains other edits.
Both states have the same corner declarations at all 16 typing sites.
[Read-only inventory with both locations and source hashes](baseline/2026-10-04/input-field-inventory.json).

## Before-audit root cause

This is source styling, not a screenshot or phone-rendering defect.
`DESIGN.md` explicitly specifies “Inputs / Data-entry: 0px”; `AppRadius.input`
in `app_text.dart` is zero, and `buildAppTheme` uses it for default, enabled and
focused input borders. Onboarding name and deletion confirmation additionally
hardcode `BorderRadius.zero`. Other forms override the rule with 10px card
corners, Explore uses a literal 12px, and exercise search uses the 14px button
token. That creates the inconsistency the owner reported.

There are **16 TextField declarations in 13 files**: seven boxed typing sites
with square edges, seven already rounded, and two intentionally unboxed numeric
templates. These are source declarations, not a count of runtime set rows.
No TextFormField, EditableText, CupertinoTextField, SearchBar or SearchAnchor
declarations were found in application source.

## Frozen before inventory and approved treatment

| Typing surface | Current corners | Proposed treatment | Source in lib/ |
|---|---|---|---|
| Onboarding name | Explicit 0px | Shared 10px input token | features/auth/presentation/widgets/onboarding/step_name.dart |
| Exercise search | Button token, 14px | Shared 10px input token | features/exercises/presentation/screens/exercise_selection_screen.dart |
| New exercise name | Input token, 0px | Shared 10px input token | features/exercises/presentation/widgets/create_exercise_dialog.dart |
| Delete-account confirmation | Explicit 0px | Shared 10px; retain destructive red focus | features/profile/presentation/screens/delete_account_screen.dart |
| Feedback topic | Helper uses card token, 10px | Same 10px shape, reference input token | features/profile/presentation/screens/help_feedback_screen.dart |
| Feedback details | Helper uses card token, 10px | Same 10px shape, reference input token | features/profile/presentation/screens/help_feedback_screen.dart |
| AI paste text | Outer 10px container; inner inherited 0px border/fill | Consistent rounded field layers and visible focus | features/routines/presentation/screens/ai_routine_import_screen.dart |
| AI review target/reps text | Card token, 10px | Same 10px shape, reference input token | features/routines/presentation/screens/ai_routine_review_screen.dart |
| AI review routine name | Card token, 10px | Same 10px shape, reference input token | features/routines/presentation/screens/ai_routine_review_screen.dart |
| Explore search | Literal 12px | Shared 10px input token | features/routines/presentation/screens/explore_screen.dart |
| Routine-editor name | Card token, 10px | Same 10px shape, reference input token | features/routines/presentation/screens/routine_editor_screen.dart |
| Training-plan / one-session search | Inherited input token, 0px | Shared 10px input token | features/routines/presentation/widgets/training_launchpad.dart |
| Finish-workout naming | Input token, 0px | Shared 10px input token | features/workout/presentation/widgets/finish_summary_sheet.dart |
| Set weight/reps/time/distance inputs | Explicit no border/fill | Preserve familiar unboxed numeric cells | features/workout/presentation/widgets/set_row.dart, numeric helper |
| Inline duration edit | Explicit no border/fill | Preserve unboxed numeric cell | features/workout/presentation/widgets/set_row.dart, duration field |
| Shared name-edit dialog | Input token, 0px | Shared 10px input token | shared/widgets/ui/app_dialog.dart |

The shared name dialog also covers Profile and Personal details name editing.
New-exercise muscle/equipment selects use the input-radius token and should
match the rounded name field, though they are selection controls rather than
typing fields. Profile uses the input token for nine text-loading skeletons;
decouple those references so this correction preserves the existing placeholders.

## Additional observed defect

The AI paste field declares only `border: InputBorder.none`. Flutter still applies
the theme's explicit enabled/focused borders and filled surface. An outer rounded
container therefore does not guarantee a rounded inner field. The preview checks
the actual resolved InputDecorator, rather than assuming the parent clips it.

The AI paste heading row also overflows horizontally at 390px with 1.6x and 2x
text. The 1.6x captured error is 28 pixels. Its label has no Flexible/Expanded
wrapper beside the Paste button. This failure exists both with the current theme
and with the proposed radius-only theme; changing corners does not fix it.
[Failing layout checks](baseline/2026-10-04/input-radius-extended-red.log) and
[complete runnable fixture archived for the implementation pass](baseline/2026-10-04/input-radius-extended-red.dart.txt).

## Three refinements considered

| Direction | Decision | Weakness |
|---|---|---|
| One 10px boxed-input radius | Recommended; already used by forms and cards, fits existing nested surfaces | Exercise search changes from 14px and Explore from 12px; requires checking local overrides and all border states |
| One 14px radius matching buttons exactly | Rejected in favour of the established 10px form language | Makes inputs resemble CTA geometry more closely and changes more existing rounded forms |
| Round only search fields; retain the other input styles | Rejected; does not address the owner's whole-app typing concern | Names, workout naming, confirmation and paste fields remain inconsistent |

On approval, update DESIGN.md and the input token together; remove explicit
zero-radius overrides, standardize rounded overrides on the input token, and
keep default/enabled/focused/disabled/error/focused-error corners consistent.
Preserve each field's colours, text styles, validation, formatters, controllers,
keyboard actions, sizes and save/edit callbacks. Retain unboxed workout cells.
Wrap the AI paste heading while keeping its Paste action accessible.

## One implemented-style visual proposal

These are production Flutter screens, real bundled fonts and actual theme
components, using synthetic data. A **review-only theme override** changes the
three existing input-border radii from 0 to 10; no app source was edited.
Every capture includes an illustrative keyboard with a real 280px view inset.
The searched result is scrolled into view using the existing chooser path.

- [Before / proposed, 1x](renders/input-consistency/chooser-higgsfield-1.0x-comparison.png)
- [1.6x](renders/input-consistency/chooser-higgsfield-1.6x-comparison.png)
- [2x](renders/input-consistency/chooser-higgsfield-2.0x-comparison.png)
- [AI paste, 1x](renders/input-consistency/ai-paste-higgsfield-1.0x-comparison.png)

The comparison boards preserve exact captured pixels without resizing or
changing the screen content. Sixteen bounded preview checks pass: chooser at
1x/1.6x/2x, AI paste at 1x, two palettes, before/proposed.
[Preview log](baseline/2026-10-04/input-radius-preview-green.log).
The extended 24-case run passes 16 and fails eight AI large-text checks (four
baseline states and the same four radius-only proposal states). Those failures
are preserved; AI large-text layout is **not qualified** by the passing preview.

Static analysis of the new review fixture could not be confirmed: the local
Analysis Server failed during shutdown deleting its Windows Dart/perf entry
(OS error 1920). This is not recorded as an analysis pass. Compilation/render
checks succeed. No production fix, new commit, pushed CI or updated APK is
claimed for this audit. The earlier candidate's CI remains tied to 4b3d544c.

Three remaining limitations: this preview demonstrates two representative
surfaces rather than every form; the AI large-text defect still needs its
source fix; the actual keyboard, touch and focus behaviour needs a phone.
After approval, verify the actual changed surfaces in all six palettes, including
idle/focus/error/disabled states, and run verify.ps1 before any commit.

Haptics, timer feel and one-handed use: **unverified, needs device**. Native
keyboard and screen-reader use: **unverified, needs device**. Stash 907fe399
and concurrent main-checkout app edits remain untouched. The withdrawn active
workout redesign remains outside this correction.

Owner decision received: **“implement it”**. The 10px boxed-input treatment and
AI paste heading wrap are approved. The preceding preview-only limitations
describe the historical audit; final implementation evidence follows below.
No new whole-section score or acceptance is claimed.

## Implementation evidence

All 14 boxed typing declarations now resolve to the 10px input role; both
unboxed workout numeric templates are unchanged. Adjacent exercise selectors
follow the same token. Nine Profile text-loading skeletons now keep explicit
zero-radius ends, decoupled from the input role. DESIGN.md records the approved
change. No controllers, formatting, validation, keyboard actions or save paths
were changed. The shared theme retains its existing colours and border widths;
Flutter fallback error/disabled borders inherit the rounded base shape.

[Final source inventory](baseline/2026-10-04/input-field-final-inventory.json).
[Failing-first 28px heading regression](baseline/2026-10-04/input-implementation-red.log).
The source fix wraps the heading with Expanded beside the existing Paste action.
Real production chooser/AI paste checks pass at 1x, 1.6x and 2x in all six
palettes; idle/disabled/error/focused-error goldens also pass in each palette.
The actual forms/dialogs cover all 14 boxed declarations in the same six
palettes. Together these are **114 new real-font golden checks**, all with an
illustrative keyboard and a real 280px view inset. They preserve typed values;
the AI paste provider retains the entered text and Paste remains accessible.

Three remaining weaknesses: most secondary forms are captured at 1x; the AI
multiline field is tall at 2x and uses scrolling with the keyboard; native
keyboard focus, touch comfort and reach remain unverified. Proposed scoped
visual score: **8/10**, based on consistent field geometry, preserved richness
and six-palette render checks. This is a self-assessment of this correction,
not a whole-app score or owner/device acceptance. Existing independent Home
8.0/10 and Library 7.8/10 verdicts remain unchanged.

Haptics, timer feel and one-handed use: **unverified, needs device**. Native
keyboard and screen-reader use: **unverified, needs device**.

The full regression run also identified **126** old-shape golden failures, all
golden comparisons, across naming/rename and chooser save/recovery states.
The focused refresh passes all 126 checks. Across the complete **210**
refreshed pre-existing goldens, dimensions are unchanged; the largest difference
contains 873 pixels and the tallest difference bounding box is 77 logical
pixels. Representative before/after inspection shows the intended field-corner
change. [Complete comparison inventory](baseline/2026-10-04/input-existing-golden-diff-inventory.json).
[Focused refresh log](baseline/2026-10-04/input-existing-form-goldens.log).

Final local `scripts/verify.ps1` exits 0: 379 Dart files checked with zero format
changes, fatal analysis clean, custom lint clean, **2,382 tests passing**.
No schema/provider/model change required code generation. Updated APK and
pushed CI are pending in this committed validation record.
