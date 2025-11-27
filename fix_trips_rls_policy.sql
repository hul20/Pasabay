-- ============================================================
-- FIX: Trips RLS Policy for Requester Search
-- ============================================================
-- The existing policy checks "current_requests < available_capacity"
-- which is INCORRECT because:
-- - available_capacity = remaining slots (starts at 5, decreases to 2)
-- - current_requests = accepted requests (starts at 0, increases to 3)
-- 
-- Example of the BUG:
-- Trip with 5 max slots, 3 occupied:
-- - available_capacity = 2 (remaining)
-- - current_requests = 3 (occupied)
-- - Check: 3 < 2 = FALSE ❌ (trip hidden!)
--
-- CORRECT logic: Just check if there are remaining slots
-- ============================================================

-- Drop the incorrect policy (using IF EXISTS to avoid errors)
DROP POLICY IF EXISTS "Requesters can view active trips" ON public.trips;

-- Create the CORRECT policy
CREATE POLICY "Requesters can view active trips"
ON public.trips
FOR SELECT
TO authenticated
USING (
  trip_status IN ('Upcoming', 'In Progress') 
  AND available_capacity > 0  -- ✅ CORRECT: Check if slots remain
);
