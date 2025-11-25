import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../models/conversation.dart';
import '../../services/messaging_service.dart';
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(scaleFactor),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _conversations.isEmpty
                  ? _buildEmptyState(scaleFactor)
                  : RefreshIndicator(
                      onRefresh: _loadConversations,
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: 18 * scaleFactor,
                        ),
                        itemCount: _conversations.length,
                        itemBuilder: (context, index) {
                          final conversation = _conversations[index];
                          return _buildConversationCard(
                            conversation,
                            scaleFactor,
                          );
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
                        image: AssetImage(AppConstants.logoPath),
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
            builder: (context) => ChatDetailPage(conversation: conversation),
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
                  ? Icon(
                      Icons.person,
                      size: 30 * scaleFactor,
                      color: Colors.white,
                    )
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
                            borderRadius: BorderRadius.circular(
                              12 * scaleFactor,
                            ),
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
              MaterialPageRoute(
                builder: (context) => const RequesterHomePage(),
              ),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const RequesterActivityPage(),
              ),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const RequesterProfilePage(),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Activity',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
