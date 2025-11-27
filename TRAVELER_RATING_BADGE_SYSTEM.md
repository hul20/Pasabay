# Traveler Rating & Badge System

## Overview

This document describes the comprehensive rating and badge system implemented for travelers in the Pasabay app. The system tracks traveler performance, builds trust through statistics, and rewards excellence with badges.

## Database Schema

### Tables Created

1. **`ratings`** - Stores individual ratings from requesters
2. **`traveler_statistics`** - Aggregated traveler performance metrics
3. **`route_statistics`** - Tracks traveler route frequency
4. **`traveler_badges`** - Earned badges for travelers

### Setup Instructions

1. **Execute the SQL schema:**

   ```bash
   # Run this in your Supabase SQL editor
   supabase_ratings_and_badges_schema.sql
   ```

2. **Verify tables were created:**

   - Check Supabase dashboard → Database → Tables
   - Confirm: `ratings`, `traveler_statistics`, `route_statistics`, `traveler_badges`

3. **Check RLS policies:**
   - All tables have Row Level Security enabled
   - Public can view statistics (for profile visibility)
   - Only authenticated users can rate completed requests

## Profile Statistics

### Trust Score (Average Rating)

- **Display:** "4.9/5.0 ⭐"
- **Calculation:** Average of all ratings received
- **Updates:** Automatically when new rating is submitted
- **Range:** 1.0 - 5.0

### Successful Trips

- **Display:** "24"
- **Calculation:** Count of trips with status = 'Completed'
- **Updates:** Automatically via trigger when trip status changes

### Reliability Rate

- **Display:** "100%"
- **Calculation:** `(fulfilled_requests / total_accepted_requests) * 100`
- **Updates:** When request status changes from Accepted → Completed/Cancelled
- **Importance:** HIGH - Shows commitment to accepted bookings

## Badge System

### 🏆 Badge Types

#### ⚡ Flash Traveler

**Criteria:** 10+ on-time deliveries
**Vibe:** "You can count on me to be on time."
**How to Earn:**

- Complete deliveries without delays
- Requester must mark `is_fast_delivery = true` when rating
- Badge awarded automatically when counter reaches 10

#### 🛍️ Pasabuy Pro

**Criteria:** 10+ five-star "Pabakal" requests
**Vibe:** "I know how to pick good produce/items and handle receipts correctly."
**How to Earn:**

- Complete Pabakal (purchase) requests
- Receive 5.0 rating AND `is_good_shopper = true` feedback
- Badge awarded automatically when counter reaches 10

#### 🛣️ Route Master

**Criteria:** 5+ trips on the same route
**Vibe:** "I know the [Route A]-[Route B] route like the back of my hand."
**How to Earn:**

- Travel the same departure → destination route 5+ times
- Multiple badges possible (one per route mastered)
- Badge awarded automatically when route counter reaches 5
  **Example:** "🛣️ Route Master (Iloilo-Roxas)" if traveled that route 5+ times

#### 📦 Gentle Handler

**Criteria:** 5+ fragile item deliveries with positive feedback
**Vibe:** "Your birthday cake is safe with me."
**How to Earn:**

- Complete deliveries with fragile items (cakes, electronics, glass, etc.)
- Requester must mark `is_fragile_handler = true` when rating
- Badge awarded automatically when counter reaches 5

### Badge Display

- Badges appear on traveler profile page
- Shown as colorful chips with emoji + name
- Clicking badge shows description and criteria (future enhancement)

## Rating System

### When Ratings Happen

- **Timing:** After request status = 'Completed'
- **Who Rates:** Requester rates the Traveler
- **Frequency:** One rating per request

### Rating Structure

```dart
{
  "rating": 4.5,              // Overall rating (1.0-5.0)
  "review_text": "Great service!",  // Optional text review
  "punctuality_rating": 5.0,  // Optional detailed rating
  "communication_rating": 4.5, // Optional detailed rating
  "item_condition_rating": 5.0, // Optional detailed rating

  // Badge criteria flags
  "is_fragile_handler": true,  // Gentle Handler badge
  "is_fast_delivery": true,    // Flash Traveler badge
  "is_good_shopper": true      // Pasabuy Pro badge
}
```

### Rating Constraints

- Rating must be between 1.0 and 5.0
- Cannot rate same request twice
- Cannot rate yourself
- Must have completed request to rate

## Code Integration

### Models

Location: `lib/models/traveler_statistics.dart`

Classes:

- `TravelerStatistics` - Profile statistics
- `TravelerBadge` - Badge information
- `RouteStatistic` - Route frequency data
- `TravelerRating` - Individual rating data

### Service

Location: `lib/services/traveler_stats_service.dart`

Key Methods:

```dart
// Get statistics
await TravelerStatsService().getMyStatistics()
await TravelerStatsService().getTravelerStatistics(userId)

// Get badges
await TravelerStatsService().getMyBadges()
await TravelerStatsService().getTravelerBadges(userId)

// Submit rating (requester side)
await TravelerStatsService().submitRating(
  travelerId: '...',
  tripId: '...',
  requestId: '...',
  rating: 5.0,
  reviewText: 'Excellent!',
  isFastDelivery: true,
  isGoodShopper: true,
)

// Get complete profile
await TravelerStatsService().getCompleteProfile(userId)
```

### Profile Page Integration

Location: `lib/screens/profile_page.dart`

Features:

- Auto-loads statistics on profile page load
- Displays Trust Score, Successful Trips, Reliability Rate
- Shows earned badges with icons
- Lists top 3 routes with trip counts
- Loading state while fetching data
- Only shown for users with role = 'Traveler'

## Database Triggers

### Automatic Updates

1. **Trip Completion Trigger**

   - When trip status → 'Completed'
   - Updates: `total_trips`, `successful_trips` in traveler_statistics
   - Updates: `trip_count` in route_statistics

2. **Rating Submission Trigger**

   - When new rating is inserted
   - Updates: `average_rating`, `total_ratings`
   - Updates: Badge counters (on_time_deliveries, fragile_item_deliveries, etc.)
   - Calls badge check function

3. **Request Status Trigger**

   - When request status changes
   - Tracks: Accepted, Completed, Cancelled requests
   - Calculates: Reliability rate

4. **Badge Award Function**
   - Automatically checks criteria after statistics update
   - Awards badges when thresholds are met
   - Creates entries in traveler_badges table

## Testing the System

### 1. Initialize Statistics

```sql
-- Run this to create statistics for existing travelers
INSERT INTO public.traveler_statistics (traveler_id)
SELECT id FROM public.users WHERE role = 'Traveler'
ON CONFLICT (traveler_id) DO NOTHING;
```

### 2. Manually Update Statistics (for testing)

```sql
-- Give a traveler some stats for testing
UPDATE public.traveler_statistics
SET
  total_trips = 25,
  successful_trips = 24,
  average_rating = 4.8,
  total_ratings = 20,
  reliability_rate = 96.00,
  on_time_deliveries = 15,  -- Will earn Flash Traveler
  five_star_pabakal_count = 12,  -- Will earn Pasabuy Pro
  fragile_item_deliveries = 6  -- Will earn Gentle Handler
WHERE traveler_id = 'YOUR_USER_ID';

-- Manually award badges
SELECT check_and_award_badges('YOUR_USER_ID');
```

### 3. Test Rating Submission

```sql
-- Insert test rating (must have completed request)
INSERT INTO public.ratings (
  traveler_id,
  requester_id,
  trip_id,
  request_id,
  rating,
  review_text,
  is_fast_delivery,
  is_good_shopper,
  is_fragile_handler
) VALUES (
  'TRAVELER_USER_ID',
  'REQUESTER_USER_ID',
  'TRIP_ID',
  'REQUEST_ID',
  5.0,
  'Excellent service!',
  true,
  true,
  false
);
```

### 4. Verify Profile Display

1. Log in as a traveler
2. Navigate to Profile page
3. Check that statistics appear:
   - Trust Score showing
   - Successful Trips count
   - Reliability Rate percentage
4. Check badges section (if any earned)
5. Check top routes section (if any trips completed)

## Future Enhancements

### Phase 2 (Rating Feature)

- [ ] Add rating UI for requesters after delivery
- [ ] Show rating modal when request status = 'Completed'
- [ ] Display recent reviews on profile
- [ ] Add detailed rating categories
- [ ] Enable travelers to respond to reviews

### Phase 3 (Advanced Features)

- [ ] Badge levels (Bronze, Silver, Gold)
- [ ] Leaderboards (top travelers)
- [ ] Monthly achievement notifications
- [ ] Badge showcase customization
- [ ] Profile sharing (public traveler profiles)
- [ ] Rating analytics dashboard

### Phase 4 (Gamification)

- [ ] Experience points system
- [ ] Achievement notifications
- [ ] Streak tracking (consecutive on-time deliveries)
- [ ] Seasonal badges
- [ ] Referral rewards

## Troubleshooting

### Statistics Not Showing

1. Check if user role = 'Traveler'
2. Verify traveler_statistics entry exists for user
3. Check console for API errors
4. Verify RLS policies allow read access

### Badges Not Awarded

1. Check if triggers are enabled
2. Verify counter values meet criteria:
   ```sql
   SELECT * FROM traveler_statistics WHERE traveler_id = 'USER_ID';
   ```
3. Manually run badge check:
   ```sql
   SELECT check_and_award_badges('USER_ID');
   ```

### Ratings Not Accepting

1. Verify request status = 'Completed'
2. Check if rating already exists for that request
3. Verify requester_id matches current user
4. Check RLS policy allows insert

### Statistics Not Updating

1. Check if triggers are enabled:
   ```sql
   SELECT * FROM pg_trigger WHERE tgname LIKE '%traveler%';
   ```
2. Verify trigger functions exist:
   ```sql
   \df *traveler*
   ```
3. Check trigger logs in Supabase dashboard

## Security Considerations

### Row Level Security (RLS)

- ✅ All tables have RLS enabled
- ✅ Statistics are publicly readable (for trust building)
- ✅ Only requesters can rate completed requests
- ✅ Cannot rate same request twice
- ✅ Cannot rate yourself

### Data Privacy

- Ratings are visible to travelers
- Personal rating data (who rated) is not exposed in UI
- Statistics are aggregated and anonymous
- Badge criteria are transparent

## API Reference

### Get Statistics Endpoint

```dart
// Service method
TravelerStatistics? stats = await _statsService.getTravelerStatistics(userId);

// Returns
{
  average_rating: 4.8,
  successful_trips: 24,
  reliability_rate: 96.0,
  total_ratings: 20,
  // ... more fields
}
```

### Get Badges Endpoint

```dart
// Service method
List<TravelerBadge> badges = await _statsService.getTravelerBadges(userId);

// Returns array of
{
  badge_type: 'flash_traveler',
  display_name: '⚡ Flash Traveler',
  description: 'You can count on me to be on time.',
  earned_at: '2025-11-27T...',
  // ... more fields
}
```

### Submit Rating Endpoint

```dart
// Service method
bool success = await _statsService.submitRating(
  travelerId: travelerId,
  tripId: tripId,
  requestId: requestId,
  rating: 5.0,
  reviewText: 'Great!',
  isFastDelivery: true,
);
```

## Maintenance

### Regular Tasks

- Monitor badge distribution (ensure criteria aren't too easy/hard)
- Review rating patterns for anomalies
- Update badge criteria based on user feedback
- Archive old ratings (consider retention policy)

### Performance Optimization

- Statistics are pre-calculated (not computed on-demand)
- Indexes on frequently queried columns
- Consider caching for high-traffic profiles
- Monitor trigger performance

---

## Support

For issues or questions:

1. Check console logs for error messages
2. Verify SQL schema was executed completely
3. Test with sample data first
4. Review Supabase logs in dashboard

**Created:** November 27, 2025
**Last Updated:** November 27, 2025
**Version:** 1.0.0
