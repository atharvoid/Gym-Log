--- PROTOCOL ---
You are upgrading DELT/DELT section by section. Spec: docs/upgrade/AUDIT.md.
Memory: docs/upgrade/LEDGER.md. Read both, plus DESIGN.md and repo conventions,
before touching anything. Work ONLY on the named session scope. Shared-token
changes are allowed but must be listed in the ledger.

VISUAL GUARDRAIL (applies to every session):
- Refine, never replace. Keep the existing visual language (cards, accent
  usage, depth, motion) unless the owner explicitly asks to change it.
- Every after-render must look at least as rich as the before-render.
  Flatter, plainer or more "wireframe" results are a failure.
- Concept renders must be high-fidelity, using real components and the
  real theme, never wireframes.
- Show ONE implemented-style render for owner approval, plus the
  before-render side by side.
- The audit is a list of problems, not a design brief. Fix the
  problems without adopting its aesthetic suggestions.

PER SECTION:
1. UNDERSTAND: render current state (390x844 and 1.6x text) into
   docs/upgrade/renders/<session>/before/.
2. DIVERGE: consider 3 possible refinements within the existing visual
   language; reject at least one with a reason. Present ONE high-fidelity,
   implemented-style candidate using real components and the real theme,
   side by side with the before-render. STOP for owner approval before
   changing app code. Choose by what helps a lifter mid-set or glancing
   at the phone while preserving the existing visual richness.
3. TEST FIRST: failing behavior tests for every logic/truth change, then pass.
4. BUILD: keep OLED canvas, accent tokens, Inter. No new packages. No invented
   claims: separate logged facts, estimates, suggestions.
5. VERIFY: run verify.ps1. Real-font goldens (no masked text). Render after/
   at 390px, 1.6x text, a second palette, plus empty/low-data/error states.
6. SELF-CRITIQUE: compare before/after honestly; list 3 remaining weaknesses.
7. ITERATE up to 4 times. Each iteration must try a different idea, not
   polish the same one.
8. REPORT in LEDGER.md: decisions, rejected ideas, evidence, unverified items
   (device, haptics, native), proposed score with justification. Never
   declare 9+ yourself; an independent critic scores it.

RULES: Patience over speed. If something needs a product decision or a
physical Android device, stop and write the question in the ledger instead of
guessing. Honest "unverified" beats optimistic claims. Do not commit until
verify.ps1 passes.
--- END ---
