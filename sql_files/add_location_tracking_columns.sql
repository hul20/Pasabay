-- ============================================================================
-- ADD LOCATION TRACKING COLUMNS TO SERVICE REQUESTS
-- ============================================================================
-- This migration adds columns for real-time location tracking of travelers
-- Run this in Supabase SQL Editor
-- ============================================================================

-- Add location tracking columns
ALTER TABLE public.service_requests
ADD COLUMN IF NOT EXISTS traveler_latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS traveler_longitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS location_updated_at TIMESTAMPTZ;

-- Create index for faster location queries
CREATE INDEX IF NOT EXISTS idx_service_requests_location
ON public.service_requests(id, traveler_latitude, traveler_longitude)
WHERE traveler_latitude IS NOT NULL AND traveler_longitude IS NOT NULL;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Check that the columns were added successfully
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'service_requests'
  AND column_name IN ('traveler_latitude', 'traveler_longitude', 'location_updated_at')
ORDER BY column_name;

-- Check the index
SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename = 'service_requests'
  AND indexname = 'idx_service_requests_location';
