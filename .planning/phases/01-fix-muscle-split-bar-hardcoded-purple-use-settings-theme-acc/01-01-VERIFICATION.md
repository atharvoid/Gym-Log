---
phase: 01-fix-muscle-split-bar-hardcoded-purple-use-settings-theme-acc
slug: fix-muscle-split-bar-hardcoded-purple-use-settings-theme-acc
verified: 2026-08-09T16:20:00Z
status: human_needed
score: 6/6 truths verified
behavior_unverified: 0
overrides_applied: 0
human_verification:
  - test: "On a physical device: Settings → Appearance → switch the accent palette (default Volt/higgsfield) → open the 'Pull Day' routine → confirm the muscle split bar legend dots and stacked segments render in the newly selected accent, not the legacy purple."
    expected: "The bar repaints with the selected settings accent (e.g. neonPurple) immediately after the palette switch, matching the rest of the themed UI; no purple remnant visible."
    why_human: "Color perception and OLED rendering of the ThemeExtension-driven repaint are only conclusively judgeable on real hardware; automated tests prove the color values, not the perceptual result."
---

# Phase 1: Fix muscle split bar hardcoded purple; use settings theme accent — Verification Report

**Phase Goal:** Routine-detail muscle split bar renders with the user's selected settings accent palette (reactive `context.accent` ramp), replacing the hardcoded static purple ramp.
**Verified:** 2026-08-09
**Status:** human_needed (all automated truths VERIFIED; 1 device-UAT item remains)
**Re-verification:** No — initial verification

## Goal Achievement

Goal reached in code: `MuscleLoadBar` reads `context.accent.muscleSplitRamp` (live ThemeExtension) instead of `AppColors.muscleSplitPalette`. Independently re-run: 5 accent widget tests green, 2 golden variants (windows + ci) green with zero diffs, and the full `.\scripts\verify.ps1` gate green end-to-end (571 tests). Live grep: no `muscleSplitPalette`/`0xFF7F00FF`/`AppColors.` remains in the bar; the only `lib/` consumers of the static palette are `app_colors.dart` (definition) + `muscle_color_service.dart` (backward-compat fallbacks), exactly as planned.

### Observable Truths

| #   | Truth   | Status     | Evidence       |
| --- | ------- | ---------- | -------------- |
| 1 | Muscle split bar legend dot colors equal the active ramp for the default palette (Volt/higgsfield) | ✓ VERIFIED | `test/muscle_load_bar_accent_test.dart:44-52` asserts equality vs `ThemePalette.higgsfield.tokens.muscleSplitRamp[0..2]`; targeted run passed (5/5) |
| 2 | Legend dot colors equal the active ramp under neonPurple | ✓ VERIFIED | `test/muscle_load_bar_accent_test.dart:54-61`; passed in targeted run; source reads `context.accent.muscleSplitRamp` (`muscle_load_bar.dart:50`) |
| 3 | No hardcoded purple literal (`0xFF7F00FF`) remains in `muscle_load_bar.dart` | ✓ VERIFIED | Grep: zero hits for `0xFF7F00FF`/`0xff7f00ff`/`AppColors\.`/`muscleSplitPalette` in the file; regression test (`neonPurple legacy purple`) passed |
| 4 | Pixel golden baseline of the bar exists for all 6 palettes and passes cleanly | ✓ VERIFIED | `muscle_load_bar_golden_test.dart` uses `allThemes`Group (6 scenarios); baselines exist at 17,245 B (`windows/`) + 5,453 B (`ci/`); plain run (no `--update-goldens`) passed both variants |
| 5 | `scripts/verify.ps1` passes end-to-end (format, analyze --fatal-infos --fatal-warnings, custom_lint, flutter test) | ✓ VERIFIED | I ran `.\scripts\verify.ps1` myself: exit 0, "verify passed", 571 tests passed |
| 6 | `verify.ps1` migrated-screen gate includes `muscle_load_bar.dart` and still passes | ✓ VERIFIED | `verify.ps1:45` lists `lib/shared/widgets/body/muscle_load_bar.dart` in `$migratedFiles` and the full gate run above passed with it |

**Score:** 6/6 truths verified (0 present-but-behavior-unverified).

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `lib/shared/widgets/body/muscle_load_bar.dart` | accent-driven; static palette constant removed | ✓ VERIFIED | 204 lines; `final palette = context.accent.muscleSplitRamp;` (line 50); `app_colors.dart` import kept for `context.surface` (lines 47, 111, 147); wired in production at `routine_detail_screen.dart:586` |
| `test/muscle_load_bar_accent_test.dart` | new, passing | ✓ VERIFIED | 5 tests: higgsfield ramp, neonPurple ramp, no legacy-purple literal, 8-entry clamp (+5 overflow), empty→SizedBox.shrink |
| `test/golden/muscle_load_bar_golden_test.dart` | new, passing | ✓ VERIFIED | alchemist `goldenTest`, `fileName: 'muscle_load_bar_all_themes'`, renders all 6 palettes |
| `test/golden/goldens/windows/muscle_load_bar_all_themes.png` | baseline | ✓ VERIFIED | 17,245 B |
| `test/golden/goldens/ci/muscle_load_bar_all_themes.png` | mirrored baseline | ✓ VERIFIED | 5,453 B |
| `scripts/verify.ps1` | `muscle_load_bar.dart` in migrated list | ✓ VERIFIED | `$migratedFiles` at line 45; non-semantic AppColors gate passed in full run |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `muscle_load_bar.dart` | `context.accent` ThemeExtension | `context.accent.muscleSplitRamp` read in `build()` | WIRED | line 50; same extension that sibling `muscle_split_section.dart:21` uses (`ramp: context.accent.muscleSplitRamp`) |
| `muscle_load_bar.dart` | `app_colors.dart` | `context.surface` (`SurfaceContextX`) | WIRED | import retained (line 3); `context.surface` used at lines 47/147; zero `AppColors.` usages (gate-clean) |
| golden baselines | post-fix colors | generated after `5541ea9` (fix) — commit `e29bb31` (golden) ordered after it; baselines pass against current accent-driven code | WIRED | git log: `52fea9 → 5541ea9 → … → e29bb31`, and plain golden run zero diff |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Accent test suite (higgsfield/neonPurple ramp, legacy-purple pin, clamp, employee-empty) | `flutter test test/muscle_load_bar_accent_test.dart` | All passed | ✓ PASS |
| Golden renders all 6 palettes, zero diff | `flutter test test/golden/muscle_load_bar_golden_test.dart` | +2 (Windows + CI) passed | ✓ PASS |
| Full repo gate (format/analyze/custom_lint/571 tests) | `.\scripts\verify.ps1` | In line with verify passed; 571 tests | ✓ PASS |

### Probe Execution

No declared probes for this phase (plan uses targeted tests + verify.ps1 = the probes); both executed successfully.

### Requirements Coverage

| Requirement | Description (VALIDATION.md) | Status | Evidence |
| ----------- | --------------------------- | ------ | -------- |
| PH-1 | Bar follows selected accent (reroute to `context.accent`) | ✓ SATISFIED | source line 50; passing widget tests 1-2; device UAT pending |
| PH-2 | 6-accent pixel golden baseline | ✓ SATISFIED | `allThemes`Group golden + baselines in windows/ and ci/, passing |
| PH-3 | Verify suite green + gate hardened | ✓ SATISFIED | `verify.ps1` exit 0 (571 tests); `$migratedFiles` includes the bar path |

All 3 required IDs claimed by PLAN (`requirements: [PH-1, PH-2, PH-3]`) are accounted for.

### Anti-Patterns Found

None. TBD/FIXME/XXX/placeholder scan of modified files: zero hits.

### Human Verification Required

| Test | Expected | Why human |
| ---- | -------- | --------- |
| Device: Settings → Appearance → switch palette → open "Pull Day" routine → check bar follows accent (default Volt) | Bar segments + legend dots repaint in the newly selected accent, visible immediately | Color perception / OLED contrast only conclusively judged on hardware; widget tests prove values, not perceptual parity |

### Gaps Summary

No gaps. All static, key-link, artifact, and behavioral checks passed; the only open item is the physical-device UAT above, which the plan explicitly deferred as manual and not phase-gating.

---

_Verified: 2026-08-09_
_Verifier: the agent (gsd-verifier)_