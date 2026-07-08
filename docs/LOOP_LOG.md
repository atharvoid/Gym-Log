# GymLog — Loop Log

> Running, append-only record: *bug → root cause → the guard that now prevents it.*
>
> Every regression fix must add (a) a failing-first test that reproduces it and
> (b) a one-line entry here. This is the inner→outer hand-off: each session's
> lesson becomes the next session's guardrail.

---

## Format

```
| Date | Bug | Root Cause | Guard Added |
```

---

## Log

| Date | Bug | Root Cause | Guard Added |
|---|---|---|---|
| 2026-06-25 | CI never ran on `remediation/8-phase` — all v2–v9 regressions shipped without any gate firing | `ci.yml` triggered only on `push`/`PR` to `main`; working branches invisible | H1: widened CI triggers to `remediation/**` |
| 2026-06-25 | Agent declared "done" with no mechanical check — green suite said nothing about actual bugs | No local command mirroring CI; "done" was a feeling, not a measurement | H2: `scripts/verify.ps1` — the termination criterion |
| 2026-06-25 | Local `flutter analyze` weaker than CI — agent missed riverpod lint violations until push | `analysis_options.yaml` didn't register `custom_lint` plugin | H3: wired `custom_lint` into `analysis_options.yaml` |
| 2026-06-25 | Every theme/accent/layout regression (v2–v9) invisible to harness — only caught by human | Zero golden/screenshot tests in the suite | H4: added `alchemist` + seed golden test pipeline |
| 2026-06-25 | `AGENTS.md` said "only a default widget test" and "no CI/CD" — both false; agent misinformed | Guides never updated after test suite and CI were built | H5: rewrote `AGENTS.md`, `CLAUDE.md`; deleted wrong `STITCH_DESIGN_SYSTEM.md`; created `DESIGN_NORTH_STAR.md` |
| 2026-06-25 | `CLAUDE.md` said `npm run build && npm test` — for a Flutter app | Boilerplate from a different tool pasted into the repo | H5: replaced with real Flutter commands |
| 2026-06-25 | `STITCH_DESIGN_SYSTEM.md` described a light-mode smart-home app — agents steered 180° wrong | File was for a different product ("The Luminous Engine") | H5: deleted; replaced with `docs/DESIGN_NORTH_STAR.md` |
| 2026-07-08 | GIFs fail to load in small/thumbnail views | `ui.instantiateImageCodec` with `targetWidth` fails on animated GIFs | Decoded animated GIFs at native size in `gifFirstFrameProvider`/`gifLastFrameProvider` |
