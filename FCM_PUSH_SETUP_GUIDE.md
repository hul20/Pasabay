# Push Notifications Outside App - Complete Setup

## 🚨 URGENT FIX - Message Sending Error

### Run This SQL First

The trigger was referencing wrong column names. Run this in Supabase SQL Editor:

```sql
-- Drop and recreate the message notification trigger with correct column names
DROP TRIGGER IF EXISTS trigger_notify_new_message ON public.messages;

CREATE OR REPLACE FUNCTION notify_new_message()
RETURNS TRIGGER AS $$
DECLARE
  recipient_id uuid;
  sender_name text;
  conversation_request_id uuid;
BEGIN
  -- Get the conversation details
  SELECT request_id INTO conversation_request_id
  FROM public.conversations
  WHERE id = NEW.conversation_id;

  -- Determine recipient (the other person in the conversation)
  SELECT
    CASE
      WHEN sr.requester_id = NEW.sender_id THEN sr.traveler_id
      ELSE sr.requester_id
    END INTO recipient_id
  FROM public.service_requests sr
  WHERE sr.id = conversation_request_id;

  -- Get sender's name
  SELECT COALESCE(first_name || ' ' || last_name, 'Someone') INTO sender_name
  FROM public.users
  WHERE id = NEW.sender_id;

  -- Create notification for recipient
  IF recipient_id IS NOT NULL THEN
    INSERT INTO public.notifications (user_id, notification_type, title, body, related_id)
    VALUES (
      recipient_id,
      'new_message',
      'New Message from ' || sender_name,
      LEFT(NEW.message_text, 100),
      conversation_request_id
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_notify_new_message
AFTER INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION notify_new_message();
```

This fixes the error: `record "new" has no field "message_type"`

---

## 🔔 Firebase Cloud Messaging (FCM) Setup

To get push notifications working even when the app is closed, you need FCM:

### Step 1: Firebase Project Setup

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Create/Select Project**: Use existing project or create new one
3. **Add Android App**:

   - Click "Add app" → Select Android
   - Android package name: `com.pasabay.app` (check `android/app/build.gradle`)
   - Download `google-services.json`
   - Place in `android/app/` folder

4. **Get Server Key**:
   - Go to Project Settings → Cloud Messaging
   - Copy "Server key" (you'll need this)

### Step 2: Flutter Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_messaging: ^14.7.6
```

Run:

```bash
flutter pub get
```

### Step 3: Android Configuration

**android/app/build.gradle** - Add at the bottom:

```gradle
apply plugin: 'com.google.gms.google-services'
```

**android/build.gradle** - Add to dependencies:

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

**android/app/src/main/AndroidManifest.xml** - Add inside `<application>`:

```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="high_importance_channel" />

<service
    android:name=".MyFirebaseMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
```

### Step 4: Flutter Code Setup

Create `lib/services/fcm_service.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final _supabase = Supabase.instance.client;

  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ FCM Permission granted');

      // Get FCM token
      String? token = await _fcm.getToken();
      if (token != null) {
        await _saveFCMToken(token);
        print('✅ FCM Token saved: ${token.substring(0, 20)}...');
      }

      // Listen for token refresh
      _fcm.onTokenRefresh.listen(_saveFCMToken);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📬 Foreground message received');
        _handleMessage(message);
      });

      // Handle background message tap
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('📬 Background message tapped');
        _handleMessageTap(message);
      });

      // Handle terminated state message tap
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        print('📬 Terminated state message');
        _handleMessageTap(initialMessage);
      }
    } else {
      print('❌ FCM Permission denied');
    }
  }

  Future<void> _saveFCMToken(String token) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.rpc('update_fcm_token', params: {
        'p_user_id': userId,
        'p_fcm_token': token,
      });
      print('✅ FCM token saved to database');
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  void _handleMessage(RemoteMessage message) {
    // Show local notification or update UI
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');
  }

  void _handleMessageTap(RemoteMessage message) {
    // Navigate to appropriate screen based on notification type
    final data = message.data;
    final type = data['type'];

    print('Notification tapped: $type');
    // TODO: Add navigation logic based on type
  }

  Future<void> clearToken() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.rpc('update_fcm_token', params: {
        'p_user_id': userId,
        'p_fcm_token': null,
      });
      await _fcm.deleteToken();
    } catch (e) {
      print('Error clearing FCM token: $e');
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📬 Background message: ${message.notification?.title}');
}
```

### Step 5: Update main.dart

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Supabase
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initFCM();
  }

  Future<void> _initFCM() async {
    // Wait for user to be authenticated
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      await FCMService().initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Your app build method
  }
}
```

### Step 6: Initialize FCM After Login

In your login/signup success handlers:

```dart
Future<void> onLoginSuccess() async {
  await FCMService().initialize();
  // Navigate to home...
}
```

### Step 7: Clear Token on Logout

```dart
Future<void> onLogout() async {
  await FCMService().clearToken();
  await Supabase.instance.client.auth.signOut();
}
```

### Step 8: Database Setup

Run `setup_fcm_push_notifications.sql` in Supabase SQL Editor to:

- Add `fcm_token` column to users table
- Create function to send push notifications
- Update triggers to send both in-app and push notifications

### Step 9: Create Supabase Edge Function

Create a new Edge Function in Supabase:

**supabase/functions/send-push-notification/index.ts**:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const FCM_SERVER_KEY = "YOUR_FCM_SERVER_KEY_HERE";

serve(async (req) => {
  try {
    const { fcm_token, title, body, data } = await req.json();

    // Send to FCM
    const response = await fetch("https://fcm.googleapis.com/fcm/send", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `key=${FCM_SERVER_KEY}`,
      },
      body: JSON.stringify({
        to: fcm_token,
        notification: {
          title: title,
          body: body,
          sound: "default",
          badge: 1,
        },
        data: data,
        priority: "high",
      }),
    });

    const result = await response.json();

    return new Response(JSON.stringify({ success: true, result }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }
});
```

Deploy:

```bash
supabase functions deploy send-push-notification
```

### Step 10: Enable pg_net Extension

In Supabase SQL Editor:

```sql
CREATE EXTENSION IF NOT EXISTS pg_net;
```

### Step 11: Set Supabase Configuration

In Supabase Dashboard → Project Settings → API:

Add these as secrets in Edge Functions:

- `FCM_SERVER_KEY`: Your Firebase server key

---

## Testing Push Notifications

### Test 1: App Closed

1. Close the app completely
2. Create a new request from another device
3. Should receive notification on device

### Test 2: App in Background

1. Put app in background
2. Send a message from another device
3. Should receive notification

### Test 3: App in Foreground

1. Keep app open
2. Accept/reject a request from another device
3. Should see snackbar notification

---

## Troubleshooting

### Messages Still Not Sending

Run this SQL to verify the trigger is working:

```sql
-- Check if trigger exists
SELECT * FROM pg_trigger WHERE tgname = 'trigger_notify_new_message';

-- Test the function manually
SELECT notify_new_message();
```

### Push Notifications Not Arriving

1. **Check FCM token is saved**:

```sql
SELECT id, first_name, fcm_token FROM users WHERE fcm_token IS NOT NULL;
```

2. **Check Edge Function logs**:

```bash
supabase functions logs send-push-notification
```

3. **Test FCM directly**:
   Use Firebase Console → Cloud Messaging → Send test message

### Token Not Saving

Check if the RPC function exists:

```sql
SELECT * FROM pg_proc WHERE proname = 'update_fcm_token';
```

---

## Summary

✅ **Immediate Fix**: Run the updated trigger SQL to fix message sending
✅ **Full Push Notifications**: Follow FCM setup for notifications outside app
✅ **Both systems work together**: In-app + Push notifications

The in-app notification system works now. For push notifications when app is closed, you need to complete the FCM setup (Steps 1-11 above).
