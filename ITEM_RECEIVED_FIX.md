# Fix for "Item Received" Button Error

## Problem

When clicking "Item Received" button, getting error:

```
PostgrestException(message: Cannot coerce the result to a single JSON object, code: PGRST116, details: The result contains 0 rows)
```

## Root Cause

The error occurs because the RLS (Row Level Security) policies in Supabase are preventing the requester from updating the `service_requests` table. The `.select().single()` method was trying to return the updated row, but RLS blocked the update, resulting in 0 rows.

## Solution

### 1. Code Fix (Already Applied)

✅ Removed `.select().single()` from the update query to avoid the row-return issue
✅ Added detailed logging to debug RLS issues

### 2. Supabase Database Fix (You Need to Do This)

**Steps:**

1. **Open Supabase Dashboard**

   - Go to your Supabase project
   - Navigate to: **SQL Editor**

2. **Run the RLS Fix Script**

   - Copy the contents of `fix_service_requests_rls.sql`
   - Paste into the SQL Editor
   - Click **Run** or press Ctrl+Enter

3. **What This Script Does:**
   - Drops old restrictive RLS policies
   - Creates new policies allowing both **requesters** and **travelers** to update service requests
   - Ensures users can view their own requests
   - Grants necessary permissions to authenticated users

### Alternative: Manual RLS Policy Setup

If you prefer to do it manually:

1. Go to **Authentication > Policies** in Supabase
2. Find the `service_requests` table
3. Create/Edit the UPDATE policy:

   ```sql
   Policy Name: Users can update service requests
   Target Roles: authenticated

   USING expression:
   auth.uid() = requester_id OR auth.uid() = traveler_id

   WITH CHECK expression:
   auth.uid() = requester_id OR auth.uid() = traveler_id
   ```

### 3. Test After Applying Fix

After running the SQL script:

1. Hot restart the Flutter app (press `R` in terminal or restart the app)
2. Navigate to a chat with "Order Sent" status
3. Click "Item Received" → Confirm
4. Check the console logs - should see:
   ```
   🔄 Updating request [id] to Completed
   ✅ Request updated successfully
   ✅ Local state updated to: Completed
   ```

### 4. Verification

To verify RLS policies are correct:

```sql
SELECT
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'service_requests'
ORDER BY policyname;
```

You should see policies allowing UPDATE for both requester_id and traveler_id.

## Additional Notes

### Why This Happened

- Previous RLS policy might have only allowed travelers to update requests
- Or the policy was missing the requester's ability to update status to "Completed"
- RLS is Supabase's security feature to control who can access/modify data

### Why The Fix Works

- The update no longer tries to return rows (avoiding the "0 rows" error)
- Real-time subscription handles UI updates automatically
- New RLS policy explicitly allows requesters to update their requests

## Files Modified

1. ✅ `lib/screens/chat_detail_page.dart` - Removed `.select().single()`
2. 📄 `fix_service_requests_rls.sql` - RLS policy fix (run this in Supabase)

## Expected Behavior After Fix

- ✅ Button disables immediately after clicking "Confirm"
- ✅ Status updates to "Completed" in database
- ✅ Automated message sent: "Transaction completed! Item received. ✅"
- ✅ Button stays disabled when navigating away and back
- ✅ Button shows "Completed ✓" text
- ✅ No more PGRST116 errors
