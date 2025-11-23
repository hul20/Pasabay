# 📱 Supabase Dashboard Configuration Steps

## Visual Step-by-Step Guide

Follow these exact steps in your Supabase Dashboard:

---

## Step 1: Open Your Project

```
1. Go to: https://app.supabase.com
2. Click your project: "Pasabay" (or your project name)
```

---

## Step 2: Verify Realtime is Enabled

```
1. Click "Settings" (⚙️ gear icon in left sidebar)
2. Click "API" in the settings menu
3. Scroll down to "Realtime" section
4. You should see:

   ┌─────────────────────────────────────┐
   │ Realtime                            │
   ├─────────────────────────────────────┤
   │ Enable Realtime  [✅ ON]            │
   │                                     │
   │ Realtime is enabled for your       │
   │ project. Your clients can subscribe│
   │ to database changes.               │
   └─────────────────────────────────────┘

5. If it says "OFF", toggle it ON
6. Wait 10 seconds for changes to apply
```

**✅ Checkpoint**: Realtime is enabled

---

## Step 3: Open SQL Editor

```
1. Click "SQL Editor" (📝 icon in left sidebar)
2. Click "New Query" button (top right)
3. You'll see a blank SQL editor
```

---

## Step 4: Run Realtime Configuration SQL

```
1. Copy the ENTIRE script from supabase_realtime_setup.sql
   (Or copy the commands below)

2. Paste into the SQL editor

3. Click "Run" button (or press Ctrl+Enter / Cmd+Enter)

4. You should see: "Success. No rows returned"
```

### SQL to Run:

```sql
-- Enable Realtime for messages table
ALTER PUBLICATION supabase_realtime ADD TABLE messages;

-- Enable Realtime for conversations table
ALTER PUBLICATION supabase_realtime ADD TABLE conversations;

-- Enable Realtime for service_requests table
ALTER PUBLICATION supabase_realtime ADD TABLE service_requests;

-- Set replica identity to FULL (required for Realtime)
ALTER TABLE messages REPLICA IDENTITY FULL;
ALTER TABLE conversations REPLICA IDENTITY FULL;
ALTER TABLE service_requests REPLICA IDENTITY FULL;
```

**✅ Checkpoint**: SQL executed successfully

---

## Step 5: Verify Setup

```
1. In the same SQL Editor, clear the query
2. Paste this verification query:
```

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

```
3. Click "Run"
4. You should see this result:

   ┌────────────┬──────────────────┐
   │ schemaname │ tablename        │
   ├────────────┼──────────────────┤
   │ public     │ messages         │
   │ public     │ conversations    │
   │ public     │ service_requests │
   └────────────┴──────────────────┘

5. If you see all 3 tables, ✅ SUCCESS!
```

**✅ Checkpoint**: All tables in publication

---

## Step 6: Verify Replica Identity

```
1. Run this query:
```

```sql
SELECT
    n.nspname as schema,
    c.relname as table,
    CASE
        WHEN c.relreplident = 'f' THEN 'FULL ✅'
        WHEN c.relreplident = 'd' THEN 'DEFAULT ❌'
        WHEN c.relreplident = 'n' THEN 'NOTHING ❌'
        WHEN c.relreplident = 'i' THEN 'INDEX ❌'
    END as replica_identity
FROM
    pg_class c
JOIN
    pg_namespace n ON c.relnamespace = n.oid
WHERE
    n.nspname = 'public'
    AND c.relname IN ('messages', 'conversations', 'service_requests');
```

```
2. Expected output:

   ┌────────┬──────────────────┬──────────────────┐
   │ schema │ table            │ replica_identity │
   ├────────┼──────────────────┼──────────────────┤
   │ public │ messages         │ FULL ✅          │
   │ public │ conversations    │ FULL ✅          │
   │ public │ service_requests │ FULL ✅          │
   └────────┴──────────────────┴──────────────────┘

3. All should say "FULL ✅"
```

**✅ Checkpoint**: Replica identity set correctly

---

## Step 7: Check RLS Policies

```
1. Click "Authentication" in left sidebar
2. Click "Policies" tab
3. Find these tables:
   - messages
   - conversations
   - service_requests

4. Each should have policies like:
   - "Users can view their conversation messages" ✅
   - "Users can insert their own messages" ✅
   - "Users can view their conversations" ✅

5. If policies exist, you're good!
```

**✅ Checkpoint**: RLS policies active

---

## Step 8: Get Your API Keys (Already Done)

```
1. Click "Settings" → "API"
2. Find "Project API keys"
3. You should already have:
   - Project URL: https://xxx.supabase.co
   - anon/public key: eyJhbGc...

4. These should already be in your Flutter app
5. No need to change anything
```

**✅ Checkpoint**: API keys confirmed

---

## Step 9: Test in Flutter App

```
1. Open terminal in your project folder
2. Run:
   flutter clean
   flutter pub get
   flutter run

3. Wait for app to launch
4. Check console for:
   ✅ Supabase initialized
   ✅ Subscribed to messages channel
```

**✅ Checkpoint**: App running

---

## Step 10: Live Test

```
Option A: Two Physical Devices
1. Install app on Device A
2. Install app on Device B
3. Login as different users
4. Start a chat
5. Send message from Device A
6. Watch it appear instantly on Device B! ⚡

Option B: Emulator + Physical Device
1. Run on emulator (Device A)
2. Install on phone (Device B)
3. Same as above

Option C: Two Emulators
1. Start emulator 1
2. Start emulator 2
3. Run: flutter run -d [device-id]
4. Same as above
```

**✅ Final Test**: Messages appear in real-time!

---

## 🎯 Success Indicators

### In Flutter Console:

```
I/flutter (12345): ✅ Supabase initialized
I/flutter (12345): ✅ Subscribed to messages channel
I/flutter (12345): ✅ Message sent
I/flutter (12345): ✅ New message received via Realtime
I/flutter (12345): ✅ Found 1 conversations
```

### In the App:

- ⚡ Messages appear instantly (no refresh)
- 🔔 Unread counters update automatically
- 💬 Conversations move to top when new message arrives
- ✅ Read status updates in real-time

---

## 📊 Monitor Realtime Usage

```
1. Go to Supabase Dashboard
2. Click "Settings" → "Usage"
3. Scroll to "Realtime" section
4. You'll see:

   ┌─────────────────────────────────────┐
   │ Realtime Usage                      │
   ├─────────────────────────────────────┤
   │ Messages this month:                │
   │ 1,234 / 2,000,000 (0.06%)          │
   │                                     │
   │ Active connections: 12 / 200        │
   │                                     │
   │ Peak connections: 24                │
   └─────────────────────────────────────┘

5. As long as you're under limits, you're good!
```

---

## 🐛 If Something Goes Wrong

### "Success. No rows returned" after ALTER PUBLICATION

**This is GOOD!** ✅  
It means the command executed successfully.

### "relation already exists in publication"

**This is OK!** ✅  
It means Realtime was already enabled for that table.  
Just continue to the next step.

### "permission denied"

**Fix:**

1. Make sure you're logged in as the project owner
2. Or contact your project admin

### Tables not showing in verification query

**Fix:**

```sql
-- Remove and re-add the table
ALTER PUBLICATION supabase_realtime DROP TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
```

### Replica identity is "DEFAULT" not "FULL"

**Fix:**

```sql
-- Set it to FULL
ALTER TABLE messages REPLICA IDENTITY FULL;
```

---

## ✅ Final Checklist

Before closing this guide, verify:

- [x] Realtime is enabled in Dashboard (Settings → API)
- [x] SQL script executed without errors
- [x] All 3 tables appear in publication
- [x] All 3 tables have FULL replica identity
- [x] RLS policies exist for messages and conversations
- [x] Flutter app rebuilt and running
- [x] Test completed: Messages appear instantly
- [x] Console shows "Subscribed to messages channel"
- [x] No WebSocket errors
- [x] Unread counters update automatically

---

## 🎉 You're Done!

**Total time**: 5-10 minutes  
**Difficulty**: Easy  
**Result**: Professional real-time chat! ⚡

Your Pasabay app now has real-time messaging like WhatsApp! 🚀

---

## 📞 Need Help?

If you're stuck:

1. **Re-read the step** you're on
2. **Check the troubleshooting** section above
3. **Read**: SUPABASE_REALTIME_SETUP_GUIDE.md (detailed guide)
4. **Ask**: Supabase Community or Support

---

**Now go test your real-time chat! Open it on 2 devices and be amazed! ✨**
