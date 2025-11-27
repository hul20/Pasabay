-- =====================================================
-- RATINGS AND TRAVELER STATISTICS SCHEMA
-- =====================================================
-- This schema supports traveler ratings, statistics, and badges

-- =====================================================
-- 1. RATINGS TABLE
-- =====================================================
-- Stores ratings from requesters for completed trips
CREATE TABLE IF NOT EXISTS public.ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Foreign Keys
    traveler_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    requester_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    request_id UUID NOT NULL REFERENCES public.service_requests(id) ON DELETE CASCADE,
    
    -- Rating Details
    rating DECIMAL(2,1) NOT NULL CHECK (rating >= 1.0 AND rating <= 5.0),
    review_text TEXT,
    
    -- Rating Categories (optional detailed ratings)
    punctuality_rating DECIMAL(2,1) CHECK (punctuality_rating >= 1.0 AND punctuality_rating <= 5.0),
    communication_rating DECIMAL(2,1) CHECK (communication_rating >= 1.0 AND communication_rating <= 5.0),
    item_condition_rating DECIMAL(2,1) CHECK (item_condition_rating >= 1.0 AND item_condition_rating <= 5.0),
    
    -- Feedback Tags
    is_fragile_handler BOOLEAN DEFAULT FALSE, -- For Gentle Handler badge
    is_fast_delivery BOOLEAN DEFAULT FALSE,   -- For Flash Traveler badge
    is_good_shopper BOOLEAN DEFAULT FALSE,    -- For Pasabuy Pro badge
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(request_id, requester_id), -- One rating per request per requester
    CHECK (traveler_id != requester_id) -- Can't rate yourself
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_ratings_traveler_id ON public.ratings(traveler_id);
CREATE INDEX IF NOT EXISTS idx_ratings_requester_id ON public.ratings(requester_id);
CREATE INDEX IF NOT EXISTS idx_ratings_trip_id ON public.ratings(trip_id);
CREATE INDEX IF NOT EXISTS idx_ratings_request_id ON public.ratings(request_id);
CREATE INDEX IF NOT EXISTS idx_ratings_created_at ON public.ratings(created_at DESC);

-- =====================================================
-- 2. TRAVELER STATISTICS TABLE
-- =====================================================
-- Aggregated statistics for each traveler (updated via triggers)
CREATE TABLE IF NOT EXISTS public.traveler_statistics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    traveler_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Core Statistics
    total_trips INT DEFAULT 0,
    successful_trips INT DEFAULT 0,
    cancelled_trips INT DEFAULT 0,
    
    -- Rating Statistics
    average_rating DECIMAL(3,2) DEFAULT 0.00,
    total_ratings INT DEFAULT 0,
    
    -- Reliability Metrics
    total_accepted_requests INT DEFAULT 0,
    fulfilled_requests INT DEFAULT 0,
    cancelled_requests INT DEFAULT 0,
    reliability_rate DECIMAL(5,2) DEFAULT 0.00, -- Percentage
    
    -- Service Type Statistics
    pabakal_completed INT DEFAULT 0,
    pasabay_completed INT DEFAULT 0,
    
    -- Badge Criteria Counters
    on_time_deliveries INT DEFAULT 0,
    late_deliveries INT DEFAULT 0,
    fragile_item_deliveries INT DEFAULT 0,
    five_star_pabakal_count INT DEFAULT 0,
    
    -- Metadata
    last_calculated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for quick lookups
CREATE INDEX IF NOT EXISTS idx_traveler_statistics_traveler_id ON public.traveler_statistics(traveler_id);

-- =====================================================
-- 3. ROUTE STATISTICS TABLE
-- =====================================================
-- Tracks how many times a traveler has traveled specific routes
CREATE TABLE IF NOT EXISTS public.route_statistics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    traveler_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Route Details
    departure_location TEXT NOT NULL,
    destination_location TEXT NOT NULL,
    trip_count INT DEFAULT 1,
    
    -- Metadata
    first_trip_at TIMESTAMPTZ DEFAULT NOW(),
    last_trip_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Unique constraint for traveler + route
    UNIQUE(traveler_id, departure_location, destination_location)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_route_statistics_traveler_id ON public.route_statistics(traveler_id);
CREATE INDEX IF NOT EXISTS idx_route_statistics_trip_count ON public.route_statistics(trip_count DESC);

-- =====================================================
-- 4. TRAVELER BADGES TABLE
-- =====================================================
-- Tracks which badges a traveler has earned
CREATE TABLE IF NOT EXISTS public.traveler_badges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    traveler_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Badge Details
    badge_type TEXT NOT NULL CHECK (badge_type IN (
        'flash_traveler',
        'pasabuy_pro',
        'route_master',
        'gentle_handler'
    )),
    badge_level INT DEFAULT 1, -- For future: Bronze, Silver, Gold levels
    
    -- Route Master specific data
    route_departure TEXT,
    route_destination TEXT,
    
    -- Metadata
    earned_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(traveler_id, badge_type, route_departure, route_destination)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_traveler_badges_traveler_id ON public.traveler_badges(traveler_id);
CREATE INDEX IF NOT EXISTS idx_traveler_badges_badge_type ON public.traveler_badges(badge_type);

-- =====================================================
-- 5. FUNCTIONS & TRIGGERS
-- =====================================================

-- Function: Initialize traveler statistics when user becomes traveler
CREATE OR REPLACE FUNCTION initialize_traveler_statistics()
RETURNS TRIGGER AS $$
BEGIN
    -- Only initialize if user role is set to Traveler
    IF NEW.role = 'Traveler' AND OLD.role IS DISTINCT FROM 'Traveler' THEN
        INSERT INTO public.traveler_statistics (traveler_id)
        VALUES (NEW.id)
        ON CONFLICT (traveler_id) DO NOTHING;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: Create statistics when user becomes traveler
DROP TRIGGER IF EXISTS trigger_initialize_traveler_statistics ON public.users;
CREATE TRIGGER trigger_initialize_traveler_statistics
    AFTER UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION initialize_traveler_statistics();

-- Function: Update traveler statistics when trip is completed
CREATE OR REPLACE FUNCTION update_traveler_statistics_on_trip_complete()
RETURNS TRIGGER AS $$
BEGIN
    -- Only process when trip status changes to Completed
    IF NEW.trip_status = 'Completed' AND OLD.trip_status != 'Completed' THEN
        -- Upsert traveler statistics
        INSERT INTO public.traveler_statistics (
            traveler_id,
            total_trips,
            successful_trips
        ) VALUES (
            NEW.traveler_id,
            1,
            1
        )
        ON CONFLICT (traveler_id) DO UPDATE SET
            total_trips = traveler_statistics.total_trips + 1,
            successful_trips = traveler_statistics.successful_trips + 1,
            updated_at = NOW();
        
        -- Update or create route statistics
        INSERT INTO public.route_statistics (
            traveler_id,
            departure_location,
            destination_location,
            trip_count,
            last_trip_at
        ) VALUES (
            NEW.traveler_id,
            NEW.departure_location,
            NEW.destination_location,
            1,
            NOW()
        )
        ON CONFLICT (traveler_id, departure_location, destination_location) DO UPDATE SET
            trip_count = route_statistics.trip_count + 1,
            last_trip_at = NOW(),
            updated_at = NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: Update statistics on trip completion
DROP TRIGGER IF EXISTS trigger_update_statistics_on_trip_complete ON public.trips;
CREATE TRIGGER trigger_update_statistics_on_trip_complete
    AFTER UPDATE ON public.trips
    FOR EACH ROW
    EXECUTE FUNCTION update_traveler_statistics_on_trip_complete();

-- Function: Update statistics when rating is added
CREATE OR REPLACE FUNCTION update_statistics_on_rating()
RETURNS TRIGGER AS $$
DECLARE
    avg_rating DECIMAL(3,2);
    rating_count INT;
BEGIN
    -- Calculate new average rating
    SELECT 
        CAST(AVG(rating) AS DECIMAL(3,2)),
        COUNT(*)
    INTO avg_rating, rating_count
    FROM public.ratings
    WHERE traveler_id = NEW.traveler_id;
    
    -- Upsert traveler statistics (create if not exists)
    INSERT INTO public.traveler_statistics (
        traveler_id,
        average_rating,
        total_ratings,
        fragile_item_deliveries,
        on_time_deliveries,
        five_star_pabakal_count,
        updated_at,
        last_calculated_at
    ) VALUES (
        NEW.traveler_id,
        avg_rating,
        rating_count,
        CASE WHEN NEW.is_fragile_handler THEN 1 ELSE 0 END,
        CASE WHEN NEW.is_fast_delivery THEN 1 ELSE 0 END,
        CASE WHEN NEW.rating = 5.0 AND NEW.is_good_shopper THEN 1 ELSE 0 END,
        NOW(),
        NOW()
    )
    ON CONFLICT (traveler_id) DO UPDATE SET 
        average_rating = avg_rating,
        total_ratings = rating_count,
        -- Update badge counters
        fragile_item_deliveries = traveler_statistics.fragile_item_deliveries + CASE WHEN NEW.is_fragile_handler THEN 1 ELSE 0 END,
        on_time_deliveries = traveler_statistics.on_time_deliveries + CASE WHEN NEW.is_fast_delivery THEN 1 ELSE 0 END,
        five_star_pabakal_count = traveler_statistics.five_star_pabakal_count + 
            CASE WHEN NEW.rating = 5.0 AND NEW.is_good_shopper THEN 1 ELSE 0 END,
        updated_at = NOW(),
        last_calculated_at = NOW();
    
    -- Check and award badges
    PERFORM check_and_award_badges(NEW.traveler_id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: Update statistics when rating is added
DROP TRIGGER IF EXISTS trigger_update_statistics_on_rating ON public.ratings;
CREATE TRIGGER trigger_update_statistics_on_rating
    AFTER INSERT ON public.ratings
    FOR EACH ROW
    EXECUTE FUNCTION update_statistics_on_rating();

-- Function: Update reliability rate when request status changes
CREATE OR REPLACE FUNCTION update_reliability_rate()
RETURNS TRIGGER AS $$
BEGIN
    -- Track accepted requests
    IF NEW.status = 'Accepted' AND OLD.status != 'Accepted' THEN
        UPDATE public.traveler_statistics
        SET 
            total_accepted_requests = total_accepted_requests + 1,
            updated_at = NOW()
        WHERE traveler_id = NEW.traveler_id;
    END IF;
    
    -- Track fulfilled requests
    IF NEW.status = 'Completed' AND OLD.status != 'Completed' THEN
        UPDATE public.traveler_statistics
        SET 
            fulfilled_requests = fulfilled_requests + 1,
            successful_trips = successful_trips + 1,
            total_trips = total_trips + 1,
            reliability_rate = CASE 
                WHEN total_accepted_requests > 0 
                THEN CAST((fulfilled_requests + 1) * 100.0 / total_accepted_requests AS DECIMAL(5,2))
                ELSE 0.00
            END,
            -- Update service type counters
            pabakal_completed = pabakal_completed + CASE WHEN NEW.service_type = 'Pabakal' THEN 1 ELSE 0 END,
            pasabay_completed = pasabay_completed + CASE WHEN NEW.service_type = 'Pasabay' THEN 1 ELSE 0 END,
            updated_at = NOW()
        WHERE traveler_id = NEW.traveler_id;
    END IF;
    
    -- Track cancelled requests (after acceptance)
    IF NEW.status = 'Cancelled' AND OLD.status = 'Accepted' THEN
        UPDATE public.traveler_statistics
        SET 
            cancelled_requests = cancelled_requests + 1,
            reliability_rate = CASE 
                WHEN total_accepted_requests > 0 
                THEN CAST(fulfilled_requests * 100.0 / total_accepted_requests AS DECIMAL(5,2))
                ELSE 0.00
            END,
            updated_at = NOW()
        WHERE traveler_id = NEW.traveler_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: Update reliability rate
DROP TRIGGER IF EXISTS trigger_update_reliability_rate ON public.service_requests;
CREATE TRIGGER trigger_update_reliability_rate
    AFTER UPDATE ON public.service_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_reliability_rate();

-- Function: Check and award badges
CREATE OR REPLACE FUNCTION check_and_award_badges(p_traveler_id UUID)
RETURNS VOID AS $$
DECLARE
    stats RECORD;
    route RECORD;
BEGIN
    -- Get traveler statistics
    SELECT * INTO stats
    FROM public.traveler_statistics
    WHERE traveler_id = p_traveler_id;
    
    IF stats IS NULL THEN RETURN; END IF;
    
    -- Award Flash Traveler Badge (10+ on-time deliveries)
    IF stats.on_time_deliveries >= 10 THEN
        INSERT INTO public.traveler_badges (traveler_id, badge_type)
        VALUES (p_traveler_id, 'flash_traveler')
        ON CONFLICT (traveler_id, badge_type, route_departure, route_destination) DO NOTHING;
    END IF;
    
    -- Award Pasabuy Pro Badge (10+ five-star Pabakal requests)
    IF stats.five_star_pabakal_count >= 10 THEN
        INSERT INTO public.traveler_badges (traveler_id, badge_type)
        VALUES (p_traveler_id, 'pasabuy_pro')
        ON CONFLICT (traveler_id, badge_type, route_departure, route_destination) DO NOTHING;
    END IF;
    
    -- Award Gentle Handler Badge (5+ fragile item deliveries with good feedback)
    IF stats.fragile_item_deliveries >= 5 THEN
        INSERT INTO public.traveler_badges (traveler_id, badge_type)
        VALUES (p_traveler_id, 'gentle_handler')
        ON CONFLICT (traveler_id, badge_type, route_departure, route_destination) DO NOTHING;
    END IF;
    
    -- Award Route Master Badges (5+ trips on same route)
    FOR route IN 
        SELECT departure_location, destination_location, trip_count
        FROM public.route_statistics
        WHERE traveler_id = p_traveler_id AND trip_count >= 5
    LOOP
        INSERT INTO public.traveler_badges (
            traveler_id, 
            badge_type, 
            route_departure, 
            route_destination
        )
        VALUES (
            p_traveler_id, 
            'route_master',
            route.departure_location,
            route.destination_location
        )
        ON CONFLICT (traveler_id, badge_type, route_departure, route_destination) DO NOTHING;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 6. ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE public.ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.traveler_statistics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.route_statistics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.traveler_badges ENABLE ROW LEVEL SECURITY;

-- Ratings Policies
-- Travelers can view their own ratings
CREATE POLICY "Travelers can view their own ratings"
    ON public.ratings FOR SELECT
    USING (auth.uid() = traveler_id);

-- Requesters can view ratings they created
CREATE POLICY "Requesters can view their own created ratings"
    ON public.ratings FOR SELECT
    USING (auth.uid() = requester_id);

-- Requesters can create ratings for completed requests
CREATE POLICY "Requesters can create ratings"
    ON public.ratings FOR INSERT
    WITH CHECK (
        auth.uid() = requester_id AND
        EXISTS (
            SELECT 1 FROM public.service_requests
            WHERE id = request_id 
            AND requester_id = auth.uid()
            AND status = 'Completed'
        )
    );

-- Traveler Statistics Policies
-- Anyone can view traveler statistics (public profile data)
CREATE POLICY "Anyone can view traveler statistics"
    ON public.traveler_statistics FOR SELECT
    USING (true);

-- Route Statistics Policies
-- Anyone can view route statistics (public profile data)
CREATE POLICY "Anyone can view route statistics"
    ON public.route_statistics FOR SELECT
    USING (true);

-- Traveler Badges Policies
-- Anyone can view badges (public profile data)
CREATE POLICY "Anyone can view traveler badges"
    ON public.traveler_badges FOR SELECT
    USING (true);

-- =====================================================
-- 7. HELPER FUNCTIONS FOR FRONTEND
-- =====================================================

-- Function: Get traveler profile with statistics
CREATE OR REPLACE FUNCTION get_traveler_profile(p_traveler_id UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'traveler_id', p_traveler_id,
        'statistics', (
            SELECT row_to_json(stats)
            FROM public.traveler_statistics stats
            WHERE stats.traveler_id = p_traveler_id
        ),
        'badges', (
            SELECT json_agg(row_to_json(badges))
            FROM public.traveler_badges badges
            WHERE badges.traveler_id = p_traveler_id
        ),
        'top_routes', (
            SELECT json_agg(row_to_json(routes))
            FROM (
                SELECT departure_location, destination_location, trip_count
                FROM public.route_statistics
                WHERE traveler_id = p_traveler_id
                ORDER BY trip_count DESC
                LIMIT 5
            ) routes
        ),
        'recent_ratings', (
            SELECT json_agg(row_to_json(recent))
            FROM (
                SELECT rating, review_text, created_at
                FROM public.ratings
                WHERE traveler_id = p_traveler_id
                ORDER BY created_at DESC
                LIMIT 10
            ) recent
        )
    ) INTO result;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 8. INITIAL DATA SEEDING
-- =====================================================

-- Create statistics entries for existing travelers
INSERT INTO public.traveler_statistics (traveler_id)
SELECT id FROM public.users WHERE role = 'Traveler'
ON CONFLICT (traveler_id) DO NOTHING;

-- Recalculate existing trip statistics
UPDATE public.traveler_statistics ts
SET 
    total_trips = (
        SELECT COUNT(*) FROM public.trips 
        WHERE traveler_id = ts.traveler_id
    ),
    successful_trips = (
        SELECT COUNT(*) FROM public.trips 
        WHERE traveler_id = ts.traveler_id AND trip_status = 'Completed'
    ),
    updated_at = NOW();

COMMENT ON TABLE public.ratings IS 'Stores traveler ratings and reviews from requesters';
COMMENT ON TABLE public.traveler_statistics IS 'Aggregated statistics for traveler profiles';
COMMENT ON TABLE public.route_statistics IS 'Tracks traveler route frequency for Route Master badge';
COMMENT ON TABLE public.traveler_badges IS 'Stores earned badges for travelers';
