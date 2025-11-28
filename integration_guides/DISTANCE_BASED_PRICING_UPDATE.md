# Distance-Based Automatic Pricing System

## Overview

Implemented a complete overhaul of the traveler pricing system to use automatic distance-based calculation instead of manual price input.

## Changes Made

### 1. New Distance Service (`lib/services/distance_service.dart`)

Created a new service that:

- **Calculates distance** using Google Maps Distance Matrix API
- **Falls back to Haversine formula** if API fails
- **Automatic pricing**: ₱10 per kilometer
- **Minimum charge**: ₱50
- **Same price for both services**: Pasabay and Pabakal use identical pricing

**Key Features:**

```dart
- calculateDistance() - Uses Google Maps API with fallback
- formatDistance() - Display formatting (e.g., "5.2 km")
- formatPrice() - Display formatting (e.g., "₱52.00")
```

### 2. Traveler Home Page Updates (`lib/screens/traveler_home_page.dart`)

#### Removed:

- Manual price input controllers (`_pasabayPriceController`, `_pabakalPriceController`)
- Price input TextFields from UI
- Separate pricing for Pasabay and Pabakal

#### Added:

- **Distance calculation state variables:**

  - `_totalDistanceKm` - Calculated distance
  - `_calculatedPrice` - Automatic price based on distance
  - `_isCalculatingDistance` - Loading state
  - `_distanceService` - Service instance

- **New methods:**
  - `_setDefaultDeparture()` - Auto-sets current city as departure on page load
  - `_calculateDistanceAndPrice()` - Calculates distance and price when both locations are set

#### Modified:

- **Location selection flow:**
  1. Current city is automatically set as departure location on page load
  2. User prompted with "Where to?" for destination
  3. After both locations set, distance and price calculate automatically
- **Map tap handler** (`_onMapTap`):
  - Now triggers distance calculation when destination is set
- **Trip registration** (`_registerTrip`):
  - Uses calculated price instead of manual input
  - Both Pasabay and Pabakal use same price

#### UI Changes:

- **Departure field**: Hint text changed to "From (Current City)"
- **Destination field**: Hint text changed to "Where to?" with larger, bold text
- **Pricing section replaced with**:
  - Distance display (e.g., "5.2 km")
  - Calculated price display (e.g., "₱52.00")
  - Loading indicator while calculating
  - Info message when locations not set

### 3. Google Maps API Integration

- Uses existing API key from `android/local.properties`
- API Key: `AIzaSyA_NbVgJyqKX2HehA9Xkm4CZ6ItBXL7f4s`
- Endpoint: Google Maps Distance Matrix API

## Pricing Formula

```
Base Rate: ₱10 per kilometer
Minimum Charge: ₱50

Examples:
- 3 km trip = ₱50 (minimum)
- 10 km trip = ₱100
- 25.5 km trip = ₱255
```

## User Flow

### For Travelers:

1. **Open trip creation** - Current city automatically set as departure
2. **Enter destination** - Tap "Where to?" field or use map
3. **Distance calculated** - Automatic calculation shows distance and price
4. **Review details** - See total distance and service fee
5. **Set schedule** - Choose date and time
6. **Set capacity** - Number of available slots
7. **Register trip** - Price is automatically applied

### Visual Feedback:

- ✅ **Green checkmark** when departure set
- 🔴 **Red marker** when destination set
- 📏 **Distance display** with kilometers
- 💵 **Price display** in Philippine Pesos
- ⏳ **Loading spinner** while calculating

## Database Impact

### Trips Table:

- `pasabay_price` - Now automatically set based on distance
- `pabakal_price` - Now automatically set based on distance (same value)
- Both fields still exist for compatibility, just auto-populated

### No Migration Needed:

- Existing schema remains compatible
- Only the way prices are set has changed (from manual to automatic)

## Testing Checklist

- [ ] Test automatic departure location setting
- [ ] Test destination selection via text input
- [ ] Test destination selection via map tap
- [ ] Test distance calculation with valid locations
- [ ] Test distance calculation fallback (Haversine)
- [ ] Verify minimum charge (₱50) applies
- [ ] Verify price scales with distance (₱10/km)
- [ ] Test trip creation with calculated price
- [ ] Verify both Pasabay and Pabakal use same price
- [ ] Test with poor internet (should fallback to Haversine)

## Files Modified

1. **Created:**

   - `lib/services/distance_service.dart` (New - 207 lines)

2. **Modified:**

   - `lib/screens/traveler_home_page.dart` (Major changes)
     - Removed price controllers
     - Added distance calculation
     - Updated UI to show calculated prices
     - Auto-set departure location

3. **Unchanged:**
   - `lib/models/trip.dart` - Schema remains compatible
   - `lib/services/trip_service.dart` - No changes needed
   - Database schema - No migration required

## Benefits

1. **Consistency**: All travelers charge the same rate
2. **Fairness**: Price based on actual distance
3. **Simplicity**: No need for travelers to set prices
4. **Transparency**: Requesters see clear distance-based pricing
5. **Automatic**: One less step for travelers to worry about

## Notes

- Pricing can be adjusted by changing constants in `DistanceService`:
  - `_pricePerKm` - Currently ₱10
  - `_minimumCharge` - Currently ₱50
- Google Maps API provides accurate road distance
- Haversine formula provides straight-line distance as fallback
- Both services (Pasabay & Pabakal) intentionally use same pricing

## Future Enhancements

Possible improvements:

- Different pricing tiers for different vehicle types
- Peak hour pricing multipliers
- Dynamic pricing based on demand
- Discount codes or promotions
- Service type differentiation (if needed)
