import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../models/conversation.dart';
import '../../services/messaging_service.dart';
=======
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
>>>>>>> 0f05632dac88866b90bd3d130afbd6c0a364c1f5
import '../chat_detail_page.dart';
import 'requester_home_page.dart';
import 'requester_activity_page.dart';
import 'requester_profile_page.dart';

class RequesterMessagesPage extends StatefulWidget {
  const RequesterMessagesPage({super.key});

  @override
  State<RequesterMessagesPage> createState() => _RequesterMessagesPageState();
}

class _RequesterMessagesPageState extends State<RequesterMessagesPage> {
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
<<<<<<< HEAD
            _buildHeader(scaleFactor),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _conversations.isEmpty
                      ? _buildEmptyState(scaleFactor)
                      : RefreshIndicator(
                          onRefresh: _loadConversations,
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 18 * scaleFactor),
                            itemCount: _conversations.length,
                            itemBuilder: (context, index) {
                              final conversation = _conversations[index];
                              return _buildConversationCard(conversation, scaleFactor);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(scaleFactor),
    );
  }

  Widget _buildHeader(double scaleFactor) {
    return Padding(
      padding: EdgeInsets.all(18 * scaleFactor),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40 * scaleFactor,
                    height: 40 * scaleFactor,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8 * scaleFactor),
                      image: const DecorationImage(
                        image: NetworkImage(AppConstants.logoUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 12 * scaleFactor),
                  Text(
                    'Pasabay',
                    style: TextStyle(
                      fontSize: 22 * scaleFactor,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.textPrimaryColor,
                    ),
                  ),
                ],
              ),
              Container(
                width: 44 * scaleFactor,
                height: 44 * scaleFactor,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12 * scaleFactor),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.notifications_outlined,
                        color: AppConstants.primaryColor,
                        size: 26 * scaleFactor,
                      ),
                    ),
                    if (_totalUnread > 0)
                      Positioned(
                        right: 10 * scaleFactor,
                        top: 10 * scaleFactor,
                        child: Container(
                          width: 8 * scaleFactor,
                          height: 8 * scaleFactor,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20 * scaleFactor),
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
              'Your conversations with travelers\nwill appear here',
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
            CircleAvatar(
              radius: 30 * scaleFactor,
              backgroundColor: Color(0xFF00B4D8),
              backgroundImage: conversation.otherUserImage != null
                  ? NetworkImage(conversation.otherUserImage!)
                  : null,
              child: conversation.otherUserImage == null
                  ? Icon(Icons.person, size: 30 * scaleFactor, color: Colors.white)
                  : null,
            ),
            SizedBox(width: 14 * scaleFactor),
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
                            color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                            fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
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
=======
            // Header
            Padding(
              padding: EdgeInsets.all(18 * scaleFactor),
              child: Column(
                children: [
                  // Logo and Notification
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40 * scaleFactor,
                            height: 40 * scaleFactor,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8 * scaleFactor),
                              image: const DecorationImage(
                                image: NetworkImage(AppConstants.logoUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(width: 12 * scaleFactor),
                          Text(
                            'Pasabay',
                            style: TextStyle(
                              fontSize: 22 * scaleFactor,
                              fontWeight: FontWeight.w700,
                              color: AppConstants.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 44 * scaleFactor,
                        height: 44 * scaleFactor,
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12 * scaleFactor),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Icon(
                                Icons.notifications_outlined,
                                color: AppConstants.primaryColor,
                                size: 26 * scaleFactor,
                              ),
                            ),
                            Positioned(
                              right: 10 * scaleFactor,
                              top: 10 * scaleFactor,
                              child: Container(
                                width: 8 * scaleFactor,
                                height: 8 * scaleFactor,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20 * scaleFactor),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12 * scaleFactor),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search messages...',
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
                ],
              ),
            ),

            // Messages Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18 * scaleFactor),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Messages',
                    style: TextStyle(
                      fontSize: 20 * scaleFactor,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimaryColor,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12 * scaleFactor,
                      vertical: 6 * scaleFactor,
                    ),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20 * scaleFactor),
                    ),
                    child: Text(
                      '3 Unread',
                      style: TextStyle(
                        color: AppConstants.primaryColor,
                        fontSize: 12 * scaleFactor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
>>>>>>> 0f05632dac88866b90bd3d130afbd6c0a364c1f5
                  ),
                ],
              ),
            ),
<<<<<<< HEAD
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

  Widget _buildBottomNav(double scaleFactor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const RequesterHomePage()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
=======

            SizedBox(height: 16 * scaleFactor),

            // Messages List
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 18 * scaleFactor),
                children: [
                  _buildMessageCard(
                    name: 'Maria Santos',
                    message: 'Your iPhone 15 Pro has been delivered!',
                    time: '2m ago',
                    isUnread: true,
                    isOnline: true,
                    avatarUrl: 'https://i.pravatar.cc/150?img=5',
                    scaleFactor: scaleFactor,
                  ),
                  SizedBox(height: 12 * scaleFactor),
                  _buildMessageCard(
                    name: 'Carlos Reyes',
                    message: 'I can deliver your laptop next week',
                    time: '1h ago',
                    isUnread: true,
                    isOnline: false,
                    avatarUrl: 'https://i.pravatar.cc/150?img=8',
                    scaleFactor: scaleFactor,
                  ),
                  SizedBox(height: 12 * scaleFactor),
                  _buildMessageCard(
                    name: 'Anna Dela Cruz',
                    message: 'Thanks for using Pasabay!',
                    time: '3h ago',
                    isUnread: false,
                    isOnline: true,
                    avatarUrl: 'https://i.pravatar.cc/150?img=9',
                    scaleFactor: scaleFactor,
                  ),
                  SizedBox(height: 12 * scaleFactor),
                  _buildMessageCard(
                    name: 'John Mendoza',
                    message: 'The item is currently in customs',
                    time: '1d ago',
                    isUnread: false,
                    isOnline: false,
                    avatarUrl: 'https://i.pravatar.cc/150?img=12',
                    scaleFactor: scaleFactor,
                  ),
                  SizedBox(height: 80 * scaleFactor),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: Colors.grey,
        currentIndex: 2, // Messages tab
        onTap: (index) async {
          if (index == 0) {
            Navigator.pop(context);
          } else if (index == 1) {
            await Navigator.pushReplacement(
>>>>>>> 0f05632dac88866b90bd3d130afbd6c0a364c1f5
              context,
              MaterialPageRoute(builder: (context) => const RequesterActivityPage()),
            );
          } else if (index == 3) {
<<<<<<< HEAD
            Navigator.pushReplacement(
=======
            await Navigator.pushReplacement(
>>>>>>> 0f05632dac88866b90bd3d130afbd6c0a364c1f5
              context,
              MaterialPageRoute(builder: (context) => const RequesterProfilePage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
<<<<<<< HEAD
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Activity'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
=======
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Activity'),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
>>>>>>> 0f05632dac88866b90bd3d130afbd6c0a364c1f5
        ],
      ),
    );
  }
<<<<<<< HEAD
=======

  Widget _buildMessageCard({
    required String name,
    required String message,
    required String time,
    required bool isUnread,
    required bool isOnline,
    required String avatarUrl,
    required double scaleFactor,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailPage(
              name: name,
              imageUrl: avatarUrl,
              isOnline: isOnline,
              itemId: '1',
              route: 'Manila to Cebu',
              items: 'iPhone 15 Pro',
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16 * scaleFactor),
      child: Container(
        padding: EdgeInsets.all(14 * scaleFactor),
        decoration: BoxDecoration(
          color: isUnread ? AppConstants.primaryColor.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16 * scaleFactor),
          border: Border.all(
            color: isUnread
                ? AppConstants.primaryColor.withOpacity(0.2)
                : Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                ClipOval(
                  child: Image.network(
                    avatarUrl,
                    width: 56 * scaleFactor,
                    height: 56 * scaleFactor,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 56 * scaleFactor,
                        height: 56 * scaleFactor,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person, color: Colors.grey[600]),
                      );
                    },
                  ),
                ),
                if (isOnline)
                  Positioned(
                    right: 2 * scaleFactor,
                    bottom: 2 * scaleFactor,
                    child: Container(
                      width: 14 * scaleFactor,
                      height: 14 * scaleFactor,
                      decoration: BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 14 * scaleFactor),

            // Message content
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
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                          color: AppConstants.textPrimaryColor,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 12 * scaleFactor,
                          color: isUnread
                              ? AppConstants.primaryColor
                              : AppConstants.textSecondaryColor,
                          fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6 * scaleFactor),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          message,
                          style: TextStyle(
                            fontSize: 14 * scaleFactor,
                            color: isUnread
                                ? AppConstants.textPrimaryColor
                                : AppConstants.textSecondaryColor,
                            fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUnread)
                        Container(
                          margin: EdgeInsets.only(left: 8 * scaleFactor),
                          width: 8 * scaleFactor,
                          height: 8 * scaleFactor,
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
>>>>>>> 0f05632dac88866b90bd3d130afbd6c0a364c1f5
}

