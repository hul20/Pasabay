import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../models/conversation.dart';
import '../services/messaging_service.dart';
=======
import '../utils/constants.dart';
import '../utils/helpers.dart';
>>>>>>> 0f05632dac88866b90bd3d130afbd6c0a364c1f5
import 'chat_detail_page.dart';
import 'profile_page.dart';
import 'activity_page.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
<<<<<<< HEAD
  final MessagingService _messagingService = MessagingService();
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  int _totalUnread = 0;
  RealtimeChannel? _conversationsChannel;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _subscribeToConversations();
  }

  @override
  void dispose() {
    if (_conversationsChannel != null) {
      _messagingService.unsubscribe(_conversationsChannel!);
    }
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);

    try {
      final conversations = await _messagingService.getConversations();
      
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _calculateUnreadCount();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading conversations: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculateUnreadCount() {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      _totalUnread = 0;
      return;
    }

    _totalUnread = _conversations.fold<int>(
      0, 
      (sum, conv) => sum + conv.getUnreadCount(currentUserId),
    );
  }

  void _subscribeToConversations() {
    _conversationsChannel = _messagingService.subscribeToConversations(() {
      _loadConversations();
    });
  }
=======
>>>>>>> 0f05632dac88866b90bd3d130afbd6c0a364c1f5
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Header Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18 * scaleFactor),
              child: Column(
                children: [
                  SizedBox(height: 12 * scaleFactor),
                  // Top bar: logo and role icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36 * scaleFactor,
                            height: 36 * scaleFactor,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                8 * scaleFactor,
                              ),
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
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF00B4D8),
                          borderRadius: BorderRadius.circular(10 * scaleFactor),
                        ),
                        padding: EdgeInsets.all(8 * scaleFactor),
                        child: Icon(
                          Icons.directions_bus,
                          color: Colors.white,
                          size: 28 * scaleFactor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16 * scaleFactor),
                  // Search bar with notifications
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12 * scaleFactor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search for a message',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 15 * scaleFactor,
                              ),
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.search, color: Colors.grey),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 16 * scaleFactor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12 * scaleFactor),
                      Stack(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.notifications_none,
                              size: 28 * scaleFactor,
                              color: Colors.black,
                            ),
                            onPressed: () {},
                          ),
                          Positioned(
                            right: 8 * scaleFactor,
                            top: 8 * scaleFactor,
                            child: Container(
                              width: 16 * scaleFactor,
                              height: 16 * scaleFactor,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '2',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10 * scaleFactor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 18 * scaleFactor),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
<<<<<<< HEAD
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _conversations.isEmpty
                      ? _buildEmptyState(scaleFactor)
                      : RefreshIndicator(
                          onRefresh: _loadConversations,
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 18 * scaleFactor),
                            itemCount: _conversations.length + 1, // +1 for header
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                // Header
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Messages',
                                          style: TextStyle(
                                            fontSize: 28 * scaleFactor,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        if (_totalUnread > 0)
                                          Text(
                                            '$_totalUnread Unread',
                                            style: TextStyle(
                                              fontSize: 15 * scaleFactor,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 18 * scaleFactor),
                                  ],
                                );
                              }

                              final conversation = _conversations[index - 1];
                              return _buildConversationCard(conversation, scaleFactor);
                            },
                          ),
                        ),
=======
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18 * scaleFactor),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Messages Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Messages',
                            style: TextStyle(
                              fontSize: 28 * scaleFactor,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            '3 Unread',
                            style: TextStyle(
                              fontSize: 15 * scaleFactor,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 18 * scaleFactor),

                      // Message Card
                      _buildMessageCard(
                        name: 'Maria Santos',
                        message: 'Hello Sir! Thank you gid sa pag accept.',
                        time: '16m',
                        unreadCount: 2,
                        isOnline: true,
                        imageUrl: 'https://i.pravatar.cc/150?img=5',
                        itemId: 'ID#12313',
                        route: 'Iloilo City → Roxas City',
                        items: 'Polo Shirts, Blazer, and Pants',
                        scaleFactor: scaleFactor,
                      ),

                      SizedBox(height: 80 * scaleFactor),
                    ],
                  ),
                ),
              ),
>>>>>>> 0f05632dac88866b90bd3d130afbd6c0a364c1f5
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: Colors.grey,
        currentIndex: 2, // Messages tab selected
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
          } else if (index == 1) {
            // Navigate to Activity page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const ActivityPage(),
              ),
            );
          } else if (index == 3) {
            // Navigate to Profile page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfilePage(),
              ),
            );
          }
          // Handle other navigation items
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildEmptyState(double scaleFactor) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40 * scaleFactor),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80 * scaleFactor,
              color: Colors.grey[300],
            ),
            SizedBox(height: 24 * scaleFactor),
            Text(
              'No Messages Yet',
              style: TextStyle(
                fontSize: 24 * scaleFactor,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 12 * scaleFactor),
            Text(
              'Accept requests to start chatting\nwith requesters',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15 * scaleFactor,
                color: Colors.grey[500],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationCard(Conversation conversation, double scaleFactor) {
    final currentUserId = _supabase.auth.currentUser?.id ?? '';
    final unreadCount = conversation.getUnreadCount(currentUserId);
    
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailPage(
              conversation: conversation,
            ),
          ),
        );
        
        // Refresh if needed
        if (result == true) {
          await _loadConversations();
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12 * scaleFactor),
        padding: EdgeInsets.all(16 * scaleFactor),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16 * scaleFactor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Profile Image
            CircleAvatar(
              radius: 30 * scaleFactor,
              backgroundColor: Color(0xFF00B4D8),
              backgroundImage: conversation.otherUserImage != null
                  ? NetworkImage(conversation.otherUserImage!)
                  : null,
              child: conversation.otherUserImage == null
                  ? Icon(
                      Icons.person,
                      size: 30 * scaleFactor,
                      color: Colors.white,
                    )
                  : null,
            ),
            SizedBox(width: 14 * scaleFactor),

            // Message Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.otherUserName ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 16 * scaleFactor,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.serviceType != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8 * scaleFactor,
                            vertical: 4 * scaleFactor,
                          ),
                          decoration: BoxDecoration(
                            color: conversation.serviceType == 'Pabakal'
                                ? Colors.blue.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12 * scaleFactor),
                          ),
                          child: Text(
                            conversation.serviceType!,
                            style: TextStyle(
                              fontSize: 10 * scaleFactor,
                              fontWeight: FontWeight.w600,
                              color: conversation.serviceType == 'Pabakal'
                                  ? Colors.blue[700]
                                  : Colors.green[700],
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 6 * scaleFactor),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessageText ?? 'No messages yet',
                          style: TextStyle(
                            fontSize: 14 * scaleFactor,
                            color: unreadCount > 0 
                                ? Colors.black87 
                                : Colors.grey[600],
                            fontWeight: unreadCount > 0 
                                ? FontWeight.w600 
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8 * scaleFactor),
                      Text(
                        conversation.formattedLastMessageTime,
                        style: TextStyle(
                          fontSize: 12 * scaleFactor,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Unread Badge
            if (unreadCount > 0) ...[
              SizedBox(width: 12 * scaleFactor),
              Container(
                padding: EdgeInsets.all(6 * scaleFactor),
                decoration: BoxDecoration(
                  color: Color(0xFF00B4D8),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount > 9 ? '9+' : unreadCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11 * scaleFactor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Old method - no longer used, kept for reference
  Widget _buildMessageCard_OLD({
=======
  Widget _buildMessageCard({
>>>>>>> 0f05632dac88866b90bd3d130afbd6c0a364c1f5
    required String name,
    required String message,
    required String time,
    required int unreadCount,
    required bool isOnline,
    required String imageUrl,
    required String itemId,
    required String route,
    required String items,
    required double scaleFactor,
  }) {
    return GestureDetector(
      onTap: () {
<<<<<<< HEAD
        // Old navigation - replaced by _buildConversationCard
=======
        // Navigate to chat detail page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailPage(
              name: name,
              imageUrl: imageUrl,
              isOnline: isOnline,
              itemId: itemId,
              route: route,
              items: items,
            ),
          ),
        );
>>>>>>> 0f05632dac88866b90bd3d130afbd6c0a364c1f5
      },
      child: Container(
        padding: EdgeInsets.all(14 * scaleFactor),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16 * scaleFactor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Profile Image with online indicator
            Stack(
              children: [
                ClipOval(
                  child: Image.network(
                    imageUrl,
                    width: 60 * scaleFactor,
                    height: 60 * scaleFactor,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60 * scaleFactor,
                        height: 60 * scaleFactor,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          size: 30 * scaleFactor,
                          color: Colors.grey[600],
                        ),
                      );
                    },
                  ),
                ),
                if (isOnline)
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

            // Message Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16 * scaleFactor,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 13 * scaleFactor,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(width: 4 * scaleFactor),
                          if (isOnline)
                            Container(
                              width: 8 * scaleFactor,
                              height: 8 * scaleFactor,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 4 * scaleFactor),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14 * scaleFactor,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Unread Badge
            if (unreadCount > 0) ...[
              SizedBox(width: 8 * scaleFactor),
              Container(
                padding: EdgeInsets.all(6 * scaleFactor),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12 * scaleFactor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

