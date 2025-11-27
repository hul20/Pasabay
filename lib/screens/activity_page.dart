import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../models/trip.dart';
import '../models/request.dart';
import '../services/trip_service.dart';
import '../services/request_service.dart';
import 'messages_page.dart';
import 'profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_service.dart';
import 'notifications_page.dart';
import 'traveler/edit_trip_page.dart';
import 'traveler/request_detail_page.dart';

class ActivityPage extends StatefulWidget {
  final bool embedded;

  const ActivityPage({super.key, this.embedded = false});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _selectedTab = 0; // 0: Requests, 1: Ongoing, 2: Completed
  final TripService _tripService = TripService();
  final RequestService _requestService = RequestService();
  final NotificationService _notificationService = NotificationService();
  List<Trip> _myTrips = [];
  Trip? _selectedTrip;
  bool _isLoading = true;
  List<ServiceRequest> _pendingRequests = [];
  List<ServiceRequest> _ongoingRequests = [];
  List<ServiceRequest> _completedRequests = [];
  Map<String, Map<String, dynamic>> _requesterInfoCache = {};
  int _unreadNotifications = 0;
  RealtimeChannel? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _loadTrips();
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

  Future<void> _loadTrips() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final trips = await _tripService.getActiveTrips();
      if (mounted) {
        setState(() {
          _myTrips = trips;
          // Auto-select first upcoming trip
          if (_myTrips.isNotEmpty) {
            _selectedTrip = _myTrips.first;
          }
          _isLoading = false;
        });

        // Load requests for the selected trip
        if (_selectedTrip != null) {
          await _loadRequests();
        }
      }
    } catch (e) {
      print('Error loading trips: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadRequests() async {
    if (_selectedTrip == null) return;

    try {
      // Get all requests for the traveler
      final allRequests = await _requestService.getTravelerRequests();

      // Filter by selected trip
      final tripRequests = allRequests
          .where((req) => req.tripId == _selectedTrip!.id)
          .toList();

      // Separate into pending, ongoing, and completed
      final pending = tripRequests
          .where((req) => req.status == 'Pending')
          .toList();

      final ongoing = tripRequests
          .where(
            (req) =>
                req.status == 'Accepted' ||
                req.status == 'Order Sent' ||
                req.status == 'Item Bought' ||
                req.status == 'Picked Up' ||
                req.status == 'On the Way' ||
                req.status == 'Dropped Off',
          )
          .toList();

      final completed = tripRequests
          .where((req) => req.status == 'Completed')
          .toList();

      // Load requester info for each request
      for (var request in tripRequests) {
        if (!_requesterInfoCache.containsKey(request.requesterId)) {
          final info = await _requestService.getRequesterInfo(
            request.requesterId,
          );
          if (info != null) {
            _requesterInfoCache[request.requesterId] = info;
          }
        }
      }

      if (mounted) {
        setState(() {
          _pendingRequests = pending;
          _ongoingRequests = ongoing;
          _completedRequests = completed;
        });
      }
    } catch (e) {
      print('Error loading requests: $e');
    }
  }

  void _showTripSelectionModal(double scaleFactor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24 * scaleFactor),
                  topRight: Radius.circular(24 * scaleFactor),
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.all(20 * scaleFactor),
                    child: Row(
                      children: [
                        Text(
                          'Select Trip',
                          style: TextStyle(
                            fontSize: 20 * scaleFactor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1),

                  // Scrollable Trip List
                  Expanded(
                    child: _myTrips.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(40 * scaleFactor),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.route_outlined,
                                    size: 60 * scaleFactor,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 12 * scaleFactor),
                                  Text(
                                    'No Active Trips',
                                    style: TextStyle(
                                      fontSize: 16 * scaleFactor,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  SizedBox(height: 8 * scaleFactor),
                                  Text(
                                    'Log a trip from the home page',
                                    style: TextStyle(
                                      fontSize: 14 * scaleFactor,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: EdgeInsets.symmetric(
                              vertical: 8 * scaleFactor,
                            ),
                            itemCount: _myTrips.length,
                            itemBuilder: (context, index) {
                              final trip = _myTrips[index];
                              final isSelected = _selectedTrip?.id == trip.id;
                              final canDelete =
                                  trip.currentRequests ==
                                  0; // Can delete if no bookings

                              return Container(
                                margin: EdgeInsets.symmetric(
                                  horizontal: 12 * scaleFactor,
                                  vertical: 4 * scaleFactor,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppConstants.primaryColor.withOpacity(
                                          0.05,
                                        )
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(
                                    12 * scaleFactor,
                                  ),
                                  border: isSelected
                                      ? Border.all(
                                          color: AppConstants.primaryColor
                                              .withOpacity(0.3),
                                          width: 1,
                                        )
                                      : null,
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12 * scaleFactor,
                                    vertical: 8 * scaleFactor,
                                  ),
                                  leading: Icon(
                                    Icons.route,
                                    color: isSelected
                                        ? AppConstants.primaryColor
                                        : Colors.grey,
                                    size: 28 * scaleFactor,
                                  ),
                                  title: Text(
                                    '${trip.departureLocation} → ${trip.destinationLocation}',
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      fontSize: 15 * scaleFactor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 4 * scaleFactor),
                                      Text(
                                        '${trip.formattedDepartureDate}',
                                        style: TextStyle(
                                          fontSize: 12 * scaleFactor,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(height: 2 * scaleFactor),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 12 * scaleFactor,
                                            color: Colors.grey[500],
                                          ),
                                          SizedBox(width: 4 * scaleFactor),
                                          Text(
                                            trip.formattedDepartureTime,
                                            style: TextStyle(
                                              fontSize: 12 * scaleFactor,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          SizedBox(width: 12 * scaleFactor),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 6 * scaleFactor,
                                              vertical: 2 * scaleFactor,
                                            ),
                                            decoration: BoxDecoration(
                                              color: trip.currentRequests == 0
                                                  ? Colors.green.withOpacity(
                                                      0.1,
                                                    )
                                                  : Colors.orange.withOpacity(
                                                      0.1,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    4 * scaleFactor,
                                                  ),
                                            ),
                                            child: Text(
                                              '${trip.currentRequests}/${trip.availableCapacity + trip.currentRequests} requests',
                                              style: TextStyle(
                                                fontSize: 11 * scaleFactor,
                                                fontWeight: FontWeight.w600,
                                                color: trip.currentRequests == 0
                                                    ? Colors.green[700]
                                                    : Colors.orange[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          color: AppConstants.primaryColor,
                                          size: 24 * scaleFactor,
                                        ),
                                      if (canDelete) ...[
                                        SizedBox(width: 8 * scaleFactor),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete_outline,
                                            color: Colors.red[400],
                                            size: 22 * scaleFactor,
                                          ),
                                          onPressed: () => _confirmDeleteTrip(
                                            trip,
                                            scaleFactor,
                                          ),
                                          tooltip: 'Delete trip',
                                        ),
                                      ],
                                    ],
                                  ),
                                  onTap: () async {
                                    setState(() {
                                      _selectedTrip = trip;
                                    });
                                    Navigator.pop(context);
                                    await _loadRequests();
                                  },
                                ),
                              );
                            },
                          ),
                  ),

                  // Add New Trip Button
                  Container(
                    padding: EdgeInsets.all(20 * scaleFactor),
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
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 50 * scaleFactor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12 * scaleFactor),
                        ),
                        elevation: 0,
                      ),
                      icon: Icon(Icons.add, size: 22 * scaleFactor),
                      label: Text(
                        'Add New Trip',
                        style: TextStyle(
                          fontSize: 16 * scaleFactor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context); // Go back to home page
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteTrip(Trip trip, double scaleFactor) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16 * scaleFactor),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 28 * scaleFactor,
            ),
            SizedBox(width: 12 * scaleFactor),
            Expanded(
              child: Text(
                'Delete Trip?',
                style: TextStyle(fontSize: 20 * scaleFactor),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this trip?',
              style: TextStyle(fontSize: 15 * scaleFactor),
            ),
            SizedBox(height: 12 * scaleFactor),
            Container(
              padding: EdgeInsets.all(12 * scaleFactor),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8 * scaleFactor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16 * scaleFactor,
                        color: Colors.grey[700],
                      ),
                      SizedBox(width: 6 * scaleFactor),
                      Expanded(
                        child: Text(
                          '${trip.departureLocation} → ${trip.destinationLocation}',
                          style: TextStyle(
                            fontSize: 14 * scaleFactor,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6 * scaleFactor),
                  Text(
                    '${trip.formattedDepartureDate} • ${trip.formattedDepartureTime}',
                    style: TextStyle(
                      fontSize: 13 * scaleFactor,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12 * scaleFactor),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                fontSize: 13 * scaleFactor,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 15 * scaleFactor,
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8 * scaleFactor),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(fontSize: 15 * scaleFactor)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteTrip(trip);
    }
  }

  Future<void> _deleteTrip(Trip trip) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      await _tripService.deleteTrip(trip.id);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Close trip selection modal if open
      if (mounted) Navigator.pop(context);

      // Update state
      setState(() {
        _myTrips.removeWhere((t) => t.id == trip.id);
        if (_selectedTrip?.id == trip.id) {
          _selectedTrip = _myTrips.isNotEmpty ? _myTrips.first : null;
        }
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Trip deleted successfully')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Failed to delete trip: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  String _getTruncatedLocation(String location, int maxLength) {
    if (location.length <= maxLength) return location;
    return '${location.substring(0, maxLength)}...';
  }

  List<Widget> _buildPendingRequestsList(double scaleFactor) {
    if (_pendingRequests.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: EdgeInsets.all(40 * scaleFactor),
            child: Column(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 60 * scaleFactor,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 12 * scaleFactor),
                Text(
                  'No Pending Requests',
                  style: TextStyle(
                    fontSize: 18 * scaleFactor,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8 * scaleFactor),
                Text(
                  'New requests for this trip\nwill appear here',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14 * scaleFactor,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return _pendingRequests.map((request) {
      final requesterInfo = _requesterInfoCache[request.requesterId];
      return Padding(
        padding: EdgeInsets.only(bottom: 12 * scaleFactor),
        child: _buildRequestCard(
          request: request,
          requesterInfo: requesterInfo,
          scaleFactor: scaleFactor,
        ),
      );
    }).toList();
  }

  List<Widget> _buildOngoingRequestsList(double scaleFactor) {
    if (_ongoingRequests.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: EdgeInsets.all(40 * scaleFactor),
            child: Column(
              children: [
                Icon(
                  Icons.pending_actions,
                  size: 60 * scaleFactor,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 12 * scaleFactor),
                Text(
                  'No Ongoing Requests',
                  style: TextStyle(
                    fontSize: 18 * scaleFactor,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8 * scaleFactor),
                Text(
                  'Accepted requests will\nappear here',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14 * scaleFactor,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return _ongoingRequests.map((request) {
      final requesterInfo = _requesterInfoCache[request.requesterId];
      return Padding(
        padding: EdgeInsets.only(bottom: 12 * scaleFactor),
        child: _buildRequestCard(
          request: request,
          requesterInfo: requesterInfo,
          scaleFactor: scaleFactor,
        ),
      );
    }).toList();
  }

  List<Widget> _buildCompletedRequestsList(double scaleFactor) {
    if (_completedRequests.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: EdgeInsets.all(40 * scaleFactor),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 60 * scaleFactor,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 12 * scaleFactor),
                Text(
                  'No Completed Requests',
                  style: TextStyle(
                    fontSize: 18 * scaleFactor,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8 * scaleFactor),
                Text(
                  'Completed requests for\nthis trip will appear here',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14 * scaleFactor,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return _completedRequests.map((request) {
      final requesterInfo = _requesterInfoCache[request.requesterId];
      return Padding(
        padding: EdgeInsets.only(bottom: 12 * scaleFactor),
        child: _buildRequestCard(
          request: request,
          requesterInfo: requesterInfo,
          scaleFactor: scaleFactor,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
              child: RefreshIndicator(
                onRefresh: _loadTrips,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18 * scaleFactor),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Registered Schedule Card (Tappable)
                        GestureDetector(
                          onTap: () => _showTripSelectionModal(scaleFactor),
                          child: Container(
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
                                        'Registered Schedule',
                                        style: TextStyle(
                                          fontSize: 26 * scaleFactor,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 20 * scaleFactor,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6 * scaleFactor),
                                Text(
                                  _selectedTrip == null
                                      ? 'Tap to select a trip and see requests'
                                      : 'Tap to change route and date',
                                  style: TextStyle(
                                    fontSize: 13 * scaleFactor,
                                    color: Colors.white.withOpacity(0.95),
                                  ),
                                ),
                                SizedBox(height: 16 * scaleFactor),
                                // Route info container
                                Container(
                                  padding: EdgeInsets.all(14 * scaleFactor),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      12 * scaleFactor,
                                    ),
                                  ),
                                  child: _selectedTrip == null
                                      ? Center(
                                          child: Text(
                                            'No trip selected',
                                            style: TextStyle(
                                              fontSize: 14 * scaleFactor,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        )
                                      : Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              color: Colors.grey[700],
                                              size: 20 * scaleFactor,
                                            ),
                                            SizedBox(width: 8 * scaleFactor),
                                            Expanded(
                                              child: RichText(
                                                text: TextSpan(
                                                  style: TextStyle(
                                                    fontSize: 14 * scaleFactor,
                                                    color: Colors.black,
                                                    fontFamily:
                                                        AppConstants.fontFamily,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text: _getTruncatedLocation(
                                                        _selectedTrip!
                                                            .departureLocation,
                                                        15,
                                                      ),
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: ' → ',
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: _getTruncatedLocation(
                                                        _selectedTrip!
                                                            .destinationLocation,
                                                        15,
                                                      ),
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Text(
                                              '${_selectedTrip!.formattedDepartureDate.split(',')[0]}, ${_selectedTrip!.formattedDepartureTime}',
                                              style: TextStyle(
                                                fontSize: 13 * scaleFactor,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black,
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

                        // Toggle Buttons (Requests / Ongoing / Completed)
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedTab = 0;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 12 * scaleFactor,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedTab == 0
                                        ? Color(0xFF00B4D8)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(
                                      12 * scaleFactor,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Requests',
                                      style: TextStyle(
                                        fontSize: 14 * scaleFactor,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedTab == 0
                                            ? Colors.white
                                            : Colors.grey[400],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8 * scaleFactor),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedTab = 1;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 12 * scaleFactor,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedTab == 1
                                        ? Color(0xFF00B4D8)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(
                                      12 * scaleFactor,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Ongoing',
                                      style: TextStyle(
                                        fontSize: 14 * scaleFactor,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedTab == 1
                                            ? Colors.white
                                            : Colors.grey[400],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8 * scaleFactor),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedTab = 2;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 12 * scaleFactor,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedTab == 2
                                        ? Color(0xFF00B4D8)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(
                                      12 * scaleFactor,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Completed',
                                      style: TextStyle(
                                        fontSize: 14 * scaleFactor,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedTab == 2
                                            ? Colors.white
                                            : Colors.grey[400],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20 * scaleFactor),

                        // Content based on selected trip and tab
                        if (_selectedTrip == null)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(40 * scaleFactor),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 60 * scaleFactor,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 12 * scaleFactor),
                                  Text(
                                    'Select a Trip',
                                    style: TextStyle(
                                      fontSize: 18 * scaleFactor,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  SizedBox(height: 8 * scaleFactor),
                                  Text(
                                    'Tap the blue card above to select\na trip and view its requests',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14 * scaleFactor,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (_selectedTab == 0)
                          ..._buildPendingRequestsList(scaleFactor)
                        else if (_selectedTab == 1)
                          ..._buildOngoingRequestsList(scaleFactor)
                        else
                          ..._buildCompletedRequestsList(scaleFactor),

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
      bottomNavigationBar: widget.embedded
          ? null
          : BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppConstants.primaryColor,
              unselectedItemColor: Colors.grey,
              currentIndex: 1, // Activity tab selected
              onTap: (index) {
                if (index == 0) {
                  Navigator.pop(context);
                } else if (index == 2) {
                  // Navigate to Messages page
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MessagesPage(),
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

  Widget _buildStatusBadge(String status, double scaleFactor) {
    Color bgColor;
    IconData icon;
    String label;

    switch (status) {
      case 'Accepted':
        bgColor = Colors.green;
        icon = Icons.check_circle;
        label = 'Accepted';
        break;
      case 'Item Bought':
        bgColor = Colors.teal;
        icon = Icons.shopping_cart;
        label = 'Item Bought';
        break;
      case 'Picked Up':
        bgColor = Colors.teal;
        icon = Icons.inventory_2;
        label = 'Picked Up';
        break;
      case 'On the Way':
        bgColor = Colors.orange;
        icon = Icons.local_shipping;
        label = 'On the Way';
        break;
      case 'Dropped Off':
        bgColor = Colors.purple;
        icon = Icons.place;
        label = 'Dropped Off';
        break;
      case 'Order Sent':
        bgColor = Colors.orange;
        icon = Icons.local_shipping;
        label = 'Order Sent';
        break;
      case 'Completed':
        bgColor = Colors.blue;
        icon = Icons.check_circle;
        label = 'Completed';
        break;
      default:
        bgColor = Colors.grey;
        icon = Icons.info;
        label = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8 * scaleFactor,
        vertical: 3 * scaleFactor,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10 * scaleFactor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12 * scaleFactor, color: Colors.white),
          SizedBox(width: 4 * scaleFactor),
          Text(
            label,
            style: TextStyle(
              fontSize: 11 * scaleFactor,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard({
    required ServiceRequest request,
    Map<String, dynamic>? requesterInfo,
    required double scaleFactor,
  }) {
    final String requesterName = requesterInfo != null
        ? '${requesterInfo['first_name']} ${requesterInfo['last_name']}'
        : 'Unknown';
    final String? imageUrl = requesterInfo?['profile_image_url'];

    final String itemsDescription = request.serviceType == 'Pabakal'
        ? request.productName ?? 'Items'
        : (request.packageDescription ?? 'Package delivery');

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RequestDetailPage(
              request: request,
              requesterInfo: requesterInfo,
            ),
          ),
        );

        // Refresh if needed (if request was accepted/rejected)
        if (result == true) {
          await _loadRequests();
        }
      },
      child: Container(
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
              radius: 35 * scaleFactor,
              backgroundColor: Color(0xFF00B4D8),
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
              child: imageUrl == null
                  ? Icon(
                      Icons.person,
                      size: 35 * scaleFactor,
                      color: Colors.white,
                    )
                  : null,
            ),
            SizedBox(width: 14 * scaleFactor),

            // Info Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          requesterName,
                          style: TextStyle(
                            fontSize: 16 * scaleFactor,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8 * scaleFactor,
                          vertical: 4 * scaleFactor,
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
                            fontSize: 11 * scaleFactor,
                            fontWeight: FontWeight.w600,
                            color: request.serviceType == 'Pabakal'
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
                      Icon(
                        request.serviceType == 'Pabakal'
                            ? Icons.shopping_bag
                            : Icons.local_shipping,
                        size: 14 * scaleFactor,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4 * scaleFactor),
                      Expanded(
                        child: Text(
                          itemsDescription,
                          style: TextStyle(
                            fontSize: 13 * scaleFactor,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5 * scaleFactor),
                  Row(
                    children: [
                      // Icon(
                      //   Icons.attach_money,
                      //   size: 14 * scaleFactor,
                      //   color: Colors.green[700],
                      // ),
                      Text(
                        '₱ ${request.serviceFee.toStringAsFixed(2)} fee',
                        style: TextStyle(
                          fontSize: 13 * scaleFactor,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                      Spacer(),
                      _buildStatusBadge(request.status, scaleFactor),
                    ],
                  ),
                  SizedBox(height: 5 * scaleFactor),
                  Text(
                    request.formattedCreatedAt,
                    style: TextStyle(
                      fontSize: 11 * scaleFactor,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),

            // Arrow Icon
            Icon(
              Icons.arrow_forward_ios,
              size: 18 * scaleFactor,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
