# Session 1 composed contrast evaluation

Scope: all live textTertiary uses and chart-axis aliases, on the six selectable OLED palettes. Source inventory: [all call sites with context](baseline/2026-10-02/session-1-tertiary-source-inventory.txt). The inventory includes token definitions, defaults and decorative icons; these are not counted as separate text surfaces. No caller replaces the tertiary alpha with a lower alpha.

Measurement: sRGB relative luminance after foreground alpha composition, (lighter + 0.05)/(darker + 0.05). The widget tests use Flutter Color.alphaBlend and computeLuminance; the table independently calculates the same composition. Minima cover base, all four raised surfaces, both card-gradient endpoints, accent-muted on surface3, accent-glow on surface2, completed-row success tint and warm-up warning tint on surface3. Normal meaningful text must reach 4.5:1.

| Palette | Previous tertiary minimum | New tertiary minimum | onAccent/base |
|---|---:|---:|---:|
| Volt | 2.841 | 5.317 | 16.743 |
| Purple | 2.976 | 5.774 | 4.517 |
| White | 2.829 | 5.250 | 17.576 |
| Cyan | 2.886 | 5.508 | 14.055 |
| Magenta | 2.976 | 5.774 | 5.164 |
| Orange | 2.976 | 5.774 | 6.743 |

Purple previously reached 4.393:1. Its base shifts from #BF00FF to #C400FF; blue, saturation and the light/dark companions stay the same. Muted/glow and the first muscle ramp step follow its revised base.

Role evaluation:

- Chart ticks, date captions, graph empty/low-data labels, routine analytics legends: dark chart/card/base backings; chartAxisLabel and profileGraphAxisLabel now alias tertiary.
- Search, exercise/routine naming, set-entry ghost values, dialog hints, import prompt and name counters: input surface3 or base; completed/warm-up set rows include their semantic tints in the tested bound.
- Reassurance, local-processing/privacy, help, paywall and custom-exercise notes: base or raised sheet/card. Readable ink is a visibility qualification, not validation of the underlying claims.
- Catalog/preview micro labels, metadata, muscle summaries, unselected filters and range controls: base/raised cards or subdued accent tints. Enabled text retains the contrast floor; disabled controls require disabled semantics and are not accepted merely by this contrast check.
- Share-card dates, witness metadata and watermark subtitle: base/gradient/raised surfaces. Their small font sizes and existing footer overlap remain separate usability concerns.
- AppText micro/column defaults, theme labelSmall and hintStyle inherit the same tested floor. Icons using tertiary also clear the 3:1 non-text floor on these backings.

Limits: this is a static source/backing evaluation plus real-font render evidence, not a pixel survey of every navigation state. Transient fades, photographic/media backings and future opacity wrappers must be evaluated separately. Ice White remains a dark canvas accent. Unreachable draft light-mode tokens are unqualified. Secondary and tertiary now share a luminance floor; typography and position must preserve hierarchy.

