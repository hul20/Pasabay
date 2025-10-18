-- Migration: Add is_verified column to users table
-- Date: October 18, 2025
-- Purpose: Track traveler identity verification status

-- Add is_verified column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND column_name = 'is_verified'
    ) THEN
        ALTER TABLE public.users ADD COLUMN is_verified BOOLEAN DEFAULT FALSE;
        COMMENT ON COLUMN public.users.is_verified IS 'Identity verification status for travelers';
    END IF;
END $$;

-- Create verification_requests table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.verification_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  id_type VARCHAR(50) NOT NULL, -- 'passport', 'national_id', 'drivers_license', 'umid', etc.
  id_front_url TEXT NOT NULL,
  id_back_url TEXT, -- Optional for some ID types
  selfie_url TEXT NOT NULL,
  status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'approved', 'rejected', 'resubmit'
  rejection_reason TEXT,
  reviewed_by UUID REFERENCES auth.users(id),
  reviewed_at TIMESTAMPTZ,
  submitted_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security on verification_requests
ALTER TABLE public.verification_requests ENABLE ROW LEVEL SECURITY;

-- Policies for verification_requests
CREATE POLICY "Users can view own verification requests"
  ON public.verification_requests FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own verification requests"
  ON public.verification_requests FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Admins can view and update all verification requests
-- (You'll need to create an 'admins' table or use auth.uid() checks)

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS verification_requests_user_id_idx ON public.verification_requests(user_id);
CREATE INDEX IF NOT EXISTS verification_requests_status_idx ON public.verification_requests(status);
CREATE INDEX IF NOT EXISTS users_is_verified_idx ON public.users(is_verified);

-- Add comment
COMMENT ON TABLE public.verification_requests IS 'Stores traveler identity verification submissions';
