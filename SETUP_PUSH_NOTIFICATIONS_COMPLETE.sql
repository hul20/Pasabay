-- ============================================
-- COMPLETE PUSH NOTIFICATION SETUP
-- Run this entire file in Supabase SQL Editor
-- ============================================

-- Step 1: Enable required extensions
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Step 2: Add fcm_token column to users table
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS fcm_token TEXT NULL;

-- Step 3: Create index for FCM tokens
CREATE INDEX IF NOT EXISTS idx_users_fcm_token 
ON public.users(id) 
WHERE fcm_token IS NOT NULL;

-- Step 4: Function to send push notification via Edge Function
CREATE OR REPLACE FUNCTION send_push_notification_via_edge_function(
  p_user_id uuid,
  p_title text,
  p_body text,
  p_data jsonb DEFAULT '{}'::jsonb
)
RETURNS void AS $$
DECLARE
  v_fcm_token text;
BEGIN
  -- Get user's FCM token
  SELECT fcm_token INTO v_fcm_token
  FROM public.users
  WHERE id = p_user_id;

  -- Only proceed if FCM token exists
  IF v_fcm_token IS NOT NULL THEN
    -- Call Edge Function
    PERFORM net.http_post(
      url := 'https://czodfzjqkvpicbnhtqhv.supabase.co/functions/v1/send-push-notification',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN6b2Rmempxa3ZwaWNibmh0cWh2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA3MDA2MDAsImV4cCI6MjA3NjI3NjYwMH0.jmegrTiS_SssfQrAqc66xGLn3LIz12tMdHeIu3WYYfQ'
      ),
      body := jsonb_build_object(
        'fcmToken', v_fcm_token,
        'title', p_title,
        'body', p_body,
        'data', p_data
      )
    );
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'Failed to send push notification: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 5: Grant permissions
GRANT EXECUTE ON FUNCTION send_push_notification_via_edge_function TO authenticated;
GRANT EXECUTE ON FUNCTION send_push_notification_via_edge_function TO service_role;

-- Step 6: Update trigger for new requests
DROP TRIGGER IF EXISTS trigger_notify_traveler_new_request ON public.service_requests;

CREATE OR REPLACE FUNCTION notify_traveler_new_request()
RETURNS TRIGGER AS $$
BEGIN
  -- Create in-app notification
  INSERT INTO public.notifications (user_id, notification_type, title, body, related_id)
  VALUES (
    NEW.traveler_id,
    'new_request',
    'New ' || NEW.service_type || ' Request',
    CASE 
      WHEN NEW.service_type = 'Pabakal' THEN 'You have a new Pabakal request for ' || COALESCE(NEW.product_name, 'an item')
      WHEN NEW.service_type = 'Pasabay' THEN 'You have a new Pasabay request from ' || COALESCE(NEW.recipient_name, 'a customer')
      ELSE 'You have a new service request'
    END,
    NEW.id
  );
  
  -- Send push notification
  PERFORM send_push_notification_via_edge_function(
    NEW.traveler_id,
    'New ' || NEW.service_type || ' Request',
    CASE 
      WHEN NEW.service_type = 'Pabakal' THEN 'You have a new Pabakal request'
      WHEN NEW.service_type = 'Pasabay' THEN 'You have a new Pasabay request'
      ELSE 'You have a new service request'
    END,
    jsonb_build_object('request_id', NEW.id::text, 'type', 'new_request')
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_notify_traveler_new_request
AFTER INSERT ON public.service_requests
FOR EACH ROW
EXECUTE FUNCTION notify_traveler_new_request();

-- Step 7: Update trigger for status changes
DROP TRIGGER IF EXISTS trigger_notify_requester_status_change ON public.service_requests;

CREATE OR REPLACE FUNCTION notify_requester_status_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    
    IF NEW.status = 'Accepted' THEN
      INSERT INTO public.notifications (user_id, notification_type, title, body, related_id)
      VALUES (
        NEW.requester_id,
        'request_accepted',
        'Request Accepted',
        'Your ' || NEW.service_type || ' request has been accepted by the traveler!',
        NEW.id
      );
      
      PERFORM send_push_notification_via_edge_function(
        NEW.requester_id,
        'Request Accepted',
        'Your ' || NEW.service_type || ' request has been accepted!',
        jsonb_build_object('request_id', NEW.id::text, 'type', 'request_accepted')
      );
    
    ELSIF NEW.status = 'Rejected' THEN
      INSERT INTO public.notifications (user_id, notification_type, title, body, related_id)
      VALUES (
        NEW.requester_id,
        'request_rejected',
        'Request Rejected',
        'Your ' || NEW.service_type || ' request has been rejected. ' || COALESCE('Reason: ' || NEW.rejection_reason, ''),
        NEW.id
      );
      
      PERFORM send_push_notification_via_edge_function(
        NEW.requester_id,
        'Request Rejected',
        'Your ' || NEW.service_type || ' request has been rejected',
        jsonb_build_object('request_id', NEW.id::text, 'type', 'request_rejected')
      );
    
    ELSIF NEW.status = 'Cancelled' THEN
      INSERT INTO public.notifications (user_id, notification_type, title, body, related_id)
      VALUES (
        NEW.traveler_id,
        'request_cancelled',
        'Request Cancelled',
        'A ' || NEW.service_type || ' request has been cancelled by the requester.',
        NEW.id
      );
      
      PERFORM send_push_notification_via_edge_function(
        NEW.traveler_id,
        'Request Cancelled',
        'A ' || NEW.service_type || ' request has been cancelled',
        jsonb_build_object('request_id', NEW.id::text, 'type', 'request_cancelled')
      );
    
    ELSIF NEW.status = 'Order Sent' AND OLD.status = 'Accepted' THEN
      INSERT INTO public.notifications (user_id, notification_type, title, body, related_id)
      VALUES (
        NEW.requester_id,
        'request_accepted',
        'Order Sent',
        'The traveler has sent your order. Check your messages for proof of delivery.',
        NEW.id
      );
      
      PERFORM send_push_notification_via_edge_function(
        NEW.requester_id,
        'Order Sent',
        'The traveler has sent your order',
        jsonb_build_object('request_id', NEW.id::text, 'type', 'order_sent')
      );
    
    ELSIF NEW.status = 'Completed' AND OLD.status = 'Order Sent' THEN
      INSERT INTO public.notifications (user_id, notification_type, title, body, related_id)
      VALUES (
        NEW.traveler_id,
        'request_accepted',
        'Request Completed',
        'The requester has confirmed receipt. Your service fee has been credited!',
        NEW.id
      );
      
      PERFORM send_push_notification_via_edge_function(
        NEW.traveler_id,
        'Request Completed',
        'The requester has confirmed receipt',
        jsonb_build_object('request_id', NEW.id::text, 'type', 'request_completed')
      );
    END IF;
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_notify_requester_status_change
AFTER UPDATE ON public.service_requests
FOR EACH ROW
EXECUTE FUNCTION notify_requester_status_change();

-- Step 8: Update trigger for new messages
DROP TRIGGER IF EXISTS trigger_notify_new_message ON public.messages;

CREATE OR REPLACE FUNCTION notify_new_message()
RETURNS TRIGGER AS $$
DECLARE
  recipient_id uuid;
  sender_name text;
  conversation_request_id uuid;
BEGIN
  SELECT request_id INTO conversation_request_id
  FROM public.conversations
  WHERE id = NEW.conversation_id;
  
  SELECT 
    CASE 
      WHEN sr.requester_id = NEW.sender_id THEN sr.traveler_id
      ELSE sr.requester_id
    END INTO recipient_id
  FROM public.service_requests sr
  WHERE sr.id = conversation_request_id;
  
  SELECT COALESCE(first_name || ' ' || last_name, 'Someone') INTO sender_name
  FROM public.users
  WHERE id = NEW.sender_id;
  
  IF recipient_id IS NOT NULL THEN
    INSERT INTO public.notifications (user_id, notification_type, title, body, related_id)
    VALUES (
      recipient_id,
      'new_message',
      'New Message from ' || sender_name,
      LEFT(NEW.message_text, 100),
      conversation_request_id
    );
    
    PERFORM send_push_notification_via_edge_function(
      recipient_id,
      'New Message from ' || sender_name,
      LEFT(NEW.message_text, 100),
      jsonb_build_object('request_id', conversation_request_id::text, 'type', 'new_message')
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_notify_new_message
AFTER INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION notify_new_message();

-- Verification queries
SELECT 'Setup complete! Run these queries to verify:' AS message;
SELECT 'SELECT * FROM pg_extension WHERE extname = ''pg_net'';' AS verify_extension;
SELECT 'SELECT column_name FROM information_schema.columns WHERE table_name = ''users'' AND column_name = ''fcm_token'';' AS verify_column;
SELECT 'SELECT trigger_name FROM information_schema.triggers WHERE event_object_table IN (''service_requests'', ''messages'');' AS verify_triggers;
