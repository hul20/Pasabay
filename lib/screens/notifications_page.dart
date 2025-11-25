import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await _notificationService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
        // Mark all as read when opening the page
        _notificationService.markAllAsRead();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () =>
              Navigator.pop(context, true), // Return true to refresh count
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18 * scaleFactor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64 * scaleFactor,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: 16 * scaleFactor),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 16 * scaleFactor,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16 * scaleFactor),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return _buildNotificationItem(notification, scaleFactor);
              },
            ),
    );
  }

  Widget _buildNotificationItem(
    AppNotification notification,
    double scaleFactor,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12 * scaleFactor),
      padding: EdgeInsets.all(16 * scaleFactor),
      decoration: BoxDecoration(
        color: notification.isRead
            ? Colors.white
            : Color(0xFF00B4D8).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12 * scaleFactor),
        border: Border.all(
          color: notification.isRead
              ? Colors.grey[200]!
              : Color(0xFF00B4D8).withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10 * scaleFactor),
            decoration: BoxDecoration(
              color: _getIconColor(notification.type).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIcon(notification.type),
              color: _getIconColor(notification.type),
              size: 20 * scaleFactor,
            ),
          ),
          SizedBox(width: 16 * scaleFactor),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 15 * scaleFactor,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      notification.timeAgo,
                      style: TextStyle(
                        fontSize: 12 * scaleFactor,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4 * scaleFactor),
                Text(
                  notification.message,
                  style: TextStyle(
                    fontSize: 14 * scaleFactor,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'new_request':
        return Icons.add_shopping_cart;
      case 'request_accepted':
        return Icons.check_circle_outline;
      case 'request_rejected':
        return Icons.cancel_outlined;
      case 'request_cancelled':
        return Icons.cancel_outlined;
      case 'new_message':
        return Icons.chat_bubble_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'new_request':
        return Color(0xFF00B4D8);
      case 'request_accepted':
        return Colors.green;
      case 'request_rejected':
        return Colors.red;
      case 'request_cancelled':
        return Colors.orange;
      case 'new_message':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
