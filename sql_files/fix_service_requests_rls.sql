-- Fix RLS policies for service_requests table
-- This allows requesters to update their own requests to "Completed" status

-- First, check existing policies (for reference)
-- SELECT * FROM pg_policies WHERE tablename = 'service_requests';

-- Drop existing update policy if it's too restrictive
DROP POLICY IF EXISTS "Users can update their own requests" ON service_requests;
DROP POLICY IF EXISTS "Requesters can update their requests" ON service_requests;
DROP POLICY IF EXISTS "Travelers can update requests" ON service_requests;

-- Create a comprehensive update policy for service_requests
-- Allows both requesters and travelers to update requests
CREATE POLICY "Users can update service requests"
ON service_requests
FOR UPDATE
USING (
  auth.uid() = requester_id OR auth.uid() = traveler_id
)
WITH CHECK (
  auth.uid() = requester_id OR auth.uid() = traveler_id
);

-- Also ensure users can read their own requests
DROP POLICY IF EXISTS "Users can view their own requests" ON service_requests;

CREATE POLICY "Users can view service requests"
ON service_requests
FOR SELECT
USING (
  auth.uid() = requester_id OR auth.uid() = traveler_id
);

-- Grant necessary permissions
GRANT UPDATE ON service_requests TO authenticated;
GRANT SELECT ON service_requests TO authenticated;

-- Verify the policies
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'service_requests'
ORDER BY policyname;
