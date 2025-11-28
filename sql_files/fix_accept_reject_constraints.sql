-- ============================================================
-- FINAL FIX: Accept/Reject Request Issues
-- ============================================================

-- 1. Fix Capacity Constraint (Logic was inverted)
ALTER TABLE public.trips DROP CONSTRAINT IF EXISTS trips_capacity_check;
ALTER TABLE public.trips ADD CONSTRAINT trips_capacity_check CHECK (available_capacity >= 0);

-- 2. Fix Future Date Constraint (Prevents updating past trips)
-- This constraint prevents any update to a trip if the departure date has passed.
-- This causes errors when accepting requests for trips that are happening "today" or just passed.
ALTER TABLE public.trips DROP CONSTRAINT IF EXISTS trips_future_date_check;

-- 3. Ensure Accept Function is Correct
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

-- 4. Ensure Reject Function is Correct
CREATE OR REPLACE FUNCTION public.reject_service_request(
    request_id UUID,
    reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_traveler_id UUID;
BEGIN
    -- Get traveler_id from the request
    SELECT traveler_id INTO v_traveler_id
    FROM public.service_requests
    WHERE id = request_id AND status = 'Pending';
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Check if the current user is the traveler
    IF auth.uid() != v_traveler_id THEN
        RETURN FALSE;
    END IF;
    
    -- Reject the request
    UPDATE public.service_requests
    SET status = 'Rejected',
        rejection_reason = reason,
        updated_at = NOW()
    WHERE id = request_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
