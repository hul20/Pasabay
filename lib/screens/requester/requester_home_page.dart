import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/supabase_service.dart';
import '../../services/request_service.dart';
import '../../models/trip.dart';
import 'requester_activity_page.dart';
import 'requester_messages_page.dart';
import 'requester_profile_page.dart';
import 'traveler_search_results_page.dart';

class RequesterHomePage extends StatefulWidget {
  const RequesterHomePage({super.key});

  @override
  State<RequesterHomePage> createState() => _RequesterHomePageState();
}

class _RequesterHomePageState extends State<RequesterHomePage> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  String userName = "Maria";
  
  // Location controllers
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final RequestService _requestService = RequestService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchUserProfile();
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchUserProfile,
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
                  
                  // Search bar with notifications (matching traveler)
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
                  
                  // Stats Cards Row (Active Travelers & Hot Route)
                  Row(
                    children: [
                      Expanded(
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Active Travelers',
                                    style: TextStyle(
                                      fontSize: 13 * scaleFactor,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Icon(
                                    Icons.trending_up,
                                    color: Color(0xFF00B4D8),
                                    size: 18 * scaleFactor,
                                  ),
                                ],
                              ),
                              SizedBox(height: 8 * scaleFactor),
                              Text(
                                '67',
                                style: TextStyle(
                                  fontSize: 36 * scaleFactor,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 12 * scaleFactor),
                      Expanded(
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Hot Route',
                                    style: TextStyle(
                                      fontSize: 13 * scaleFactor,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Icon(
                                    Icons.trending_up,
                                    color: Color(0xFF00B4D8),
                                    size: 18 * scaleFactor,
                                  ),
                                ],
                              ),
                              SizedBox(height: 8 * scaleFactor),
                              Text(
                                'Iloilo To\nRoxas',
                                style: TextStyle(
                                  fontSize: 16 * scaleFactor,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
                            borderRadius: BorderRadius.circular(12 * scaleFactor),
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
                            borderRadius: BorderRadius.circular(12 * scaleFactor),
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
                  
                  SizedBox(height: 16 * scaleFactor),
                  
                  // Ideal Schedule Card (Gray-Blue) - Optional filter
                  Container(
                    padding: EdgeInsets.all(20 * scaleFactor),
                    decoration: BoxDecoration(
                      color: Color(0xFF6B9AA5),
                      borderRadius: BorderRadius.circular(16 * scaleFactor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filter by Schedule',
                          style: TextStyle(
                            fontSize: 24 * scaleFactor,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8 * scaleFactor),
                        Text(
                          'Optional: Filter by preferred travel date',
                          style: TextStyle(
                            fontSize: 13 * scaleFactor,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        SizedBox(height: 16 * scaleFactor),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16 * scaleFactor,
                                  vertical: 14 * scaleFactor,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12 * scaleFactor),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      color: Colors.black,
                                      size: 20 * scaleFactor,
                                    ),
                                    SizedBox(width: 8 * scaleFactor),
                                    Text(
                                      'Any Date',
                                      style: TextStyle(
                                        fontSize: 14 * scaleFactor,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 12 * scaleFactor),
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16 * scaleFactor,
                                  vertical: 14 * scaleFactor,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12 * scaleFactor),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      color: Colors.black,
                                      size: 20 * scaleFactor,
                                    ),
                                    SizedBox(width: 8 * scaleFactor),
                                    Text(
                                      'Any Time',
                                      style: TextStyle(
                                        fontSize: 14 * scaleFactor,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
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
                  ),
                  
                  SizedBox(height: 16 * scaleFactor),
                  
                  // Find Travelers Button
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16 * scaleFactor),
                    decoration: BoxDecoration(
                      color: Color(0xFF00B4D8),
                      borderRadius: BorderRadius.circular(12 * scaleFactor),
                    ),
                    child: Center(
                      child: Text(
                        'Find Travelers',
                        style: TextStyle(
                          fontSize: 18 * scaleFactor,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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
              MaterialPageRoute(builder: (context) => const RequesterActivityPage()),
            ).then((_) {
              setState(() => _selectedIndex = 0);
              _fetchUserProfile();
            });
          } else if (index == 2) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RequesterMessagesPage()),
            ).then((_) {
              setState(() => _selectedIndex = 0);
              _fetchUserProfile();
            });
          } else if (index == 3) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RequesterProfilePage()),
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
