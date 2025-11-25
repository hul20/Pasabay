-- Create notifications table if not exists
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid (),
  user_id uuid NOT NULL,
  notification_type character varying(50) NOT NULL,
  title text NOT NULL,
  body text NOT NULL,
  related_id uuid NULL,
  is_read boolean NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE,
  CONSTRAINT notifications_notification_type_check CHECK (
    (notification_type)::text = ANY (
      ARRAY[
        'new_request'::character varying,
        'request_accepted'::character varying,
        'request_rejected'::character varying,
        'new_message'::character varying,
        'request_cancelled'::character varying
      ]::text[]
    )
  )
) TABLESPACE pg_default;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user 
ON public.notifications USING btree (user_id, created_at DESC) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_notifications_unread 
ON public.notifications USING btree (user_id, is_read) TABLESPACE pg_default
WHERE (is_read = false);

-- Enable RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own notifications"
ON public.notifications FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications"
ON public.notifications FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "System can insert notifications"
ON public.notifications FOR INSERT
WITH CHECK (true);

-- ============================================
-- TRIGGER FUNCTION: Notify traveler of new request
-- ============================================
CREATE OR REPLACE FUNCTION notify_traveler_new_request()
RETURNS TRIGGER AS $$
BEGIN
  -- Create notification for the traveler
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
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS trigger_notify_traveler_new_request ON public.service_requests;

-- Create trigger for new requests
CREATE TRIGGER trigger_notify_traveler_new_request
AFTER INSERT ON public.service_requests
FOR EACH ROW
EXECUTE FUNCTION notify_traveler_new_request();

-- ============================================
-- TRIGGER FUNCTION: Notify requester of request status change
-- ============================================
CREATE OR REPLACE FUNCTION notify_requester_status_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Only notify on status changes to Accepted, Rejected, or Completed
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    
    -- Notify on Accepted
    IF NEW.status = 'Accepted' THEN
      INSERT INTO public.notifications (user_id, notification_type, title, body, related_id)
      VALUES (
        NEW.requester_id,
        'request_accepted',
        'Request Accepted',
        'Your ' || NEW.service_type || ' request has been accepted by the traveler!',
        NEW.id
      );
    
    -- Notify on Rejected
    ELSIF NEW.status = 'Rejected' THEN
      INSERT INTO public.notifications (user_id, notification_type, title, body, related_id)
      VALUES (
        NEW.requester_id,
        'request_rejected',
        'Request Rejected',
        'Your ' || NEW.service_type || ' request has been rejected. ' || COALESCE('Reason: ' || NEW.rejection_reason, ''),
        NEW.id
      );
    
    -- Notify on Cancelled
    ELSIF NEW.status = 'Cancelled' THEN
      -- Notify the traveler if requester cancelled
      INSERT INTO public.notifications (user_id, notification_type, title, body, related_id)
      VALUES (
        NEW.traveler_id,
        'request_cancelled',
        'Request Cancelled',
        'A ' || NEW.service_type || ' request has been cancelled by the requester.',
        NEW.id
      );
    
    -- Notify on Order Sent (proof uploaded)
    ELSIF NEW.status = 'Order Sent' AND OLD.status = 'Accepted' THEN
      INSERT INTO public.notifications (user_id, notification_type, title, body, related_id)
      VALUES (
        NEW.requester_id,
        'request_accepted',
        'Order Sent',
        'The traveler has sent your order. Check your messages for proof of delivery.',
        NEW.id
      );
    
    -- Notify traveler on Completed (requester confirmed)
    ELSIF NEW.status = 'Completed' AND OLD.status = 'Order Sent' THEN
      INSERT INTO public.notifications (user_id, notification_type, title, body, related_id)
      VALUES (
        NEW.traveler_id,
        'request_accepted',
        'Request Completed',
        'The requester has confirmed receipt. Your service fee has been credited!',
        NEW.id
      );
    END IF;
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS trigger_notify_requester_status_change ON public.service_requests;

-- Create trigger for status changes
CREATE TRIGGER trigger_notify_requester_status_change
AFTER UPDATE ON public.service_requests
FOR EACH ROW
EXECUTE FUNCTION notify_requester_status_change();

-- ============================================
-- TRIGGER FUNCTION: Notify on new message
-- ============================================
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

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS trigger_notify_new_message ON public.messages;

-- Create trigger for new messages
CREATE TRIGGER trigger_notify_new_message
AFTER INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION notify_new_message();

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON public.notifications TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;
