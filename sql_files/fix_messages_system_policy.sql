-- ============================================================
-- FIX: Allow System Messages from SECURITY DEFINER Functions
-- ============================================================
-- The issue: Payment messages inserted by complete_request_payment()
-- function are blocked by RLS policy that requires auth.uid() = sender_id
--
-- Solution: Drop the restrictive INSERT policy and create a new one
-- that allows inserts in user's own conversations (checking conversation
-- membership instead of sender_id)
-- ============================================================

-- Drop the old restrictive policy
DROP POLICY IF EXISTS "Users can send messages in their conversations" ON public.messages;

-- Create new policy that checks conversation membership, not sender_id
-- This allows SECURITY DEFINER functions to insert messages on behalf of users
CREATE POLICY "Users can send messages in their conversations"
ON public.messages
FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.conversations
        WHERE conversations.id = conversation_id
        AND (conversations.requester_id = auth.uid() 
             OR conversations.traveler_id = auth.uid()
             OR conversations.requester_id = sender_id
             OR conversations.traveler_id = sender_id)
    )
);

-- Grant execute permission on the payment function
GRANT EXECUTE ON FUNCTION complete_request_payment(UUID) TO authenticated;

-- Verify the policy was updated
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    cmd,
    with_check
FROM pg_policies 
WHERE tablename = 'messages'
AND policyname = 'Users can send messages in their conversations';
