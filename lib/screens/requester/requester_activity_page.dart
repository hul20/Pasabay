import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import 'requester_home_page.dart';
import 'requester_messages_page.dart';
import 'requester_profile_page.dart';
import 'traveler_detail_page.dart';

class RequesterActivityPage extends StatefulWidget {
  const RequesterActivityPage({super.key});

  @override
  State<RequesterActivityPage> createState() => _RequesterActivityPageState();
}

class _RequesterActivityPageState extends State<RequesterActivityPage> {
  String _selectedTab = 'Available'; // Available or My Requests

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
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
              context,
              MaterialPageRoute(builder: (context) => const RequesterMessagesPage()),
            );
          } else if (index == 3) {
            await Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const RequesterProfilePage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Activity'),
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
