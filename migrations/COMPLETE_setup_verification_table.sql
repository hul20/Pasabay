-- =====================================================
-- COMPLETE Verification Requests Table Setup
-- =====================================================
-- Run this ONCE in Supabase SQL Editor
-- Dashboard → SQL Editor → New Query → Paste & Run
-- =====================================================

-- Step 1: Drop existing table if you want to start fresh (CAREFUL!)
-- DROP TABLE IF EXISTS public.verification_requests CASCADE;

-- Step 2: Create verification_requests table WITH all columns
CREATE TABLE IF NOT EXISTS public.verification_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- File URLs and metadata
  gov_id_url TEXT,
  selfie_url TEXT,
  gov_id_filename TEXT,
  selfie_filename TEXT,
  submitted_at TIMESTAMPTZ,
  
  -- Status tracking
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  rejection_reason TEXT,
  reviewed_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES auth.users(id),
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Step 3: Add comments
COMMENT ON TABLE public.verification_requests IS 'Traveler identity verification requests';
COMMENT ON COLUMN public.verification_requests.user_id IS 'User submitting verification request';
COMMENT ON COLUMN public.verification_requests.gov_id_url IS 'Supabase Storage URL for government ID document';
COMMENT ON COLUMN public.verification_requests.selfie_url IS 'Supabase Storage URL for selfie photo';
COMMENT ON COLUMN public.verification_requests.gov_id_filename IS 'Original filename of government ID';
COMMENT ON COLUMN public.verification_requests.selfie_filename IS 'Original filename of selfie';
COMMENT ON COLUMN public.verification_requests.submitted_at IS 'When user submitted the verification request';
COMMENT ON COLUMN public.verification_requests.status IS 'Verification status: pending, approved, or rejected';
COMMENT ON COLUMN public.verification_requests.rejection_reason IS 'Reason for rejection (if rejected)';
COMMENT ON COLUMN public.verification_requests.reviewed_at IS 'When admin reviewed the request';
COMMENT ON COLUMN public.verification_requests.reviewed_by IS 'Admin who reviewed the request';

-- Step 4: Create indexes
CREATE INDEX IF NOT EXISTS verification_requests_user_id_idx 
ON public.verification_requests(user_id);

CREATE INDEX IF NOT EXISTS verification_requests_status_idx 
ON public.verification_requests(status);

CREATE INDEX IF NOT EXISTS verification_requests_created_at_idx 
ON public.verification_requests(created_at DESC);

CREATE INDEX IF NOT EXISTS verification_requests_gov_id_url_idx 
ON public.verification_requests(gov_id_url);

CREATE INDEX IF NOT EXISTS verification_requests_selfie_url_idx 
ON public.verification_requests(selfie_url);

-- Step 5: Enable Row Level Security
ALTER TABLE public.verification_requests ENABLE ROW LEVEL SECURITY;

-- Step 6: Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own verification requests" ON public.verification_requests;
DROP POLICY IF EXISTS "Users can create own verification requests" ON public.verification_requests;
DROP POLICY IF EXISTS "Users can update own pending requests" ON public.verification_requests;

-- Step 7: Create RLS Policies

-- Policy: Users can view their own verification requests
CREATE POLICY "Users can view own verification requests"
ON public.verification_requests
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Policy: Users can insert their own verification requests
CREATE POLICY "Users can create own verification requests"
ON public.verification_requests
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own pending requests
CREATE POLICY "Users can update own pending requests"
ON public.verification_requests
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id AND status = 'pending')
WITH CHECK (auth.uid() = user_id AND status = 'pending');

-- Step 8: Create function to auto-update updated_at
CREATE OR REPLACE FUNCTION public.update_verification_requests_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 9: Create trigger
DROP TRIGGER IF EXISTS verification_requests_updated_at_trigger ON public.verification_requests;
CREATE TRIGGER verification_requests_updated_at_trigger
  BEFORE UPDATE ON public.verification_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.update_verification_requests_updated_at();

-- =====================================================
-- ✅ Table Created Successfully!
-- =====================================================
-- The table now includes ALL required columns:
-- - id, user_id
-- - gov_id_url, selfie_url
-- - gov_id_filename, selfie_filename
-- - submitted_at
-- - status, rejection_reason
-- - reviewed_at, reviewed_by
-- - created_at, updated_at
-- =====================================================

-- Test query: View the table structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'verification_requests'
ORDER BY ordinal_position;

-- =====================================================
-- Next Steps:
-- 1. Create Storage bucket: verification-documents
-- 2. Set Storage RLS policies (see FILE_UPLOAD_SETUP.md)
-- 3. Test the upload flow in your app
-- =====================================================
