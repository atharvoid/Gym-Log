# Roadmap — GymLog

---

## Legacy ATOMIC remediation (committed before canonical UX-95 program)

The 15-phase ATOMIC plan below was executed and committed on `fix-sha1-auth-issue`
prior to the canonical UX-95 program. These phases addressed the 50-section
audit but do **not** satisfy the UX-95 acceptance criteria.

### Phase 1 — Measurement Model Foundation (P0-01)
| | |
|---|---|
| **Goal** | Add `repsOnly` as 4th measurement type, sealed rest-preference state, DB migration |
| **Key files** | `lib/core/database/`, `lib/features/workout/`, `lib/shared/models/` |
| **Status** | ✅ Complete |

### Phase 2 — Compact Rest Timer UI
| | |
|---|---|
| **Goal** | Compact rest sheet with expand/collapse, count-up, audio at expiry, background notification |
| **Key files** | `lib/features/workout/widgets/rest_timer/` |
| **Status** | ✅ Complete |

### Phase 3 — Active Workout Visual Reconstruction
| | |
|---|---|
| **Goal** | Dense exercise cards, scrollable exercise name in header, stable expansion, elapsed time display |
| **Key files** | `lib/features/workout/` |
| **Status** | ✅ Complete |

### Phase 4 — Auth Screen First Principles
| | |
|---|---|
| **Goal** | Sign-in screen with calm motion, brand, typing feedback, error recovery |
| **Key files** | `lib/features/auth/` |
| **Status** | ✅ Complete |

### Phase 5 — Reversible Deletion & Exercise Replacement
| | |
|---|---|
| **Goal** | Undo snackbar for set deletion, exercise replacement preserves unsaved sets, last-exercise confirm |
| **Key files** | `lib/features/workout/` |
| **Status** | ✅ Complete |

### Phase 6 — Metric-Aware CSV Import
| | |
|---|---|
| **Goal** | Import accepts metric column, decimal weights, reps-only rows |
| **Key files** | `lib/features/import_export/` |
| **Status** | ✅ Complete |

### Phase 7 — Metric-Aware CSV Export
| | |
|---|---|
| **Goal** | Export includes metric column, backwards-compatible header |
| **Key files** | `lib/features/import_export/` |
| **Status** | ✅ Complete |

### Phase 8 — Metric-Aware History, Analytics & PRs
| | |
|---|---|
| **Goal** | Per-measurement-type PRs, history charts, weekly display |
| **Key files** | `lib/features/dashboard/`, `lib/features/history/` |
| **Status** | ✅ Complete |

### Phase 9 — Premium Entitlement Integrity
| | |
|---|---|
| **Goal** | Strict entitlement ID check, degraded gracefully, offline cache |
| **Key files** | `lib/features/premium/`, `lib/core/config/` |
| **Status** | ✅ Complete |

### Phase 10 — Sync Resilience (Quarantine + Monotonic Versions)
| | |
|---|---|
| **Goal** | Corrupt payload quarantine, monotonic revision conflict resolution |
| **Key files** | `lib/features/sync/` |
| **Status** | ✅ Complete |

### Phase 11 — Account Isolation
| | |
|---|---|
| **Goal** | Sign-out purges old subscriptions, scoped sync queries, clean account switch |
| **Key files** | `lib/features/auth/`, `lib/features/sync/` |
| **Status** | ✅ Complete |

### Phase 12 — Bounded Media Cache & Nonblocking Startup
| | |
|---|---|
| **Goal** | LRU exercise media cache (max 50), deferred media loading |
| **Key files** | `lib/features/exercises/`, `lib/core/cache/` |
| **Status** | ✅ Complete |

### Phase 13 — Accessibility Core Journey & Charts
| | |
|---|---|
| **Goal** | 48×48 tap targets, text scale, screen reader workout flow, chart semantics |
| **Key files** | `lib/features/workout/`, `lib/features/dashboard/`, `lib/shared/widgets/` |
| **Status** | ✅ Complete |

### Phase 14 — Documentation & Support Metadata
| | |
|---|---|
| **Goal** | Canonical docs/, AGENTS.md truth, release verification document |
| **Key files** | `docs/`, `AGENTS.md` |
| **Status** | ✅ Complete |

### Phase 15 — Release Certification
| | |
|---|---|
| **Goal** | Signed artifacts, Sentry symbols, store submission, physical device testing |
| **Key files** | `android/`, `ios/`, `.github/workflows/` |
| **Status** | 🟡 Gap checklist created; not complete |

### Legacy Dependency Graph

```
 1 (measurement) ──┬── 6 (import) ── 7 (export)
                    ├── 8 (history/PRs)
                    └── 2 (rest timer)
 3 (workout UI) ──── 5 (deletion)
 4 (auth UI)    ──┬─ 13 (accessibility)
 3 (workout UI) ──┘
 9 (premium)     (independent)
10 (sync)        (independent)
11 (isolation)   (independent)
12 (media cache) (independent)
14 (docs)        (independent)
 1–14 ───────────── 15 (release)
```

### Legacy Sequencing

| Wave | Phases | Status |
|------|--------|--------|
| Wave 1 (independent) | 1, 3, 4, 9, 10, 11, 12, 14 | ✅ All done |
| Wave 2 (depends on 1) | 2, 6, 7, 8 | ✅ All done |
| Wave 3 (depends on 3) | 5 | ✅ Done |
| Wave 4 (depends on 3,4) | 13 | ✅ Done |
| Wave 5 (depends on all) | 15 | 🟡 Partial |

---

## Canonical UX-95 Program

HEAD `57e7888` on `fix-sha1-auth-issue` delivers:

- **UX-95-01 implementation** (dynamic shell/navigation reconstruction)
- **UX-95-02 source implementation** (adaptive/large-text header reflow for active workout)
- Cross-app dynamic color-token migration
- Partial Help/recovery hardening

The commit numbering does **not** reflect the canonical Notion specification.

| Phase | Description | Status |
|-------|-------------|--------|
| UX-95-01 | Dynamic shell and bottom-navigation reconstruction | **Implementation complete; visual/device acceptance pending** |
| UX-95-02 | Adaptive layout and large-text foundation | **Source implementation complete; physical-device and CI acceptance pending** |
| UX-95-03 | Measurement-aware presentation architecture | **Open** |
| UX-95-04 | Active-workout final density and timer reconstruction | **Open** |
| UX-95-05 | Routine and exercise authoring reconstruction | **Open** |
| UX-95-06 | Help, resume, error, and database-recovery safety | **Open** |
| UX-95-07 | Settings and Profile information architecture | **Open** |
| UX-95-08 | Splash and onboarding time-to-value | **Open** |
| UX-95-09 | Paywall, billing truth, and purchase accessibility | **Open** |
| UX-95-10 | Whole-app accessibility and keyboard qualification | **Open** |
| UX-95-11 | Motion, rendering, and performance budget | **Open** |
| UX-95-12 | Design-system consolidation and visual consistency | **Open** |
| UX-95-13 | Exact-SHA full-screen visual certification | **Open** |
| UX-95-14 | Store, billing, monitoring, and release certification | **Open** |

---

## Next Execution

Capture acceptance evidence for **UX-95-02**:
- Physical-device acceptance at 1.0×, 1.6× and 2.0× text scales
- Gesture and three-button navigation
- Rest timer visibility alongside reflowed header
- BillingClient dependency resolves to API 8+
- Android native build passes after RevenueCat and edge-to-edge changes
- Obtain a CI-equivalent result (CI only triggers on `main` and `remediation/**`)

*Last updated: 2026-07-23*
