-- ============================================================
-- Phase 6: Sync RLS — Defense-in-depth for Pro-only sync
-- ============================================================
-- This SQL restricts the `sync_objects` table so that only users
-- with an active Pro entitlement can INSERT or UPDATE rows.
-- Free users retain SELECT access to any historical data that may
-- have been synced before the gating was introduced.
--
-- This is a SERVER-SIDE safety net. The client-side SyncEntitlementGate
-- is the primary enforcement point; this RLS policy exists in case
-- the client gate is bypassed (e.g. a modified client or direct
-- API call).
--
-- PREREQUISITE:
--   The `profiles` table must have an `is_premium` boolean column
--   (or equivalent) that is kept in sync with RevenueCat. If your
--   implementation uses a different column name, adjust accordingly.
--
-- HOW TO APPLY:
--   Run this in the Supabase SQL Editor for your project.
-- ============================================================

-- 1. Revoke default privileges so nothing leaks by accident.
REVOKE ALL ON sync_objects FROM anon, authenticated;

-- 2. Re-grant minimum access.
--    authenticated users can SELECT (read historical data)
--    but INSERT/UPDATE/DELETE are governed by RLS below.
GRANT SELECT ON sync_objects TO authenticated;

-- 3. Enable RLS (if not already enabled).
ALTER TABLE sync_objects ENABLE ROW LEVEL SECURITY;

-- 4. Drop existing policies if they exist (idempotent).
DROP POLICY IF EXISTS sync_objects_select_own ON sync_objects;
DROP POLICY IF EXISTS sync_objects_insert_own ON sync_objects;
DROP POLICY IF EXISTS sync_objects_update_own ON sync_objects;
DROP POLICY IF EXISTS sync_objects_delete_own ON sync_objects;

-- 5. SELECT — all authenticated users can read their own rows.
--    This preserves historical data for users who downgraded from Pro.
CREATE POLICY sync_objects_select_own
  ON sync_objects
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- 6. INSERT — only Pro users can create new sync rows.
CREATE POLICY sync_objects_insert_own
  ON sync_objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.is_premium = true
    )
  );

-- 7. UPDATE — only Pro users can modify their existing sync rows.
CREATE POLICY sync_objects_update_own
  ON sync_objects
  FOR UPDATE
  TO authenticated
  USING (
    user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.is_premium = true
    )
  )
  WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.is_premium = true
    )
  );

-- 8. DELETE — only Pro users can delete their own sync rows.
--    Free users cannot delete historical data (GDPR deletion is
--    handled separately via the account deletion flow).
CREATE POLICY sync_objects_delete_own
  ON sync_objects
  FOR DELETE
  TO authenticated
  USING (
    user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.is_premium = true
    )
  );

-- ============================================================
-- NOTES:
--   - If your `profiles` table uses a different column for premium
--     status (e.g. `entitlement_status` or `subscription_tier`),
--     update the WHERE clauses accordingly.
--   - The `is_premium` column should be populated by a RevenueCat
--     webhook or the client app on entitlement change.
--   - For extra robustness, consider a Supabase Function that
--     validates the RevenueCat entitlement server-side before
--     granting write access, rather than relying solely on the
--     `profiles.is_premium` column.
-- ============================================================
