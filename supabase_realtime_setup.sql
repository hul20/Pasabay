-- ============================================================
-- SUPABASE REALTIME CONFIGURATION FOR CHAT
-- ============================================================
-- This script enables Realtime subscriptions for the messaging system
-- Execute this in your Supabase SQL Editor
-- ============================================================

-- ============================================================
-- STEP 1: ENABLE REALTIME FOR TABLES
-- ============================================================

-- Enable Realtime for messages table
ALTER PUBLICATION supabase_realtime ADD TABLE messages;

-- Enable Realtime for conversations table
ALTER PUBLICATION supabase_realtime ADD TABLE conversations;

-- Enable Realtime for service_requests table (for notifications)
ALTER PUBLICATION supabase_realtime ADD TABLE service_requests;

-- ============================================================
-- STEP 2: CREATE REPLICA IDENTITY (Required for Realtime)
-- ============================================================

-- For messages table
ALTER TABLE messages REPLICA IDENTITY FULL;

-- For conversations table
ALTER TABLE conversations REPLICA IDENTITY FULL;

-- For service_requests table
ALTER TABLE service_requests REPLICA IDENTITY FULL;

-- ============================================================
-- STEP 3: VERIFY SETUP
-- ============================================================

-- Check if tables are in the publication
SELECT 
    schemaname,
    tablename
FROM 
    pg_publication_tables
WHERE 
    pubname = 'supabase_realtime'
    AND tablename IN ('messages', 'conversations', 'service_requests');

-- Check replica identity settings
SELECT 
    schemaname,
    tablename,
    CASE 
        WHEN relreplident = 'f' THEN 'FULL'
        WHEN relreplident = 'd' THEN 'DEFAULT'
        WHEN relreplident = 'n' THEN 'NOTHING'
        WHEN relreplident = 'i' THEN 'INDEX'
    END as replica_identity
FROM 
    pg_class c
JOIN 
    pg_namespace n ON c.relnamespace = n.oid
WHERE 
    n.nspname = 'public'
    AND c.relname IN ('messages', 'conversations', 'service_requests');

-- ============================================================
-- STEP 4: TEST REALTIME (Optional)
-- ============================================================

-- Insert a test message and check if it triggers realtime
-- Run this after setting up the Flutter app
-- You should see the new message appear in real-time

/*
INSERT INTO messages (
    conversation_id,
    sender_id,
    message_text,
    is_read
) VALUES (
    'your-conversation-id-here',
    'your-user-id-here',
    'Test realtime message!',
    false
);
*/

-- ============================================================
-- NOTES:
-- ============================================================
-- 1. Realtime subscriptions work through WebSockets
-- 2. Make sure your Flutter app has proper RLS policies
-- 3. Users can only subscribe to conversations they're part of
-- 4. The subscription automatically reconnects if connection drops
-- 5. Realtime quota: 
--    - Free tier: 2 million messages/month
--    - Pro tier: 5 million messages/month
-- ============================================================

-- ============================================================
-- TROUBLESHOOTING:
-- ============================================================
-- If Realtime isn't working:
--
-- 1. Check if Realtime is enabled in Supabase Dashboard:
--    Settings > API > Realtime > Enable
--
-- 2. Verify RLS policies allow SELECT on tables:
--    - messages: Users can select messages from their conversations
--    - conversations: Users can select their own conversations
--
-- 3. Check browser console for WebSocket errors
--
-- 4. Verify the table is in the publication:
--    SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime';
--
-- 5. Check replica identity:
--    Should be FULL for realtime to work properly
-- ============================================================

