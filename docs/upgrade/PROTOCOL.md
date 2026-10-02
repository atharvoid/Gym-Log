--- PROTOCOL ---
You are upgrading DELT/GymLog section by section. Spec: docs/upgrade/AUDIT.md.
Memory: docs/upgrade/LEDGER.md. Read both, plus DESIGN.md and repo conventions,
before touching anything. Work ONLY on the named session scope. Shared-token
changes are allowed but must be listed in the ledger.

PER SECTION:
1. UNDERSTAND: render current state (390x844 and 1.6x text) into
   docs/upgrade/renders/<session>/before/.
2. DIVERGE: propose 3 meaningfully different solutions (hierarchy, layout,
   motion, copy). Reject at least one with a reason. Choose by what helps a
   lifter mid-set or glancing at the phone, not by what looks decorative.
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
