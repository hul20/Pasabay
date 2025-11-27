-- =====================================================
-- CLEANUP SCRIPT - Remove Old Rating System Functions
-- =====================================================
-- Run this FIRST before executing supabase_ratings_and_badges_schema.sql
-- This removes old functions that reference the wrong table names

-- Drop old functions that reference 'traveler_stats' (incorrect name)
DROP FUNCTION IF EXISTS update_traveler_stats_on_completion() CASCADE;
DROP FUNCTION IF EXISTS update_traveler_stats_on_review() CASCADE;
DROP FUNCTION IF EXISTS update_ratings_on_review() CASCADE;
DROP FUNCTION IF EXISTS calculate_trust_score(UUID) CASCADE;
DROP FUNCTION IF EXISTS award_badge_if_eligible(UUID) CASCADE;
DROP FUNCTION IF EXISTS get_traveler_profile_stats(UUID) CASCADE;

-- Drop any old triggers that might be referencing these functions
DROP TRIGGER IF EXISTS trigger_update_traveler_stats_on_completion ON public.service_requests;
DROP TRIGGER IF EXISTS trigger_update_traveler_stats_on_review ON public.ratings;
DROP TRIGGER IF EXISTS trigger_update_ratings_on_review ON public.ratings;

-- Verify cleanup
SELECT 'Old functions removed successfully!' AS status;

-- Now you can execute supabase_ratings_and_badges_schema.sql
