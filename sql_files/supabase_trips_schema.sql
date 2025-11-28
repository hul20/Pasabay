-- ============================================
-- TRIPS TABLE SCHEMA FOR PASABAY APP
-- ============================================
-- This table stores traveler trip information including routes, schedules, and status

-- Drop existing table if needed (CAUTION: This deletes all data)
-- DROP TABLE IF EXISTS public.trips CASCADE;

-- Create trips table
CREATE TABLE IF NOT EXISTS public.trips (
  -- Primary identification
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  traveler_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Location information
  departure_location text NOT NULL,
  departure_lat double precision,
  departure_lng double precision,
  destination_location text NOT NULL,
  destination_lat double precision,
  destination_lng double precision,
  
  -- Schedule information
  departure_date date NOT NULL,
  departure_time time NOT NULL,
  estimated_arrival_time time,
  
  -- Trip details
  trip_status text NOT NULL DEFAULT 'Upcoming',
  available_capacity integer DEFAULT 5,
  current_requests integer DEFAULT 0,
  
  -- Financial
  base_fee decimal(10,2) DEFAULT 0.00,
  total_earnings decimal(10,2) DEFAULT 0.00,
  
  -- Additional info
  notes text,
  route_polyline text,
  
  -- Metadata
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  
  -- Constraints
  CONSTRAINT trips_status_check CHECK (trip_status IN ('Upcoming', 'In Progress', 'Completed', 'Cancelled')),
  CONSTRAINT trips_capacity_check CHECK (current_requests <= available_capacity),
  CONSTRAINT trips_future_date_check CHECK (departure_date >= CURRENT_DATE)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_trips_traveler_id ON public.trips(traveler_id);
CREATE INDEX IF NOT EXISTS idx_trips_status ON public.trips(trip_status);
CREATE INDEX IF NOT EXISTS idx_trips_departure_date ON public.trips(departure_date);
CREATE INDEX IF NOT EXISTS idx_trips_traveler_status ON public.trips(traveler_id, trip_status);

-- Enable Row Level Security
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;

-- RLS Policies for trips table

-- Policy: Travelers can view their own trips
CREATE POLICY "Travelers can view their own trips"
ON public.trips
FOR SELECT
TO authenticated
USING (auth.uid() = traveler_id);

-- Policy: Travelers can insert their own trips
CREATE POLICY "Travelers can insert their own trips"
ON public.trips
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = traveler_id);

-- Policy: Travelers can update their own trips
CREATE POLICY "Travelers can update their own trips"
ON public.trips
FOR UPDATE
TO authenticated
USING (auth.uid() = traveler_id)
WITH CHECK (auth.uid() = traveler_id);

-- Policy: Travelers can delete their own trips
CREATE POLICY "Travelers can delete their own trips"
ON public.trips
FOR DELETE
TO authenticated
USING (auth.uid() = traveler_id);

-- Policy: Requesters can view active trips (for searching/browsing)
CREATE POLICY "Requesters can view active trips"
ON public.trips
FOR SELECT
TO authenticated
USING (
  trip_status IN ('Upcoming', 'In Progress') 
  AND current_requests < available_capacity
);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_trips_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to call the function before updates
DROP TRIGGER IF EXISTS trips_updated_at_trigger ON public.trips;
CREATE TRIGGER trips_updated_at_trigger
  BEFORE UPDATE ON public.trips
  FOR EACH ROW
  EXECUTE FUNCTION update_trips_updated_at();

-- Function to get trip statistics for a traveler
CREATE OR REPLACE FUNCTION get_trip_stats(_traveler_id uuid)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  result json;
BEGIN
  SELECT json_build_object(
    'active_trips', COUNT(*) FILTER (WHERE trip_status IN ('Upcoming', 'In Progress')),
    'completed_trips', COUNT(*) FILTER (WHERE trip_status = 'Completed'),
    'cancelled_trips', COUNT(*) FILTER (WHERE trip_status = 'Cancelled'),
    'total_earnings', COALESCE(SUM(total_earnings) FILTER (WHERE trip_status = 'Completed'), 0),
    'current_month_earnings', COALESCE(
      SUM(total_earnings) FILTER (
        WHERE trip_status = 'Completed' 
        AND EXTRACT(MONTH FROM updated_at) = EXTRACT(MONTH FROM CURRENT_DATE)
        AND EXTRACT(YEAR FROM updated_at) = EXTRACT(YEAR FROM CURRENT_DATE)
      ), 0
    )
  ) INTO result
  FROM public.trips
  WHERE traveler_id = _traveler_id;
  
  RETURN result;
END;
$$;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION get_trip_stats(uuid) TO authenticated;

-- ============================================
-- SAMPLE DATA (OPTIONAL - FOR TESTING)
-- ============================================
-- Uncomment to insert sample data for testing

/*
-- Insert sample trip (replace 'YOUR_USER_ID' with actual user ID)
INSERT INTO public.trips (
  traveler_id,
  departure_location,
  departure_lat,
  departure_lng,
  destination_location,
  destination_lat,
  destination_lng,
  departure_date,
  departure_time,
  trip_status,
  available_capacity,
  base_fee
) VALUES (
  'YOUR_USER_ID'::uuid,
  'Manila, Philippines',
  14.5995,
  120.9842,
  'Baguio City, Philippines',
  16.4023,
  120.5960,
  CURRENT_DATE + INTERVAL '2 days',
  '08:00:00',
  'Upcoming',
  5,
  500.00
);
*/

-- ============================================
-- VERIFICATION
-- ============================================
-- Run these queries to verify the schema was created correctly

-- Check if table exists
-- SELECT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'trips');

-- Check table structure
-- SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'trips';

-- Check policies
-- SELECT * FROM pg_policies WHERE tablename = 'trips';

COMMENT ON TABLE public.trips IS 'Stores traveler trip schedules, routes, and status for the Pasabay app';
COMMENT ON COLUMN public.trips.route_polyline IS 'Encoded Google Maps polyline for route visualization';
COMMENT ON COLUMN public.trips.trip_status IS 'Current status: Upcoming, In Progress, Completed, or Cancelled';

