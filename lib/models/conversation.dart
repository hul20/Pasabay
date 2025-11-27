import 'package:intl/intl.dart';

class Conversation {
  final String id;
  final String requestId;
  final String requesterId;
  final String travelerId;
  final DateTime? lastMessageAt;
  final int requesterUnreadCount;
  final int travelerUnreadCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Additional fields (not from DB, loaded separately)
  String? otherUserName;
  String? otherUserImage;
  String? lastMessageText;
  String? serviceType;
  String? pickupLocation;
  String? dropoffLocation;

  Conversation({
    required this.id,
    required this.requestId,
    required this.requesterId,
    required this.travelerId,
    this.lastMessageAt,
    this.requesterUnreadCount = 0,
    this.travelerUnreadCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.otherUserName,
    this.otherUserImage,
    this.lastMessageText,
    this.serviceType,
    this.pickupLocation,
    this.dropoffLocation,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    // Helper to parse and convert to local time
    // Supabase returns timestamps in UTC without timezone indicator
    DateTime? parseToLocalTime(String? dateStr) {
      if (dateStr == null) return null;

      // If no timezone indicator, treat as UTC by appending Z
      if (!dateStr.contains('Z') &&
          !dateStr.contains('+') &&
          !dateStr.contains('-', 10)) {
        dateStr = '${dateStr}Z';
      }

      DateTime parsed = DateTime.parse(dateStr);
      return parsed.toLocal();
    }

    return Conversation(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      requesterId: json['requester_id'] as String,
      travelerId: json['traveler_id'] as String,
      lastMessageAt: parseToLocalTime(json['last_message_at'] as String?),
      requesterUnreadCount: json['requester_unread_count'] as int? ?? 0,
      travelerUnreadCount: json['traveler_unread_count'] as int? ?? 0,
      createdAt: parseToLocalTime(json['created_at'] as String)!,
      updatedAt: parseToLocalTime(json['updated_at'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_id': requestId,
      'requester_id': requesterId,
      'traveler_id': travelerId,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'requester_unread_count': requesterUnreadCount,
      'traveler_unread_count': travelerUnreadCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get formattedLastMessageTime {
    if (lastMessageAt == null) return '';

    final now = DateTime.now();
    final messageDate = lastMessageAt!;

    // If today, show time only (e.g., "11:42 AM")
    if (now.year == messageDate.year &&
        now.month == messageDate.month &&
        now.day == messageDate.day) {
      return DateFormat('h:mm a').format(messageDate);
    }

    // If this year, show date without year (e.g., "Nov 27, 11:42 AM")
    if (now.year == messageDate.year) {
      return DateFormat('MMM d, h:mm a').format(messageDate);
    }

    // Otherwise show full date (e.g., "Nov 27, 2024")
    return DateFormat('MMM d, yyyy').format(messageDate);
  }

  String get routeDisplay {
    if (pickupLocation != null && dropoffLocation != null) {
      return '$pickupLocation → $dropoffLocation';
    } else if (pickupLocation != null) {
      return pickupLocation!;
    } else if (dropoffLocation != null) {
      return dropoffLocation!;
    }
    return '';
  }

  String getOtherUserId(String currentUserId) {
    return currentUserId == requesterId ? travelerId : requesterId;
  }

  int getUnreadCount(String currentUserId) {
    return currentUserId == requesterId
        ? requesterUnreadCount
        : travelerUnreadCount;
  }

  bool get hasUnread {
    return requesterUnreadCount > 0 || travelerUnreadCount > 0;
  }
}
