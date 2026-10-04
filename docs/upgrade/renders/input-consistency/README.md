# Typing fields — implemented approved treatment

Owner approved the 10px boxed-input direction with “implement it”. These are actual production Flutter widgets and the real theme, bundled Inter/Material fonts, synthetic local data and an illustrative keyboard with a real 280px view inset. Frozen before/proposed images are retained separately; after images use production source with no theme override.

- [Before / implemented chooser](chooser-higgsfield-1.0x-implemented-comparison.png), [1.6x](chooser-higgsfield-1.6x-implemented-comparison.png), [2x](chooser-higgsfield-2.0x-implemented-comparison.png)
- [Before / implemented AI paste](ai-paste-higgsfield-1.0x-implemented-comparison.png), [implemented 1.6x](after/ai-paste-higgsfield-1.6x.png), [2x](after/ai-paste-higgsfield-2.0x.png)
- [Forms overview 1](forms-1-overview.png), [overview 2](forms-2-overview.png). Overview thumbnails are scaled; individual after PNGs retain full 2x pixels.
- [Idle / disabled / error / focused error](after/input-states-higgsfield.png), [second palette](after/input-states-neonPurple.png)
- [Onboarding](after/onboarding-name-higgsfield.png), [exercise search](after/exercise-search-higgsfield.png), [new exercise](after/create-exercise-higgsfield.png), [destructive confirmation](after/delete-confirmation-higgsfield.png)
- [Feedback topic](after/feedback-topic-higgsfield.png), [details](after/feedback-details-higgsfield.png), [AI review name](after/review-name-higgsfield.png), [target reps](after/review-reps-higgsfield.png)
- [Explore](after/explore-search-higgsfield.png), [routine editor](after/routine-name-higgsfield.png), [finish naming](after/finish-name-higgsfield.png), [shared name editing](after/shared-name-higgsfield.png)

All 14 boxed declarations have real-component goldens in all six palettes. Chooser and AI paste also cover 1.6x and 2x. Core border-state goldens cover idle, disabled, error and focused error. Dense workout numeric cells remain unboxed and Profile text-loading bars retain their original geometry.

Remaining weaknesses: secondary forms have 1x capture coverage; the AI multiline field is tall and scrolls at large text with an open keyboard; native focus and reach need a phone. Haptics, timer feel and one-handed use: **unverified, needs device**. Native keyboard and screen-reader use: **unverified, needs device**.
