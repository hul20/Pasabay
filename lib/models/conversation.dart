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
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      requesterId: json['requester_id'] as String,
      travelerId: json['traveler_id'] as String,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      requesterUnreadCount: json['requester_unread_count'] as int? ?? 0,
      travelerUnreadCount: json['traveler_unread_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
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
    final difference = now.difference(lastMessageAt!);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(lastMessageAt!);
    }
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


