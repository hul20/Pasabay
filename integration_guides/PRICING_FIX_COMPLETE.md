# Pricing and Fees Fix Summary

## 🐛 Issues Identified and Fixed

### Issue 1: Pasabay Total Amount Calculation

**Problem**: For Pasabay requests, the `_totalAmount` getter was adding product cost (which doesn't exist) to the service fee, showing incorrect total.

**Root Cause**: The code assumed both Pabakal and Pasabay have product costs.

**Fix Applied**:

```dart
double get _totalAmount {
  if (_selectedServiceType == 'Pabakal') {
    final productCost = double.tryParse(_costController.text) ?? 0;
    return productCost + _serviceFee;  // Product + Delivery
  } else {
    // Pasabay: service fee only (no product cost)
    return _serviceFee;  // Service fee IS the total
  }
}
```

**Location**: `lib/screens/requester/traveler_detail_page.dart`

---

### Issue 2: Unclear Fee Display for Pasabay

**Problem**: Pasabay requests showed "Service Fee" but didn't clarify that this IS the total amount (no separate product cost).

**Fix Applied**:

1. Added route information at top of pricing card
2. Changed "Service Fee" to context-specific labels:
   - Pabakal: "Delivery Fee" (since there's a separate product cost)
   - Pasabay: "Service Fee" (this is the only charge)
3. Added info tooltip explaining distance-based pricing (₱1/km, min ₱20)
4. For Pasabay, Total Amount now shows the service fee directly (no confusing breakdown)

**Location**: `lib/screens/requester/traveler_detail_page.dart`

---

### Issue 3: Old Trips Using Legacy Pricing

**Problem**: Trips created before the distance-based pricing update (₱50/₱100) still have those old prices stored in the database.

**Why This Happens**: When a traveler creates a trip, the calculated price is saved to `pasabay_price` and `pabakal_price` columns. Old trips still have the old values.

**Fix Provided**: SQL migration script `UPDATE_TRIP_PRICING.sql` with two options:

- **Option 1**: Set all active trips to minimum ₱20 (quick fix)
- **Option 2**: Calculate distance-based pricing using lat/lng if available

**Important Note**:

- ✅ Existing service_requests keep their original prices (what requester agreed to)
- ✅ Only NEW requests on updated trips will use corrected pricing
- ✅ This is fair to both requesters and travelers

---

## 📊 How Pricing Works Now

### For Travelers (Creating Trips):

1. Enter departure and destination
2. System auto-fills departure with current location
3. System calculates distance using Google Maps Distance Matrix API
4. Pricing: **₱1 per kilometer, minimum ₱20**
5. Same price applies to both Pasabay and Pabakal services
6. Price is stored in `trips.pasabay_price` and `trips.pabakal_price`

### For Requesters (Submitting Requests):

1. Browse available trips
2. Select a traveler
3. Choose service type (Pasabay or Pabakal)
4. See pricing breakdown:
   - **Pabakal**: Product Cost + Delivery Fee = Total
   - **Pasabay**: Service Fee = Total (no product)
5. Fee shown is the trip's calculated distance-based price

### When Request is Saved:

```dart
// Pabakal
{
  'product_cost': 100.0,      // User-entered
  'service_fee': 45.0,        // From trip (distance-based)
  'total_amount': 145.0,      // product_cost + service_fee
}

// Pasabay
{
  'product_cost': null,       // No product
  'service_fee': 45.0,        // From trip (distance-based)
  'total_amount': 45.0,       // service_fee only
}
```

---

## ✅ Files Modified

### `lib/screens/requester/traveler_detail_page.dart`

**Changes**:

1. Fixed `_totalAmount` getter to handle Pasabay correctly
2. Enhanced pricing card UI with route info
3. Added tooltip for pricing explanation
4. Separate displays for Pabakal vs Pasabay totals
5. Changed "Service Fee" to "Delivery Fee" for Pabakal (clearer)

**Lines Changed**: ~50-70 (pricing logic and UI)

---

## 🗄️ Database Considerations

### Existing Trips

If you have trips in your database with old pricing:

- Run `UPDATE_TRIP_PRICING.sql` in Supabase SQL Editor
- Choose Option 1 for quick fix (all → ₱20)
- Choose Option 2 if you have lat/lng data (distance-based)

### Existing Requests

- ✅ **Do NOT update** - requesters already agreed to these prices
- Old requests will still show their original fees
- This maintains transaction integrity

### New Trips

- ✅ Automatically use distance-based pricing (₱1/km, min ₱20)
- ✅ Both Pasabay and Pabakal use same calculated price

---

## 🧪 Testing Checklist

### Test 1: Pabakal Request Pricing

1. Select a traveler with active trip
2. Choose "Pabakal" service
3. Enter product details and cost (e.g., ₱100)
4. **Expected**:
   - Product Cost: ₱100.00
   - Delivery Fee: ₱[trip's distance price]
   - Total Amount: ₱[100 + distance price]

### Test 2: Pasabay Request Pricing

1. Select a traveler with active trip
2. Choose "Pasabay" service
3. Enter recipient details
4. **Expected**:
   - Service Fee: ₱[trip's distance price]
   - Total Amount: ₱[trip's distance price] (same as service fee)
   - No "Product Cost" line shown

### Test 3: Tooltip Display

1. On pricing card, hover/tap info icon next to "Delivery Fee" or "Service Fee"
2. **Expected**: Tooltip shows "Distance-based: ₱1/km (min ₱20)"

### Test 4: Route Display

1. Check pricing card at bottom of form
2. **Expected**: Shows route like "Iloilo City → Manila" at top of card

### Test 5: Request Status Page

1. Submit a request
2. Navigate to Request Status page
3. **Expected**:
   - Shows correct Service Fee from when request was created
   - Shows correct Total Amount
   - For Pasabay: Total = Service Fee
   - For Pabakal: Total = Product Cost + Service Fee

---

## 📝 API Integration

### Distance Calculation Service

**File**: `lib/services/distance_service.dart`

**How It Works**:

1. Uses Google Maps Distance Matrix API
2. Fallback to Haversine formula if API fails
3. Formula: `price = max(20, distance_km * 1.0)`

**API Key**: Loaded from `android/local.properties`

```properties
GOOGLE_MAPS_API_KEY=AIzaSyA_NbVgJyqKX2HehA9Xkm4CZ6ItBXL7f4s
```

---

## 🔍 Debugging Tips

### If Pricing Looks Wrong:

1. **Check Trip Prices**:

```sql
SELECT
    departure_location,
    destination_location,
    pasabay_price,
    pabakal_price
FROM trips
WHERE id = 'your-trip-id';
```

2. **Check Request Prices**:

```sql
SELECT
    service_type,
    product_cost,
    service_fee,
    total_amount
FROM service_requests
WHERE id = 'your-request-id';
```

3. **Console Logs** (when creating request):

```
📤 Submitting Pasabay request...
   Requester: [user-id]
   Traveler: [traveler-id]
   Service Fee: 45.0
   Total: 45.0
```

### Common Issues:

| Issue                     | Cause                              | Solution                         |
| ------------------------- | ---------------------------------- | -------------------------------- |
| ₱50 showing for new trips | Trip created before pricing update | Run UPDATE_TRIP_PRICING.sql      |
| Pasabay shows wrong total | Using old code                     | Update traveler_detail_page.dart |
| Distance not calculating  | API key missing/invalid            | Check local.properties           |
| Minimum not applied       | Distance < 20km                    | Formula ensures min ₱20          |

---

## 💡 Summary

**What Was Wrong**:

- Pasabay total amount calculation included non-existent product cost
- UI didn't clearly show that Pasabay service fee IS the total
- Old trips had legacy pricing (₱50/₱100)

**What's Fixed**:

- ✅ Pasabay now correctly shows service fee as total
- ✅ Clear labels: "Delivery Fee" (Pabakal) vs "Service Fee" (Pasabay)
- ✅ Added route info and pricing tooltip
- ✅ Provided SQL to update old trip prices
- ✅ All new trips use distance-based pricing

**Next Steps**:

1. Run UPDATE_TRIP_PRICING.sql for existing trips (if needed)
2. Test Pasabay request flow thoroughly
3. Verify pricing displays correctly in all pages
4. Monitor console logs for any API issues

**Formula Reminder**:

- **Distance-based**: ₱1 per kilometer
- **Minimum**: ₱20
- **Example**: 100km trip = ₱100, 15km trip = ₱20 (minimum)
