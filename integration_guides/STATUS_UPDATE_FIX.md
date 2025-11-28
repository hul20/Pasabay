# Status Update Fix - Item Bought/Picked Up Error

## Problem

When clicking "Item Bought" or "Picked Up" buttons in the chat, the app showed this error:

```
PostgrestException(message: new row for relation "service_requests" violates check constraint "service_requests_status_check", code: 23514, details: Bad Request, hint: null)
```

## Root Cause

The database constraint on the `service_requests` table only allowed these status values:

- `Pending`
- `Accepted`
- `Rejected`
- `Completed`
- `Cancelled`

But the new progress tracking system uses additional intermediate statuses:

- `Item Bought` (Pabakal)
- `Picked Up` (Pasabay)
- `On the Way`
- `Dropped Off`
- `Order Sent`

## Solution

### 1. Update Database Constraint

**Run this SQL in Supabase SQL Editor:**

Open the file `update_service_request_statuses.sql` and execute it in your Supabase Dashboard:

1. Go to Supabase Dashboard → SQL Editor
2. Copy the contents of `update_service_request_statuses.sql`
3. Paste and click "Run"

This will update the status constraint to allow all the new status values.

### 2. Keyboard Overflow Fix

Added `resizeToAvoidBottomInset: true` to the Scaffold in `chat_detail_page.dart` to prevent overflow when the keyboard appears.

## Status Flow

### Pabakal (Shopping):

1. **Accepted** (Order Accepted) - Initial state
2. **Item Bought** - Traveler bought the item
3. **On the Way** - Traveler is delivering
4. **Dropped Off** - Item delivered
5. **Completed** - Requester confirmed receipt

### Pasabay (Delivery):

1. **Accepted** (Order Accepted) - Initial state
2. **Picked Up** - Traveler picked up package
3. **On the Way** - Traveler is delivering
4. **Dropped Off** - Package delivered
5. **Completed** - Requester confirmed receipt

## Testing

After running the SQL update:

1. Open the app and go to a chat with an accepted request
2. As a traveler, click the "Item Bought" or "Picked Up" button
3. Verify the status updates without error
4. Verify the progress bar updates correctly
5. Click "On the Way" button
6. Verify it updates again
7. Test keyboard appearance - should not overflow

## Files Modified

1. `update_service_request_statuses.sql` - New SQL migration file
2. `lib/screens/chat_detail_page.dart` - Added resizeToAvoidBottomInset
3. `lib/screens/requester/requester_home_page.dart` - Updated progress steps (already done)

## Notes

- The `Order Sent` status is kept for backward compatibility
- All old requests with legacy statuses will continue to work
- The progress bar correctly maps all statuses to the appropriate steps
