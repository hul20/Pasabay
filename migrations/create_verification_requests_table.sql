-- =====================================================
-- Create Verification Requests Table
-- =====================================================
-- Run this FIRST before add_verification_file_urls.sql
-- https://supabase.com/dashboard/project/czodfzjqkvpicbnhtqhv/sql
-- =====================================================

-- Step 1: Create verification_requests table
CREATE TABLE IF NOT EXISTS public.verification_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  rejection_reason TEXT,
  reviewed_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Step 2: Add comments
COMMENT ON TABLE public.verification_requests IS 'Traveler identity verification requests';
COMMENT ON COLUMN public.verification_requests.user_id IS 'User submitting verification request';
COMMENT ON COLUMN public.verification_requests.status IS 'Verification status: pending, approved, or rejected';
COMMENT ON COLUMN public.verification_requests.rejection_reason IS 'Reason for rejection (if rejected)';
COMMENT ON COLUMN public.verification_requests.reviewed_at IS 'When admin reviewed the request';
COMMENT ON COLUMN public.verification_requests.reviewed_by IS 'Admin who reviewed the request';

-- Step 3: Create indexes
CREATE INDEX IF NOT EXISTS verification_requests_user_id_idx 
ON public.verification_requests(user_id);

CREATE INDEX IF NOT EXISTS verification_requests_status_idx 
ON public.verification_requests(status);

CREATE INDEX IF NOT EXISTS verification_requests_created_at_idx 
ON public.verification_requests(created_at DESC);

-- Step 4: Enable Row Level Security
ALTER TABLE public.verification_requests ENABLE ROW LEVEL SECURITY;

-- Step 5: Create RLS Policies

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

-- Step 6: Create function to auto-update updated_at
CREATE OR REPLACE FUNCTION public.update_verification_requests_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 7: Create trigger
DROP TRIGGER IF EXISTS verification_requests_updated_at_trigger ON public.verification_requests;
CREATE TRIGGER verification_requests_updated_at_trigger
  BEFORE UPDATE ON public.verification_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.update_verification_requests_updated_at();

-- =====================================================
-- Table Created Successfully! ✅
-- =====================================================
-- Next: Run add_verification_file_urls.sql
-- =====================================================
