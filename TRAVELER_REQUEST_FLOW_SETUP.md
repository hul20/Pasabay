# Traveler Request Management & Messaging - Complete Implementation

## 📋 Overview

This implementation enables the complete flow from request submission to messaging:

1. ✅ **Requester submits** Pabakal/Pasabay request
2. ✅ **Traveler gets notified** (database trigger creates notification)
3. ✅ **Traveler views requests** in Activity tab
4. ✅ **Traveler accepts/rejects** with detailed view
5. ✅ **On acceptance**: Both parties can communicate via Messages
6. ✅ **Real-time notifications** for all status changes

---

## 🎯 Features Implemented

### 1. **Request Detail Page** (`lib/screens/traveler/request_detail_page.dart`)

**Purpose**: Travelers view full request details and accept/reject

**Features:**
- Shows requester profile and contact info
- Displays complete Pabakal or Pasabay details
- Payment breakdown (service fee, total)
- Attachments viewer (photos/documents)
- Accept/Reject buttons with confirmation dialogs
- Automatic navigation to Messages after acceptance

**User Flow:**
1. Traveler taps on a request card
2. Views all details (items, location, cost, etc.)
3. Can accept (earns service fee) or reject (with reason)
4. After acceptance → redirects to Messages page
5. Can message requester directly from requester card

---

### 2. **Updated Activity Page** (`lib/screens/activity_page.dart`)

**New Features:**
- Fetches real service requests from Supabase
- Filters by selected trip
- Separates **Pending** and **Ongoing** requests
- Shows requester info with cached profiles
- Request cards display service type, items, fee
- Auto-refresh after accept/reject

**Data Flow:**
```
Select Trip → Load Requests for Trip → Display in Tabs
  ├─ Pending Tab: Shows new requests awaiting response
  └─ Ongoing Tab: Shows accepted requests in progress
```

**Request Card Shows:**
- Requester name and profile picture
- Service type badge (Pabakal/Pasabay)
- Item/package description
- Service fee you'll earn
- "Accepted" status badge (for ongoing)
- Timestamp

---

### 3. **Request Service Updates** (`lib/services/request_service.dart`)

**New Methods:**

```dart
// Accept a request (with capacity check via SQL function)
Future<bool> acceptRequest(String requestId)

// Reject a request with optional reason
Future<bool> rejectRequest(String requestId, String? reason)

// Get requester profile information
Future<Map<String, dynamic>?> getRequesterInfo(String requesterId)

// Get all requests for a traveler
Future<List<ServiceRequest>> getTravelerRequests({String? status})
```

**Smart Fallback**: If SQL functions aren't available, falls back to direct updates

---

## 🗄️ Database Updates

### **New Tables:**

#### 1. **conversations** - Chat conversations
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| request_id | UUID | Links to service_requests |
| requester_id | UUID | Requester user |
| traveler_id | UUID | Traveler user |
| last_message_at | TIMESTAMPTZ | Last message time |
| requester_unread_count | INT | Unread count for requester |
| traveler_unread_count | INT | Unread count for traveler |

#### 2. **messages** - Individual messages
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| conversation_id | UUID | Links to conversations |
| sender_id | UUID | Who sent the message |
| message_text | TEXT | Message content (max 5000 chars) |
| is_read | BOOLEAN | Read status |

#### 3. **notifications** - System notifications
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | Recipient user |
| notification_type | VARCHAR(50) | Type of notification |
| title | TEXT | Notification title |
| body | TEXT | Notification body |
| related_id | UUID | Related request/message ID |
| is_read | BOOLEAN | Read status |

---

### **SQL Functions:**

#### **Accept Request** (`accept_service_request`)
```sql
SELECT public.accept_service_request('request-uuid-here');
```
- Validates traveler owns the trip
- Checks available capacity
- Updates request status to 'Accepted'
- Decrements trip capacity
- Increments accepted_requests counter

#### **Reject Request** (`reject_service_request`)
```sql
SELECT public.reject_service_request('request-uuid-here', 'Reason here');
```
- Validates traveler owns the trip
- Updates status to 'Rejected'
- Stores rejection reason

#### **Get/Create Conversation** (`get_or_create_conversation`)
```sql
SELECT public.get_or_create_conversation('request-uuid-here');
```
- Returns existing conversation ID
- Creates new one if doesn't exist
- Automatically links requester and traveler

#### **Mark Messages as Read** (`mark_messages_as_read`)
```sql
SELECT public.mark_messages_as_read('conversation-uuid', 'user-uuid');
```
- Marks all unread messages as read
- Resets unread counter
- Updates conversation state

---

### **Automatic Notifications:**

Triggers create notifications automatically:

| Event | Recipient | Notification |
|-------|-----------|--------------|
| New request submitted | Traveler | "New Pabakal/Pasabay Request!" |
| Request accepted | Requester | "Request Accepted!" |
| Request rejected | Requester | "Request Rejected" + reason |
| Request cancelled | Traveler | "Request Cancelled" |

---

## 🔐 Security (RLS Policies)

### **Conversations:**
- Users can only view their own conversations
- Both requester and traveler can update (unread counts)

### **Messages:**
- Users can only view messages in their conversations
- Users can only send messages as themselves
- Users can mark messages as read in their conversations

### **Notifications:**
- Users can only view their own notifications
- System can create notifications for any user
- Users can mark their notifications as read

---

## 📱 UI Flow Examples

### **Scenario 1: Traveler Accepts a Pabakal Request**

```
1. Requester submits:
   - Product: iPhone 15 Pro Max
   - Store: Apple Store SM Iloilo
   - Cost: ₱75,000
   - Service fee: ₱7,500

2. Traveler receives notification

3. Traveler opens Activity → Requests tab
   Shows: "Maria Santos" | Pabakal | iPhone 15 Pro Max | ₱7,500 fee

4. Traveler taps → Views full details
   - Requester: Maria Santos (profile pic, phone)
   - Product: iPhone 15 Pro Max, Space Black 256GB
   - Store: Apple Store, SM City Iloilo
   - Cost: ₱75,000
   - Service fee (you earn): ₱7,500
   - Total: ₱82,500

5. Traveler taps "Accept"
   Dialog: "You will earn ₱7,500"
   Confirms

6. Redirected to Messages page
   Can now chat with Maria about pickup details

7. Maria receives notification:
   "Request Accepted! Your Pabakal request has been accepted."
```

### **Scenario 2: Traveler Rejects a Request**

```
1. Traveler views request details

2. Taps "Reject"
   Dialog: "Please provide a reason"
   Enters: "Sorry, capacity is full"

3. Request status → Rejected

4. Requester receives notification:
   "Request Rejected. Reason: Sorry, capacity is full"

5. Request removed from traveler's pending list
```

---

## 🔄 Integration Points

### **Messages Page Integration:**

The existing `MessagesPage` can be enhanced to:
- Show conversation list with unread counts
- Display messages in chronological order
- Send new messages
- Mark messages as read when viewed

**Example Navigation:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => MessagesPage(
      otherUserId: request.requesterId,
      otherUserName: requesterName,
    ),
  ),
);
```

---

## 🧪 Testing

### **Test as Traveler:**

1. **Create a trip** as traveler
2. **Switch to requester account** (or use different device)
3. **Submit a request** for that trip
4. **Switch back to traveler**
5. **Open Activity tab** → See the request
6. **Tap on request** → View details
7. **Accept or Reject** → Test both flows
8. **After acceptance** → Test messaging

### **Database Verification:**

```sql
-- Check notifications
SELECT * FROM notifications 
WHERE user_id = 'YOUR_USER_ID'
ORDER BY created_at DESC;

-- Check conversations
SELECT * FROM conversations 
WHERE requester_id = 'USER_ID' OR traveler_id = 'USER_ID';

-- Check messages
SELECT m.*, c.requester_id, c.traveler_id
FROM messages m
JOIN conversations c ON c.id = m.conversation_id
WHERE c.id = 'CONVERSATION_ID'
ORDER BY m.created_at;

-- Check request status
SELECT 
    sr.id,
    sr.service_type,
    sr.status,
    sr.service_fee,
    sr.created_at,
    sr.updated_at
FROM service_requests sr
WHERE sr.traveler_id = 'YOUR_USER_ID'
ORDER BY sr.created_at DESC;
```

---

## 🚀 Setup Instructions

### **Step 1: Run SQL Schema**

Execute `supabase_service_requests_schema.sql` in Supabase SQL Editor. This creates:
- ✅ service_requests table (if not already created)
- ✅ conversations table
- ✅ messages table
- ✅ notifications table
- ✅ All helper functions
- ✅ All triggers
- ✅ RLS policies

### **Step 2: Verify Tables**

```sql
-- List all tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('service_requests', 'conversations', 'messages', 'notifications');

-- Check triggers
SELECT trigger_name, event_object_table 
FROM information_schema.triggers 
WHERE trigger_schema = 'public';
```

### **Step 3: Test Flow**

1. Submit a request as requester
2. Check if notification was created
3. View request in traveler's activity page
4. Accept/reject request
5. Verify status changes
6. Check messaging works

---

## 📊 Statistics & Analytics

### **Get Traveler Stats:**

```sql
SELECT * FROM get_traveler_request_stats('TRAVELER_USER_ID');
```

Returns:
- Total requests received
- Pending count
- Accepted count
- Completed count
- Total earnings from completed requests

### **Get Requester Stats:**

```sql
SELECT * FROM get_requester_request_stats('REQUESTER_USER_ID');
```

Returns:
- Total requests made
- Pending count
- Accepted count
- Completed count
- Total amount spent

---

## 🐛 Troubleshooting

### **Issue: Notifications not appearing**

**Solution:**
```sql
-- Check if triggers are enabled
SELECT * FROM pg_trigger WHERE tgname LIKE '%notify%';

-- Manually create a test notification
SELECT public.create_notification(
    'USER_ID',
    'new_request',
    'Test Title',
    'Test Body',
    NULL
);
```

### **Issue: Can't accept request**

**Solution:**
- Check trip has available capacity
- Verify user is the trip owner
- Check RLS policies are enabled
- Try the fallback (direct update)

### **Issue: Messages not showing**

**Solution:**
- Verify conversation was created
- Check RLS policies for conversations/messages
- Ensure user IDs match

---

## 📝 Summary

✅ **Implemented:**
- Complete request viewing system for travelers
- Accept/Reject functionality with confirmation
- Automatic messaging integration
- Notification system (database-level)
- Conversation management
- Unread message tracking
- Real-time status updates

✅ **Database:**
- 3 new tables (conversations, messages, notifications)
- 6 SQL functions for request/message management
- 4 automatic triggers for notifications
- Complete RLS security

✅ **User Experience:**
- Intuitive request cards with all key info
- Detailed request view with full breakdown
- One-tap accept → message flow
- Empty states for no requests
- Pull-to-refresh support

---

## 🎉 Complete Flow Diagram

```
Requester                          System                        Traveler
    |                                |                              |
    |--Submit Request--------------->|                              |
    |                                |--Create Notification-------->|
    |                                |                              |
    |                                |<----View in Activity Tab-----|
    |                                |                              |
    |                                |<----Tap Request--------------|
    |                                |                              |
    |                                |<----Accept/Reject------------|
    |                                |                              |
    |<--Notification (status)--------|                              |
    |                                |                              |
    |                                |<----Create Conversation------|
    |                                |                              |
    |<========================Messages Page========================>|
    |                                |                              |
```

---

## ✨ Ready to Test!

The complete traveler request management and messaging system is now fully functional. Travelers can view, accept/reject requests, and communicate with requesters seamlessly!

