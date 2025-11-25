-- ============================================================
-- FIX: Trips Capacity Constraint
-- ============================================================
-- The existing constraint "trips_capacity_check" (current_requests <= available_capacity)
-- is incorrect because "available_capacity" decreases as "current_requests" increases.
-- This causes the constraint to fail when (current_requests > available_capacity).
--
-- Example:
-- Start: Available=5, Current=0
-- Accept 1: Available=4, Current=1 (1 <= 4 OK)
-- Accept 2: Available=3, Current=2 (2 <= 3 OK)
-- Accept 3: Available=2, Current=3 (3 <= 2 FAIL)
-- ============================================================

-- 1. Drop the incorrect constraint
ALTER TABLE public.trips DROP CONSTRAINT IF EXISTS trips_capacity_check;

-- 2. Add a correct constraint (ensure capacity doesn't go below zero)
ALTER TABLE public.trips ADD CONSTRAINT trips_capacity_check CHECK (available_capacity >= 0);

-- 3. Ensure accept_service_request function is correct (re-applying just in case)
CREATE OR REPLACE FUNCTION public.accept_service_request(request_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_trip_id UUID;
    v_current_capacity INTEGER;
    v_traveler_id UUID;
BEGIN
    -- Get trip_id and traveler_id from the request
    SELECT trip_id, traveler_id INTO v_trip_id, v_traveler_id
    FROM public.service_requests
    WHERE id = request_id AND status = 'Pending';
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Check if there's available capacity
    SELECT available_capacity INTO v_current_capacity
    FROM public.trips
    WHERE id = v_trip_id;
    
    IF v_current_capacity <= 0 THEN
        RETURN FALSE;
    END IF;
    
    -- Accept the request
    UPDATE public.service_requests
    SET status = 'Accepted', updated_at = NOW()
    WHERE id = request_id;
    
    -- Update trip capacity
    UPDATE public.trips
    SET available_capacity = available_capacity - 1,
        current_requests = current_requests + 1,
        updated_at = NOW()
    WHERE id = v_trip_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
