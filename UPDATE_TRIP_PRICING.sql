-- ============================================================================
-- UPDATE EXISTING TRIPS TO USE DISTANCE-BASED PRICING
-- ============================================================================
-- This updates old trips that were created with manual pricing (₱50/₱100)
-- to use the new distance-based automatic pricing (₱1/km, minimum ₱20)
-- ============================================================================

-- First, let's check current pricing in trips
SELECT 
    id,
    departure_location,
    destination_location,
    pasabay_price,
    pabakal_price,
    trip_status,
    created_at
FROM trips
WHERE trip_status IN ('Upcoming', 'In Progress')
ORDER BY created_at DESC;

-- ============================================================================
-- OPTION 1: Update all active trips to minimum pricing (₱20)
-- ============================================================================
-- Use this if you don't have distance data and want to set a fair minimum price

UPDATE trips
SET 
    pasabay_price = 20.0,
    pabakal_price = 20.0,
    updated_at = NOW()
WHERE 
    trip_status IN ('Upcoming', 'In Progress')
    AND (pasabay_price > 20.0 OR pabakal_price > 20.0 OR pasabay_price < 20.0 OR pabakal_price < 20.0);

-- ============================================================================
-- OPTION 2: Calculate distance-based pricing using lat/lng
-- ============================================================================
-- Use this if your trips have departure_lat, departure_lng, destination_lat, destination_lng

-- Function to calculate Haversine distance (km)
CREATE OR REPLACE FUNCTION calculate_trip_distance(
    lat1 DOUBLE PRECISION,
    lng1 DOUBLE PRECISION,
    lat2 DOUBLE PRECISION,
    lng2 DOUBLE PRECISION
) RETURNS DOUBLE PRECISION AS $$
DECLARE
    earth_radius CONSTANT DOUBLE PRECISION := 6371; -- Earth radius in kilometers
    dlat DOUBLE PRECISION;
    dlng DOUBLE PRECISION;
    a DOUBLE PRECISION;
    c DOUBLE PRECISION;
BEGIN
    -- Convert to radians
    dlat := radians(lat2 - lat1);
    dlng := radians(lng2 - lng1);
    
    -- Haversine formula
    a := sin(dlat/2) * sin(dlat/2) + 
         cos(radians(lat1)) * cos(radians(lat2)) * 
         sin(dlng/2) * sin(dlng/2);
    c := 2 * atan2(sqrt(a), sqrt(1-a));
    
    RETURN earth_radius * c;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Update trips with calculated distance-based pricing
UPDATE trips
SET 
    pasabay_price = GREATEST(
        20.0,  -- Minimum ₱20
        ROUND(
            CAST(
                calculate_trip_distance(
                    departure_lat,
                    departure_lng,
                    destination_lat,
                    destination_lng
                ) * 1.0  -- ₱1 per km
                AS numeric
            ),
            2
        )
    ),
    pabakal_price = GREATEST(
        20.0,  -- Minimum ₱20
        ROUND(
            CAST(
                calculate_trip_distance(
                    departure_lat,
                    departure_lng,
                    destination_lat,
                    destination_lng
                ) * 1.0  -- ₱1 per km
                AS numeric
            ),
            2
        )
    ),
    updated_at = NOW()
WHERE 
    trip_status IN ('Upcoming', 'In Progress')
    AND departure_lat IS NOT NULL
    AND departure_lng IS NOT NULL
    AND destination_lat IS NOT NULL
    AND destination_lng IS NOT NULL;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Check updated pricing
SELECT 
    id,
    departure_location,
    destination_location,
    pasabay_price,
    pabakal_price,
    trip_status,
    CASE 
        WHEN departure_lat IS NOT NULL AND departure_lng IS NOT NULL 
             AND destination_lat IS NOT NULL AND destination_lng IS NOT NULL
        THEN ROUND(
            CAST(
                calculate_trip_distance(
                    departure_lat, departure_lng,
                    destination_lat, destination_lng
                ) AS numeric
            ), 2
        )
        ELSE NULL
    END as calculated_distance_km,
    updated_at
FROM trips
WHERE trip_status IN ('Upcoming', 'In Progress')
ORDER BY updated_at DESC;

-- Show summary
SELECT 
    trip_status,
    COUNT(*) as trip_count,
    ROUND(CAST(AVG(pasabay_price) AS numeric), 2) as avg_pasabay_price,
    ROUND(CAST(AVG(pabakal_price) AS numeric), 2) as avg_pabakal_price,
    MIN(pasabay_price) as min_price,
    MAX(pasabay_price) as max_price
FROM trips
WHERE trip_status IN ('Upcoming', 'In Progress')
GROUP BY trip_status;

-- ============================================================================
-- NOTES:
-- ============================================================================
-- 1. Run OPTION 1 for quick fix (sets all to ₱20 minimum)
-- 2. Run OPTION 2 only if trips have lat/lng coordinates
-- 3. Existing service_requests will NOT be updated (they keep their agreed price)
-- 4. Only NEW requests on updated trips will use the new pricing
-- 5. Pricing formula: ₱1 per kilometer, minimum ₱20
-- ============================================================================
