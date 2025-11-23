-- ============================================================
-- FIX: Ambiguous request_id Error
-- ============================================================
-- Error: column reference "request_id" is ambiguous
-- Fix: Rename the parameter to avoid conflict with table column
-- ============================================================

-- Fixed accept_service_request function
CREATE OR REPLACE FUNCTION public.accept_service_request(request_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_trip_id UUID;
    v_current_capacity INTEGER;
    v_traveler_id UUID;
    v_requester_id UUID;
    v_conversation_id UUID;
    v_request_id UUID := request_id;  -- ✅ Store parameter in variable
BEGIN
    -- Get request details (use v_request_id)
    SELECT trip_id, traveler_id, requester_id 
    INTO v_trip_id, v_traveler_id, v_requester_id
    FROM public.service_requests
    WHERE id = v_request_id AND status = 'Pending';
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Check if the current user is the traveler
    IF auth.uid() != v_traveler_id THEN
        RETURN FALSE;
    END IF;
    
    -- Check available capacity
    SELECT available_capacity INTO v_current_capacity
    FROM public.trips
    WHERE id = v_trip_id;
    
    IF v_current_capacity <= 0 THEN
        RETURN FALSE;
    END IF;
    
    -- Accept the request
    UPDATE public.service_requests
    SET status = 'Accepted', updated_at = NOW()
    WHERE id = v_request_id;
    
    -- Update trip capacity
    UPDATE public.trips
    SET available_capacity = available_capacity - 1,
        current_requests = current_requests + 1,
        updated_at = NOW()
    WHERE id = v_trip_id;
    
    -- Create conversation (use c.request_id to avoid ambiguity)
    SELECT id INTO v_conversation_id
    FROM public.conversations c
    WHERE c.request_id = v_request_id;
    
    IF v_conversation_id IS NULL THEN
        INSERT INTO public.conversations (
            request_id, requester_id, traveler_id, created_at, updated_at
        ) VALUES (
            v_request_id, v_requester_id, v_traveler_id, NOW(), NOW()
        );
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fixed reject_service_request function
CREATE OR REPLACE FUNCTION public.reject_service_request(
    request_id UUID,
    rejection_reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_traveler_id UUID;
    v_request_id UUID := request_id;  -- ✅ Store parameter in variable
BEGIN
    -- Get traveler_id from the request
    SELECT traveler_id INTO v_traveler_id
    FROM public.service_requests
    WHERE id = v_request_id AND status = 'Pending';
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Check if the current user is the traveler
    IF auth.uid() != v_traveler_id THEN
        RETURN FALSE;
    END IF;
    
    -- Reject the request
    UPDATE public.service_requests
    SET 
        status = 'Rejected',
        rejection_reason = rejection_reason,
        updated_at = NOW()
    WHERE id = v_request_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fixed cancel_service_request function
CREATE OR REPLACE FUNCTION public.cancel_service_request(request_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_trip_id UUID;
    v_requester_id UUID;
    v_current_status VARCHAR(20);
    v_request_id UUID := request_id;  -- ✅ Store parameter in variable
BEGIN
    SELECT trip_id, requester_id, status 
    INTO v_trip_id, v_requester_id, v_current_status
    FROM public.service_requests
    WHERE id = v_request_id;
    
    IF NOT FOUND THEN RETURN FALSE; END IF;
    IF auth.uid() != v_requester_id THEN RETURN FALSE; END IF;
    IF v_current_status NOT IN ('Pending', 'Accepted') THEN RETURN FALSE; END IF;
    
    IF v_current_status = 'Accepted' THEN
        UPDATE public.trips
        SET available_capacity = available_capacity + 1,
            current_requests = current_requests - 1,
            updated_at = NOW()
        WHERE id = v_trip_id;
    END IF;
    
    UPDATE public.service_requests
    SET status = 'Cancelled', updated_at = NOW()
    WHERE id = v_request_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- VERIFICATION
-- ============================================================

-- Test (replace with actual request ID)
-- SELECT accept_service_request('your-request-id-here');

-- ============================================================
-- NOTES
-- ============================================================
-- The issue was "column reference 'request_id' is ambiguous"
-- This happens when a parameter name matches a column name
-- 
-- Fixed by:
-- 1. Store parameter in a variable (v_request_id)
-- 2. Use the variable throughout the function
-- 3. Or use table alias (c.request_id) in queries
-- ============================================================


