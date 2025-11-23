-- ============================================================
-- FIX: Accept Service Request Function
-- ============================================================
-- This fixes the error: column "accepted_requests" does not exist
-- The trips table uses "current_requests", not "accepted_requests"
-- ============================================================

-- Function: Accept a service request (with capacity check)
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
    
    -- Update trip capacity (use current_requests, not accepted_requests)
    UPDATE public.trips
    SET available_capacity = available_capacity - 1,
        current_requests = current_requests + 1,     -- ✅ FIXED: Changed from accepted_requests
        updated_at = NOW()
    WHERE id = v_trip_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Cancel a service request
CREATE OR REPLACE FUNCTION public.cancel_service_request(request_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_trip_id UUID;
    v_requester_id UUID;
    v_current_status VARCHAR(20);
BEGIN
    -- Get request details
    SELECT trip_id, requester_id, status 
    INTO v_trip_id, v_requester_id, v_current_status
    FROM public.service_requests
    WHERE id = request_id;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Check if the current user is the requester
    IF auth.uid() != v_requester_id THEN
        RETURN FALSE;
    END IF;
    
    -- Can only cancel Pending or Accepted requests
    IF v_current_status NOT IN ('Pending', 'Accepted') THEN
        RETURN FALSE;
    END IF;
    
    -- If it was accepted, restore capacity
    IF v_current_status = 'Accepted' THEN
        UPDATE public.trips
        SET available_capacity = available_capacity + 1,
            current_requests = current_requests - 1,     -- ✅ FIXED: Changed from accepted_requests
            updated_at = NOW()
        WHERE id = v_trip_id;
    END IF;
    
    -- Cancel the request
    UPDATE public.service_requests
    SET status = 'Cancelled', updated_at = NOW()
    WHERE id = request_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- VERIFICATION
-- ============================================================

-- Test query (optional)
-- SELECT accept_service_request('your-request-id-here');

-- ============================================================
-- NOTES
-- ============================================================
-- The trips table has these columns:
-- - available_capacity: Remaining slots
-- - current_requests: Number of accepted requests
--
-- The old function was trying to use "accepted_requests" which doesn't exist
-- This has been corrected to use "current_requests"
-- ============================================================


