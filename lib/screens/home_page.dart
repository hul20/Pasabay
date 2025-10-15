import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20 * scaleFactor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with profile
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, User!',
                          style: TextStyle(
                            fontSize: 24 * scaleFactor,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 4 * scaleFactor),
                        Text(
                          'Welcome back',
                          style: TextStyle(
                            fontSize: 14 * scaleFactor,
                            color: const Color(0xFF667085),
                          ),
                        ),
                      ],
                    ),
                    // Profile Avatar
                    Container(
                      width: 48 * scaleFactor,
                      height: 48 * scaleFactor,
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 28 * scaleFactor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24 * scaleFactor),

                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12 * scaleFactor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search for rides or deliveries...',
                      hintStyle: TextStyle(
                        color: const Color(0xFF667085),
                        fontSize: 14 * scaleFactor,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: const Color(0xFF667085),
                        size: 20 * scaleFactor,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16 * scaleFactor,
                        vertical: 14 * scaleFactor,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 28 * scaleFactor),

                // Quick Actions Section
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18 * scaleFactor,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 16 * scaleFactor),

                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        context,
                        icon: Icons.local_shipping_outlined,
                        title: 'Request\nDelivery',
                        color: AppConstants.primaryColor,
                        scaleFactor: scaleFactor,
                      ),
                    ),
                    SizedBox(width: 12 * scaleFactor),
                    Expanded(
                      child: _buildQuickActionCard(
                        context,
                        icon: Icons.directions_car_outlined,
                        title: 'Find\nRide',
                        color: const Color(0xFF0083B0),
                        scaleFactor: scaleFactor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 28 * scaleFactor),

                // Recent Activity Section
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18 * scaleFactor,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 16 * scaleFactor),

                // Activity List
                _buildActivityCard(
                  context,
                  icon: Icons.shopping_bag_outlined,
                  title: 'Pasabuy from Manila',
                  subtitle: 'Delivered • 2 days ago',
                  scaleFactor: scaleFactor,
                ),
                SizedBox(height: 12 * scaleFactor),
                _buildActivityCard(
                  context,
                  icon: Icons.local_shipping_outlined,
                  title: 'Padala to Quezon City',
                  subtitle: 'In Progress • Today',
                  scaleFactor: scaleFactor,
                ),
                SizedBox(height: 12 * scaleFactor),
                _buildActivityCard(
                  context,
                  icon: Icons.directions_car_outlined,
                  title: 'Ride to BGC',
                  subtitle: 'Completed • 1 week ago',
                  scaleFactor: scaleFactor,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppConstants.primaryColor,
          unselectedItemColor: const Color(0xFF667085),
          selectedFontSize: 12 * scaleFactor,
          unselectedFontSize: 12 * scaleFactor,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              activeIcon: Icon(Icons.add_circle),
              label: 'Post',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required double scaleFactor,
  }) {
    return Container(
      padding: EdgeInsets.all(20 * scaleFactor),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16 * scaleFactor),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10 * scaleFactor),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12 * scaleFactor),
            ),
            child: Icon(icon, color: Colors.white, size: 28 * scaleFactor),
          ),
          SizedBox(height: 12 * scaleFactor),
          Text(
            title,
            style: TextStyle(
              fontSize: 16 * scaleFactor,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required double scaleFactor,
  }) {
    return Container(
      padding: EdgeInsets.all(16 * scaleFactor),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12 * scaleFactor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10 * scaleFactor),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10 * scaleFactor),
            ),
            child: Icon(
              icon,
              color: AppConstants.primaryColor,
              size: 24 * scaleFactor,
            ),
          ),
          SizedBox(width: 12 * scaleFactor),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14 * scaleFactor,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4 * scaleFactor),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12 * scaleFactor,
                    color: const Color(0xFF667085),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16 * scaleFactor,
            color: const Color(0xFF667085),
          ),
        ],
      ),
    );
  }
}
