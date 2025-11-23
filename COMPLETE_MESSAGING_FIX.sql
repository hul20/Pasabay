-- ============================================================
-- COMPLETE MESSAGING FIX - ALL ISSUES
-- ============================================================
-- This fixes:
-- 1. Traveler names showing "null null"
-- 2. Cannot accept requests (column error)
-- 3. Conversations not created when accepting requests
-- 4. Messages page is empty
-- ============================================================

-- ============================================================
-- FIX #1: Users Table RLS - Allow viewing other users
-- ============================================================

DROP POLICY IF EXISTS "Users can view their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can view all profiles" ON public.users;
DROP POLICY IF EXISTS "Users can view own complete profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
DROP POLICY IF EXISTS "Verifiers can view all users" ON public.users;

-- Allow all authenticated users to view profiles
CREATE POLICY "Users can view all profiles"
ON public.users 
FOR SELECT 
TO authenticated
USING (true);

-- Users can update only their own profile
CREATE POLICY "Users can update own profile"
ON public.users 
FOR UPDATE 
TO authenticated
USING (auth.uid() = id) 
WITH CHECK (auth.uid() = id);

-- Users can insert their own profile
CREATE POLICY "Users can insert own profile"
ON public.users 
FOR INSERT 
TO authenticated
WITH CHECK (auth.uid() = id);

-- ============================================================
-- FIX #2: Accept Request - Fix column name & create conversation
-- ============================================================

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
    
    -- Update trip capacity (FIXED: use current_requests)
    UPDATE public.trips
    SET available_capacity = available_capacity - 1,
        current_requests = current_requests + 1,
        updated_at = NOW()
    WHERE id = v_trip_id;
    
    -- ✅ CREATE CONVERSATION (automatically!)
    SELECT id INTO v_conversation_id
    FROM public.conversations
    WHERE request_id = request_id;
    
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
-- FIX #3: Cancel Request - Fix column name
-- ============================================================

CREATE OR REPLACE FUNCTION public.cancel_service_request(request_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_trip_id UUID;
    v_requester_id UUID;
    v_current_status VARCHAR(20);
BEGIN
    SELECT trip_id, requester_id, status 
    INTO v_trip_id, v_requester_id, v_current_status
    FROM public.service_requests
    WHERE id = request_id;
    
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
    WHERE id = request_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- VERIFICATION
-- ============================================================

-- Check users table policies
SELECT tablename, policyname, cmd 
FROM pg_policies 
WHERE tablename = 'users' 
ORDER BY policyname;

-- Check if conversations table exists
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'conversations'
) as conversations_exists;

-- Check conversations RLS policies
SELECT tablename, policyname 
FROM pg_policies 
WHERE tablename IN ('conversations', 'messages')
ORDER BY tablename, policyname;

-- ============================================================
-- TEST QUERIES (Optional - for debugging)
-- ============================================================

-- View all conversations (after accepting a request)
-- SELECT 
--     c.id,
--     c.request_id,
--     sr.service_type,
--     u1.first_name || ' ' || u1.last_name as requester_name,
--     u2.first_name || ' ' || u2.last_name as traveler_name,
--     c.created_at
-- FROM conversations c
-- JOIN service_requests sr ON sr.id = c.request_id
-- JOIN users u1 ON u1.id = c.requester_id
-- JOIN users u2 ON u2.id = c.traveler_id
-- ORDER BY c.created_at DESC
-- LIMIT 5;

-- ============================================================
-- SUMMARY OF FIXES
-- ============================================================
-- ✅ Users can view other users' profiles (names show correctly)
-- ✅ Accept request uses correct column name (no more errors)
-- ✅ Conversations auto-created when accepting (messages page works)
-- ✅ Both traveler and requester see conversations immediately
-- 
-- After running this SQL:
-- 1. Accept a request as traveler
-- 2. Go to Messages page (both traveler and requester)
-- 3. Should see the conversation!
-- 4. Can start chatting immediately
-- ============================================================

