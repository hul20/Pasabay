import 'package:flutter/material.dart';
<<<<<<< HEAD
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
=======
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import 'requester_home_page.dart';
import 'requester_messages_page.dart';
import 'requester_profile_page.dart';
import 'traveler_detail_page.dart';
>>>>>>> 0f05632dac88866b90bd3d130afbd6c0a364c1f5

class RequesterActivityPage extends StatefulWidget {
  const RequesterActivityPage({super.key});

  @override
  State<RequesterActivityPage> createState() => _RequesterActivityPageState();
}

class _RequesterActivityPageState extends State<RequesterActivityPage> {
<<<<<<< HEAD
  final RequestService _requestService = RequestService();
  final MessagingService _messagingService = MessagingService();
  final _supabase = Supabase.instance.client;
  
  List<ServiceRequest> _pendingRequests = [];
  List<ServiceRequest> _acceptedRequests = [];
  List<ServiceRequest> _completedRequests = [];
  Map<String, Map<String, dynamic>> _travelerInfoCache = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);

    try {
      final requests = await _requestService.getRequesterRequests();
      
      final pending = <ServiceRequest>[];
      final accepted = <ServiceRequest>[];
      final completed = <ServiceRequest>[];

      for (var request in requests) {
        if (request.status == 'Pending') {
          pending.add(request);
        } else if (request.status == 'Accepted') {
          accepted.add(request);
        } else {
          completed.add(request);
        }

        if (!_travelerInfoCache.containsKey(request.travelerId)) {
          final info = await _requestService.getTravelerInfo(request.travelerId);
          if (info != null) {
            _travelerInfoCache[request.travelerId] = info;
          }
        }
      }

      if (mounted) {
        setState(() {
          _pendingRequests = pending;
          _acceptedRequests = accepted;
          _completedRequests = completed;
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
        content: Text('Are you sure you want to cancel this ${request.serviceType} request?'),
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
          SnackBar(content: Text('Request cancelled'), backgroundColor: Colors.orange),
        );
        await _loadRequests();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }
=======
  String _selectedTab = 'Available'; // Available or My Requests
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
            SizedBox(height: 20 * scaleFactor),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadRequests,
                      child: DefaultTabController(
                        length: 3,
                        child: Column(
                          children: [
                            TabBar(
                              labelColor: Color(0xFF00B4D8),
                              unselectedLabelColor: Colors.grey,
                              indicatorColor: Color(0xFF00B4D8),
                              tabs: [
                                Tab(text: 'Pending (${_pendingRequests.length})'),
                                Tab(text: 'Ongoing (${_acceptedRequests.length})'),
                                Tab(text: 'History (${_completedRequests.length})'),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  _buildRequestsList(_pendingRequests, true, scaleFactor),
                                  _buildRequestsList(_acceptedRequests, false, scaleFactor),
                                  _buildRequestsList(_completedRequests, false, scaleFactor),
                                ],
                              ),
                            ),
                          ],
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
          Text(
            'My Requests',
            style: TextStyle(
              fontSize: 24 * scaleFactor,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList(List<ServiceRequest> requests, bool showCancel, double scaleFactor) {
    if (requests.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(40 * scaleFactor),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 60 * scaleFactor, color: Colors.grey[300]),
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
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(18 * scaleFactor),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        final travelerInfo = _travelerInfoCache[request.travelerId];
        return _buildRequestCard(request, travelerInfo, showCancel, scaleFactor);
      },
    );
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
              Icon(Icons.person, size: 16 * scaleFactor, color: Colors.grey[600]),
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
                        final conversations = await _messagingService.getConversations();
                        final conversation = conversations.firstWhere(
                          (c) => c.requestId == request.id,
                          orElse: () => throw 'Conversation not found',
                        );
                        
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetailPage(conversation: conversation),
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
              MaterialPageRoute(builder: (context) => const RequesterHomePage()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
=======
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18 * scaleFactor),
              child: Column(
                children: [
                  SizedBox(height: 12 * scaleFactor),
                  // Top bar: logo and user icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
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
                              hintText: 'Search for location, route, etc.',
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
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 18 * scaleFactor),

            // Preferred Schedule Card
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18 * scaleFactor),
              child: Container(
                padding: EdgeInsets.all(18 * scaleFactor),
                decoration: BoxDecoration(
                  color: Color(0xFF00B4D8),
                  borderRadius: BorderRadius.circular(20 * scaleFactor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preferred Schedule',
                      style: TextStyle(
                        fontSize: 22 * scaleFactor,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8 * scaleFactor),
                    Text(
                      'Tap to change ideal date and time for travelers',
                      style: TextStyle(
                        fontSize: 13 * scaleFactor,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    SizedBox(height: 14 * scaleFactor),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14 * scaleFactor,
                        vertical: 12 * scaleFactor,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12 * scaleFactor),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 20 * scaleFactor,
                            color: Colors.black,
                          ),
                          SizedBox(width: 10 * scaleFactor),
                          Expanded(
                            child: Text(
                              'Iloilo City → Roxas City',
                              style: TextStyle(
                                fontSize: 14 * scaleFactor,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10 * scaleFactor,
                              vertical: 6 * scaleFactor,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8 * scaleFactor),
                            ),
                            child: Text(
                              'April 3 - April 5',
                              style: TextStyle(
                                fontSize: 12 * scaleFactor,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20 * scaleFactor),

            // Toggle buttons: Available / My Requests
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18 * scaleFactor),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 'Available'),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14 * scaleFactor),
                        decoration: BoxDecoration(
                          color: _selectedTab == 'Available'
                              ? Color(0xFF00B4D8)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12 * scaleFactor),
                          border: Border.all(
                            color: _selectedTab == 'Available'
                                ? Color(0xFF00B4D8)
                                : Colors.grey[300]!,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Available',
                            style: TextStyle(
                              fontSize: 15 * scaleFactor,
                              fontWeight: FontWeight.w600,
                              color: _selectedTab == 'Available'
                                  ? Colors.white
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 14 * scaleFactor),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 'My Requests'),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14 * scaleFactor),
                        decoration: BoxDecoration(
                          color: _selectedTab == 'My Requests'
                              ? Color(0xFF00B4D8)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12 * scaleFactor),
                          border: Border.all(
                            color: _selectedTab == 'My Requests'
                                ? Color(0xFF00B4D8)
                                : Colors.grey[300]!,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'My Requests',
                            style: TextStyle(
                              fontSize: 15 * scaleFactor,
                              fontWeight: FontWeight.w600,
                              color: _selectedTab == 'My Requests'
                                  ? Colors.white
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20 * scaleFactor),

            // Results count
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18 * scaleFactor),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '1 Result',
                  style: TextStyle(
                    fontSize: 14 * scaleFactor,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),

            SizedBox(height: 14 * scaleFactor),

            // Travelers List
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 18 * scaleFactor),
                children: [
                  _buildTravelerCard(
                    name: 'Juan Carlos Santos',
                    route: 'Iloilo City → Roxas City',
                    date: 'April 3, 5:00 PM',
                    rating: '4.9',
                    imageUrl: 'https://i.pravatar.cc/150?img=12',
                    scaleFactor: scaleFactor,
                    context: context,
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
        currentIndex: 1, // Activity tab
        onTap: (index) async {
          if (index == 0) {
            Navigator.pop(context);
          } else if (index == 2) {
            await Navigator.pushReplacement(
>>>>>>> 0f05632dac88866b90bd3d130afbd6c0a364c1f5
              context,
              MaterialPageRoute(builder: (context) => const RequesterMessagesPage()),
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
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Activity'),
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
}

=======

  Widget _buildTravelerCard({
    required String name,
    required String route,
    required String date,
    required String rating,
    required String imageUrl,
    required double scaleFactor,
    required BuildContext context,
  }) {
    return GestureDetector(
      onTap: () {
        // Navigate to traveler detail page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TravelerDetailPage(
              name: name,
              route: route,
              date: date,
              rating: rating,
              imageUrl: imageUrl,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(16 * scaleFactor),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16 * scaleFactor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Profile Picture
            ClipOval(
              child: Image.network(
                imageUrl,
                width: 64 * scaleFactor,
                height: 64 * scaleFactor,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 64 * scaleFactor,
                    height: 64 * scaleFactor,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person, color: Colors.grey[600], size: 32 * scaleFactor),
                  );
                },
              ),
            ),
            SizedBox(width: 14 * scaleFactor),

            // Traveler Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 16 * scaleFactor,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Color(0xFFFFA726),
                            size: 18 * scaleFactor,
                          ),
                          SizedBox(width: 4 * scaleFactor),
                          Text(
                            rating,
                            style: TextStyle(
                              fontSize: 15 * scaleFactor,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 6 * scaleFactor),
                  Text(
                    route,
                    style: TextStyle(
                      fontSize: 14 * scaleFactor,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 4 * scaleFactor),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 13 * scaleFactor,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 10 * scaleFactor),

            // Engaging button
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 18 * scaleFactor,
                vertical: 10 * scaleFactor,
              ),
              decoration: BoxDecoration(
                color: Color(0xFF00B4D8),
                borderRadius: BorderRadius.circular(10 * scaleFactor),
              ),
              child: Text(
                'Engaging',
                style: TextStyle(
                  fontSize: 13 * scaleFactor,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
>>>>>>> 0f05632dac88866b90bd3d130afbd6c0a364c1f5
