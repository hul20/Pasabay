import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';
import '../models/message.dart';
import '../services/messaging_service.dart';

class ChatWidget extends StatefulWidget {
  final String requestId;
  final String currentUserId;
  final String otherUserId;

  const ChatWidget({
    super.key,
    required this.requestId,
    required this.currentUserId,
    required this.otherUserId,
  });

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MessagingService _messagingService = MessagingService();
  final _supabase = Supabase.instance.client;

  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  RealtimeChannel? _messagesChannel;
  String? _conversationId;
  String _otherUserName = 'User';
  String? _otherUserImage;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    if (_messagesChannel != null) {
      _messagingService.unsubscribe(_messagesChannel!);
    }
    super.dispose();
  }

  Future<void> _initializeChat() async {
    try {
      // Get other user info
      final userResponse = await _supabase
          .from('users')
          .select('first_name, last_name, profile_image_url')
          .eq('id', widget.otherUserId)
          .single();

      if (mounted) {
        setState(() {
          _otherUserName =
              '${userResponse['first_name']} ${userResponse['last_name']}';
          _otherUserImage = userResponse['profile_image_url'];
        });
      }

      // Get conversation ID
      final conversationId = await _messagingService.getOrCreateConversation(
        widget.requestId,
      );

      if (conversationId != null) {
        _conversationId = conversationId;
        await _loadMessages();
        _subscribeToMessages();
        _markAsRead();
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error initializing chat: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMessages() async {
    if (_conversationId == null) return;

    try {
      final messages = await _messagingService.getMessages(_conversationId!);

      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error loading messages: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeToMessages() {
    if (_conversationId == null) return;

    _messagesChannel = _messagingService.subscribeToMessages(_conversationId!, (
      message,
    ) {
      if (mounted) {
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();

        // Mark as read if it's from the other user
        if (message.senderId != widget.currentUserId) {
          _markAsRead();
        }
      }
    });
  }

  Future<void> _markAsRead() async {
    if (_conversationId == null) return;
    await _messagingService.markMessagesAsRead(_conversationId!);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    try {
      if (_conversationId == null) {
        // Try to create conversation again if it failed initially
        final conversationId = await _messagingService.getOrCreateConversation(
          widget.requestId,
        );
        if (conversationId != null) {
          _conversationId = conversationId;
          _subscribeToMessages();
        } else {
          throw Exception('Failed to create conversation');
        }
      }

      final success = await _messagingService.sendMessage(
        conversationId: _conversationId!,
        messageText: text,
      );

      if (success) {
        _messageController.clear();
        // Message will be added via subscription
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to send message')));
        }
      }
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // Wait for list to render
      Future.delayed(Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Chat Header (Other user info)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppConstants.primaryColor,
                  backgroundImage: _otherUserImage != null
                      ? NetworkImage(_otherUserImage!)
                      : null,
                  child: _otherUserImage == null
                      ? Icon(Icons.person, color: Colors.white, size: 20)
                      : null,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _otherUserName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Requester',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: _isLoading
                        ? CircularProgressIndicator()
                        : Text(
                            'Start a conversation',
                            style: TextStyle(color: Colors.grey),
                          ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message.senderId == widget.currentUserId;

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.only(bottom: 8),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? AppConstants.primaryColor
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          constraints: BoxConstraints(maxWidth: 260),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.messageText,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                message.formattedTime,
                                style: TextStyle(
                                  color: isMe
                                      ? Colors.white70
                                      : Colors.grey[500],
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Input Area
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: _isSending
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.send, color: AppConstants.primaryColor),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
