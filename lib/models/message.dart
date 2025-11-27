import 'package:intl/intl.dart';

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String messageText;
  final bool isRead;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.messageText,
    this.isRead = false,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    // Parse timestamp - Supabase returns timestamps in UTC
    // Format could be: "2025-11-27T15:53:00.000000" or "2025-11-27T15:53:00+00:00"
    String dateStr = json['created_at'] as String;

    // If no timezone indicator, treat as UTC by appending Z
    if (!dateStr.contains('Z') &&
        !dateStr.contains('+') &&
        !dateStr.contains('-', 10)) {
      dateStr = '${dateStr}Z';
    }

    DateTime parsedDate = DateTime.parse(dateStr);
    final localTime = parsedDate.toLocal();

    return Message(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      messageText: json['message_text'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: localTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'message_text': messageText,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get formattedTime {
    return DateFormat('hh:mm a').format(createdAt);
  }

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      createdAt.year,
      createdAt.month,
      createdAt.day,
    );

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(Duration(days: 1))) {
      return 'Yesterday';
    } else if (now.difference(createdAt).inDays < 7) {
      return DateFormat('EEEE').format(createdAt); // Day name
    } else {
      return DateFormat('MMM dd, yyyy').format(createdAt);
    }
  }

  bool isSentBy(String userId) {
    return senderId == userId;
  }
}
