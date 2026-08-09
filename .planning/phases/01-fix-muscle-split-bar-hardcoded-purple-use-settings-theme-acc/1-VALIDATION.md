---
phase: 1
slug: fix-muscle-split-bar-hardcoded-purple-use-settings-theme-acc
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-09
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (Dart) + golden_toolkit/alchemist (goldens) |
| **Config file** | `pubspec.yaml` (dev_dependencies) |
| **Quick run command** | `flutter test test/muscle_load_bar_accent_test.dart test/golden/muscle_load_bar_golden_test.dart` |
| **Full suite command** | `.\scripts\verify.ps1` (format → analyze --fatal-infos --fatal-warnings → custom_lint → flutter test) |
| **Estimated runtime** | ~90 seconds (full verify; quick ~10s) |

---

## Sampling Rate

- **After every task commit:** Run quick test command (targeted new tests)
- **After every plan wave:** Run `flutter test` full suite
- **Before `/gsd-verify-work`:** `.\scripts\verify.ps1` must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Wave | Requirement | Threat Ref | Test Type | Automated Command | File Exists | Status |
|---------|------|-------------|------------|-----------|-------------------|-------------|--------|
| 1-01-01 | 1 | PH-1 (reroute to context.accent) | — | widget | `flutter test test/muscle_load_bar_accent_test.dart` | ❌ W0 | ⬜ pending |
| 1-01-02 | 1 | PH-2 (6-palette golden) | — | golden | `flutter test test/golden/muscle_load_bar_golden_test.dart` | ❌ W0 | ⬜ pending |
| 1-01-03 | 1 | PH-3 (verify suite green) | — | CI gate | `.\scripts\verify.ps1` | n/a | ⬜ pending |

---

## Wave 0 Requirements

- [ ] `test/muscle_load_bar_accent_test.dart` — widget test asserting legend/segment colors equal `context.accent.muscleSplitRamp` and no `0xFF7F00FF` literal remains
- [ ] `test/golden/muscle_load_bar_golden_test.dart` — alchemy golden across all 6 accent palettes
- [ ] Existing infrastructure (flutter_test, golden_stoolkit) already installed — no new framework

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual bar color matches chosen accent palette on device | PH-1 | Color perception + OLED contrast best judged on hardware | Open "Pull Day" routine → verify muscle split bar uses settings-selected accent (default Volt) |

---

## Validation Sign-Off

- [ ] All tasks have automated verify in Wave 1 (no 3 consecutive tasks without automated verify)
- [ ] Wave 0 covers all missing test references
- [ ] No watch-mode flags
- [ ] Full suite latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending