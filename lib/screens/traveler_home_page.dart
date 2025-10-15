import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class TravelerHomePage extends StatelessWidget {
  const TravelerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32 * scaleFactor,
              height: 32 * scaleFactor,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6 * scaleFactor),
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
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 24 * scaleFactor,
            ),
            onPressed: () {},
          ),
          Padding(
            padding: EdgeInsets.only(right: 16 * scaleFactor),
            child: CircleAvatar(
              radius: 18 * scaleFactor,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                color: AppConstants.primaryColor,
                size: 20 * scaleFactor,
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 120 * scaleFactor,
              color: AppConstants.primaryColor.withOpacity(0.3),
            ),
            SizedBox(height: 24 * scaleFactor),
            Text(
              'Traveler Home',
              style: TextStyle(
                fontSize: 32 * scaleFactor,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryColor,
              ),
            ),
            SizedBox(height: 16 * scaleFactor),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 48 * scaleFactor),
              child: Text(
                'Welcome to your Traveler dashboard!\nContent coming soon...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16 * scaleFactor,
                  color: Colors.grey[600],
                  height: 1.5,
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
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Post Trip',
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
