-- ============================================
-- URGENT FIX: Message Sending Error
-- ============================================
-- This fixes the error: record "new" has no field "message_type"
-- Run this in Supabase SQL Editor NOW to fix message sending

-- Drop the broken trigger
DROP TRIGGER IF EXISTS trigger_notify_new_message ON public.messages;

-- Recreate the function with correct column names
-- Uses NEW.message_text instead of NEW.content and NEW.message_type
CREATE OR REPLACE FUNCTION notify_new_message()
RETURNS TRIGGER AS $$
DECLARE
  recipient_id uuid;
  sender_name text;
  conversation_request_id uuid;
BEGIN
  -- Get the conversation details
  SELECT request_id INTO conversation_request_id
  FROM public.conversations
  WHERE id = NEW.conversation_id;
  
  -- Determine recipient (the other person in the conversation)
  SELECT 
    CASE 
      WHEN sr.requester_id = NEW.sender_id THEN sr.traveler_id
      ELSE sr.requester_id
    END INTO recipient_id
  FROM public.service_requests sr
  WHERE sr.id = conversation_request_id;
  
  -- Get sender's name
  SELECT COALESCE(first_name || ' ' || last_name, 'Someone') INTO sender_name
  FROM public.users
  WHERE id = NEW.sender_id;
  
  -- Create notification for recipient
  IF recipient_id IS NOT NULL THEN
    INSERT INTO public.notifications (user_id, notification_type, title, body, related_id)
    VALUES (
      recipient_id,
      'new_message',
      'New Message from ' || sender_name,
      LEFT(NEW.message_text, 100),
      conversation_request_id
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER trigger_notify_new_message
AFTER INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION notify_new_message();

-- Verify the fix
SELECT 'Trigger fixed! You can now send messages.' AS status;
