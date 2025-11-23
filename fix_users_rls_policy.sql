-- ============================================================
-- FIX: Users Table RLS Policy for Public Profile Information
-- ============================================================
-- This script allows users to view basic profile information 
-- (name, image) of other users while keeping sensitive data private
-- ============================================================

-- DROP the restrictive policy that only allows viewing own profile
DROP POLICY IF EXISTS "Users can view their own profile" ON users;

-- CREATE a new policy that allows viewing basic profile info of all users
-- This is needed for:
-- - Requesters to see traveler names and images
-- - Travelers to see requester names and images
-- - Displaying user information in service requests
CREATE POLICY "Users can view all profiles" ON users
  FOR SELECT
  TO authenticated
  USING (true);

-- Note: This allows viewing all profile fields. 
-- If you want to restrict to only certain fields, you would need to:
-- 1. Create a separate "public_profiles" view with only first_name, last_name, profile_image_url
-- 2. Query from that view instead of the users table directly
-- 3. Apply RLS to the view

-- CREATE a policy for users to update their own profile
CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- CREATE a policy for users to view their own complete profile
-- (This ensures users can see all their own data)
CREATE POLICY "Users can view own complete profile" ON users
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- ============================================================
-- VERIFICATION
-- ============================================================

-- Check the policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'users'
ORDER BY policyname;

-- Test query (should work now for any user)
-- SELECT id, first_name, last_name, profile_image_url FROM users LIMIT 5;

-- ============================================================
-- NOTES
-- ============================================================
-- This change allows all authenticated users to view basic profile
-- information of other users, which is necessary for:
-- 
-- 1. Requester searching for travelers
-- 2. Displaying traveler names in search results
-- 3. Showing user info in service requests
-- 4. Displaying user info in conversations
-- 
-- Security considerations:
-- - Email and other sensitive data is still in the table
-- - Consider creating a public_profiles view with only safe fields
-- - Or filter in application code to only request safe fields
-- 
-- Current query pattern (safe):
-- SELECT first_name, last_name, profile_image_url FROM users WHERE id = ?
-- 
-- This only selects public fields, not email or other sensitive data
-- ============================================================


