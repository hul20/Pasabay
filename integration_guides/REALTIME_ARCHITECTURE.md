# 🏗️ Realtime Chat Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     PASABAY REALTIME CHAT                       │
└─────────────────────────────────────────────────────────────────┘

┌──────────────┐                                    ┌──────────────┐
│   Device A   │                                    │   Device B   │
│  (Requester) │                                    │  (Traveler)  │
└──────┬───────┘                                    └──────┬───────┘
       │                                                   │
       │ 1. User types message                            │
       │    "Hello!"                                      │
       ▼                                                   │
┌──────────────┐                                          │
│ Flutter App  │                                          │
│ sendMessage()│                                          │
└──────┬───────┘                                          │
       │                                                   │
       │ 2. HTTP POST                                     │
       ▼                                                   │
┌─────────────────────────────────────────────────────────────────┐
│                      SUPABASE BACKEND                           │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    PostgreSQL                           │   │
│  │  ┌───────────────────────────────────────────────┐     │   │
│  │  │  INSERT INTO messages                         │     │   │
│  │  │  (conversation_id, sender_id, message_text)   │     │   │
│  │  └───────────────┬───────────────────────────────┘     │   │
│  │                  │                                      │   │
│  │                  │ 3. Trigger fires                     │   │
│  │                  ▼                                      │   │
│  │  ┌───────────────────────────────────────────────┐     │   │
│  │  │  UPDATE conversations                         │     │   │
│  │  │  SET last_message_at = NOW()                  │     │   │
│  │  │      unread_count = unread_count + 1          │     │   │
│  │  └───────────────────────────────────────────────┘     │   │
│  └──────────────────────┬──────────────────────────────────┘   │
│                         │                                       │
│                         │ 4. Realtime detects INSERT           │
│                         ▼                                       │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              REALTIME ENGINE                            │   │
│  │  - Reads WAL (Write-Ahead Log)                          │   │
│  │  - Filters by conversation_id                           │   │
│  │  - Broadcasts to subscribed clients                     │   │
│  └─────────────────────┬───────────────────────────────────┘   │
└────────────────────────┼───────────────────────────────────────┘
                         │
        ┌────────────────┴─────────────────┐
        │ 5. WebSocket broadcast           │
        │    (Only to authorized users)    │
        ▼                                  ▼
┌──────────────┐                    ┌──────────────┐
│  Device A    │                    │  Device B    │
│  (Sender)    │                    │  (Receiver)  │
│              │                    │              │
│ ✓ Sent       │                    │ 6. NEW MSG!  │
│              │                    │    "Hello!"  │
│              │                    │    ⚡ Instant│
└──────────────┘                    └──────────────┘
```

---

## 📡 WebSocket Connection Flow

```
Flutter App Startup
    │
    ├─► Supabase.initialize()
    │   └─► Establishes WebSocket connection
    │       wss://your-project.supabase.co/realtime/v1/websocket
    │
    ├─► User opens chat
    │   └─► subscribeToMessages(conversationId)
    │       │
    │       ├─► Creates channel: "messages:abc-123"
    │       │
    │       ├─► Sends subscription request:
    │       │   {
    │       │     "event": "postgres_changes",
    │       │     "table": "messages",
    │       │     "filter": "conversation_id=eq.abc-123"
    │       │   }
    │       │
    │       └─► Server responds: "Subscribed" ✅
    │
    ├─► WebSocket stays open (persistent)
    │   └─► Listens for events...
    │
    └─► User closes chat
        └─► unsubscribe()
            └─► Removes channel
                └─► Frees resources
```

---

## 🔄 Message Flow Timeline

```
Time    Device A (Sender)              Server                  Device B (Receiver)
─────────────────────────────────────────────────────────────────────────────────
0ms     User types "Hello"             Waiting...              Chat open, waiting...
        
100ms   Taps Send button               Waiting...              Waiting...
        
120ms   sendMessage() called           Waiting...              Waiting...
        HTTP POST sent ──────────────►  
        
180ms   Loading indicator...           Receives POST           Waiting...
                                       INSERT INTO messages    
                                       Commits transaction     
                                       
200ms   Loading indicator...           Writes to WAL           Waiting...
                                       Realtime reads WAL      
                                       
210ms   Loading indicator...           Broadcasts event ──────► Receives event!
                                       via WebSocket           onNewMessage()
                                       
220ms   ✓ Message sent!                Event delivered         setState()
        Sees own message                                       Message appears! ⚡
        
─────────────────────────────────────────────────────────────────────────────────
Total latency: 120ms (typical)
```

---

## 🛡️ Security Layer

```
┌─────────────────────────────────────────────────────────┐
│               ROW LEVEL SECURITY (RLS)                  │
└─────────────────────────────────────────────────────────┘

User subscribes to conversation ABC-123
    │
    ▼
┌──────────────────────────────────────────────────┐
│ RLS Check: Is user part of this conversation?   │
│                                                  │
│ SELECT id FROM conversations                     │
│ WHERE id = 'ABC-123'                            │
│   AND (requester_id = auth.uid()               │
│        OR traveler_id = auth.uid())            │
└──────────────┬───────────────────────────────────┘
               │
    ┌──────────┴──────────┐
    │                     │
    ▼                     ▼
┌─────────┐         ┌──────────┐
│ ALLOWED │         │ DENIED   │
│ ✅ Subscribe     │ ❌ Error  │
│ ✅ Receive       │ 403       │
└─────────┘         └──────────┘
```

---

## 📊 Data Structures

### Messages Table
```
┌──────────────────────────────────────────────────────┐
│ messages                                             │
├──────────────┬───────────┬───────────────────────────┤
│ id           │ UUID      │ Primary Key               │
│ conversation_│ UUID      │ → conversations.id       │
│ sender_id    │ UUID      │ → users.id               │
│ message_text │ TEXT      │ Message content          │
│ is_read      │ BOOLEAN   │ Read status              │
│ created_at   │ TIMESTAMP │ When sent                │
└──────────────┴───────────┴───────────────────────────┘
```

### Conversations Table
```
┌──────────────────────────────────────────────────────┐
│ conversations                                        │
├──────────────┬───────────┬───────────────────────────┤
│ id           │ UUID      │ Primary Key               │
│ request_id   │ UUID      │ → service_requests.id    │
│ requester_id │ UUID      │ → users.id               │
│ traveler_id  │ UUID      │ → users.id               │
│ last_message_│ TIMESTAMP │ Last activity            │
│ requester_   │ INTEGER   │ Unread count             │
│ traveler_    │ INTEGER   │ Unread count             │
└──────────────┴───────────┴───────────────────────────┘
```

---

## 🔌 Realtime Channels

### Channel Structure
```
Channel Name: "messages:{conversationId}"
              └─► Unique per conversation

Subscription Filter:
{
  "event": "INSERT",
  "schema": "public",
  "table": "messages",
  "filter": "conversation_id=eq.{conversationId}"
}

Result: Only receives messages for THAT conversation
```

### Multiple Channels Example
```
User in 3 conversations:
├─► Channel: "messages:abc-123"  (with Maria)
├─► Channel: "messages:def-456"  (with Carlos)
└─► Channel: "messages:ghi-789"  (with Anna)

When message arrives in "abc-123":
✅ abc-123 channel fires → Update Maria chat
❌ def-456 channel silent
❌ ghi-789 channel silent
```

---

## ⚡ Performance Characteristics

### Latency Breakdown
```
┌─────────────────────────────┬──────────┐
│ Operation                   │ Time     │
├─────────────────────────────┼──────────┤
│ Network RTT                 │ 50-80ms  │
│ Database INSERT             │ 10-20ms  │
│ Trigger execution           │ 5-10ms   │
│ Realtime processing         │ 5-15ms   │
│ WebSocket broadcast         │ 10-20ms  │
├─────────────────────────────┼──────────┤
│ TOTAL (typical)            │ 80-145ms │
│ TOTAL (worst case)         │ 200-300ms│
└─────────────────────────────┴──────────┘
```

### Scalability
```
Free Tier:
├─► 2M Realtime messages/month
├─► 200 concurrent connections
└─► ~6,600 messages/day average

Pro Tier:
├─► 5M Realtime messages/month
├─► 500 concurrent connections
└─► ~16,600 messages/day average
```

---

## 🎯 Optimization Strategies

### 1. Channel Management
```dart
// ✅ GOOD: One channel per conversation
_channel = supabase.channel('messages:$conversationId');

// ❌ BAD: Subscribe to all messages
_channel = supabase.channel('all-messages'); // Inefficient!
```

### 2. Unsubscribe Pattern
```dart
// ✅ GOOD: Clean up on dispose
@override
void dispose() {
  _messagingService.unsubscribe(_messagesChannel!);
  super.dispose();
}

// ❌ BAD: Keep channels open forever
// Memory leak + quota drain!
```

### 3. Filter at Source
```dart
// ✅ GOOD: Filter on server
filter: PostgresChangeFilter(
  column: 'conversation_id',
  value: conversationId,
)

// ❌ BAD: Receive all, filter in Flutter
// Wastes bandwidth + battery
```

---

## 🔍 Debugging Tools

### Check Active Channels
```dart
// In your Flutter app
print('Active channels: ${Supabase.instance.client.getChannels()}');
```

### Monitor Realtime Events
```sql
-- In Supabase Dashboard > Logs > Realtime
-- Shows all subscriptions and broadcasts
```

### Network Inspector
```
Chrome DevTools → Network → WS (WebSocket)
└─► See all Realtime messages in real-time!
```

---

## 📈 Monitoring Dashboard

```
Supabase Dashboard → Settings → Usage

┌──────────────────────────────────────────┐
│ Realtime Usage                           │
├──────────────────────────────────────────┤
│ Messages: 45,232 / 2,000,000 (2.3%)    │
│ Connections: 12 / 200                    │
│ Peak connections: 24                     │
│ Average latency: 127ms                   │
└──────────────────────────────────────────┘
```

---

## ✅ Architecture Benefits

1. **Instant Updates**
   - No polling required
   - Sub-200ms latency
   - Real chat experience

2. **Efficient**
   - Single WebSocket connection
   - Filtered at source
   - Low bandwidth usage

3. **Secure**
   - RLS enforced
   - Auth required
   - Encrypted (WSS)

4. **Scalable**
   - Handles 1000s of users
   - Auto-reconnects
   - Built-in backpressure

---

**Your real-time chat is powered by this architecture! 🚀**

