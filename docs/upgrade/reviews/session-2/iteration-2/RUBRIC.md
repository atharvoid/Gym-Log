# DELT independent critique rubric

Judge the candidate from the provided before/after renders and diff. Be adversarial: actively seek unclear priorities, lost capabilities, misleading information, unreadable states, and changes that look polished but worsen the task. Judge the section's purpose, not the quantity of decoration.

## Scoring

Score each dimension out of 10, with equal weight; report the arithmetic mean to one decimal place as the section score. Also score affected micro elements separately where they reveal a material issue. Do not infer user validation or native behavior from screenshots.

| Dimension | What to inspect |
|---|---|
| Task hierarchy and flow | Is the intended next action obvious? Does the ordering suit the task? Are recurring actions easy to reach and existing capabilities preserved? |
| Information truth and usefulness | Are units, estimates, comparison periods, statuses, and labels accurate? Does the screen explain the meaning of the result without inventing personalization or fitness claims? |
| Legibility and adaptive presentation | Are meaningful labels and editable values readable? Do evidenced narrow/large-text states avoid collisions, clipping, and lost context? Check semantics and interaction constraints visible in the diff. |
| Composition and visual identity | Does scale, spacing, alignment, containment, and accent create a clear focal point and coherent DELT identity? Are supporting elements quieter and useful? |
| State clarity and feedback | Are current, editable, ready, committed, saving, saved, empty, and error states distinguishable where relevant? Is feedback proportionate to the actual event? |

Anchors: 3 = major experience gap; 5 = serviceable but ordinary; 7 = coherent and useful; 8 = clearly strong with specific observable improvements; 9 = exceptional craft across the evidenced states; 10 = exceptional with convincing real-user validation. With renders and diff alone, real-user validation is unverified.

**Every score above 7, including each dimension and micro score, requires specific evidence.** Name the render and visible element or exact diff hunk/line, explain why it exceeds coherent baseline quality, and state any unverified behavior. Generic praise is insufficient. Missing evidence is unknown, not a pass.

For each section, compare before and after explicitly. Prioritize findings by consequence: blocking task/data failure; major confusion or legibility regression; minor polish. Do not hide a material defect behind a high average. Separate defects established by the evidence from hypotheses needing device or user testing.

## Required verdict

1. Section and candidate identifier from the supplied diff/filenames.
2. Before/after assessment with the five dimension scores and section mean.
3. Specific justification for every score above 7.
4. Material findings, with render element or diff references and practical consequences.
5. Regressions and missing state coverage.
6. Verdict: Pass or Revision needed. Pass means no unresolved material defect in the supplied evidence; it does not certify tests, CI, devices, or release readiness.
7. Smallest corrective changes and remaining unknowns.
