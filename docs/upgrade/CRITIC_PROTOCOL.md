# Fresh-context critic protocol

The user requires an independent critic that has never seen the builder's reasoning. This protocol is for the coordinator/builder; it is not part of the critic's evidence packet.

## Isolation

- Start a new critic for each candidate with no conversation-history fork (`fork_turns="none"` when using sub-agents). Do not reuse a builder or a critic that has received builder discussion.
- Give it only RUBRIC.md, before/after renders, and the exact candidate diff. The instruction to be adversarial and justify all scores above 7 is already in RUBRIC.md.
- Do not supply AUDIT.md, LEDGER.md, design rationale, implementation plans, desired scores, prior verdicts, or builder summaries. Do not let it inspect unrelated repository files or previous conversations.
- Ask it to read only the supplied evidence paths. Sub-agents share filesystem access, so this is procedural context isolation, not a filesystem security boundary.

## Evidence packet

- Use candidate-specific paths: `docs/upgrade/reviews/<section-id>/iteration-<n>/` with `before/`, `after/`, and `candidate.diff`. Save the returned verdict as `VERDICT.md` after the critique finishes.
- Render before and after with matched data, viewport, palette, text scale, and relevant interaction state. Mark synthetic fixtures and missing media/native surfaces in the render filenames or diff metadata. Include narrow and large-text states plus affected palettes where relevant.
- The diff must capture this candidate's actual changes against its recorded pre-change snapshot, including new files. The working tree already contains unrelated changes; do not substitute an unfiltered working-tree diff.
- Include sufficient surrounding diff context to assess changed behavior. If the packet is insufficient, the critic must report the gap rather than browse builder context or infer a pass.
- Preserve the evidence used for a verdict. Later revisions get a new packet and a new fresh-context critic.

## Coordination

The coordinator checks target attainment and repository validation separately, updates LEDGER.md, and routes material findings back to the builder. A critic Pass is one gate, not permission to skip tests, affected-theme goldens, CI, or required hardware qualification.

Setup alone does not start implementation or a comparative critique: there is no after candidate yet. The baseline audit remains the initial editorial assessment until a candidate receives independent review.
