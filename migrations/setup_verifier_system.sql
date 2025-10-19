-- Create users table with roles
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  role TEXT NOT NULL CHECK (role IN ('TRAVELER', 'REQUESTER', 'VERIFIER', 'ADMIN')),
  is_verified BOOLEAN DEFAULT FALSE,
  verified_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create verification_requests table
CREATE TABLE IF NOT EXISTS verification_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  traveler_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  traveler_name TEXT NOT NULL,
  traveler_email TEXT NOT NULL,
  documents JSONB NOT NULL DEFAULT '{}',
  status TEXT NOT NULL CHECK (status IN ('PENDING', 'UNDER_REVIEW', 'APPROVED', 'REJECTED', 'RESUBMITTED')) DEFAULT 'PENDING',
  verifier_id UUID REFERENCES users(id) ON DELETE SET NULL,
  verifier_name TEXT,
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  reviewed_at TIMESTAMP WITH TIME ZONE,
  rejection_reason TEXT,
  verifier_notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_verification_requests_traveler_id ON verification_requests(traveler_id);
CREATE INDEX IF NOT EXISTS idx_verification_requests_verifier_id ON verification_requests(verifier_id);
CREATE INDEX IF NOT EXISTS idx_verification_requests_status ON verification_requests(status);
CREATE INDEX IF NOT EXISTS idx_verification_requests_submitted_at ON verification_requests(submitted_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE verification_requests ENABLE ROW LEVEL SECURITY;

-- RLS Policies for users table
CREATE POLICY "Users can view their own profile" ON users
  FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON users
  FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Verifiers can view all users" ON users
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'VERIFIER'
    )
  );

-- RLS Policies for verification_requests table
CREATE POLICY "Travelers can view their own requests" ON verification_requests
  FOR SELECT
  USING (traveler_id = auth.uid());

CREATE POLICY "Travelers can insert their own requests" ON verification_requests
  FOR INSERT
  WITH CHECK (traveler_id = auth.uid());

CREATE POLICY "Verifiers can view all requests" ON verification_requests
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'VERIFIER'
    )
  );

CREATE POLICY "Verifiers can update requests" ON verification_requests
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'VERIFIER'
    )
  );

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers to automatically update updated_at
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_verification_requests_updated_at
  BEFORE UPDATE ON verification_requests
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Insert a test verifier account (optional - for testing)
-- Password should be set via Supabase Auth Dashboard
-- INSERT INTO auth.users (id, email) VALUES (gen_random_uuid(), 'verifier@pasabay.com');
-- INSERT INTO users (id, email, role) VALUES ((SELECT id FROM auth.users WHERE email = 'verifier@pasabay.com'), 'verifier@pasabay.com', 'VERIFIER');

COMMENT ON TABLE users IS 'User profiles with role-based access';
COMMENT ON TABLE verification_requests IS 'Identity verification requests from travelers';
COMMENT ON COLUMN users.role IS 'User role: TRAVELER, REQUESTER, VERIFIER, or ADMIN';
COMMENT ON COLUMN verification_requests.status IS 'Request status: PENDING, UNDER_REVIEW, APPROVED, REJECTED, or RESUBMITTED';
COMMENT ON COLUMN verification_requests.documents IS 'JSON object containing document URLs (e.g., {"government_id": "url", "selfie": "url"})';
