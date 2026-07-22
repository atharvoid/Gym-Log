# Roadmap — GymLog Release Certification

## Phase 1 — Measurement Model Foundation (P0-01)
| | |
|---|---|
| **Depends on** | — |
| **Dependents** | 6, 7, 8 |
| **Goal** | Add `repsOnly` as 4th measurement type, sealed rest-preference state, DB migration |
| **Key files** | `lib/core/database/`, `lib/features/workout/`, `lib/shared/models/` |
| **Verification** | AC-P001 |

## Phase 2 — Compact Rest Timer UI
| | |
|---|---|
| **Depends on** | 1 |
| **Dependents** | — |
| **Goal** | Compact rest sheet with expand/collapse, count-up, audio at expiry, background notification |
| **Key files** | `lib/features/workout/widgets/rest_timer/` |
| **Verification** | AC-P002 |

## Phase 3 — Active Workout Visual Reconstruction
| | |
|---|---|
| **Depends on** | — |
| **Dependents** | 5, 13 |
| **Goal** | Dense exercise cards, scrollable exercise name in header, stable expansion, elapsed time display |
| **Key files** | `lib/features/workout/` |
| **Verification** | AC-P003 |

## Phase 4 — Auth Screen First Principles
| | |
|---|---|
| **Depends on** | — |
| **Dependents** | 13 |
| **Goal** | Sign-in screen with calm motion, brand, typing feedback, error recovery |
| **Key files** | `lib/features/auth/` |
| **Verification** | AC-P004 |

## Phase 5 — Reversible Deletion & Exercise Replacement
| | |
|---|---|
| **Depends on** | 3 |
| **Dependents** | — |
| **Goal** | Undo snackbar for set deletion, exercise replacement preserves unsaved sets, last-exercise confirm |
| **Key files** | `lib/features/workout/` |
| **Verification** | AC-P005 |

## Phase 6 — Metric-Aware CSV Import
| | |
|---|---|
| **Depends on** | 1 |
| **Dependents** | — |
| **Goal** | Import accepts metric column, decimal weights, reps-only rows |
| **Key files** | `lib/features/import_export/` |
| **Verification** | AC-P006 (import half) |

## Phase 7 — Metric-Aware CSV Export
| | |
|---|---|
| **Depends on** | 1 |
| **Dependents** | — |
| **Goal** | Export includes metric column, backwards-compatible header |
| **Key files** | `lib/features/import_export/` |
| **Verification** | AC-P006 (export half) |

## Phase 8 — Metric-Aware History, Analytics & PRs
| | |
|---|---|
| **Depends on** | 1 |
| **Dependents** | — |
| **Goal** | Per-measurement-type PRs, history charts, weekly display |
| **Key files** | `lib/features/dashboard/`, `lib/features/history/` |
| **Verification** | AC-P007 |

## Phase 9 — Premium Entitlement Integrity
| | |
|---|---|
| **Depends on** | — |
| **Dependents** | — |
| **Goal** | Strict entitlement ID check, degraded gracefully, offline cache |
| **Key files** | `lib/features/premium/`, `lib/core/config/` |
| **Verification** | AC-P008 |

## Phase 10 — Sync Resilience (Quarantine + Monotonic Versions)
| | |
|---|---|
| **Depends on** | — |
| **Dependents** | — |
| **Goal** | Corrupt payload quarantine, monotonic revision conflict resolution |
| **Key files** | `lib/features/sync/` |
| **Verification** | AC-P009 |

## Phase 11 — Account Isolation
| | |
|---|---|
| **Depends on** | — |
| **Dependents** | — |
| **Goal** | Sign-out purges old subscriptions, scoped sync queries, clean account switch |
| **Key files** | `lib/features/auth/`, `lib/features/sync/` |
| **Verification** | AC-P010 |

## Phase 12 — Bounded Media Cache & Nonblocking Startup
| | |
|---|---|
| **Depends on** | — |
| **Dependents** | — |
| **Goal** | LRU exercise media cache (max 50), deferred media loading |
| **Key files** | `lib/features/exercises/`, `lib/core/cache/` |
| **Verification** | AC-P011 |

## Phase 13 — Accessibility Core Journey & Charts
| | |
|---|---|
| **Depends on** | 3, 4 |
| **Dependents** | — |
| **Goal** | 48×48 tap targets, text scale, screen reader workout flow, chart semantics |
| **Key files** | `lib/features/workout/`, `lib/features/dashboard/`, `lib/shared/widgets/` |
| **Verification** | AC-P012, AC-P013 |

## Phase 14 — Documentation & Support Metadata
| | |
|---|---|
| **Depends on** | — |
| **Dependents** | — |
| **Goal** | Canonical docs/, AGENTS.md truth, release verification document |
| **Key files** | `docs/`, `AGENTS.md` |
| **Verification** | AC-P014 |

## Phase 15 — Release Certification
| | |
|---|---|
| **Depends on** | 1–14 |
| **Dependents** | — |
| **Goal** | Signed artifacts, Sentry symbols, store submission, physical device testing |
| **Key files** | `android/`, `ios/`, `.github/workflows/` |
| **Verification** | AC-P015 |

## Dependency Graph

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

## Sequencing Strategy

**Wave 1** (independent): 1, 3, 4, 9, 10, 11, 12, 14 — ✅ all done
**Wave 2** (depends on 1): 2, 6, 7, 8 — ✅ all done
**Wave 3** (depends on 3): 5 — ✅ done
**Wave 4** (depends on 3,4): 13 — ✅ done
**Wave 5** (depends on all): 15 — 🟡 partial (checklist created, gaps documented)

## Status Summary

**Older ATOMIC remediation** (committed before this program): partially addresses related areas but does NOT satisfy the UX-95-01-14 acceptance criteria.

| Phase | Status |
|-------|--------|
| UX-95-01 — Dynamic shell/navigation | pending |
| UX-95-02 — Safe draft recovery | pending |
| UX-95-03 — Adaptive Help report | pending |
| UX-95-04 — Measurement-aware presentation | pending |
| UX-95-05 — Safe catalog parsing | pending |
| UX-95-06 — Large-text/adaptive primitives | pending |
| UX-95-07 — Exact-SHA visual certification | pending |
| UX-95-08 — Store certification | pending |

---
*Corrected 2026-07-22: UX-95-01-14 is a new program, distinct from older ATOMIC remediation*
