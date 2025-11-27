# Quick Setup Guide - Traveler Rating & Badge System

## Step-by-Step Setup

### 1. Execute Database Schema

1. Open **Supabase Dashboard** → SQL Editor
2. Copy contents of `supabase_ratings_and_badges_schema.sql`
3. Paste and execute the SQL script
4. Verify tables created:
   - ✅ `ratings`
   - ✅ `traveler_statistics`
   - ✅ `route_statistics`
   - ✅ `traveler_badges`

### 2. Verify Row Level Security

Check that RLS is enabled for all tables:

```sql
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('ratings', 'traveler_statistics', 'route_statistics', 'traveler_badges');
```

All should show `rowsecurity = true`

### 3. Initialize Statistics for Existing Travelers

Run this to create statistics entries for existing travelers:

```sql
INSERT INTO public.traveler_statistics (traveler_id)
SELECT id FROM public.users WHERE role = 'Traveler'
ON CONFLICT (traveler_id) DO NOTHING;
```

### 4. Test the System

#### Option A: Test with Real Data

1. Log in as a traveler
2. Complete a trip (status = 'Completed')
3. Navigate to Profile page
4. Verify statistics appear

#### Option B: Test with Sample Data

```sql
-- Get your user ID
SELECT id FROM auth.users WHERE email = 'your.email@example.com';

-- Update statistics for testing
UPDATE public.traveler_statistics
SET
  total_trips = 25,
  successful_trips = 24,
  average_rating = 4.8,
  total_ratings = 20,
  reliability_rate = 96.00,
  on_time_deliveries = 15,
  five_star_pabakal_count = 12,
  fragile_item_deliveries = 6
WHERE traveler_id = 'YOUR_USER_ID_HERE';

-- Award badges
SELECT check_and_award_badges('YOUR_USER_ID_HERE');
```

### 5. Verify Profile Display

1. Open the app
2. Log in as a traveler
3. Navigate to Profile page
4. You should see:
   - ⭐ **Trust Score:** 4.8/5.0
   - ✅ **Successful Trips:** 24
   - 🎯 **Reliability Rate:** 96%
   - **Badges Section** (if any earned)
   - **Top Routes Section** (if any trips completed)

## Features Implemented

### ✅ Backend (Supabase)

- [x] Database tables for ratings, statistics, badges
- [x] Automatic triggers for statistics updates
- [x] Badge award system with criteria checking
- [x] Row Level Security policies
- [x] Helper functions for profile data

### ✅ Frontend (Flutter)

- [x] Traveler statistics model
- [x] Badge and rating models
- [x] Statistics service with API methods
- [x] Profile page UI with statistics display
- [x] Badge chips with icons
- [x] Top routes display
- [x] Loading states

### 🔄 Coming Soon (Rating Feature)

- [ ] Rating submission UI for requesters
- [ ] Rating modal after delivery completion
- [ ] Review display on profile
- [ ] Rating history page

## Badge Criteria Summary

| Badge          | Emoji | Criteria                       | Counter Field                    |
| -------------- | ----- | ------------------------------ | -------------------------------- |
| Flash Traveler | ⚡    | 10+ on-time deliveries         | `on_time_deliveries`             |
| Pasabuy Pro    | 🛍️    | 10+ five-star Pabakal requests | `five_star_pabakal_count`        |
| Route Master   | 🛣️    | 5+ trips on same route         | `trip_count` in route_statistics |
| Gentle Handler | 📦    | 5+ fragile item deliveries     | `fragile_item_deliveries`        |

## Quick Test Commands

### Check Your Statistics

```sql
SELECT * FROM traveler_statistics
WHERE traveler_id = 'YOUR_USER_ID';
```

### Check Your Badges

```sql
SELECT * FROM traveler_badges
WHERE traveler_id = 'YOUR_USER_ID';
```

### Check Your Routes

```sql
SELECT * FROM route_statistics
WHERE traveler_id = 'YOUR_USER_ID'
ORDER BY trip_count DESC;
```

### Manually Award All Badges (Testing)

```sql
-- Flash Traveler
INSERT INTO traveler_badges (traveler_id, badge_type)
VALUES ('YOUR_USER_ID', 'flash_traveler')
ON CONFLICT DO NOTHING;

-- Pasabuy Pro
INSERT INTO traveler_badges (traveler_id, badge_type)
VALUES ('YOUR_USER_ID', 'pasabuy_pro')
ON CONFLICT DO NOTHING;

-- Gentle Handler
INSERT INTO traveler_badges (traveler_id, badge_type)
VALUES ('YOUR_USER_ID', 'gentle_handler')
ON CONFLICT DO NOTHING;

-- Route Master (with route)
INSERT INTO traveler_badges (traveler_id, badge_type, route_departure, route_destination)
VALUES ('YOUR_USER_ID', 'route_master', 'Iloilo', 'Roxas')
ON CONFLICT DO NOTHING;
```

## Troubleshooting

### Problem: Statistics not showing on profile

**Solution:**

1. Check if user role is 'Traveler'
2. Run initialization SQL (Step 3)
3. Restart the app

### Problem: Badges not appearing

**Solution:**

```sql
-- Manually trigger badge check
SELECT check_and_award_badges('YOUR_USER_ID');
```

### Problem: Statistics not updating after trip

**Solution:**

1. Check if triggers are enabled
2. Verify trip status is exactly 'Completed'
3. Check Supabase logs for trigger errors

## Next Steps

1. **Test the current implementation**

   - Navigate to Profile page
   - Verify statistics display
   - Check loading states

2. **Implement rating submission UI**

   - Add rating modal after delivery
   - Create rating form with stars
   - Add feedback checkboxes for badges

3. **Enhance profile display**
   - Add recent reviews section
   - Show rating distribution chart
   - Add "View All Badges" detail page

## Documentation

For complete details, see:

- `TRAVELER_RATING_BADGE_SYSTEM.md` - Full documentation
- `supabase_ratings_and_badges_schema.sql` - Database schema

---

**Setup Time:** ~10 minutes
**Last Updated:** November 27, 2025
