import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';
import '../../services/haptic_service.dart';
import '../../utils/helpers.dart';
import '../../utils/supabase_service.dart';
import '../../services/request_service.dart';
import '../../services/notification_service.dart';
import '../../services/distance_service.dart';
import '../../services/location_tracking_service.dart';
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
  final DistanceService _distanceService = DistanceService();
  final LocationTrackingService _trackingService = LocationTrackingService();
  int _unreadNotifications = 0;
  RealtimeChannel? _notificationSubscription;

  // Ongoing transaction
  Map<String, dynamic>? _ongoingRequest;
  bool _loadingRequest = false;

  // ETA for ongoing request
  double _etaMinutes = 0;
  double _distanceKm = 0;
  bool _isCalculatingETA = false;

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
          .select('''
            *,
            trips:trip_id (
              destination_location,
              destination_lat,
              destination_lng
            )
          ''')
          .eq('requester_id', userId)
          .inFilter('status', [
            'Accepted',
            'Order Sent',
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

        // Calculate ETA if status is "On the Way"
        if (response.first['status'] == 'On the Way') {
          _calculateETA(response.first);
        }
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

  Future<void> _calculateETA(Map<String, dynamic> request) async {
    if (_isCalculatingETA) return;

    setState(() => _isCalculatingETA = true);

    try {
      // Get traveler's current location
      final location = await _trackingService.getCurrentLocation(request['id']);

      if (location == null) {
        setState(() => _isCalculatingETA = false);
        return;
      }

      // Get destination coordinates from trip
      final tripData = request['trips'];
      if (tripData == null) {
        setState(() => _isCalculatingETA = false);
        return;
      }

      final destLat = tripData['destination_lat'];
      final destLng = tripData['destination_lng'];

      if (destLat == null || destLng == null) {
        setState(() => _isCalculatingETA = false);
        return;
      }

      // Calculate distance and ETA
      final result = await _distanceService.calculateDistance(
        originLat: location['latitude']!,
        originLng: location['longitude']!,
        destLat: (destLat as num).toDouble(),
        destLng: (destLng as num).toDouble(),
      );

      if (mounted && result.success) {
        setState(() {
          _etaMinutes = result.durationInMinutes;
          _distanceKm = result.distanceInKm;
          _isCalculatingETA = false;
        });
      } else {
        setState(() => _isCalculatingETA = false);
      }
    } catch (e) {
      print('Error calculating ETA: $e');
      if (mounted) {
        setState(() => _isCalculatingETA = false);
      }
    }
  }

  String _formatETA() {
    if (_etaMinutes < 1) {
      return 'Arriving now';
    } else if (_etaMinutes < 60) {
      return '${_etaMinutes.round()} min';
    } else {
      final hours = _etaMinutes ~/ 60;
      final mins = (_etaMinutes % 60).round();
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
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

  Widget _buildOngoingTransactionCard(double scaleFactor) {
    final serviceType = _ongoingRequest!['service_type'] ?? 'Pasabay';
    final status = _ongoingRequest!['status'] ?? 'Accepted';
    final serviceFee = (_ongoingRequest!['service_fee'] ?? 0).toDouble();
    final isCompleted = status == 'Completed';

    // Determine the service type display name and icon
    String displayServiceType;
    IconData serviceIcon;
    if (serviceType == 'Pabakal') {
      displayServiceType = 'Buy & Deliver';
      serviceIcon = Icons.shopping_bag_outlined;
    } else {
      displayServiceType = 'Package Delivery';
      serviceIcon = Icons.local_shipping_outlined;
    }

    // White Timeline Card only
    return Container(
      padding: EdgeInsets.all(16 * scaleFactor),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * scaleFactor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Icon, Service Type & Fee, Arrow
          GestureDetector(
            onTap: () {
              if (status == 'On the Way') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrackingMapPage(
                      requestId: _ongoingRequest!['id'],
                      travelerName: 'Traveler',
                      serviceType: serviceType,
                      status: status,
                    ),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RequesterActivityPage(),
                  ),
                );
              }
            },
            child: Row(
              children: [
                // Service Icon
                Container(
                  width: 48 * scaleFactor,
                  height: 48 * scaleFactor,
                  decoration: BoxDecoration(
                    color: Color(0xFF00B4D8).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12 * scaleFactor),
                  ),
                  child: Icon(
                    serviceIcon,
                    color: Color(0xFF00B4D8),
                    size: 26 * scaleFactor,
                  ),
                ),
                SizedBox(width: 12 * scaleFactor),
                // Service Type and Fee
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayServiceType,
                        style: TextStyle(
                          fontSize: 16 * scaleFactor,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2 * scaleFactor),
                      Row(
                        children: [
                          Text(
                            'Service Fee: ',
                            style: TextStyle(
                              fontSize: 13 * scaleFactor,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '₱${serviceFee.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 13 * scaleFactor,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF00B4D8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 24 * scaleFactor,
                ),
              ],
            ),
          ),

          // ETA Badge (only show when status is "On the Way" and ETA is available)
          if (status == 'On the Way' && _etaMinutes > 0) ...[
            SizedBox(height: 12 * scaleFactor),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 12 * scaleFactor,
                vertical: 8 * scaleFactor,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8 * scaleFactor),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_filled,
                    color: Colors.green[700],
                    size: 16 * scaleFactor,
                  ),
                  SizedBox(width: 6 * scaleFactor),
                  Text(
                    'Arriving in ${_formatETA()}',
                    style: TextStyle(
                      fontSize: 13 * scaleFactor,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                  if (_distanceKm > 0) ...[
                    Text(
                      ' • ${_distanceKm.toStringAsFixed(1)} km away',
                      style: TextStyle(
                        fontSize: 12 * scaleFactor,
                        color: Colors.green[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          SizedBox(height: 20 * scaleFactor),

          // Progress Timeline
          _buildProgressBar(
            _getProgressSteps(serviceType),
            _getCurrentStepIndex(status, serviceType),
            scaleFactor,
          ),

          SizedBox(height: 16 * scaleFactor),

          // Action Buttons
          Row(
            children: [
              // Details/Track Button
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    if (status == 'On the Way') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TrackingMapPage(
                            requestId: _ongoingRequest!['id'],
                            travelerName: 'Traveler',
                            serviceType: serviceType,
                            status: status,
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RequesterActivityPage(),
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12 * scaleFactor),
                    side: BorderSide(color: Color(0xFF00B4D8)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8 * scaleFactor),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (status == 'On the Way') ...[
                        Icon(
                          Icons.location_on,
                          color: Color(0xFF00B4D8),
                          size: 18 * scaleFactor,
                        ),
                        SizedBox(width: 4 * scaleFactor),
                      ],
                      Text(
                        status == 'On the Way' ? 'Track' : 'Details',
                        style: TextStyle(
                          fontSize: 14 * scaleFactor,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00B4D8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12 * scaleFactor),
              // Completed or Action Button
              Expanded(
                child: ElevatedButton(
                  onPressed: isCompleted
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RequesterMessagesPage(),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompleted
                        ? Colors.grey[300]
                        : Color(0xFF00B4D8),
                    padding: EdgeInsets.symmetric(vertical: 12 * scaleFactor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8 * scaleFactor),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isCompleted) ...[
                        Icon(
                          Icons.check,
                          color: Colors.grey[600],
                          size: 18 * scaleFactor,
                        ),
                        SizedBox(width: 4 * scaleFactor),
                      ],
                      Text(
                        isCompleted ? 'Completed' : 'Chat',
                        style: TextStyle(
                          fontSize: 14 * scaleFactor,
                          fontWeight: FontWeight.w600,
                          color: isCompleted ? Colors.grey[600] : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
                    _buildOngoingTransactionCard(scaleFactor)
                  else
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20 * scaleFactor),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16 * scaleFactor),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48 * scaleFactor,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 12 * scaleFactor),
                          Text(
                            'No Ongoing Transactions',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16 * scaleFactor,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 4 * scaleFactor),
                          Text(
                            'Search for travelers below to start',
                            textAlign: TextAlign.center,
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
          HapticService.tabChange();
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
