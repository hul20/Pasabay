import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../services/messaging_service.dart';

class ChatDetailPage extends StatefulWidget {
  final Conversation conversation;

  const ChatDetailPage({
    super.key,
    required this.conversation,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MessagingService _messagingService = MessagingService();
  final _supabase = Supabase.instance.client;
  
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  RealtimeChannel? _messagesChannel;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeToMessages();
    _markAsRead();
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

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      final messages = await _messagingService.getMessages(widget.conversation.id);
      
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error loading messages: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _subscribeToMessages() {
    _messagesChannel = _messagingService.subscribeToMessages(
      widget.conversation.id,
      (newMessage) {
        if (mounted) {
          setState(() {
            _messages.add(newMessage);
          });
          _scrollToBottom();
          _markAsRead();
        }
      },
    );
  }

  Future<void> _markAsRead() async {
    await _messagingService.markMessagesAsRead(widget.conversation.id);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final success = await _messagingService.sendMessage(
        conversationId: widget.conversation.id,
        messageText: text,
      );

      if (success) {
        _messageController.clear();
        // Message will be added via real-time subscription
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);
    final currentUserId = _supabase.auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18 * scaleFactor,
              backgroundColor: Color(0xFF00B4D8),
              backgroundImage: widget.conversation.otherUserImage != null
                  ? NetworkImage(widget.conversation.otherUserImage!)
                  : null,
              child: widget.conversation.otherUserImage == null
                  ? Icon(Icons.person, size: 18 * scaleFactor, color: Colors.white)
                  : null,
            ),
            SizedBox(width: 12 * scaleFactor),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversation.otherUserName ?? 'Unknown',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16 * scaleFactor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.conversation.serviceType != null)
                    Text(
                      widget.conversation.serviceType!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12 * scaleFactor,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState(scaleFactor)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(16 * scaleFactor),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final showDate = index == 0 ||
                              _messages[index - 1].formattedDate != message.formattedDate;
                          
                          return Column(
                            children: [
                              if (showDate)
                                _buildDateDivider(message.formattedDate, scaleFactor),
                              _buildMessageBubble(
                                message,
                                message.isSentBy(currentUserId),
                                scaleFactor,
                              ),
                            ],
                          );
                        },
                      ),
          ),

          // Message Input
          _buildMessageInput(scaleFactor),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double scaleFactor) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40 * scaleFactor),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64 * scaleFactor,
              color: Colors.grey[300],
            ),
            SizedBox(height: 16 * scaleFactor),
            Text(
              'Start the conversation',
              style: TextStyle(
                fontSize: 18 * scaleFactor,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8 * scaleFactor),
            Text(
              'Send your first message below',
              style: TextStyle(
                fontSize: 14 * scaleFactor,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateDivider(String date, double scaleFactor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16 * scaleFactor),
      child: Row(
        children: [
          Expanded(child: Divider()),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16 * scaleFactor),
            child: Text(
              date,
              style: TextStyle(
                fontSize: 12 * scaleFactor,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMine, double scaleFactor) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 8 * scaleFactor,
          left: isMine ? 60 * scaleFactor : 0,
          right: isMine ? 0 : 60 * scaleFactor,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 16 * scaleFactor,
          vertical: 10 * scaleFactor,
        ),
        decoration: BoxDecoration(
          color: isMine ? Color(0xFF00B4D8) : Colors.white,
          borderRadius: BorderRadius.circular(16 * scaleFactor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.messageText,
              style: TextStyle(
                color: isMine ? Colors.white : Colors.black87,
                fontSize: 15 * scaleFactor,
              ),
            ),
            SizedBox(height: 4 * scaleFactor),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.formattedTime,
                  style: TextStyle(
                    color: isMine ? Colors.white.withOpacity(0.8) : Colors.grey[500],
                    fontSize: 11 * scaleFactor,
                  ),
                ),
                if (isMine) ...[
                  SizedBox(width: 4 * scaleFactor),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14 * scaleFactor,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(double scaleFactor) {
    return Container(
      padding: EdgeInsets.all(12 * scaleFactor),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16 * scaleFactor),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24 * scaleFactor),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    fontSize: 15 * scaleFactor,
                    color: Colors.grey[500],
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          SizedBox(width: 8 * scaleFactor),
          Material(
            color: Color(0xFF00B4D8),
            borderRadius: BorderRadius.circular(24 * scaleFactor),
            child: InkWell(
              onTap: _isSending ? null : _sendMessage,
              borderRadius: BorderRadius.circular(24 * scaleFactor),
              child: Container(
                padding: EdgeInsets.all(12 * scaleFactor),
                child: _isSending
                    ? SizedBox(
                        width: 20 * scaleFactor,
                        height: 20 * scaleFactor,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20 * scaleFactor,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


