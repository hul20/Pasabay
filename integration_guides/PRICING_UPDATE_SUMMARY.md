# Trip Pricing System Update

## Overview

Updated the trip creation system to allow travelers to set their own prices for Pasabay (package delivery) and Pabakal (shopping) services, as well as specify available slots.

## Database Changes

### SQL Migration File

**File:** `update_trips_pricing.sql`

Added two new columns to the `trips` table:

- `pasabay_price` (decimal(10,2)) - Price for package delivery service
- `pabakal_price` (decimal(10,2)) - Price for shopping service

**To apply changes:**

1. Go to Supabase Dashboard → SQL Editor
2. Run the SQL from `update_trips_pricing.sql`
3. This adds the columns with default values (₱50 for Pasabay, ₱100 for Pabakal)

## Code Changes

### 1. Trip Model (`lib/models/trip.dart`)

**Added fields:**

- `final double pasabayPrice`
- `final double pabakalPrice`

**Updated methods:**

- Constructor: Added pasabayPrice and pabakalPrice parameters with defaults
- `fromJson()`: Parse pricing fields from database
- `toJson()`: Include pricing fields when saving
- `copyWith()`: Support updating pricing fields

### 2. TripService (`lib/services/trip_service.dart`)

**Updated `createTrip()` method:**

- Added `pasabayPrice` parameter (default: 50.0)
- Added `pabakalPrice` parameter (default: 100.0)
- Includes pricing in database insert

### 3. Traveler Home Page (`lib/screens/traveler_home_page.dart`)

**New controllers:**

- `_slotsController` - For available capacity (default: 5)
- `_pasabayPriceController` - For Pasabay pricing (default: 50)
- `_pabakalPriceController` - For Pabakal pricing (default: 100)

**New UI Section: "Pricing & Capacity"**
Added form fields for:

1. **Available Slots** - Number input with people icon
2. **Pasabay Price** - Peso amount with shipping icon (green)
3. **Pabakal Price** - Peso amount with shopping icon (blue)

**Features:**

- Input validation with number keyboards
- Visual currency prefix (₱)
- Icon indicators for each service type
- Default values pre-filled
- Form resets to defaults after successful trip creation

## User Flow

### Traveler Creating a Trip:

1. Enter departure and destination
2. Select date and time
3. **NEW:** Set available slots (1-99)
4. **NEW:** Set Pasabay price (package delivery fee)
5. **NEW:** Set Pabakal price (shopping service fee)
6. Pin locations on map
7. Submit trip

### What Happens:

- Trip is created with traveler's custom pricing
- Requesters will see these prices when browsing trips
- Service fee calculation now uses traveler's set prices instead of percentage-based fees

## Benefits

1. **Traveler Control**: Travelers set their own prices based on:

   - Distance of trip
   - Time and effort required
   - Market rates in their area

2. **Transparency**: Requesters see exact prices upfront

3. **Flexibility**: Different trips can have different pricing based on route complexity

4. **Simplified**: No more complex percentage calculations - flat rates per service type

## Default Values

- **Slots:** 5 requests
- **Pasabay Price:** ₱50.00 per request
- **Pabakal Price:** ₱100.00 per request

Travelers can adjust these values for each trip they create.

## Testing Checklist

- [ ] Run SQL migration in Supabase
- [ ] Create a new trip with custom pricing
- [ ] Verify pricing appears correctly in database
- [ ] Check that requesters see correct prices when browsing trips
- [ ] Test with various slot numbers (1, 5, 10, etc.)
- [ ] Test with different price points
- [ ] Verify form resets to defaults after submission
- [ ] Test input validation (negative numbers, decimals, etc.)
