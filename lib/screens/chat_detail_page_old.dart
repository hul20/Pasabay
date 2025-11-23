import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class ChatDetailPage extends StatefulWidget {
  final String name;
  final String imageUrl;
  final bool isOnline;
  final String itemId;
  final String route;
  final String items;

  const ChatDetailPage({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.isOnline,
    required this.itemId,
    required this.route,
    required this.items,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Hello Sir! Thank you gid sa pag accept.',
      isSent: false,
      time: '10:32 PM',
    ),
    ChatMessage(
      text: 'Hello Maria! Mamangkot ko tani kung sano kag diin ka available para sa pick up? Thank you!',
      isSent: true,
      time: '10:37 PM',
      isRead: true,
    ),
    ChatMessage(
      text: 'Perfect! 2PM Sir sa SM City Iloilo',
      isSent: false,
      time: '10:38 PM',
    ),
    ChatMessage(
      text: 'Pwede gid. Message ta ka liwat',
      isSent: true,
      time: '10:39 PM',
      isRead: false,
    ),
  ];

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
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppConstants.primaryColor,
            size: 20 * scaleFactor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36 * scaleFactor,
              height: 36 * scaleFactor,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8 * scaleFactor),
                image: const DecorationImage(
                  image: NetworkImage(AppConstants.logoUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 8 * scaleFactor),
            Text(
              'Pasabay',
              style: TextStyle(
                fontSize: 18 * scaleFactor,
                fontWeight: FontWeight.w600,
                color: AppConstants.primaryColor,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16 * scaleFactor),
            decoration: BoxDecoration(
              color: Color(0xFF00B4D8),
              borderRadius: BorderRadius.circular(10 * scaleFactor),
            ),
            padding: EdgeInsets.all(8 * scaleFactor),
            child: Icon(
              Icons.directions_bus,
              color: Colors.white,
              size: 24 * scaleFactor,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // User Header with Profile
          Container(
            padding: EdgeInsets.all(16 * scaleFactor),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    ClipOval(
                      child: Image.network(
                        widget.imageUrl,
                        width: 50 * scaleFactor,
                        height: 50 * scaleFactor,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 50 * scaleFactor,
                            height: 50 * scaleFactor,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person,
                              size: 25 * scaleFactor,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      ),
                    ),
                    if (widget.isOnline)
                      Positioned(
                        bottom: 2 * scaleFactor,
                        right: 2 * scaleFactor,
                        child: Container(
                          width: 12 * scaleFactor,
                          height: 12 * scaleFactor,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 12 * scaleFactor),
                Expanded(
                  child: Text(
                    widget.name,
                    style: TextStyle(
                      fontSize: 18 * scaleFactor,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.info_outline,
                    color: Colors.black,
                    size: 24 * scaleFactor,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Item Details Card
          Container(
            margin: EdgeInsets.all(16 * scaleFactor),
            padding: EdgeInsets.all(16 * scaleFactor),
            decoration: BoxDecoration(
              color: Color(0xFFE8F9FD),
              borderRadius: BorderRadius.circular(12 * scaleFactor),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12 * scaleFactor),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8 * scaleFactor),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: Color(0xFF00B4D8),
                    size: 24 * scaleFactor,
                  ),
                ),
                SizedBox(width: 12 * scaleFactor),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.items,
                        style: TextStyle(
                          fontSize: 15 * scaleFactor,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4 * scaleFactor),
                      Text(
                        '${widget.itemId} | ${widget.route}',
                        style: TextStyle(
                          fontSize: 13 * scaleFactor,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12 * scaleFactor,
                      vertical: 6 * scaleFactor,
                    ),
                  ),
                  child: Text(
                    'View Details',
                    style: TextStyle(
                      fontSize: 13 * scaleFactor,
                      color: Color(0xFF00B4D8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Chat Messages
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16 * scaleFactor),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index], scaleFactor);
              },
            ),
          ),

          // Action Buttons
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16 * scaleFactor,
              vertical: 8 * scaleFactor,
            ),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: Icon(
                    Icons.local_offer_outlined,
                    size: 18 * scaleFactor,
                    color: Colors.black,
                  ),
                  label: Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 14 * scaleFactor,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(width: 16 * scaleFactor),
                TextButton.icon(
                  onPressed: () {},
                  icon: Icon(
                    Icons.attach_file,
                    size: 18 * scaleFactor,
                    color: Colors.black,
                  ),
                  label: Text(
                    'Attach',
                    style: TextStyle(
                      fontSize: 14 * scaleFactor,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Message Input
          Container(
            padding: EdgeInsets.all(16 * scaleFactor),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
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
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 15 * scaleFactor,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 12 * scaleFactor,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.emoji_emotions_outlined,
                            color: Colors.grey[600],
                            size: 24 * scaleFactor,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12 * scaleFactor),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF00B4D8),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20 * scaleFactor,
                    ),
                    onPressed: () {
                      // Send message logic
                      if (_messageController.text.isNotEmpty) {
                        setState(() {
                          _messages.add(
                            ChatMessage(
                              text: _messageController.text,
                              isSent: true,
                              time: '10:40 PM',
                              isRead: false,
                            ),
                          );
                          _messageController.clear();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message, double scaleFactor) {
    return Align(
      alignment: message.isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            message.isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 8 * scaleFactor),
            padding: EdgeInsets.symmetric(
              horizontal: 16 * scaleFactor,
              vertical: 12 * scaleFactor,
            ),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            decoration: BoxDecoration(
              color: message.isSent ? Color(0xFF00B4D8) : Colors.grey[200],
              borderRadius: BorderRadius.circular(16 * scaleFactor),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                fontSize: 14 * scaleFactor,
                color: message.isSent ? Colors.white : Colors.black,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: message.isSent ? 0 : 8 * scaleFactor,
              right: message.isSent ? 8 * scaleFactor : 0,
              bottom: 12 * scaleFactor,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.time,
                  style: TextStyle(
                    fontSize: 12 * scaleFactor,
                    color: Colors.grey[600],
                  ),
                ),
                if (message.isSent) ...[
                  SizedBox(width: 4 * scaleFactor),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 16 * scaleFactor,
                    color: message.isRead ? Color(0xFF00B4D8) : Colors.grey,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isSent;
  final String time;
  final bool isRead;

  ChatMessage({
    required this.text,
    required this.isSent,
    required this.time,
    this.isRead = false,
  });
}

