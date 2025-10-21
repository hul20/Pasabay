-- Complete verification_requests table setup
-- Run this in Supabase SQL Editor

-- Drop existing table if you want to start fresh (CAUTION: This deletes data!)
-- DROP TABLE IF EXISTS verification_requests CASCADE;

-- Create verification_requests table
CREATE TABLE IF NOT EXISTS verification_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Traveler information
  traveler_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  traveler_name TEXT,
  traveler_email TEXT,
  
  -- Document URLs
  gov_id_url TEXT NOT NULL,
  selfie_url TEXT NOT NULL,
  gov_id_filename TEXT,
  selfie_filename TEXT,
  
  -- Status and review
  status TEXT NOT NULL DEFAULT 'Pending' CHECK (status IN ('Pending', 'Under Review', 'Approved', 'Rejected', 'Resubmitted')),
  
  -- Verifier information
  verifier_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  verifier_name TEXT,
  verifier_notes TEXT,
  rejection_reason TEXT,
  
  -- Timestamps
  submitted_at TIMESTAMPTZ DEFAULT NOW(),
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_verification_requests_traveler_id ON verification_requests(traveler_id);
CREATE INDEX IF NOT EXISTS idx_verification_requests_verifier_id ON verification_requests(verifier_id);
CREATE INDEX IF NOT EXISTS idx_verification_requests_status ON verification_requests(status);
CREATE INDEX IF NOT EXISTS idx_verification_requests_submitted_at ON verification_requests(submitted_at DESC);

-- Enable Row Level Security
ALTER TABLE verification_requests ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can view their own requests
CREATE POLICY "Users can view own verification requests" ON verification_requests
  FOR SELECT
  USING (auth.uid() = traveler_id);

-- RLS Policy: Users can insert their own requests
CREATE POLICY "Users can insert own verification requests" ON verification_requests
  FOR INSERT
  WITH CHECK (auth.uid() = traveler_id);

-- RLS Policy: Verifiers can view all requests
CREATE POLICY "Verifiers can view all verification requests" ON verification_requests
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'Verifier'
    )
  );

-- RLS Policy: Verifiers can update requests
CREATE POLICY "Verifiers can update verification requests" ON verification_requests
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'Verifier'
    )
  );

-- Create function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for auto-updating updated_at
DROP TRIGGER IF EXISTS update_verification_requests_updated_at ON verification_requests;
CREATE TRIGGER update_verification_requests_updated_at
  BEFORE UPDATE ON verification_requests
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Verify table was created
SELECT 
  column_name, 
  data_type, 
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'verification_requests'
ORDER BY ordinal_position;
