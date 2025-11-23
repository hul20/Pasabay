-- ============================================================
-- FIX: Accept Request - Auto-create Conversation
-- ============================================================
-- This fixes the issue where conversations are not created
-- when a traveler accepts a request, so messages page is empty
-- ============================================================

-- Updated accept_service_request function that creates a conversation
CREATE OR REPLACE FUNCTION public.accept_service_request(request_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_trip_id UUID;
    v_current_capacity INTEGER;
    v_traveler_id UUID;
    v_requester_id UUID;
    v_conversation_id UUID;
BEGIN
    -- Get request details
    SELECT trip_id, traveler_id, requester_id 
    INTO v_trip_id, v_traveler_id, v_requester_id
    FROM public.service_requests
    WHERE id = request_id AND status = 'Pending';
    
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
    WHERE id = request_id;
    
    -- Update trip capacity (FIXED: use current_requests, not accepted_requests)
    UPDATE public.trips
    SET available_capacity = available_capacity - 1,
        current_requests = current_requests + 1,
        updated_at = NOW()
    WHERE id = v_trip_id;
    
    -- ✅ CREATE CONVERSATION (NEW!)
    -- Check if conversation already exists
    SELECT id INTO v_conversation_id
    FROM public.conversations
    WHERE request_id = request_id;
    
    -- If no conversation exists, create one
    IF v_conversation_id IS NULL THEN
        INSERT INTO public.conversations (
            request_id,
            requester_id,
            traveler_id,
            created_at,
            updated_at
        ) VALUES (
            request_id,
            v_requester_id,
            v_traveler_id,
            NOW(),
            NOW()
        )
        RETURNING id INTO v_conversation_id;
        
        RAISE NOTICE 'Created conversation: %', v_conversation_id;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- VERIFICATION
-- ============================================================

-- Check if conversations table exists
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'conversations'
);

-- Check conversations structure
SELECT column_name, data_type 
FROM information_schema.columns
WHERE table_name = 'conversations'
ORDER BY ordinal_position;

-- ============================================================
-- TEST QUERY
-- ============================================================

-- After running this, when you accept a request:
-- 1. Request status changes to 'Accepted'
-- 2. Trip capacity is updated
-- 3. Conversation is automatically created
-- 4. Messages page will show the conversation

-- To test, check conversations after accepting a request:
-- SELECT * FROM conversations ORDER BY created_at DESC LIMIT 5;

-- ============================================================
-- NOTES
-- ============================================================
-- This fix ensures that:
-- 1. Conversations are AUTOMATICALLY created when accepting
-- 2. No need to manually call get_or_create_conversation
-- 3. Both traveler and requester see the chat immediately
-- 4. Messages page populates correctly
-- ============================================================


