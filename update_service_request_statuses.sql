-- ============================================================================
-- UPDATE SERVICE REQUEST STATUS CHECK CONSTRAINT
-- ============================================================================
-- This migration adds new intermediate status values for tracking order progress
-- Run this in Supabase SQL Editor to update the status constraint
-- ============================================================================

-- Drop the old constraint
ALTER TABLE public.service_requests 
DROP CONSTRAINT IF EXISTS service_requests_status_check;

-- Add the new constraint with all status values
ALTER TABLE public.service_requests 
ADD CONSTRAINT service_requests_status_check 
CHECK (status IN (
    'Pending',      -- Initial status when request is created
    'Accepted',     -- Traveler accepted the request
    'Rejected',     -- Traveler rejected the request
    'Item Bought',  -- (Pabakal only) Item has been purchased
    'Picked Up',    -- (Pasabay only) Package has been picked up
    'On the Way',   -- Traveler is en route to delivery location
    'Dropped Off',  -- Item/package has been dropped off
    'Order Sent',   -- Legacy status (kept for compatibility)
    'Completed',    -- Transaction completed successfully
    'Cancelled'     -- Request was cancelled by requester
));

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Check that the constraint was updated successfully
SELECT 
    conname AS constraint_name,
    pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'public.service_requests'::regclass
  AND conname = 'service_requests_status_check';

-- Test that new statuses work (optional - uncomment to test)
/*
-- This should succeed now
UPDATE public.service_requests 
SET status = 'Item Bought' 
WHERE id = 'YOUR_TEST_REQUEST_ID_HERE';
*/
