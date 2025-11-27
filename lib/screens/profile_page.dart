import 'package:flutter/material.dart';
import '../services/fcm_service.dart';
import '../services/traveler_stats_service.dart';
import '../models/traveler_statistics.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/supabase_service.dart';
import 'activity_page.dart';
import 'messages_page.dart';
import 'requester/requester_home_page.dart';
import 'landing_page.dart';
import 'edit_profile_page.dart';
import 'settings_page.dart';
import 'wallet_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with WidgetsBindingObserver {
  // Default data
  String userName = "Juan Carlos Santos";
  String userEmail = "juan.santos@email.com";
  String userRole = "Traveler";
  String? profileImageUrl;
  bool _isVerified = false;

  // Statistics data
  TravelerStatistics? _statistics;
  List<TravelerBadge> _badges = [];
  List<RouteStatistic> _topRoutes = [];
  bool _isLoadingStats = true;
  final TravelerStatsService _statsService = TravelerStatsService();

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
    final isVerified = await supabaseService.isUserVerified();

    if (userData != null && mounted) {
      setState(() {
        userName =
            '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'
                .trim();
        if (userName.isEmpty) userName = "Traveler";
        userEmail = userData['email'] ?? userEmail;
        userRole = userData['role'] ?? userRole;
        profileImageUrl = userData['profile_image_url'];
        _isVerified = isVerified;
      });

      // Fetch traveler statistics if user is a traveler
      if (userRole == 'Traveler') {
        _fetchTravelerStatistics();
      }
    }
  }

  Future<void> _fetchTravelerStatistics() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final profileData = await _statsService.getMyCompleteProfile();

      if (mounted) {
        setState(() {
          _statistics = profileData['statistics'] as TravelerStatistics?;
          _badges = profileData['badges'] as List<TravelerBadge>;
          _topRoutes = profileData['top_routes'] as List<RouteStatistic>;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      print('Error fetching traveler statistics: $e');
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  /// Get unique badges (deduplicate by badge_type)
  List<TravelerBadge> _getUniqueBadges() {
    final Map<BadgeType, TravelerBadge> uniqueBadgesMap = {};

    for (final badge in _badges) {
      // Keep only the first occurrence of each badge type (most recent)
      if (!uniqueBadgesMap.containsKey(badge.badgeType)) {
        uniqueBadgesMap[badge.badgeType] = badge;
      }
    }

    return uniqueBadgesMap.values.toList();
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
      // Delete FCM token before logging out
      await FCMService.deleteFCMToken();

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
              if (newRole == 'Requester') {
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
        // Show error message
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

      // Show error message
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
                            Icons.directions_bus,
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
                              if (_isVerified)
                                Container(
                                  margin: EdgeInsets.only(
                                    bottom: 4 * scaleFactor,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8 * scaleFactor,
                                    vertical: 2 * scaleFactor,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(
                                      4 * scaleFactor,
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.verified,
                                        color: Colors.white,
                                        size: 12 * scaleFactor,
                                      ),
                                      SizedBox(width: 4 * scaleFactor),
                                      Text(
                                        'Verified',
                                        style: TextStyle(
                                          fontSize: 11 * scaleFactor,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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

                    // Traveler Statistics Section (only for travelers)
                    if (userRole == 'Traveler') ...[
                      _buildStatisticsSection(scaleFactor),
                      SizedBox(height: 24 * scaleFactor),
                    ],

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

                    // Wallet
                    _buildMenuItem(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Wallet',
                      subtitle: 'Manage your balance and transactions',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WalletPage(),
                          ),
                        );
                      },
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
                        title: userRole == 'Traveler'
                            ? 'Switch To Requester'
                            : 'Switch To Traveler',
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
            // Navigate to Home
            Navigator.pop(context);
          } else if (index == 1) {
            // Navigate to Activity page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ActivityPage()),
            );
          } else if (index == 2) {
            // Navigate to Messages page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MessagesPage()),
            );
          }
          // Profile tab is already selected (index 3)
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

  // Build Traveler Statistics Section
  Widget _buildStatisticsSection(double scaleFactor) {
    if (_isLoadingStats) {
      return Container(
        padding: EdgeInsets.all(24 * scaleFactor),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16 * scaleFactor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Row(
          children: [
            Icon(
              Icons.bar_chart,
              color: Color(0xFF00B4D8),
              size: 24 * scaleFactor,
            ),
            SizedBox(width: 8 * scaleFactor),
            Text(
              'Traveler Profile',
              style: TextStyle(
                fontSize: 18 * scaleFactor,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        SizedBox(height: 16 * scaleFactor),

        // Statistics Cards
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16 * scaleFactor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Rating and Stats Row
              Container(
                padding: EdgeInsets.all(20 * scaleFactor),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00B4D8), Color(0xFF0096C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16 * scaleFactor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItemWithIcon(
                      icon: Icons.star,
                      label: 'Trust Score',
                      value: _statistics != null
                          ? '${_statistics!.formattedRating}/5.0'
                          : '0.0/5.0',
                      scaleFactor: scaleFactor,
                      isWhite: true,
                    ),
                    Container(
                      width: 1,
                      height: 40 * scaleFactor,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    _buildStatItemWithIcon(
                      icon: Icons.check_circle,
                      label: 'Successful Trips',
                      value: _statistics?.successfulTrips.toString() ?? '0',
                      scaleFactor: scaleFactor,
                      isWhite: true,
                    ),
                    Container(
                      width: 1,
                      height: 40 * scaleFactor,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    _buildStatItemWithIcon(
                      icon: Icons.adjust,
                      label: 'Reliability Rate',
                      value: _statistics?.formattedReliabilityRate ?? '0%',
                      scaleFactor: scaleFactor,
                      isWhite: true,
                    ),
                  ],
                ),
              ),

              // Badges Section
              if (_badges.isNotEmpty) ...[
                Divider(height: 1),
                Padding(
                  padding: EdgeInsets.all(20 * scaleFactor),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Badges',
                        style: TextStyle(
                          fontSize: 16 * scaleFactor,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 12 * scaleFactor),
                      Wrap(
                        spacing: 8 * scaleFactor,
                        runSpacing: 8 * scaleFactor,
                        children: _getUniqueBadges().map((badge) {
                          return _buildBadgeChip(badge, scaleFactor);
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],

              // Top Routes Section
              if (_topRoutes.isNotEmpty) ...[
                Divider(height: 1),
                Padding(
                  padding: EdgeInsets.all(20 * scaleFactor),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top Routes',
                        style: TextStyle(
                          fontSize: 16 * scaleFactor,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 12 * scaleFactor),
                      ..._topRoutes.take(3).map((route) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 8 * scaleFactor),
                          child: Row(
                            children: [
                              Icon(
                                Icons.route,
                                size: 18 * scaleFactor,
                                color: Color(0xFF00B4D8),
                              ),
                              SizedBox(width: 8 * scaleFactor),
                              Expanded(
                                child: Text(
                                  route.routeString,
                                  style: TextStyle(
                                    fontSize: 14 * scaleFactor,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8 * scaleFactor,
                                  vertical: 4 * scaleFactor,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFF00B4D8).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    12 * scaleFactor,
                                  ),
                                ),
                                child: Text(
                                  '${route.tripCount}x',
                                  style: TextStyle(
                                    fontSize: 12 * scaleFactor,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00B4D8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItemWithIcon({
    required IconData icon,
    required String label,
    required String value,
    required double scaleFactor,
    bool isWhite = false,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 28 * scaleFactor,
          color: isWhite ? Colors.white : Color(0xFF00B4D8),
        ),
        SizedBox(height: 8 * scaleFactor),
        Text(
          value,
          style: TextStyle(
            fontSize: 18 * scaleFactor,
            fontWeight: FontWeight.bold,
            color: isWhite ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 4 * scaleFactor),
        Text(
          label,
          style: TextStyle(
            fontSize: 11 * scaleFactor,
            color: isWhite ? Colors.white.withOpacity(0.9) : Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBadgeChip(TravelerBadge badge, double scaleFactor) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12 * scaleFactor,
        vertical: 8 * scaleFactor,
      ),
      decoration: BoxDecoration(
        color: Color(0xFF00B4D8).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20 * scaleFactor),
        border: Border.all(color: Color(0xFF00B4D8).withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(badge.icon, style: TextStyle(fontSize: 16 * scaleFactor)),
          SizedBox(width: 6 * scaleFactor),
          Text(
            badge.displayName.replaceAll(RegExp(r'[⚡🛍️🛣️📦]'), '').trim(),
            style: TextStyle(
              fontSize: 13 * scaleFactor,
              fontWeight: FontWeight.w600,
              color: Color(0xFF00B4D8),
            ),
          ),
        ],
      ),
    );
  }
}
