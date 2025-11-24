import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../models/request.dart';
import '../../services/request_service.dart';
import 'requester_home_page.dart';
import 'requester_messages_page.dart';
import 'requester_profile_page.dart';
import 'request_status_page.dart';
import '../chat_detail_page.dart';
import '../../services/messaging_service.dart';
import '../../services/notification_service.dart';
import '../notifications_page.dart';

class RequesterActivityPage extends StatefulWidget {
  const RequesterActivityPage({super.key});

  @override
  State<RequesterActivityPage> createState() => _RequesterActivityPageState();
}

class _RequesterActivityPageState extends State<RequesterActivityPage> {
  final RequestService _requestService = RequestService();
  final MessagingService _messagingService = MessagingService();
  final NotificationService _notificationService = NotificationService();
  final _supabase = Supabase.instance.client;

  List<ServiceRequest> _pendingRequests = [];
  List<ServiceRequest> _acceptedRequests = [];
  Map<String, Map<String, dynamic>> _travelerInfoCache = {};
  bool _isLoading = true;
  int _selectedTab = 0; // 0: Pending, 1: Ongoing
  int _unreadNotifications = 0;
  RealtimeChannel? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _loadUnreadNotifications();
    _setupNotificationSubscription();
  }

  void _setupNotificationSubscription() {
    try {
      _notificationSubscription = _notificationService.subscribeToNotifications(
        (notification) {
          if (mounted) {
            _loadUnreadNotifications();
          }
        },
      );
    } catch (e) {
      print('Error subscribing to notifications: $e');
    }
  }

  Future<void> _loadUnreadNotifications() async {
    final count = await _notificationService.getUnreadCount();
    if (mounted) {
      setState(() {
        _unreadNotifications = count;
      });
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);

    try {
      final requests = await _requestService.getRequesterRequests();

      final pending = <ServiceRequest>[];
      final accepted = <ServiceRequest>[];

      for (var request in requests) {
        if (request.status == 'Pending') {
          pending.add(request);
        } else if (request.status == 'Accepted' ||
            request.status == 'Order Sent') {
          accepted.add(request);
        }

        if (!_travelerInfoCache.containsKey(request.travelerId)) {
          final info = await _requestService.getTravelerInfo(
            request.travelerId,
          );
          if (info != null) {
            _travelerInfoCache[request.travelerId] = info;
          }
        }
      }

      if (mounted) {
        setState(() {
          _pendingRequests = pending;
          _acceptedRequests = accepted;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading requests: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cancelRequest(ServiceRequest request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Request?'),
        content: Text(
          'Are you sure you want to cancel this ${request.serviceType} request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await _requestService.cancelRequest(request.id);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
        await _loadRequests();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                                image: AssetImage(AppConstants.logoPath),
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
                          Icons.person,
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
                            borderRadius: BorderRadius.circular(
                              12 * scaleFactor,
                            ),
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
                              hintText: 'Search for an activity',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 15 * scaleFactor,
                              ),
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.grey,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 16 * scaleFactor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12 * scaleFactor),
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationsPage(),
                            ),
                          );
                          _loadUnreadNotifications();
                        },
                        child: Container(
                          width: 44 * scaleFactor,
                          height: 44 * scaleFactor,
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              12 * scaleFactor,
                            ),
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
                              if (_unreadNotifications > 0)
                                Positioned(
                                  right: 10 * scaleFactor,
                                  top: 10 * scaleFactor,
                                  child: Container(
                                    width: 10 * scaleFactor,
                                    height: 10 * scaleFactor,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 18 * scaleFactor),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadRequests,
                      child: SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 18 * scaleFactor,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // My Requests Card
                              Container(
                                padding: EdgeInsets.all(20 * scaleFactor),
                                decoration: BoxDecoration(
                                  color: Color(0xFF00B4D8),
                                  borderRadius: BorderRadius.circular(
                                    20 * scaleFactor,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'My Requests',
                                            style: TextStyle(
                                              fontSize: 26 * scaleFactor,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.list_alt,
                                          color: Colors.white,
                                          size: 24 * scaleFactor,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 6 * scaleFactor),
                                    Text(
                                      'Track and manage your service requests',
                                      style: TextStyle(
                                        fontSize: 13 * scaleFactor,
                                        color: Colors.white.withOpacity(0.95),
                                      ),
                                    ),
                                    SizedBox(height: 16 * scaleFactor),
                                    // Stats container
                                    Container(
                                      padding: EdgeInsets.all(14 * scaleFactor),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          12 * scaleFactor,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          _buildStatItem(
                                            'Pending',
                                            _pendingRequests.length.toString(),
                                            scaleFactor,
                                          ),
                                          _buildVerticalDivider(scaleFactor),
                                          _buildStatItem(
                                            'Ongoing',
                                            _acceptedRequests.length.toString(),
                                            scaleFactor,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 20 * scaleFactor),

                              // Toggle Buttons
                              Row(
                                children: [
                                  _buildTabButton('Pending', 0, scaleFactor),
                                  SizedBox(width: 8 * scaleFactor),
                                  _buildTabButton('Ongoing', 1, scaleFactor),
                                ],
                              ),
                              SizedBox(height: 20 * scaleFactor),

                              // Content based on selected tab
                              if (_selectedTab == 0)
                                ..._buildRequestsList(
                                  _pendingRequests,
                                  true,
                                  scaleFactor,
                                )
                              else
                                ..._buildRequestsList(
                                  _acceptedRequests,
                                  false,
                                  scaleFactor,
                                ),

                              SizedBox(height: 80 * scaleFactor),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(scaleFactor),
    );
  }

  Widget _buildTabButton(String title, int index, double scaleFactor) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12 * scaleFactor),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFF00B4D8) : Colors.transparent,
            borderRadius: BorderRadius.circular(12 * scaleFactor),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14 * scaleFactor,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, double scaleFactor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18 * scaleFactor,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12 * scaleFactor, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider(double scaleFactor) {
    return Container(
      height: 24 * scaleFactor,
      width: 1,
      color: Colors.grey[300],
    );
  }

  List<Widget> _buildRequestsList(
    List<ServiceRequest> requests,
    bool showCancel,
    double scaleFactor,
  ) {
    if (requests.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: EdgeInsets.all(40 * scaleFactor),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 60 * scaleFactor,
                  color: Colors.grey[300],
                ),
                SizedBox(height: 16 * scaleFactor),
                Text(
                  'No requests here',
                  style: TextStyle(
                    fontSize: 18 * scaleFactor,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return requests.map((request) {
      final travelerInfo = _travelerInfoCache[request.travelerId];
      return _buildRequestCard(request, travelerInfo, showCancel, scaleFactor);
    }).toList();
  }

  Widget _buildRequestCard(
    ServiceRequest request,
    Map<String, dynamic>? travelerInfo,
    bool showCancel,
    double scaleFactor,
  ) {
    final travelerName = travelerInfo != null
        ? '${travelerInfo['first_name']} ${travelerInfo['last_name']}'
        : 'Unknown Traveler';

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12 * scaleFactor,
                  vertical: 6 * scaleFactor,
                ),
                decoration: BoxDecoration(
                  color: request.serviceType == 'Pabakal'
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12 * scaleFactor),
                ),
                child: Text(
                  request.serviceType,
                  style: TextStyle(
                    fontSize: 12 * scaleFactor,
                    fontWeight: FontWeight.w600,
                    color: request.serviceType == 'Pabakal'
                        ? Colors.blue[700]
                        : Colors.green[700],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12 * scaleFactor,
                  vertical: 6 * scaleFactor,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(request.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12 * scaleFactor),
                ),
                child: Text(
                  request.status,
                  style: TextStyle(
                    fontSize: 12 * scaleFactor,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(request.status),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * scaleFactor),
          Row(
            children: [
              Icon(
                Icons.person,
                size: 16 * scaleFactor,
                color: Colors.grey[600],
              ),
              SizedBox(width: 6 * scaleFactor),
              Text(
                travelerName,
                style: TextStyle(
                  fontSize: 15 * scaleFactor,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 8 * scaleFactor),
          if (request.serviceType == 'Pabakal') ...[
            Text(
              request.productName ?? 'Product',
              style: TextStyle(
                fontSize: 14 * scaleFactor,
                color: Colors.grey[700],
              ),
            ),
            Text(
              '${request.storeName ?? 'Store'}',
              style: TextStyle(
                fontSize: 13 * scaleFactor,
                color: Colors.grey[600],
              ),
            ),
          ] else ...[
            Text(
              request.packageDescription ?? 'Package',
              style: TextStyle(
                fontSize: 14 * scaleFactor,
                color: Colors.grey[700],
              ),
            ),
            Text(
              'To: ${request.recipientName ?? 'Recipient'}',
              style: TextStyle(
                fontSize: 13 * scaleFactor,
                color: Colors.grey[600],
              ),
            ),
          ],
          SizedBox(height: 12 * scaleFactor),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₱${request.totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18 * scaleFactor,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00B4D8),
                ),
              ),
              Row(
                children: [
                  if (request.status == 'Accepted')
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Get conversation for this request
                        final conversations = await _messagingService
                            .getConversations();
                        final conversation = conversations.firstWhere(
                          (c) => c.requestId == request.id,
                          orElse: () => throw 'Conversation not found',
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ChatDetailPage(conversation: conversation),
                          ),
                        );
                      },
                      icon: Icon(Icons.chat, size: 16 * scaleFactor),
                      label: Text('Chat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF00B4D8),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16 * scaleFactor,
                          vertical: 8 * scaleFactor,
                        ),
                      ),
                    ),
                  if (showCancel) ...[
                    SizedBox(width: 8 * scaleFactor),
                    OutlinedButton(
                      onPressed: () => _cancelRequest(request),
                      child: Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16 * scaleFactor,
                          vertical: 8 * scaleFactor,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(width: 8 * scaleFactor),
                  IconButton(
                    icon: Icon(Icons.arrow_forward_ios, size: 16 * scaleFactor),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RequestStatusPage(
                            request: request,
                            travelerInfo: travelerInfo,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Accepted':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Completed':
        return Colors.blue;
      case 'Cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
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
        currentIndex: 1,
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
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const RequesterMessagesPage(),
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
