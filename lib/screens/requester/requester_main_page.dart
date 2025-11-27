import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';
import '../../services/notification_service.dart';
import '../notifications_page.dart';
import 'requester_home_content.dart';
import 'requester_activity_page.dart';
import 'requester_messages_page.dart';
import 'requester_profile_page.dart';

/// Main shell page for Requester that holds the bottom navigation
/// and allows swiping between pages without rebuilding them
class RequesterMainPage extends StatefulWidget {
  final int initialIndex;

  const RequesterMainPage({super.key, this.initialIndex = 0});

  @override
  State<RequesterMainPage> createState() => _RequesterMainPageState();
}

class _RequesterMainPageState extends State<RequesterMainPage>
    with WidgetsBindingObserver {
  late int _selectedIndex;
  late PageController _pageController;

  // Notification data - used by child pages via callback or for snackbar display
  final NotificationService _notificationService = NotificationService();
  RealtimeChannel? _notificationSubscription;

  // Keep track of pages to preserve state
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _selectedIndex);
    WidgetsBinding.instance.addObserver(this);
    _setupNotificationSubscription();

    // Initialize pages once
    _pages.addAll([
      const RequesterHomeContent(),
      const RequesterActivityPage(embedded: true),
      const RequesterMessagesPage(embedded: true),
      const RequesterProfilePage(embedded: true),
    ]);
  }

  void _setupNotificationSubscription() {
    try {
      _notificationSubscription = _notificationService.subscribeToNotifications(
        (notification) {
          if (mounted) {
            // Show snackbar for new notifications
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
    // Child pages handle their own state refreshing
  }

  @override
  void dispose() {
    _notificationSubscription?.unsubscribe();
    _pageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onNavItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(),
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
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
