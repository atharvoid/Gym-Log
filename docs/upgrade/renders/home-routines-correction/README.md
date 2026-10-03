# Home and Routines — implemented correction

The owner approved the visual direction on 4 October 2026. These are real production Flutter widgets from the committed-baseline correction branch, with synthetic workout data and bundled fonts. The earlier approval prototype is preserved in [APPROVAL_PREVIEW.md](APPROVAL_PREVIEW.md).

- [Home before/after](implemented-home-comparison-1.0x.png), [1.6x](implemented-home-comparison-1.6x.png), [2x](implemented-home-comparison-2.0x.png)
- [Library before/after](implemented-library-comparison-1.0x.png), [1.6x](implemented-library-comparison-1.6x.png), [2x](implemented-library-comparison-2.0x.png)
- [Plan with keyboard at 2x](final/home-plan-keyboard-higgsfield-2.0x.png), [one-session override with keyboard](final/home-override-keyboard-higgsfield-2.0x.png)
- [Explicit repeat mode](final/home-plan-repeat-higgsfield-1.0x.png), [empty Home](final/home-empty-higgsfield-2.0x.png), [empty chooser](final/home-plan-empty-higgsfield-2.0x.png)
- [Long identity and visible Start](final/home-long-name-higgsfield-2.0x.png), [actual next Library card](final/library-view-next-higgsfield-2.0x.png), [plan recovery](final/library-plan-error-higgsfield-2.0x.png)
- [320px Home](final/home-narrow-ready-higgsfield-2.0x.png), [320px Library](final/library-narrow-ready-higgsfield-2.0x.png)
- [Last-workout read failure](final/home-last-error-higgsfield-2.0x.png), [older completion year](final/home-last-older-higgsfield-2.0x.png)

The comparison tiles retain their exact source pixels without resizing. Final acceptance goldens cover all six palettes; frozen reviewer packets preserve their own before/after evidence. The keyboard graphic is illustrative, with a real viewInset used for layout.

Haptics, timer feel and one-handed use: **unverified, needs device**. Native keyboard and screen-reader use: **unverified, needs device**. The rejected active-workout redesign remains withdrawn.

Final commitment states: [saved repeat](final/home-repeat-committed-higgsfield-2.0x.png),
[canceled mode and reopening](final/home-repeat-canceled-higgsfield-2.0x.png),
[pending save](final/home-plan-saving-higgsfield-2.0x.png),
[failed save](final/home-plan-save-error-higgsfield-2.0x.png), and
[empty next day](final/home-empty-next-higgsfield-2.0x.png).
