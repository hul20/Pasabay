-- ============================================
-- FCM Push Notification Setup
-- ============================================
-- This adds support for sending push notifications to devices
-- even when the app is closed or in the background

-- Add FCM token storage to users table
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS fcm_token TEXT NULL;

-- Create index for FCM token lookups
CREATE INDEX IF NOT EXISTS idx_users_fcm_token 
ON public.users(id) 
WHERE fcm_token IS NOT NULL;

-- ============================================
-- Function to send push notification via Edge Function
-- ============================================
-- This function will be called by triggers to send actual push notifications
-- You'll need to create a Supabase Edge Function named 'send-push-notification'

CREATE OR REPLACE FUNCTION send_push_notification(
  p_user_id UUID,
  p_title TEXT,
  p_body TEXT,
  p_data JSONB DEFAULT '{}'::jsonb
)
RETURNS void AS $$
DECLARE
  v_fcm_token TEXT;
BEGIN
  -- Get the user's FCM token
  SELECT fcm_token INTO v_fcm_token
  FROM public.users
  WHERE id = p_user_id;
  
  -- If user has an FCM token, send the notification
  IF v_fcm_token IS NOT NULL THEN
    -- Call the Edge Function to send push notification
    -- This uses Supabase's pg_net extension
    PERFORM
      net.http_post(
        url := current_setting('app.supabase_url') || '/functions/v1/send-push-notification',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || current_setting('app.supabase_service_key')
        ),
        body := jsonb_build_object(
          'fcm_token', v_fcm_token,
          'title', p_title,
          'body', p_body,
          'data', p_data
        )
      );
  END IF;
  
EXCEPTION WHEN OTHERS THEN
  -- Log error but don't fail the transaction
  RAISE WARNING 'Failed to send push notification: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- UPDATED TRIGGER FUNCTIONS WITH PUSH NOTIFICATIONS
-- ============================================

-- Update: Notify traveler of new request (with push)
CREATE OR REPLACE FUNCTION notify_traveler_new_request()
RETURNS TRIGGER AS $$
DECLARE
  notification_title TEXT;
  notification_body TEXT;
BEGIN
  notification_title := 'New ' || NEW.service_type || ' Request';
  notification_body := CASE 
    WHEN NEW.service_type = 'Pabakal' THEN 'You have a new Pabakal request for ' || COALESCE(NEW.product_name, 'an item')
    WHEN NEW.service_type = 'Pasabay' THEN 'You have a new Pasabay request from ' || COALESCE(NEW.recipient_name, 'a customer')
    ELSE 'You have a new service request'
  END;
  
  -- Create in-app notification
  INSERT INTO public.notifications (user_id, notification_type, title, body, related_id)
  VALUES (
    NEW.traveler_id,
    'new_request',
    notification_title,
    notification_body,
    NEW.id
  );
  
  -- Send push notification
  PERFORM send_push_notification(
    NEW.traveler_id,
    notification_title,
    notification_body,
    jsonb_build_object(
      'type', 'new_request',
      'request_id', NEW.id
    )
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update: Notify requester of request status change (with push)
CREATE OR REPLACE FUNCTION notify_requester_status_change()
RETURNS TRIGGER AS $$
DECLARE
  notification_title TEXT;
  notification_body TEXT;
  recipient_id UUID;
  notification_type TEXT;
BEGIN
  -- Only notify on status changes
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    
    -- Notify on Accepted
    IF NEW.status = 'Accepted' THEN
      notification_title := 'Request Accepted';
      notification_body := 'Your ' || NEW.service_type || ' request has been accepted by the traveler!';
      recipient_id := NEW.requester_id;
      notification_type := 'request_accepted';
    
    -- Notify on Rejected
    ELSIF NEW.status = 'Rejected' THEN
      notification_title := 'Request Rejected';
      notification_body := 'Your ' || NEW.service_type || ' request has been rejected. ' || COALESCE('Reason: ' || NEW.rejection_reason, '');
      recipient_id := NEW.requester_id;
      notification_type := 'request_rejected';
    
    -- Notify on Cancelled
    ELSIF NEW.status = 'Cancelled' THEN
      notification_title := 'Request Cancelled';
      notification_body := 'A ' || NEW.service_type || ' request has been cancelled by the requester.';
      recipient_id := NEW.traveler_id;
      notification_type := 'request_cancelled';
    
    -- Notify on Order Sent (proof uploaded)
    ELSIF NEW.status = 'Order Sent' AND OLD.status = 'Accepted' THEN
      notification_title := 'Order Sent';
      notification_body := 'The traveler has sent your order. Check your messages for proof of delivery.';
      recipient_id := NEW.requester_id;
      notification_type := 'request_accepted';
    
    -- Notify traveler on Completed (requester confirmed)
    ELSIF NEW.status = 'Completed' AND OLD.status = 'Order Sent' THEN
      notification_title := 'Request Completed';
      notification_body := 'The requester has confirmed receipt. Your service fee has been credited!';
      recipient_id := NEW.traveler_id;
      notification_type := 'request_accepted';
    END IF;
    
    -- Send notifications if we have valid data
    IF notification_title IS NOT NULL THEN
      -- Create in-app notification
      INSERT INTO public.notifications (user_id, notification_type, title, body, related_id)
      VALUES (
        recipient_id,
        notification_type,
        notification_title,
        notification_body,
        NEW.id
      );
      
      -- Send push notification
      PERFORM send_push_notification(
        recipient_id,
        notification_title,
        notification_body,
        jsonb_build_object(
          'type', notification_type,
          'request_id', NEW.id
        )
      );
    END IF;
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update: Notify on new message (with push)
CREATE OR REPLACE FUNCTION notify_new_message()
RETURNS TRIGGER AS $$
DECLARE
  recipient_id uuid;
  sender_name text;
  conversation_request_id uuid;
  notification_title TEXT;
  notification_body TEXT;
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
    notification_title := 'New Message from ' || sender_name;
    notification_body := LEFT(NEW.message_text, 100);
    
    -- Create in-app notification
    INSERT INTO public.notifications (user_id, notification_type, title, body, related_id)
    VALUES (
      recipient_id,
      'new_message',
      notification_title,
      notification_body,
      conversation_request_id
    );
    
    -- Send push notification
    PERFORM send_push_notification(
      recipient_id,
      notification_title,
      notification_body,
      jsonb_build_object(
        'type', 'new_message',
        'request_id', conversation_request_id,
        'conversation_id', NEW.conversation_id
      )
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- Helper function to update FCM token
-- ============================================
CREATE OR REPLACE FUNCTION update_fcm_token(p_user_id UUID, p_fcm_token TEXT)
RETURNS void AS $$
BEGIN
  UPDATE public.users
  SET fcm_token = p_fcm_token
  WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION update_fcm_token(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION send_push_notification(UUID, TEXT, TEXT, JSONB) TO postgres;

-- ============================================
-- NOTES FOR SETUP
-- ============================================
-- 1. Enable pg_net extension: CREATE EXTENSION IF NOT EXISTS pg_net;
-- 2. Set configuration variables in Supabase dashboard
-- 3. Create Edge Function 'send-push-notification' 
-- 4. Add FCM setup in Flutter app
-- 5. Store FCM tokens when users log in
