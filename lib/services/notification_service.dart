import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';
import 'haptic_service.dart';

class NotificationService {
  final _supabase = Supabase.instance.client;

  // Get notifications for the current user
  Future<List<AppNotification>> getNotifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => AppNotification.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  // Get unread count
  Future<int> getUnreadCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from('notifications')
          .count(CountOption.exact)
          .eq('user_id', userId)
          .eq('is_read', false);

      return response;
    } catch (e) {
      print('Error fetching unread count: $e');
      return 0;
    }
  }

  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  // Create a notification (usually called by other services or triggers)
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String notificationType,
    String? relatedId,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'notification_type': notificationType,
        'related_id': relatedId,
        'is_read': false,
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Subscribe to notifications
  RealtimeChannel subscribeToNotifications(
    Function(AppNotification) onNotification,
  ) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    return _supabase
        .channel('public:notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final notification = AppNotification.fromJson(payload.newRecord);
            // Vibrate phone when notification received
            HapticService.notification();
            onNotification(notification);
          },
        )
        .subscribe();
  }

  void unsubscribe(RealtimeChannel channel) {
    _supabase.removeChannel(channel);
  }
}
