-- =====================================================
-- Identity Verification File Upload - Database Setup
-- =====================================================
-- Run this SQL in Supabase Dashboard → SQL Editor
-- https://supabase.com/dashboard/project/czodfzjqkvpicbnhtqhv/sql
-- =====================================================

-- Step 1: Add file URL columns to verification_requests table
ALTER TABLE public.verification_requests 
ADD COLUMN IF NOT EXISTS gov_id_url TEXT,
ADD COLUMN IF NOT EXISTS selfie_url TEXT,
ADD COLUMN IF NOT EXISTS gov_id_filename TEXT,
ADD COLUMN IF NOT EXISTS selfie_filename TEXT,
ADD COLUMN IF NOT EXISTS submitted_at TIMESTAMPTZ;

-- Step 2: Add comments for documentation
COMMENT ON COLUMN public.verification_requests.gov_id_url IS 'Supabase Storage URL for Government ID document';
COMMENT ON COLUMN public.verification_requests.selfie_url IS 'Supabase Storage URL for selfie photo';
COMMENT ON COLUMN public.verification_requests.gov_id_filename IS 'Original filename of Government ID document';
COMMENT ON COLUMN public.verification_requests.selfie_filename IS 'Original filename of selfie photo';
COMMENT ON COLUMN public.verification_requests.submitted_at IS 'Timestamp when verification was submitted';

-- Step 3: Create indexes for better query performance
CREATE INDEX IF NOT EXISTS verification_requests_gov_id_url_idx 
ON public.verification_requests(gov_id_url);

CREATE INDEX IF NOT EXISTS verification_requests_selfie_url_idx 
ON public.verification_requests(selfie_url);

CREATE INDEX IF NOT EXISTS verification_requests_submitted_at_idx 
ON public.verification_requests(submitted_at DESC);

-- Step 4: Update any existing records (if any)
UPDATE public.verification_requests 
SET submitted_at = created_at 
WHERE submitted_at IS NULL;

-- =====================================================
-- Verification Complete! ✅
-- =====================================================
-- Next Steps:
-- 1. Create Storage bucket: 'verification-documents'
-- 2. Set bucket to PUBLIC
-- 3. Configure Storage policies (see FILE_UPLOAD_IMPLEMENTATION.md)
-- =====================================================
