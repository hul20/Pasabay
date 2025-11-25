# Push Notification System - Complete Setup Guide

## Overview

This guide covers the complete push notification system for both Travelers and Requesters. Notifications are triggered automatically for:

- ✅ New requests (travelers get notified)
- ✅ Request accepted/rejected (requesters get notified)
- ✅ New messages (both parties get notified)
- ✅ Order sent (requester gets notified)
- ✅ Request completed (traveler gets notified)
- ✅ Request cancelled (traveler gets notified)

## Database Setup

### Step 1: Run the SQL Setup File

Execute the file `setup_notification_triggers.sql` in your Supabase SQL Editor:

```bash
# In Supabase Dashboard:
1. Go to SQL Editor
2. Click "New Query"
3. Copy and paste the entire contents of setup_notification_triggers.sql
4. Click "Run"
```

This will:

- ✅ Create the notifications table
- ✅ Set up RLS policies
- ✅ Create trigger functions for automatic notifications
- ✅ Set up indexes for performance

### Step 2: Verify Setup

Run this query to verify the table was created:

```sql
SELECT * FROM public.notifications LIMIT 1;
```

Check that triggers exist:

```sql
SELECT trigger_name, event_manipulation, event_object_table
FROM information_schema.triggers
WHERE trigger_schema = 'public'
AND event_object_table IN ('service_requests', 'messages');
```

You should see:

- `trigger_notify_traveler_new_request` on `service_requests`
- `trigger_notify_requester_status_change` on `service_requests`
- `trigger_notify_new_message` on `messages`

## How It Works

### Notification Types

| Type                | Triggered When               | Recipient   | Example                                                                      |
| ------------------- | ---------------------------- | ----------- | ---------------------------------------------------------------------------- |
| `new_request`       | Requester creates a request  | Traveler    | "New Pabakal Request - You have a new Pabakal request for iPhone"            |
| `request_accepted`  | Traveler accepts request     | Requester   | "Request Accepted - Your Pabakal request has been accepted by the traveler!" |
| `request_rejected`  | Traveler rejects request     | Requester   | "Request Rejected - Your Pabakal request has been rejected."                 |
| `new_message`       | Either party sends a message | Other party | "New Message from Juan - Hello, I'm on my way!"                              |
| `request_cancelled` | Requester cancels request    | Traveler    | "Request Cancelled - A Pabakal request has been cancelled by the requester." |

### Database Triggers

#### 1. New Request Notification

**Trigger:** `notify_traveler_new_request()`

- Fires when a row is inserted into `service_requests`
- Notifies the traveler about the new request
- Includes request type and details

#### 2. Status Change Notifications

**Trigger:** `notify_requester_status_change()`

- Fires when `status` field is updated in `service_requests`
- Handles: Accepted, Rejected, Cancelled, Order Sent, Completed
- Notifies appropriate party based on status change

#### 3. New Message Notifications

**Trigger:** `notify_new_message()`

- Fires when a row is inserted into `messages`
- Finds the recipient (the other person in conversation)
- Creates notification with message preview

## App Components

### 1. Notification Model (`lib/models/notification.dart`)

Updated to match database schema:

```dart
class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;  // Database field name
  final String notificationType;  // Database field name
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;
}
```

### 2. Notification Service (`lib/services/notification_service.dart`)

Provides methods to:

- Get notifications for current user
- Get unread count
- Mark notifications as read
- Subscribe to real-time notification updates
- Create notifications (for manual use)

### 3. Notification Icon (Both Home Pages)

Both Traveler and Requester home pages have:

- Bell icon in top right corner
- Red badge when unread notifications exist
- Tap to open notifications page
- Real-time badge updates

### 4. Notification Subscription

Both home pages automatically:

- Subscribe to real-time notification updates
- Show snackbar when new notification arrives
- Update badge count in real-time
- Refresh count when app returns to foreground

### 5. Notifications Page (`lib/screens/notifications_page.dart`)

Features:

- Lists all notifications (newest first)
- Different icons and colors per notification type
- Shows "time ago" for each notification
- Marks all as read when page is opened
- Visual distinction between read/unread

## Testing the Notifications

### Test 1: New Request Notification

1. **As Requester:** Create a new Pabakal or Pasabay request
2. **As Traveler:** Check notification icon - red badge should appear
3. Tap bell icon - see "New Pabakal Request" notification

### Test 2: Request Accepted Notification

1. **As Traveler:** Accept a pending request
2. **As Requester:** Check notification icon - red badge should appear
3. Tap bell icon - see "Request Accepted" notification

### Test 3: Request Rejected Notification

1. **As Traveler:** Reject a pending request
2. **As Requester:** Check notification icon - red badge should appear
3. Tap bell icon - see "Request Rejected" notification

### Test 4: New Message Notification

1. **As either party:** Send a message in chat
2. **As other party:** Check notification icon - red badge should appear
3. Tap bell icon - see "New Message from [Name]" notification
4. Message preview should be shown

### Test 5: Order Sent Notification

1. **As Traveler:** Upload proof of delivery (status changes to "Order Sent")
2. **As Requester:** Check notification icon - red badge should appear
3. Tap bell icon - see "Order Sent" notification

### Test 6: Request Completed Notification

1. **As Requester:** Click "Item Received" button
2. **As Traveler:** Check notification icon - red badge should appear
3. Tap bell icon - see "Request Completed" notification

### Test 7: Request Cancelled Notification

1. **As Requester:** Cancel a pending request
2. **As Traveler:** Check notification icon - red badge should appear
3. Tap bell icon - see "Request Cancelled" notification

## Troubleshooting

### Notifications Not Appearing

1. **Check database triggers are enabled:**

```sql
SELECT * FROM information_schema.triggers
WHERE event_object_table IN ('service_requests', 'messages');
```

2. **Check RLS policies:**

```sql
SELECT * FROM pg_policies WHERE tablename = 'notifications';
```

3. **Check for errors in trigger execution:**

```sql
-- Look at recent service requests
SELECT id, status, traveler_id, requester_id FROM service_requests ORDER BY created_at DESC LIMIT 5;

-- Check if notifications were created
SELECT * FROM notifications ORDER BY created_at DESC LIMIT 10;
```

4. **Verify real-time subscription:**

- Check console logs for "Error subscribing to notifications"
- Ensure Supabase Realtime is enabled for notifications table

### Badge Not Updating

1. **Check unread count query:**

```sql
SELECT COUNT(*) FROM notifications
WHERE user_id = 'YOUR_USER_ID' AND is_read = false;
```

2. **Verify app lifecycle observer:**

- Check that `didChangeAppLifecycleState` is being called
- Ensure `_loadUnreadNotifications()` is called on resume

3. **Check real-time channel:**

- Verify channel subscription is active
- Look for errors in console logs

### Notifications Marked as Read Too Early

The system marks all notifications as read when the NotificationsPage is opened. If you want to change this:

```dart
// In notifications_page.dart, comment out:
// _notificationService.markAllAsRead();

// Or mark individually on tap instead
```

## Performance Considerations

### Indexes

The setup includes optimized indexes:

```sql
-- For user's notifications sorted by date
idx_notifications_user (user_id, created_at DESC)

-- For unread count queries
idx_notifications_unread (user_id, is_read) WHERE is_read = false
```

### Query Optimization

- Unread count uses indexed query
- Notifications list is limited and paginated
- Real-time updates only for current user

### Memory Management

- Subscriptions are properly disposed on page exit
- Use `if (mounted)` checks before `setState`
- Unsubscribe from channels in `dispose()`

## Notification Icon Locations

### Traveler Home Page

- File: `lib/screens/traveler_home_page.dart`
- Line: ~1055 (GestureDetector with notification icon)
- Badge: Red dot appears when `_unreadNotifications > 0`

### Requester Home Page

- File: `lib/screens/requester/requester_home_page.dart`
- Line: ~295 (GestureDetector with notification icon)
- Badge: Red dot appears when `_unreadNotifications > 0`

## Real-time Features

Both home pages use:

```dart
_notificationSubscription = _notificationService.subscribeToNotifications(
  (notification) {
    // Update badge count
    _loadUnreadNotifications();

    // Show snackbar
    ScaffoldMessenger.of(context).showSnackBar(...);
  },
);
```

This provides:

- Instant notification of new items
- Automatic badge updates
- In-app snackbar alerts
- No need to refresh manually

## Security

### Row Level Security (RLS)

All notification queries are secured:

- Users can only SELECT their own notifications
- Users can only UPDATE their own notifications
- System can INSERT notifications for any user (for triggers)

### Trigger Security

Triggers run with `SECURITY DEFINER`:

- Can access all required tables
- Execute with elevated privileges
- Safe from SQL injection (using parameters)

## Next Steps

1. ✅ Run `setup_notification_triggers.sql` in Supabase
2. ✅ Verify triggers are active
3. ✅ Test each notification type
4. ✅ Monitor performance with real users
5. Consider adding:
   - Push notifications to mobile devices (FCM)
   - Email notifications for important events
   - Notification preferences/settings
   - Notification history archive

## Support

If you encounter issues:

1. Check Supabase logs for trigger errors
2. Verify RLS policies are not blocking queries
3. Test SQL queries directly in Supabase
4. Check Flutter console for subscription errors
5. Ensure real-time is enabled for the notifications table

## Summary

✅ **Complete notification system implemented**
✅ **Database triggers handle all notification creation**
✅ **Real-time updates via Supabase subscriptions**
✅ **Badge indicators on both home pages**
✅ **Full UI for viewing and managing notifications**
✅ **Secure with RLS policies**
✅ **Optimized with proper indexes**

The notification system is now fully functional and will work automatically as users interact with the app!
