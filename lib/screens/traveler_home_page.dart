import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class TravelerHomePage extends StatefulWidget {
  const TravelerHomePage({super.key});

  @override
  State<TravelerHomePage> createState() => _TravelerHomePageState();
}

class _TravelerHomePageState extends State<TravelerHomePage> {
  int _selectedIndex = 0;
  final String userName = "Juan"; // Replace with actual user name from state
  final int activeTrips = 35; // Replace with actual data
  final int totalEarnings = 5423; // Replace with actual data

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18 * scaleFactor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                            hintText: 'Search for location, route, etc.',
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
                // Greeting
                Text(
                  'Hello, $userName!',
                  style: TextStyle(
                    fontSize: 28 * scaleFactor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6 * scaleFactor),
                Text(
                  "Here's an overview for this month of October",
                  style: TextStyle(
                    fontSize: 15 * scaleFactor,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 18 * scaleFactor),
                // Cards: Active Trips & Total Earnings
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
                              color: Colors.black.withOpacity(0.07),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Active Trips',
                              style: TextStyle(
                                fontSize: 15 * scaleFactor,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8 * scaleFactor),
                            Text(
                              '$activeTrips',
                              style: TextStyle(
                                fontSize: 28 * scaleFactor,
                                fontWeight: FontWeight.bold,
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
                              color: Colors.black.withOpacity(0.07),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Earnings',
                              style: TextStyle(
                                fontSize: 15 * scaleFactor,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8 * scaleFactor),
                            Text(
                              '₱$totalEarnings',
                              style: TextStyle(
                                fontSize: 28 * scaleFactor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24 * scaleFactor),
                // Plan Your Route
                Text(
                  'Plan Your Route',
                  style: TextStyle(
                    fontSize: 20 * scaleFactor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12 * scaleFactor),
                Container(
                  padding: EdgeInsets.all(16 * scaleFactor),
                  decoration: BoxDecoration(
                    color: Color(0xFFDBF6FF),
                    borderRadius: BorderRadius.circular(16 * scaleFactor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Destination',
                        style: TextStyle(
                          fontSize: 22 * scaleFactor,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00B4D8),
                        ),
                      ),
                      SizedBox(height: 4 * scaleFactor),
                      Text(
                        'Tap to pin departure and target location',
                        style: TextStyle(
                          fontSize: 14 * scaleFactor,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 12 * scaleFactor),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Add Location',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    8 * scaleFactor,
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8 * scaleFactor),
                          Container(
                            decoration: BoxDecoration(
                              color: Color(0xFF00B4D8),
                              borderRadius: BorderRadius.circular(
                                8 * scaleFactor,
                              ),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.add, color: Colors.white),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18 * scaleFactor),
                // Schedule
                Container(
                  padding: EdgeInsets.all(16 * scaleFactor),
                  decoration: BoxDecoration(
                    color: Color(0xFFDBF6FF),
                    borderRadius: BorderRadius.circular(16 * scaleFactor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Schedule',
                        style: TextStyle(
                          fontSize: 22 * scaleFactor,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00B4D8),
                        ),
                      ),
                      SizedBox(height: 4 * scaleFactor),
                      Text(
                        'Tap to add travel date and time',
                        style: TextStyle(
                          fontSize: 14 * scaleFactor,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 12 * scaleFactor),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    8 * scaleFactor,
                                  ),
                                ),
                              ),
                              icon: Icon(Icons.calendar_today_outlined),
                              label: Text('Select Date'),
                              onPressed: () {},
                            ),
                          ),
                          SizedBox(width: 8 * scaleFactor),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    8 * scaleFactor,
                                  ),
                                ),
                              ),
                              icon: Icon(Icons.access_time_outlined),
                              label: Text('Select Time'),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18 * scaleFactor),
                // Map
                Container(
                  height: 160 * scaleFactor,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16 * scaleFactor),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          'Map Placeholder',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16 * scaleFactor,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12 * scaleFactor,
                        left: 12 * scaleFactor,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12 * scaleFactor,
                            vertical: 6 * scaleFactor,
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
                                Icons.circle,
                                color: Colors.green,
                                size: 12 * scaleFactor,
                              ),
                              SizedBox(width: 6 * scaleFactor),
                              Text(
                                'Live Tracking',
                                style: TextStyle(
                                  fontSize: 13 * scaleFactor,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18 * scaleFactor),
                // Register Travel Button
                SizedBox(
                  width: double.infinity,
                  height: 54 * scaleFactor,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16 * scaleFactor),
                      ),
                    ),
                    onPressed: () {},
                    child: Text(
                      'Register Travel',
                      style: TextStyle(
                        fontSize: 18 * scaleFactor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24 * scaleFactor),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
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
