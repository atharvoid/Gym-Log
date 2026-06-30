# Muscle Map SVG Assets

Extracted from `react-native-body-highlighter` (commit `15df9e2`, MIT License).

## ViewBoxes

| Gender | View | ViewBox |
|--------|------|---------|
| male | front | `0 0 724 1448` |
| male | back | `724 0 724 1448` |
| female | front | `-50 -40 734 1538` |
| female | back | `756 0 774 1448` |

## Slugs per view

### Male Front
chest, obliques, abs, biceps, triceps, neck, trapezius, deltoids, adductors, quadriceps, knees, tibialis, calves, forearm, hands, ankles, feet, head, hair

### Male Back
neck, trapezius, deltoids, upper-back, triceps, lower-back, forearm, gluteal, adductors, hamstring, calves, ankles, feet, hands, head, hair

### Female Front
neck, trapezius, hair, deltoids, head, chest, biceps, triceps, obliques, abs, forearm, hands, adductors, quadriceps, knees, tibialis, calves, ankles, feet

### Female Back
hair, neck, trapezius, deltoids, upper-back, lower-back, triceps, forearm, hands, gluteal, adductors, hamstring, calves, feet

## Usage

Recolor by `id` (CSS or Flutter `ColorFiltered`). No styling is baked in — composites use `fill="currentColor"` on individual parts so they can be tinted at runtime. All parts share the same viewBox as their parent composite so they overlay perfectly.

## Attribution

Original work by ELABBASSI Hicham, MIT License. See `LICENSE-upstream`.
