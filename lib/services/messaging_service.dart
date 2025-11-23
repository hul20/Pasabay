import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/conversation.dart';
import '../models/message.dart';

class MessagingService {
  final _supabase = Supabase.instance.client;

  // Get or create conversation for a request (after acceptance)
  Future<String?> getOrCreateConversation(String requestId) async {
    try {
      final response = await _supabase.rpc('get_or_create_conversation', params: {
        'req_id': requestId,
      });

      print('✅ Conversation ID: $response');
      return response as String?;
    } catch (e) {
      print('❌ Error getting/creating conversation: $e');
      return null;
    }
  }

  // Get all conversations for current user
  Future<List<Conversation>> getConversations() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw 'No user logged in';
      }

      final response = await _supabase
          .from('conversations')
          .select('''
            id,
            request_id,
            requester_id,
            traveler_id,
            last_message_at,
            requester_unread_count,
            traveler_unread_count,
            created_at,
            updated_at
          ''')
          .or('requester_id.eq.${currentUser.id},traveler_id.eq.${currentUser.id}')
          .order('last_message_at', ascending: false);

      List<Conversation> conversations = (response as List)
          .map((json) => Conversation.fromJson(json as Map<String, dynamic>))
          .toList();

      // Load additional info for each conversation
      for (var conversation in conversations) {
        await _loadConversationDetails(conversation, currentUser.id);
      }

      print('✅ Found ${conversations.length} conversations');
      return conversations;
    } catch (e) {
      print('❌ Error fetching conversations: $e');
      return [];
    }
  }

  // Load details for a conversation (other user info, request info)
  Future<void> _loadConversationDetails(Conversation conversation, String currentUserId) async {
    try {
      // Get other user ID
      final otherUserId = conversation.getOtherUserId(currentUserId);

      // Fetch other user info
      final userResponse = await _supabase
          .from('users')
          .select('first_name, last_name, profile_image_url')
          .eq('id', otherUserId)
          .single();

      conversation.otherUserName = 
          '${userResponse['first_name']} ${userResponse['last_name']}';
      conversation.otherUserImage = userResponse['profile_image_url'];

      // Fetch request info to get service type
      final requestResponse = await _supabase
          .from('service_requests')
          .select('service_type')
          .eq('id', conversation.requestId)
          .single();

      conversation.serviceType = requestResponse['service_type'];

      // Get last message text
      final messageResponse = await _supabase
          .from('messages')
          .select('message_text')
          .eq('conversation_id', conversation.id)
          .order('created_at', ascending: false)
          .limit(1);

      if (messageResponse.isNotEmpty) {
        conversation.lastMessageText = messageResponse[0]['message_text'];
      }
    } catch (e) {
      print('❌ Error loading conversation details: $e');
    }
  }

  // Get messages for a conversation
  Future<List<Message>> getMessages(String conversationId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      final messages = (response as List)
          .map((json) => Message.fromJson(json as Map<String, dynamic>))
          .toList();

      print('✅ Found ${messages.length} messages');
      return messages;
    } catch (e) {
      print('❌ Error fetching messages: $e');
      return [];
    }
  }

  // Send a message
  Future<bool> sendMessage({
    required String conversationId,
    required String messageText,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw 'No user logged in';
      }

      if (messageText.trim().isEmpty) {
        throw 'Message cannot be empty';
      }

      await _supabase.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': currentUser.id,
        'message_text': messageText.trim(),
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Message sent');
      return true;
    } catch (e) {
      print('❌ Error sending message: $e');
      return false;
    }
  }

  // Mark messages as read
  Future<bool> markMessagesAsRead(String conversationId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw 'No user logged in';
      }

      final response = await _supabase.rpc('mark_messages_as_read', params: {
        'conversation_uuid': conversationId,
        'reader_uuid': currentUser.id,
      });

      print('✅ Messages marked as read: $response');
      return response == true;
    } catch (e) {
      print('❌ Error marking messages as read: $e');
      // Fallback: direct update
      try {
        await _supabase
            .from('messages')
            .update({'is_read': true})
            .eq('conversation_id', conversationId)
            .neq('sender_id', _supabase.auth.currentUser!.id);
        
        return true;
      } catch (fallbackError) {
        print('❌ Fallback also failed: $fallbackError');
        return false;
      }
    }
  }

  // Subscribe to new messages in a conversation (real-time)
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
            try {
              final message = Message.fromJson(payload.newRecord);
              onNewMessage(message);
            } catch (e) {
              print('❌ Error processing new message: $e');
            }
          },
        )
        .subscribe();

    return channel;
  }

  // Subscribe to conversation updates (real-time)
  RealtimeChannel subscribeToConversations(
    Function() onUpdate,
  ) {
    final channel = _supabase
        .channel('conversations')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations',
          callback: (payload) {
            onUpdate();
          },
        )
        .subscribe();

    return channel;
  }

  // Unsubscribe from a channel
  void unsubscribe(RealtimeChannel channel) {
    _supabase.removeChannel(channel);
  }

  // Get conversation by request ID
  Future<Conversation?> getConversationByRequest(String requestId) async {
    try {
      final response = await _supabase
          .from('conversations')
          .select()
          .eq('request_id', requestId)
          .single();

      final conversation = Conversation.fromJson(response as Map<String, dynamic>);
      
      // Load details
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        await _loadConversationDetails(conversation, currentUser.id);
      }

      return conversation;
    } catch (e) {
      print('❌ Error fetching conversation by request: $e');
      return null;
    }
  }

  // Delete a conversation (and all its messages)
  Future<bool> deleteConversation(String conversationId) async {
    try {
      await _supabase
          .from('conversations')
          .delete()
          .eq('id', conversationId);

      print('✅ Conversation deleted');
      return true;
    } catch (e) {
      print('❌ Error deleting conversation: $e');
      return false;
    }
  }
}


