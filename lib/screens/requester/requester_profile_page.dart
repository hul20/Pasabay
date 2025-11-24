import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/supabase_service.dart';
import 'requester_home_page.dart';
import 'requester_activity_page.dart';
import 'requester_messages_page.dart';
import '../traveler_home_page.dart';
import '../landing_page.dart';
import '../settings_page.dart';
import '../edit_profile_page.dart';

class RequesterProfilePage extends StatefulWidget {
  const RequesterProfilePage({super.key});

  @override
  State<RequesterProfilePage> createState() => _RequesterProfilePageState();
}

class _RequesterProfilePageState extends State<RequesterProfilePage>
    with WidgetsBindingObserver {
  String userName = " ";
  String userEmail = " ";
  String userRole = " ";
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchUserProfile();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchUserProfile();
    }
  }

  Future<void> _fetchUserProfile() async {
    final supabaseService = SupabaseService();
    final userData = await supabaseService.getUserData();

    if (userData != null && mounted) {
      setState(() {
        userName =
            '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'
                .trim();
        if (userName.isEmpty) userName = "Requester";
        userEmail = userData['email'] ?? userEmail;
        userRole = userData['role'] ?? userRole;
        profileImageUrl = userData['profile_image_url'];
      });
    }
  }

  Future<void> _handleLogout() async {
    final supabaseService = SupabaseService();

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Log Out'),
        content: Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Log Out'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      await supabaseService.signOut();

      // Hide loading indicator and navigate to landing page
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LandingPage()),
          (route) => false,
        );
      }
    } catch (e) {
      // Hide loading indicator
      if (mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _switchRole() async {
    final supabaseService = SupabaseService();
    final newRole = userRole == 'Traveler' ? 'Requester' : 'Traveler';
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

    // Show confirmation modal bottom sheet
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24 * scaleFactor),
              topRight: Radius.circular(24 * scaleFactor),
            ),
          ),
          padding: EdgeInsets.all(32 * scaleFactor),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.close, size: 28 * scaleFactor),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              SizedBox(height: 16 * scaleFactor),

              // Sync Icon
              Icon(
                Icons.sync,
                size: 80 * scaleFactor,
                color: Color(0xFF00B4D8),
              ),
              SizedBox(height: 24 * scaleFactor),

              // Title
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 24 * scaleFactor,
                    color: Colors.black,
                    fontFamily: AppConstants.fontFamily,
                  ),
                  children: [
                    TextSpan(text: 'Switch To '),
                    TextSpan(
                      text: '$newRole Mode',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: '?'),
                  ],
                ),
              ),
              SizedBox(height: 32 * scaleFactor),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF00B4D8),
                    padding: EdgeInsets.symmetric(vertical: 16 * scaleFactor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12 * scaleFactor),
                    ),
                  ),
                  child: Text(
                    'Confirm',
                    style: TextStyle(
                      fontSize: 18 * scaleFactor,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16 * scaleFactor),
            ],
          ),
        );
      },
    );

    if (confirm != true) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await supabaseService.switchUserRole(newRole);

      // Hide loading indicator
      if (mounted) Navigator.pop(context);

      if (success) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully switched to $newRole role'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to the appropriate home page after a brief delay
          Future.delayed(Duration(milliseconds: 500), () {
            if (mounted) {
              if (newRole == 'Traveler') {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TravelerHomePage(),
                  ),
                  (route) => false,
                );
              } else {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RequesterHomePage(),
                  ),
                  (route) => false,
                );
              }
            }
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to switch role. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Hide loading indicator
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfilePage()),
    );

    // Refresh profile if changes were saved
    if (result == true) {
      _fetchUserProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Cyan Header with Profile
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Color(0xFF00B4D8),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24 * scaleFactor),
                    bottomRight: Radius.circular(24 * scaleFactor),
                  ),
                ),
                padding: EdgeInsets.all(20 * scaleFactor),
                child: Column(
                  children: [
                    // Top bar with logo and icon
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
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              10 * scaleFactor,
                            ),
                          ),
                          padding: EdgeInsets.all(8 * scaleFactor),
                          child: Icon(
                            Icons.shopping_bag,
                            color: Color(0xFF00B4D8),
                            size: 28 * scaleFactor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24 * scaleFactor),

                    // Profile Picture, Name, and Email in Same Row
                    Row(
                      children: [
                        // Profile Picture
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: ClipOval(
                            child:
                                profileImageUrl != null &&
                                    profileImageUrl!.isNotEmpty
                                ? Image.network(
                                    profileImageUrl!,
                                    width: 80 * scaleFactor,
                                    height: 80 * scaleFactor,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 80 * scaleFactor,
                                        height: 80 * scaleFactor,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.person,
                                          size: 40 * scaleFactor,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    width: 80 * scaleFactor,
                                    height: 80 * scaleFactor,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      size: 40 * scaleFactor,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(width: 16 * scaleFactor),

                        // Name and Email
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                userName,
                                style: TextStyle(
                                  fontSize: 22 * scaleFactor,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4 * scaleFactor),
                              Text(
                                userEmail,
                                style: TextStyle(
                                  fontSize: 14 * scaleFactor,
                                  color: Colors.white.withOpacity(0.95),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12 * scaleFactor),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20 * scaleFactor),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 24 * scaleFactor),

                    // Account Section
                    Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 18 * scaleFactor,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 12 * scaleFactor),

                    // Edit Profile
                    _buildMenuItem(
                      icon: Icons.person_outline,
                      title: 'Edit Profile',
                      subtitle: 'Update personal information',
                      onTap: _navigateToEditProfile,
                      scaleFactor: scaleFactor,
                    ),
                    SizedBox(height: 12 * scaleFactor),

                    // Preferences
                    _buildMenuItem(
                      icon: Icons.settings_outlined,
                      title: 'Preferences',
                      subtitle: 'Notifications and app settings',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsPage(),
                          ),
                        );
                      },
                      scaleFactor: scaleFactor,
                    ),
                    SizedBox(height: 24 * scaleFactor),

                    // Role Section
                    Text(
                      'Role',
                      style: TextStyle(
                        fontSize: 18 * scaleFactor,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 12 * scaleFactor),

                    // Switch Role Card (Highlighted)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12 * scaleFactor),
                        border: Border.all(color: Color(0xFF00B4D8), width: 2),
                      ),
                      child: _buildMenuItem(
                        icon: Icons.sync,
                        title: 'Switch To Traveler',
                        subtitle: 'Change your role',
                        onTap: _switchRole,
                        scaleFactor: scaleFactor,
                        iconColor: Color(0xFF00B4D8),
                        isHighlighted: true,
                      ),
                    ),
                    SizedBox(height: 24 * scaleFactor),

                    // Support Section
                    Text(
                      'Support',
                      style: TextStyle(
                        fontSize: 18 * scaleFactor,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 12 * scaleFactor),

                    // Help and Support
                    _buildMenuItem(
                      icon: Icons.help_outline,
                      title: 'Help and Support',
                      subtitle: 'Get help and contact support',
                      onTap: () {},
                      scaleFactor: scaleFactor,
                    ),
                    SizedBox(height: 12 * scaleFactor),

                    // Invite Friends
                    _buildMenuItem(
                      icon: Icons.share_outlined,
                      title: 'Invite Friends',
                      subtitle: 'Share Pasabay with others',
                      onTap: () {},
                      scaleFactor: scaleFactor,
                    ),
                    SizedBox(height: 24 * scaleFactor),

                    // App Section
                    Text(
                      'App',
                      style: TextStyle(
                        fontSize: 18 * scaleFactor,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 12 * scaleFactor),

                    // App Version
                    Container(
                      padding: EdgeInsets.all(16 * scaleFactor),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12 * scaleFactor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48 * scaleFactor,
                            height: 48 * scaleFactor,
                            decoration: BoxDecoration(
                              color: Color(0xFF00B4D8).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                12 * scaleFactor,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                12 * scaleFactor,
                              ),
                              child: Image.asset(
                                AppConstants.logoPath,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(width: 14 * scaleFactor),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pasabay',
                                style: TextStyle(
                                  fontSize: 16 * scaleFactor,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 4 * scaleFactor),
                              Text(
                                'Version 1.0.0',
                                style: TextStyle(
                                  fontSize: 13 * scaleFactor,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24 * scaleFactor),

                    // Logout Button
                    _buildMenuItem(
                      icon: Icons.logout,
                      title: 'Log Out',
                      subtitle: 'Sign out of your account',
                      onTap: _handleLogout,
                      scaleFactor: scaleFactor,
                      iconColor: Colors.red,
                    ),

                    SizedBox(height: 80 * scaleFactor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: Colors.grey,
        currentIndex: 3, // Profile tab selected
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const RequesterActivityPage(),
              ),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const RequesterMessagesPage(),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
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

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required double scaleFactor,
    Color? iconColor,
    bool isHighlighted = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12 * scaleFactor),
      child: Container(
        padding: EdgeInsets.all(16 * scaleFactor),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12 * scaleFactor),
          boxShadow: isHighlighted
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 48 * scaleFactor,
              height: 48 * scaleFactor,
              decoration: BoxDecoration(
                color: (iconColor ?? Colors.black).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12 * scaleFactor),
              ),
              child: Icon(
                icon,
                color: iconColor ?? Colors.black,
                size: 24 * scaleFactor,
              ),
            ),
            SizedBox(width: 14 * scaleFactor),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16 * scaleFactor,
                      fontWeight: FontWeight.w600,
                      color: isHighlighted ? Color(0xFF00B4D8) : Colors.black,
                    ),
                  ),
                  SizedBox(height: 4 * scaleFactor),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13 * scaleFactor,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isHighlighted ? Color(0xFF00B4D8) : Colors.grey[400],
              size: 18 * scaleFactor,
            ),
          ],
        ),
      ),
    );
  }
}
