import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📱 Background notification: ${message.notification?.title}');
}

class FCMService {
  static FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  static String? _fcmToken;

  // Initialize FCM
  static Future<void> initialize() async {
    try {
      // Ensure Firebase is initialized
      if (Firebase.apps.isEmpty) {
        try {
          await Firebase.initializeApp();
          debugPrint('✅ Firebase initialized successfully');
        } catch (e) {
          debugPrint('❌ Failed to initialize Firebase: $e');
          return; // Stop if Firebase cannot be initialized
        }
      } else {
        debugPrint('ℹ️ Firebase already initialized');
      }

      // Request permission for iOS and Android
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ FCM: User granted permission');

        // Get FCM token
        _fcmToken = await _messaging.getToken();
        if (_fcmToken != null) {
          debugPrint('📱 FCM Token: ${_fcmToken!.substring(0, 30)}...');

          // Save token to Supabase
          await _saveFCMTokenToDatabase(_fcmToken!);
        }

        // Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          _saveFCMTokenToDatabase(newToken);
          debugPrint('🔄 FCM Token refreshed');
        });

        // Handle background messages
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('📬 Foreground notification received');

          if (message.notification != null) {
            debugPrint('Title: ${message.notification!.title}');
            debugPrint('Body: ${message.notification!.body}');
          }

          // The notification will be handled by the notification service
          // which already shows snackbars for new notifications
        });

        // Handle notification tap when app is in background
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint('🔔 Background notification tapped');
          debugPrint('Data: ${message.data}');
          // TODO: Add navigation logic based on message.data['type']
        });

        // Handle notification tap when app was terminated
        RemoteMessage? initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          debugPrint('🔔 Terminated state notification tapped');
          debugPrint('Data: ${initialMessage.data}');
          // TODO: Add navigation logic based on initialMessage.data['type']
        }
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('⚠️ FCM: User granted provisional permission');
      } else {
        debugPrint('❌ FCM: User declined permission');
      }
    } catch (e) {
      debugPrint('❌ Error initializing FCM: $e');
    }
  }

  // Save FCM token to Supabase users table
  static Future<void> _saveFCMTokenToDatabase(String token) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('⚠️ Cannot save FCM token: No user logged in');
        return;
      }

      // Update the users table with FCM token
      await Supabase.instance.client
          .from('users')
          .update({'fcm_token': token})
          .eq('id', userId);

      debugPrint('✅ FCM token saved to database');
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  // Get current FCM token
  static String? get fcmToken => _fcmToken;

  // Delete FCM token (call on logout)
  static Future<void> deleteFCMToken() async {
    try {
      // Ensure Firebase is initialized
      if (Firebase.apps.isEmpty) {
        try {
          await Firebase.initializeApp();
        } catch (e) {
          debugPrint('❌ Failed to initialize Firebase during logout: $e');
          return;
        }
      }

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Remove FCM token from database
      await Supabase.instance.client
          .from('users')
          .update({'fcm_token': null})
          .eq('id', userId);

      // Delete token from Firebase
      await _messaging.deleteToken();
      _fcmToken = null;

      debugPrint('✅ FCM token deleted');
    } catch (e) {
      debugPrint('❌ Error deleting FCM token: $e');
    }
  }

  // Subscribe to a topic (optional, for broadcast notifications)
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic: $e');
    }
  }

  // Unsubscribe from a topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic: $e');
    }
  }
}
