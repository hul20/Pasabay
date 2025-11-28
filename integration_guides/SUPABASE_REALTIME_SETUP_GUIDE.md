# 🔴 Supabase Realtime Setup Guide for Chat

This guide will help you configure Supabase Realtime for the messaging system so that chats update instantly in real-time.

---

## 📋 Table of Contents

1. [What is Supabase Realtime?](#what-is-supabase-realtime)
2. [Enable Realtime in Supabase Dashboard](#step-1-enable-realtime-in-supabase-dashboard)
3. [Run SQL Configuration](#step-2-run-sql-configuration)
4. [Verify Setup](#step-3-verify-setup)
5. [Test in Your App](#step-4-test-in-your-app)
6. [Troubleshooting](#troubleshooting)

---

## 🎯 What is Supabase Realtime?

Supabase Realtime allows your Flutter app to listen to database changes instantly using WebSockets. When a new message is inserted, all connected clients receive it immediately without polling.

**Benefits:**
- ✅ Instant message delivery
- ✅ No need to refresh manually
- ✅ Lower database load (no polling)
- ✅ Better user experience

---

## 📍 Step 1: Enable Realtime in Supabase Dashboard

### 1.1 Go to Your Supabase Project
- Open [https://app.supabase.com](https://app.supabase.com)
- Select your project

### 1.2 Enable Realtime API
1. Go to **Settings** (gear icon in sidebar)
2. Click **API**
3. Scroll to **Realtime** section
4. Make sure **Realtime is Enabled** ✅
5. Note your **Realtime URL** (should be like `wss://your-project.supabase.co/realtime/v1/websocket`)

### 1.3 Check API Keys
1. In the same **API** section
2. Copy your **anon/public** key (you should already have this in your Flutter app)
3. This key is used for Realtime subscriptions

---

## 📍 Step 2: Run SQL Configuration

### 2.1 Open SQL Editor
1. In Supabase Dashboard, go to **SQL Editor** (in sidebar)
2. Click **New Query**

### 2.2 Copy and Run the Configuration Script

Paste the entire contents of `supabase_realtime_setup.sql` and click **Run**.

Or run these commands one by one:

```sql
-- Enable Realtime for messages table
ALTER PUBLICATION supabase_realtime ADD TABLE messages;

-- Enable Realtime for conversations table
ALTER PUBLICATION supabase_realtime ADD TABLE conversations;

-- Enable Realtime for service_requests table
ALTER PUBLICATION supabase_realtime ADD TABLE service_requests;

-- Set replica identity to FULL
ALTER TABLE messages REPLICA IDENTITY FULL;
ALTER TABLE conversations REPLICA IDENTITY FULL;
ALTER TABLE service_requests REPLICA IDENTITY FULL;
```

### 2.3 What This Does

- **ALTER PUBLICATION**: Adds tables to Supabase's Realtime publication
- **REPLICA IDENTITY FULL**: Ensures all column data is available in Realtime events (required for subscriptions)

---

## 📍 Step 3: Verify Setup

### 3.1 Check Publications

Run this query in SQL Editor:

```sql
SELECT 
    schemaname,
    tablename
FROM 
    pg_publication_tables
WHERE 
    pubname = 'supabase_realtime'
    AND tablename IN ('messages', 'conversations', 'service_requests');
```

**Expected Result:**
```
schemaname | tablename
-----------+-------------------
public     | messages
public     | conversations
public     | service_requests
```

### 3.2 Check Replica Identity

Run this query:

```sql
SELECT 
    schemaname,
    tablename,
    CASE 
        WHEN relreplident = 'f' THEN 'FULL'
        WHEN relreplident = 'd' THEN 'DEFAULT'
        WHEN relreplident = 'n' THEN 'NOTHING'
        WHEN relreplident = 'i' THEN 'INDEX'
    END as replica_identity
FROM 
    pg_class c
JOIN 
    pg_namespace n ON c.relnamespace = n.oid
WHERE 
    n.nspname = 'public'
    AND c.relname IN ('messages', 'conversations', 'service_requests');
```

**Expected Result:**
```
schemaname | tablename         | replica_identity
-----------+-------------------+-----------------
public     | messages          | FULL
public     | conversations     | FULL
public     | service_requests  | FULL
```

✅ If you see **FULL** for all tables, you're good to go!

---

## 📍 Step 4: Test in Your App

### 4.1 Rebuild Your Flutter App

Since we may have updated dependencies:

```bash
flutter clean
flutter pub get
flutter run
```

### 4.2 Test Real-time Messaging

1. **Open the app on Device A** (or emulator)
2. Login as **User A** (requester or traveler)
3. Open a chat conversation
4. **Open the app on Device B** (or another emulator)
5. Login as **User B** (the other person in the conversation)
6. Open the same chat conversation
7. **Send a message from Device A**
8. ✅ **The message should appear instantly on Device B!**

### 4.3 Check Debug Output

In your Flutter console, you should see:

```
✅ Subscribed to messages channel
✅ Message sent
✅ New message received via Realtime
```

---

## 🔧 How It Works in Your App

### Flutter Code (Already Implemented)

#### **Subscribing to Messages** (`messaging_service.dart`)

```dart
RealtimeChannel subscribeToMessages(
  String conversationId,
  Function(Message) onNewMessage,
) {
  final channel = _supabase
      .channel('messages:$conversationId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'conversation_id',
          value: conversationId,
        ),
        callback: (payload) {
          final message = Message.fromJson(payload.newRecord);
          onNewMessage(message);
        },
      )
      .subscribe();

  return channel;
}
```

#### **Using in Chat** (`chat_detail_page.dart`)

```dart
void _subscribeToMessages() {
  _messagesChannel = _messagingService.subscribeToMessages(
    widget.conversation.id,
    (newMessage) {
      setState(() {
        _messages.add(newMessage);
      });
      _scrollToBottom();
      _markAsRead();
    },
  );
}
```

---

## 🐛 Troubleshooting

### Problem: Messages don't appear in real-time

**Solution 1: Check Realtime is enabled**
- Go to Supabase Dashboard > Settings > API
- Ensure Realtime is enabled

**Solution 2: Verify tables are in publication**
```sql
SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime';
```

**Solution 3: Check replica identity**
```sql
-- Should return 'FULL' for messages
SELECT relreplident FROM pg_class WHERE relname = 'messages';
```

**Solution 4: Check RLS policies**
- Users must have SELECT permission on messages table
- Run: `SELECT * FROM messages WHERE conversation_id = 'your-id';`
- If this query fails, fix your RLS policies

---

### Problem: WebSocket connection errors

**Check your Flutter app logs:**

```
Error: WebSocket connection failed
Error: Channel subscription failed
```

**Solutions:**
1. **Check internet connection**
2. **Verify Supabase URL** in your Flutter app:
   ```dart
   await Supabase.initialize(
     url: 'https://your-project.supabase.co',
     anonKey: 'your-anon-key',
   );
   ```
3. **Check Supabase service status**: [https://status.supabase.com](https://status.supabase.com)

---

### Problem: Messages arrive delayed (3-5 seconds)

**Possible causes:**
1. **Network latency**: Normal for mobile networks
2. **Database triggers**: Check if you have heavy triggers on `messages` table
3. **Too many subscriptions**: Each conversation has its own channel

**Solutions:**
- Optimize database triggers
- Limit concurrent subscriptions
- Consider upgrading Supabase plan for better performance

---

### Problem: "Realtime quota exceeded" error

**Free Tier Limits:**
- 2 million Realtime messages/month
- 200 concurrent connections

**Solutions:**
1. **Check usage**: Dashboard > Settings > Usage
2. **Optimize subscriptions**: Unsubscribe when leaving chat
3. **Upgrade to Pro**: 5 million messages/month + more connections

---

## 📊 Realtime Event Flow

```
User A sends message
    ↓
Flutter app calls sendMessage()
    ↓
Supabase inserts into messages table
    ↓
Realtime detects INSERT event
    ↓
Broadcasts to all subscribed clients
    ↓
User B's app receives payload
    ↓
Message appears in User B's chat
    ✅ Real-time chat!
```

---

## 🔐 Security Notes

### RLS Policies (Already Set Up)

Your `supabase_service_requests_schema.sql` already has:

```sql
-- Users can only see messages from conversations they're part of
CREATE POLICY "Users can view their conversation messages"
ON messages FOR SELECT
USING (
  conversation_id IN (
    SELECT id FROM conversations 
    WHERE requester_id = auth.uid() 
       OR traveler_id = auth.uid()
  )
);
```

This ensures:
- ✅ Users can only subscribe to their own conversations
- ✅ Realtime only sends messages they're allowed to see
- ✅ No unauthorized access

---

## 📈 Performance Tips

### 1. Unsubscribe When Not Needed
```dart
@override
void dispose() {
  if (_messagesChannel != null) {
    _messagingService.unsubscribe(_messagesChannel!);
  }
  super.dispose();
}
```

### 2. Use Specific Filters
```dart
// Good: Filter by conversation_id
filter: PostgresChangeFilter(
  type: PostgresChangeFilterType.eq,
  column: 'conversation_id',
  value: conversationId,
)

// Bad: Subscribe to all messages
// (would get all messages from all conversations)
```

### 3. Batch Updates
- Don't create new subscriptions for every action
- Reuse existing channels when possible
- Limit to 1 subscription per conversation

---

## ✅ Checklist

Before testing, ensure:

- [ ] Realtime is enabled in Supabase Dashboard
- [ ] Tables are added to `supabase_realtime` publication
- [ ] Replica identity is set to FULL
- [ ] RLS policies allow SELECT on messages
- [ ] Flutter app has correct Supabase URL and key
- [ ] App properly subscribes and unsubscribes
- [ ] No console errors in Flutter or browser

---

## 🎉 Success Indicators

Your Realtime setup is working if:

✅ Messages appear instantly on both devices  
✅ Console shows "Subscribed to messages channel"  
✅ Console shows "New message received via Realtime"  
✅ No WebSocket errors  
✅ Unread counts update in real-time  
✅ Conversations list updates when new message arrives  

---

## 📚 Additional Resources

- [Supabase Realtime Docs](https://supabase.com/docs/guides/realtime)
- [Flutter Realtime Guide](https://supabase.com/docs/reference/dart/subscribe)
- [Realtime Quotas](https://supabase.com/docs/guides/platform/going-into-prod#realtime-quotas)
- [Troubleshooting Realtime](https://supabase.com/docs/guides/realtime/troubleshooting)

---

## 🆘 Need Help?

If you're still having issues after following this guide:

1. Check Supabase logs: Dashboard > Logs > Realtime
2. Enable debug mode in Flutter:
   ```dart
   // Add to main.dart
   debugPrint('Realtime event: $payload');
   ```
3. Verify with Supabase support: [https://supabase.com/support](https://supabase.com/support)

---

**Your real-time chat should now be working! 🚀**

