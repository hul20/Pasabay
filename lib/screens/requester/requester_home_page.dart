import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/supabase_service.dart';
import '../../services/request_service.dart';
import '../../services/notification_service.dart';
import '../../models/trip.dart';
import '../notifications_page.dart';
import '../tracking_map_page.dart';
import 'requester_activity_page.dart';
import 'requester_messages_page.dart';
import 'requester_profile_page.dart';
import 'traveler_search_results_page.dart';

class RequesterHomePage extends StatefulWidget {
  const RequesterHomePage({super.key});

  @override
  State<RequesterHomePage> createState() => _RequesterHomePageState();
}

class _RequesterHomePageState extends State<RequesterHomePage>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  String userName = "Maria";

  // Location controllers
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final RequestService _requestService = RequestService();
  final NotificationService _notificationService = NotificationService();
  int _unreadNotifications = 0;
  RealtimeChannel? _notificationSubscription;

  // Ongoing transaction
  Map<String, dynamic>? _ongoingRequest;
  bool _loadingRequest = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchUserProfile();
    _loadUnreadNotifications();
    _setupNotificationSubscription();
    _fetchOngoingRequest();
  }

  void _setupNotificationSubscription() {
    try {
      _notificationSubscription = _notificationService.subscribeToNotifications(
        (notification) {
          if (mounted) {
            _loadUnreadNotifications();

            // Show a snackbar for new notification
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(notification.title),
                action: SnackBarAction(
                  label: 'View',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsPage(),
                      ),
                    );
                  },
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      );
    } catch (e) {
      print('Error subscribing to notifications: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadUnreadNotifications();
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
    _departureController.dispose();
    _destinationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _searchTravelers() async {
    if (_departureController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter departure location'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_destinationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter destination location'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      final trips = await _requestService.searchAvailableTrips(
        departureLocation: _departureController.text.trim(),
        destinationLocation: _destinationController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (trips.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No travelers found for this route'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Navigate to search results
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TravelerSearchResultsPage(
            trips: trips,
            departureLocation: _departureController.text.trim(),
            destinationLocation: _destinationController.text.trim(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching travelers: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchUserProfile() async {
    final supabaseService = SupabaseService();
    final userData = await supabaseService.getUserData();

    if (userData != null && mounted) {
      setState(() {
        userName = userData['first_name'] ?? "Maria";
      });
    }
  }

  List<String> _getProgressSteps(String serviceType) {
    if (serviceType == 'Pabakal') {
      return [
        'Order Accepted',
        'Item Bought',
        'On the Way',
        'Dropped Off',
        'Completed',
      ];
    } else {
      return [
        'Order Accepted',
        'Picked Up',
        'On the Way',
        'Dropped Off',
        'Completed',
      ];
    }
  }

  int _getCurrentStepIndex(String status, String serviceType) {
    final Map<String, int> pabakalSteps = {
      'Accepted': 0,
      'Item Bought': 1,
      'On the Way': 2,
      'Dropped Off': 3,
      'Order Sent': 3,
      'Completed': 4,
    };

    final Map<String, int> pasabaySteps = {
      'Accepted': 0,
      'Picked Up': 1,
      'On the Way': 2,
      'Dropped Off': 3,
      'Order Sent': 3,
      'Completed': 4,
    };

    if (serviceType == 'Pabakal') {
      return pabakalSteps[status] ?? 0;
    } else {
      return pasabaySteps[status] ?? 0;
    }
  }

  Future<void> _fetchOngoingRequest() async {
    setState(() {
      _loadingRequest = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Get most urgent ongoing request (all active statuses)
      final response = await Supabase.instance.client
          .from('service_requests')
          .select('*')
          .eq('requester_id', userId)
          .inFilter('status', [
            'Accepted',
            'Item Bought',
            'Picked Up',
            'On the Way',
            'Dropped Off',
          ])
          .order('created_at', ascending: false)
          .limit(1);

      if (mounted && response.isNotEmpty) {
        setState(() {
          _ongoingRequest = response.first;
          _loadingRequest = false;
        });
      } else {
        setState(() {
          _ongoingRequest = null;
          _loadingRequest = false;
        });
      }
    } catch (e) {
      print('Error fetching ongoing request: \$e');
      if (mounted) {
        setState(() {
          _ongoingRequest = null;
          _loadingRequest = false;
        });
      }
    }
  }

  Widget _buildProgressBar(
    List<String> steps,
    int currentStep,
    double scaleFactor,
  ) {
    return Column(
      children: [
        // Progress dots and lines
        Row(
          children: List.generate(steps.length * 2 - 1, (index) {
            if (index.isEven) {
              // Dot
              int stepIndex = index ~/ 2;
              bool isCompleted = stepIndex <= currentStep;
              return Container(
                width: 24 * scaleFactor,
                height: 24 * scaleFactor,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? Color(0xFF00B4D8) : Colors.grey[300],
                  border: Border.all(
                    color: isCompleted ? Color(0xFF00B4D8) : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? Icon(
                        Icons.check,
                        size: 14 * scaleFactor,
                        color: Colors.white,
                      )
                    : null,
              );
            } else {
              // Line
              int stepIndex = index ~/ 2;
              bool isCompleted = stepIndex < currentStep;
              return Expanded(
                child: Container(
                  height: 2,
                  color: isCompleted ? Color(0xFF00B4D8) : Colors.grey[300],
                ),
              );
            }
          }),
        ),
        SizedBox(height: 8 * scaleFactor),
        // Step labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: steps.asMap().entries.map((entry) {
            int stepIndex = entry.key;
            String label = entry.value;
            bool isCompleted = stepIndex <= currentStep;
            return Expanded(
              child: Text(
                label,
                textAlign: stepIndex == 0
                    ? TextAlign.start
                    : stepIndex == steps.length - 1
                    ? TextAlign.end
                    : TextAlign.center,
                style: TextStyle(
                  fontSize: 10 * scaleFactor,
                  fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w400,
                  color: isCompleted ? Color(0xFF00B4D8) : Colors.grey[600],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _fetchUserProfile();
            await _fetchOngoingRequest();
          },
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 18 * scaleFactor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 12 * scaleFactor),

                  // Top bar: logo and role icon (matching traveler)
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
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Color(0xFF00B4D8),
                              borderRadius: BorderRadius.circular(
                                10 * scaleFactor,
                              ),
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
                    ],
                  ),

                  SizedBox(height: 16 * scaleFactor),

                  // Search bar with notifications (matching traveler)
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
                              hintText: 'Search for location, route, etc.',
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

                  SizedBox(height: 24 * scaleFactor),

                  // Greeting
                  Text(
                    'Hello, $userName!',
                    style: TextStyle(
                      fontSize: 32 * scaleFactor,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 4 * scaleFactor),
                  Text(
                    "Here's an overview for this month of October",
                    style: TextStyle(
                      fontSize: 14 * scaleFactor,
                      color: Colors.grey[600],
                    ),
                  ),

                  SizedBox(height: 24 * scaleFactor),

                  // Ongoing Transaction Overview
                  if (_loadingRequest)
                    Container(
                      padding: EdgeInsets.all(20 * scaleFactor),
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
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00B4D8),
                        ),
                      ),
                    )
                  else if (_ongoingRequest != null)
                    GestureDetector(
                      onTap: () {
                        // Navigate to tracking map if status is "On the Way"
                        if (_ongoingRequest!['status'] == 'On the Way') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TrackingMapPage(
                                requestId: _ongoingRequest!['id'],
                                travelerName:
                                    'Traveler', // You can fetch this from users table
                                serviceType:
                                    _ongoingRequest!['service_type'] ??
                                    'Service',
                                status: _ongoingRequest!['status'] ?? 'Active',
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(20 * scaleFactor),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16 * scaleFactor),
                          border: Border.all(
                            color: Color(0xFF00B4D8),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF00B4D8).withOpacity(0.15),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with service type badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12 * scaleFactor,
                                    vertical: 6 * scaleFactor,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF00B4D8).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                      8 * scaleFactor,
                                    ),
                                  ),
                                  child: Text(
                                    _ongoingRequest!['service_type'] ??
                                        'Pasabay',
                                    style: TextStyle(
                                      fontSize: 13 * scaleFactor,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF00B4D8),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12 * scaleFactor,
                                    vertical: 6 * scaleFactor,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        _ongoingRequest!['status'] == 'Accepted'
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                      8 * scaleFactor,
                                    ),
                                  ),
                                  child: Text(
                                    _ongoingRequest!['status'] ?? 'Pending',
                                    style: TextStyle(
                                      fontSize: 13 * scaleFactor,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          _ongoingRequest!['status'] ==
                                              'Accepted'
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16 * scaleFactor),

                            // Traveler name or product details
                            Text(
                              _ongoingRequest!['service_type'] == 'Pabakal'
                                  ? _ongoingRequest!['product_name'] ?? 'Item'
                                  : _ongoingRequest!['recipient_name'] ??
                                        'Package',
                              style: TextStyle(
                                fontSize: 18 * scaleFactor,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 8 * scaleFactor),

                            // Destination info
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 16 * scaleFactor,
                                  color: Colors.grey[600],
                                ),
                                SizedBox(width: 6 * scaleFactor),
                                Expanded(
                                  child: Text(
                                    _ongoingRequest!['service_type'] ==
                                            'Pabakal'
                                        ? 'To: ${_ongoingRequest!['delivery_address'] ?? 'N/A'}'
                                        : 'To: ${_ongoingRequest!['recipient_address'] ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 13 * scaleFactor,
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16 * scaleFactor),

                            // Progress Bar
                            _buildProgressBar(
                              _getProgressSteps(
                                _ongoingRequest!['service_type'] ?? 'Pasabay',
                              ),
                              _getCurrentStepIndex(
                                _ongoingRequest!['status'] ?? 'Accepted',
                                _ongoingRequest!['service_type'] ?? 'Pasabay',
                              ),
                              scaleFactor,
                            ),
                            SizedBox(height: 16 * scaleFactor),

                            // Divider
                            Divider(color: Colors.grey[300]),
                            SizedBox(height: 12 * scaleFactor),

                            // Amount
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Amount',
                                  style: TextStyle(
                                    fontSize: 14 * scaleFactor,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '₱${(_ongoingRequest!['total_amount'] ?? 0).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 20 * scaleFactor,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00B4D8),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12 * scaleFactor),

                            // Chat button
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RequesterMessagesPage(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF00B4D8),
                                padding: EdgeInsets.symmetric(
                                  vertical: 12 * scaleFactor,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    10 * scaleFactor,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    color: Colors.white,
                                    size: 18 * scaleFactor,
                                  ),
                                  SizedBox(width: 8 * scaleFactor),
                                  Text(
                                    'Chat',
                                    style: TextStyle(
                                      fontSize: 15 * scaleFactor,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: EdgeInsets.all(20 * scaleFactor),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16 * scaleFactor),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48 * scaleFactor,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 12 * scaleFactor),
                          Text(
                            'No Ongoing Transactions',
                            style: TextStyle(
                              fontSize: 16 * scaleFactor,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 4 * scaleFactor),
                          Text(
                            'Search for travelers below to start',
                            style: TextStyle(
                              fontSize: 13 * scaleFactor,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 28 * scaleFactor),

                  // Find Travelers Section
                  Text(
                    'Find Travelers',
                    style: TextStyle(
                      fontSize: 20 * scaleFactor,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 16 * scaleFactor),

                  // Destination Card (Cyan)
                  Container(
                    padding: EdgeInsets.all(20 * scaleFactor),
                    decoration: BoxDecoration(
                      color: Color(0xFF00B4D8),
                      borderRadius: BorderRadius.circular(16 * scaleFactor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Destination',
                          style: TextStyle(
                            fontSize: 32 * scaleFactor,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8 * scaleFactor),
                        Text(
                          'Tap to pin departure and target location',
                          style: TextStyle(
                            fontSize: 14 * scaleFactor,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        SizedBox(height: 16 * scaleFactor),

                        // Departure Location Input
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16 * scaleFactor,
                            vertical: 4 * scaleFactor,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              12 * scaleFactor,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.trip_origin,
                                color: Color(0xFF00B4D8),
                                size: 22 * scaleFactor,
                              ),
                              SizedBox(width: 12 * scaleFactor),
                              Expanded(
                                child: TextField(
                                  controller: _departureController,
                                  decoration: InputDecoration(
                                    hintText: 'From (e.g., Iloilo)',
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(
                                      fontSize: 15 * scaleFactor,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: 15 * scaleFactor,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 12 * scaleFactor),

                        // Destination Location Input
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16 * scaleFactor,
                            vertical: 4 * scaleFactor,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              12 * scaleFactor,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Color(0xFF00B4D8),
                                size: 22 * scaleFactor,
                              ),
                              SizedBox(width: 12 * scaleFactor),
                              Expanded(
                                child: TextField(
                                  controller: _destinationController,
                                  decoration: InputDecoration(
                                    hintText: 'To (e.g., Roxas)',
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(
                                      fontSize: 15 * scaleFactor,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: 15 * scaleFactor,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16 * scaleFactor),

                  // Search Travelers Button
                  ElevatedButton(
                    onPressed: _searchTravelers,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF00B4D8),
                      padding: EdgeInsets.symmetric(vertical: 16 * scaleFactor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12 * scaleFactor),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          color: Colors.white,
                          size: 24 * scaleFactor,
                        ),
                        SizedBox(width: 12 * scaleFactor),
                        Text(
                          'Search Available Travelers',
                          style: TextStyle(
                            fontSize: 16 * scaleFactor,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 80 * scaleFactor),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) async {
          setState(() {
            _selectedIndex = index;
          });

          if (index == 0) {
            // Already on Home
            await _fetchUserProfile();
          } else if (index == 1) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RequesterActivityPage(),
              ),
            ).then((_) {
              setState(() => _selectedIndex = 0);
              _fetchUserProfile();
            });
          } else if (index == 2) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RequesterMessagesPage(),
              ),
            ).then((_) {
              setState(() => _selectedIndex = 0);
              _fetchUserProfile();
            });
          } else if (index == 3) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RequesterProfilePage(),
              ),
            ).then((_) {
              setState(() => _selectedIndex = 0);
              _fetchUserProfile();
            });
          }
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
}
