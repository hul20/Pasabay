import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../models/trip.dart';
import '../services/trip_service.dart';
import 'messages_page.dart';
import 'profile_page.dart';
import 'traveler/edit_trip_page.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  bool _showRequests = true; // true for "Requests", false for "Ongoing"
  final TripService _tripService = TripService();
  List<Trip> _myTrips = [];
  Trip? _selectedTrip;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrips();
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

  void _showTripSelectionModal(double scaleFactor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24 * scaleFactor),
              topRight: Radius.circular(24 * scaleFactor),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              // Trip List
              if (_myTrips.isEmpty)
                Padding(
                  padding: EdgeInsets.all(40 * scaleFactor),
                  child: Column(
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
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: _myTrips.length,
                  itemBuilder: (context, index) {
                    final trip = _myTrips[index];
                    final isSelected = _selectedTrip?.id == trip.id;
                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: AppConstants.primaryColor.withOpacity(0.1),
                      leading: Icon(
                        Icons.route,
                        color: isSelected ? AppConstants.primaryColor : Colors.grey,
                      ),
                      title: Text(
                        '${trip.departureLocation} → ${trip.destinationLocation}',
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${trip.formattedDepartureDate} • ${trip.formattedDepartureTime}',
                        style: TextStyle(fontSize: 12 * scaleFactor),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: AppConstants.primaryColor)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedTrip = trip;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              // Add New Trip Button
              Padding(
                padding: EdgeInsets.all(20 * scaleFactor),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50 * scaleFactor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12 * scaleFactor),
                    ),
                  ),
                  icon: Icon(Icons.add),
                  label: Text('Add New Trip'),
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
  }

  String _getTruncatedLocation(String location, int maxLength) {
    if (location.length <= maxLength) return location;
    return '${location.substring(0, maxLength)}...';
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
                              hintText: 'Search for an activity',
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
                              borderRadius: BorderRadius.circular(20 * scaleFactor),
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
                                    borderRadius: BorderRadius.circular(12 * scaleFactor),
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
                                                    fontFamily: AppConstants.fontFamily,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text: _getTruncatedLocation(
                                                          _selectedTrip!.departureLocation, 15),
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w600,
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
                                                          _selectedTrip!.destinationLocation, 15),
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w600,
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

                        // Toggle Buttons (Requests / Ongoing)
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showRequests = true;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 14 * scaleFactor,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _showRequests
                                        ? Color(0xFF00B4D8)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12 * scaleFactor),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Requests',
                                      style: TextStyle(
                                        fontSize: 16 * scaleFactor,
                                        fontWeight: FontWeight.w600,
                                        color: _showRequests
                                            ? Colors.white
                                            : Colors.grey[400],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12 * scaleFactor),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showRequests = false;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 14 * scaleFactor,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !_showRequests
                                        ? Color(0xFF00B4D8)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12 * scaleFactor),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Ongoing',
                                      style: TextStyle(
                                        fontSize: 16 * scaleFactor,
                                        fontWeight: FontWeight.w600,
                                        color: !_showRequests
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
                        else if (_showRequests)
                          _buildRequestCard(
                            name: 'Maria Santos',
                            route: '${_selectedTrip!.departureLocation} → ${_selectedTrip!.destinationLocation}',
                            items: 'Polo Shirts, Blazer, and Pants',
                            rating: 4.5,
                            imageUrl: 'https://i.pravatar.cc/150?img=5',
                            scaleFactor: scaleFactor,
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
      bottomNavigationBar: BottomNavigationBar(
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


  Widget _buildRequestCard({
    required String name,
    required String route,
    required String items,
    required double rating,
    required String imageUrl,
    required double scaleFactor,
  }) {
    return Container(
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
          ClipRRect(
            borderRadius: BorderRadius.circular(12 * scaleFactor),
            child: Image.network(
              imageUrl,
              width: 70 * scaleFactor,
              height: 70 * scaleFactor,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 70 * scaleFactor,
                  height: 70 * scaleFactor,
                  color: Colors.grey[300],
                  child: Icon(
                    Icons.person,
                    size: 35 * scaleFactor,
                    color: Colors.grey[600],
                  ),
                );
              },
            ),
          ),
          SizedBox(width: 14 * scaleFactor),

          // Info Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 17 * scaleFactor,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4 * scaleFactor),
                Text(
                  route,
                  style: TextStyle(
                    fontSize: 13 * scaleFactor,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 4 * scaleFactor),
                Text(
                  items,
                  style: TextStyle(
                    fontSize: 13 * scaleFactor,
                    color: Color(0xFF00B4D8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8 * scaleFactor),

          // Right Section: Rating & Arrow
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8 * scaleFactor,
                  vertical: 4 * scaleFactor,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8 * scaleFactor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 14 * scaleFactor,
                    ),
                    SizedBox(width: 4 * scaleFactor),
                    Text(
                      rating.toString(),
                      style: TextStyle(
                        fontSize: 13 * scaleFactor,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8 * scaleFactor),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 18 * scaleFactor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

