-- ============================================================================
-- SERVICE REQUESTS TABLE SCHEMA
-- ============================================================================
-- This table stores all service requests (Pabakal/Pasabay) from requesters to travelers
-- Created: 2025
-- ============================================================================

-- Create service_requests table
CREATE TABLE IF NOT EXISTS public.service_requests (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Foreign Keys
    requester_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    traveler_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    
    -- Service Information
    service_type VARCHAR(20) NOT NULL CHECK (service_type IN ('Pabakal', 'Pasabay')),
    status VARCHAR(20) NOT NULL DEFAULT 'Pending' CHECK (status IN ('Pending', 'Accepted', 'Rejected', 'Completed', 'Cancelled')),
    
    -- Common Fields
    pickup_location TEXT,
    dropoff_location TEXT,
    pickup_time TIMESTAMPTZ,
    
    -- Pabakal Specific Fields
    product_name VARCHAR(255),
    store_name VARCHAR(255),
    store_location TEXT,
    product_cost DECIMAL(10, 2),
    product_description TEXT,
    
    -- Pasabay Specific Fields
    recipient_name VARCHAR(255),
    recipient_phone VARCHAR(20),
    package_description TEXT,
    
    -- Attachments (stored as arrays of URLs)
    photo_urls TEXT[],
    document_urls TEXT[],
    
    -- Payment
    service_fee DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    total_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    
    -- Metadata
    notes TEXT,
    rejection_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    
    -- Constraints
    CONSTRAINT valid_pabakal_fields CHECK (
        service_type != 'Pabakal' OR (
            product_name IS NOT NULL AND
            store_location IS NOT NULL AND
            product_cost IS NOT NULL
        )
    ),
    CONSTRAINT valid_pasabay_fields CHECK (
        service_type != 'Pasabay' OR (
            recipient_name IS NOT NULL AND
            recipient_phone IS NOT NULL AND
            dropoff_location IS NOT NULL
        )
    ),
    CONSTRAINT positive_amounts CHECK (
        service_fee >= 0 AND
        total_amount >= 0
    )
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Index for requester queries (most common query pattern)
CREATE INDEX IF NOT EXISTS idx_service_requests_requester 
ON public.service_requests(requester_id, status, created_at DESC);

-- Index for traveler queries
CREATE INDEX IF NOT EXISTS idx_service_requests_traveler 
ON public.service_requests(traveler_id, status, created_at DESC);

-- Index for trip-specific queries
CREATE INDEX IF NOT EXISTS idx_service_requests_trip 
ON public.service_requests(trip_id, status);

-- Index for service type filtering
CREATE INDEX IF NOT EXISTS idx_service_requests_service_type 
ON public.service_requests(service_type, status);

-- Index for created_at for sorting
CREATE INDEX IF NOT EXISTS idx_service_requests_created_at 
ON public.service_requests(created_at DESC);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS
ALTER TABLE public.service_requests ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own requests (as requester)
CREATE POLICY "Users can view requests they created"
ON public.service_requests
FOR SELECT
USING (auth.uid() = requester_id);

-- Policy: Travelers can view requests for their trips
CREATE POLICY "Travelers can view requests for their trips"
ON public.service_requests
FOR SELECT
USING (auth.uid() = traveler_id);

-- Policy: Requesters can create requests
CREATE POLICY "Requesters can create requests"
ON public.service_requests
FOR INSERT
WITH CHECK (auth.uid() = requester_id);

-- Policy: Requesters can update their own pending requests
CREATE POLICY "Requesters can update their own pending requests"
ON public.service_requests
FOR UPDATE
USING (auth.uid() = requester_id AND status = 'Pending')
WITH CHECK (auth.uid() = requester_id);

-- Policy: Travelers can update requests for their trips (accept/reject)
CREATE POLICY "Travelers can update requests for their trips"
ON public.service_requests
FOR UPDATE
USING (auth.uid() = traveler_id)
WITH CHECK (auth.uid() = traveler_id);

-- Policy: Requesters can delete their own pending requests
CREATE POLICY "Requesters can delete their own pending requests"
ON public.service_requests
FOR DELETE
USING (auth.uid() = requester_id AND status = 'Pending');

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function: Update updated_at timestamp automatically
CREATE OR REPLACE FUNCTION public.update_service_requests_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Auto-update updated_at
DROP TRIGGER IF EXISTS service_requests_updated_at_trigger ON public.service_requests;
CREATE TRIGGER service_requests_updated_at_trigger
    BEFORE UPDATE ON public.service_requests
    FOR EACH ROW
    EXECUTE FUNCTION public.update_service_requests_updated_at();

-- Function: Get request statistics for a traveler
CREATE OR REPLACE FUNCTION public.get_traveler_request_stats(traveler_user_id UUID)
RETURNS TABLE (
    total_requests BIGINT,
    pending_requests BIGINT,
    accepted_requests BIGINT,
    completed_requests BIGINT,
    total_earnings DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_requests,
        COUNT(*) FILTER (WHERE status = 'Pending') as pending_requests,
        COUNT(*) FILTER (WHERE status = 'Accepted') as accepted_requests,
        COUNT(*) FILTER (WHERE status = 'Completed') as completed_requests,
        COALESCE(SUM(service_fee) FILTER (WHERE status = 'Completed'), 0) as total_earnings
    FROM public.service_requests
    WHERE traveler_id = traveler_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get request statistics for a requester
CREATE OR REPLACE FUNCTION public.get_requester_request_stats(requester_user_id UUID)
RETURNS TABLE (
    total_requests BIGINT,
    pending_requests BIGINT,
    accepted_requests BIGINT,
    completed_requests BIGINT,
    total_spent DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_requests,
        COUNT(*) FILTER (WHERE status = 'Pending') as pending_requests,
        COUNT(*) FILTER (WHERE status = 'Accepted') as accepted_requests,
        COUNT(*) FILTER (WHERE status = 'Completed') as completed_requests,
        COALESCE(SUM(total_amount) FILTER (WHERE status = 'Completed'), 0) as total_spent
    FROM public.service_requests
    WHERE requester_id = requester_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

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
    
    -- Decrement available capacity
    UPDATE public.trips
    SET available_capacity = available_capacity - 1,
        accepted_requests = accepted_requests + 1
    WHERE id = v_trip_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Reject a service request
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

-- Function: Cancel a service request (requester)
CREATE OR REPLACE FUNCTION public.cancel_service_request(request_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_requester_id UUID;
    v_trip_id UUID;
    v_current_status VARCHAR(20);
BEGIN
    -- Get request details
    SELECT requester_id, trip_id, status 
    INTO v_requester_id, v_trip_id, v_current_status
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
            accepted_requests = accepted_requests - 1
        WHERE id = v_trip_id;
    END IF;
    
    -- Cancel the request
    UPDATE public.service_requests
    SET status = 'Cancelled', updated_at = NOW()
    WHERE id = request_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- STORAGE BUCKET FOR ATTACHMENTS
-- ============================================================================

-- Create storage bucket for request attachments (if not exists)
INSERT INTO storage.buckets (id, name, public)
VALUES ('attachments', 'attachments', true)
ON CONFLICT (id) DO NOTHING;

-- Drop existing storage policies if they exist
DROP POLICY IF EXISTS "Users can upload attachments" ON storage.objects;
DROP POLICY IF EXISTS "Users can view attachments" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own attachments" ON storage.objects;

-- Storage policies
CREATE POLICY "Users can upload attachments"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'attachments' AND
    auth.role() = 'authenticated'
);

CREATE POLICY "Users can view attachments"
ON storage.objects FOR SELECT
USING (bucket_id = 'attachments');

CREATE POLICY "Users can delete their own attachments"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'attachments' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- ============================================================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================================================

-- NOTE: Uncomment the following to insert sample data for testing
-- Make sure to replace the UUIDs with actual user IDs and trip IDs from your database

/*
-- Sample Pabakal request
INSERT INTO public.service_requests (
    requester_id,
    traveler_id,
    trip_id,
    service_type,
    product_name,
    store_name,
    store_location,
    product_cost,
    product_description,
    service_fee,
    total_amount,
    status
) VALUES (
    'REQUESTER_UUID_HERE',
    'TRAVELER_UUID_HERE',
    'TRIP_UUID_HERE',
    'Pabakal',
    'iPhone 15 Pro Max',
    'Apple Store',
    'SM City Iloilo, Mandurriao, Iloilo City',
    75000.00,
    'Space Black, 256GB',
    7500.00,
    82500.00,
    'Pending'
);

-- Sample Pasabay request
INSERT INTO public.service_requests (
    requester_id,
    traveler_id,
    trip_id,
    service_type,
    recipient_name,
    recipient_phone,
    dropoff_location,
    package_description,
    service_fee,
    total_amount,
    status
) VALUES (
    'REQUESTER_UUID_HERE',
    'TRAVELER_UUID_HERE',
    'TRIP_UUID_HERE',
    'Pasabay',
    'Maria Santos',
    '09123456789',
    '123 Main St, Roxas City, Capiz',
    'Documents and small box',
    50.00,
    50.00,
    'Pending'
);
*/

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check if table exists and view structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'service_requests'
ORDER BY ordinal_position;

-- Check indexes
SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename = 'service_requests';

-- Check RLS policies
SELECT
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'service_requests';

-- ============================================================================
-- CONVERSATIONS & MESSAGES TABLES (for in-app messaging)
-- ============================================================================

-- Create conversations table (one per requester-traveler pair per request)
CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id UUID NOT NULL REFERENCES public.service_requests(id) ON DELETE CASCADE,
    requester_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    traveler_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    last_message_at TIMESTAMPTZ,
    requester_unread_count INT DEFAULT 0,
    traveler_unread_count INT DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    
    UNIQUE(request_id) -- One conversation per request
);

-- Create messages table
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    message_text TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CHECK (length(message_text) > 0 AND length(message_text) <= 5000)
);

-- Indexes for conversations
CREATE INDEX IF NOT EXISTS idx_conversations_requester 
ON public.conversations(requester_id, last_message_at DESC);

CREATE INDEX IF NOT EXISTS idx_conversations_traveler 
ON public.conversations(traveler_id, last_message_at DESC);

CREATE INDEX IF NOT EXISTS idx_conversations_request 
ON public.conversations(request_id);

-- Indexes for messages
CREATE INDEX IF NOT EXISTS idx_messages_conversation 
ON public.messages(conversation_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_messages_unread 
ON public.messages(conversation_id, is_read) 
WHERE is_read = FALSE;

-- Enable RLS for conversations
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

-- Conversations policies
CREATE POLICY "Users can view their own conversations"
ON public.conversations
FOR SELECT
USING (auth.uid() = requester_id OR auth.uid() = traveler_id);

CREATE POLICY "System can create conversations"
ON public.conversations
FOR INSERT
WITH CHECK (auth.uid() = requester_id OR auth.uid() = traveler_id);

CREATE POLICY "Users can update their own conversations"
ON public.conversations
FOR UPDATE
USING (auth.uid() = requester_id OR auth.uid() = traveler_id);

-- Enable RLS for messages
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Messages policies
CREATE POLICY "Users can view messages in their conversations"
ON public.messages
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.conversations
        WHERE conversations.id = messages.conversation_id
        AND (conversations.requester_id = auth.uid() OR conversations.traveler_id = auth.uid())
    )
);

CREATE POLICY "Users can send messages in their conversations"
ON public.messages
FOR INSERT
WITH CHECK (
    auth.uid() = sender_id AND
    EXISTS (
        SELECT 1 FROM public.conversations
        WHERE conversations.id = conversation_id
        AND (conversations.requester_id = auth.uid() OR conversations.traveler_id = auth.uid())
    )
);

CREATE POLICY "Users can mark their messages as read"
ON public.messages
FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM public.conversations
        WHERE conversations.id = messages.conversation_id
        AND (conversations.requester_id = auth.uid() OR conversations.traveler_id = auth.uid())
    )
);

-- Function: Update conversation timestamp on new message
CREATE OR REPLACE FUNCTION public.update_conversation_on_message()
RETURNS TRIGGER AS $$
DECLARE
    v_conversation public.conversations%ROWTYPE;
BEGIN
    -- Get conversation details
    SELECT * INTO v_conversation
    FROM public.conversations
    WHERE id = NEW.conversation_id;
    
    -- Update last_message_at
    UPDATE public.conversations
    SET last_message_at = NEW.created_at,
        updated_at = NEW.created_at,
        -- Increment unread count for recipient
        requester_unread_count = CASE 
            WHEN NEW.sender_id = v_conversation.traveler_id 
            THEN requester_unread_count + 1 
            ELSE requester_unread_count 
        END,
        traveler_unread_count = CASE 
            WHEN NEW.sender_id = v_conversation.requester_id 
            THEN traveler_unread_count + 1 
            ELSE traveler_unread_count 
        END
    WHERE id = NEW.conversation_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for conversation update
DROP TRIGGER IF EXISTS messages_update_conversation_trigger ON public.messages;
CREATE TRIGGER messages_update_conversation_trigger
    AFTER INSERT ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION public.update_conversation_on_message();

-- Function: Mark messages as read
CREATE OR REPLACE FUNCTION public.mark_messages_as_read(
    conversation_uuid UUID,
    reader_uuid UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    v_conversation public.conversations%ROWTYPE;
BEGIN
    -- Get conversation
    SELECT * INTO v_conversation
    FROM public.conversations
    WHERE id = conversation_uuid;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Verify user is part of conversation
    IF reader_uuid != v_conversation.requester_id AND reader_uuid != v_conversation.traveler_id THEN
        RETURN FALSE;
    END IF;
    
    -- Mark all unread messages from the other user as read
    UPDATE public.messages
    SET is_read = TRUE
    WHERE conversation_id = conversation_uuid
      AND sender_id != reader_uuid
      AND is_read = FALSE;
    
    -- Reset unread count
    IF reader_uuid = v_conversation.requester_id THEN
        UPDATE public.conversations
        SET requester_unread_count = 0
        WHERE id = conversation_uuid;
    ELSE
        UPDATE public.conversations
        SET traveler_unread_count = 0
        WHERE id = conversation_uuid;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get or create conversation for a request
CREATE OR REPLACE FUNCTION public.get_or_create_conversation(
    req_id UUID
)
RETURNS UUID AS $$
DECLARE
    v_conversation_id UUID;
    v_request public.service_requests%ROWTYPE;
BEGIN
    -- Get request details
    SELECT * INTO v_request
    FROM public.service_requests
    WHERE id = req_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Request not found';
    END IF;
    
    -- Try to get existing conversation
    SELECT id INTO v_conversation_id
    FROM public.conversations
    WHERE request_id = req_id;
    
    -- If doesn't exist, create it
    IF v_conversation_id IS NULL THEN
        INSERT INTO public.conversations (
            request_id,
            requester_id,
            traveler_id,
            created_at
        ) VALUES (
            req_id,
            v_request.requester_id,
            v_request.traveler_id,
            NOW()
        )
        RETURNING id INTO v_conversation_id;
    END IF;
    
    RETURN v_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- NOTIFICATIONS TABLE (Optional - for push notifications)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    notification_type VARCHAR(50) NOT NULL, -- 'new_request', 'request_accepted', 'request_rejected', 'new_message'
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    related_id UUID, -- request_id or message_id
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CHECK (notification_type IN ('new_request', 'request_accepted', 'request_rejected', 'new_message', 'request_cancelled'))
);

-- Index for notifications
CREATE INDEX IF NOT EXISTS idx_notifications_user 
ON public.notifications(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_notifications_unread 
ON public.notifications(user_id, is_read) 
WHERE is_read = FALSE;

-- Enable RLS for notifications
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Notifications policies
CREATE POLICY "Users can view their own notifications"
ON public.notifications
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "System can create notifications"
ON public.notifications
FOR INSERT
WITH CHECK (TRUE); -- Allows system to create notifications

CREATE POLICY "Users can mark their notifications as read"
ON public.notifications
FOR UPDATE
USING (auth.uid() = user_id);

-- Function: Create notification
CREATE OR REPLACE FUNCTION public.create_notification(
    target_user_id UUID,
    notif_type VARCHAR(50),
    notif_title TEXT,
    notif_body TEXT,
    related_uuid UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_notification_id UUID;
BEGIN
    INSERT INTO public.notifications (
        user_id,
        notification_type,
        title,
        body,
        related_id,
        created_at
    ) VALUES (
        target_user_id,
        notif_type,
        notif_title,
        notif_body,
        related_uuid,
        NOW()
    )
    RETURNING id INTO v_notification_id;
    
    RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: Create notification on request status change
CREATE OR REPLACE FUNCTION public.notify_on_request_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Only trigger on status change
    IF OLD.status != NEW.status THEN
        IF NEW.status = 'Accepted' THEN
            -- Notify requester
            PERFORM public.create_notification(
                NEW.requester_id,
                'request_accepted',
                'Request Accepted!',
                'Your ' || NEW.service_type || ' request has been accepted by the traveler.',
                NEW.id
            );
        ELSIF NEW.status = 'Rejected' THEN
            -- Notify requester
            PERFORM public.create_notification(
                NEW.requester_id,
                'request_rejected',
                'Request Rejected',
                'Your ' || NEW.service_type || ' request was rejected.' || 
                CASE WHEN NEW.rejection_reason IS NOT NULL 
                     THEN ' Reason: ' || NEW.rejection_reason 
                     ELSE '' 
                END,
                NEW.id
            );
        ELSIF NEW.status = 'Cancelled' THEN
            -- Notify traveler
            PERFORM public.create_notification(
                NEW.traveler_id,
                'request_cancelled',
                'Request Cancelled',
                'A ' || NEW.service_type || ' request was cancelled by the requester.',
                NEW.id
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS notify_request_status_trigger ON public.service_requests;
CREATE TRIGGER notify_request_status_trigger
    AFTER UPDATE ON public.service_requests
    FOR EACH ROW
    EXECUTE FUNCTION public.notify_on_request_status_change();

-- Trigger: Notify traveler on new request
CREATE OR REPLACE FUNCTION public.notify_on_new_request()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM public.create_notification(
        NEW.traveler_id,
        'new_request',
        'New ' || NEW.service_type || ' Request!',
        'You have received a new ' || NEW.service_type || ' request.',
        NEW.id
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS notify_new_request_trigger ON public.service_requests;
CREATE TRIGGER notify_new_request_trigger
    AFTER INSERT ON public.service_requests
    FOR EACH ROW
    EXECUTE FUNCTION public.notify_on_new_request();

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================

