import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/supabase_service.dart';
import '../services/fcm_service.dart';
import 'landing_page.dart';
import 'traveler_home_page.dart';
import 'requester/requester_home_page.dart';
import 'traveler/identity_verification_screen.dart';

/// Wrapper to handle authentication state and persistent login
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _supabaseService = SupabaseService();
  bool _isLoading = true;
  Widget? _initialScreen;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      // Check if user is already logged in
      final user = _supabaseService.currentUser;

      if (user == null) {
        // No user logged in, show landing page
        setState(() {
          _initialScreen = const LandingPage();
          _isLoading = false;
        });
        return;
      }

      // User is logged in, get their data
      final userData = await _supabaseService.getUserData();

      if (userData == null) {
        // User data not found, show landing page
        setState(() {
          _initialScreen = const LandingPage();
          _isLoading = false;
        });
        return;
      }

      final userRole = userData['role'];
      final isEmailVerified = userData['email_verified'] ?? false;

      // If email not verified, logout and show landing page
      if (!isEmailVerified) {
        await _supabaseService.signOut();
        setState(() {
          _initialScreen = const LandingPage();
          _isLoading = false;
        });
        return;
      }

      // Route based on role
      if (userRole == 'Traveler') {
        // Check if traveler is identity verified
        final isVerified = await _supabaseService.isUserVerified();

        if (!isVerified) {
          // Check verification status to prevent re-submission
          final verificationStatus = await _supabaseService
              .getVerificationStatus();
          final status = verificationStatus?['status'];

          if (status == 'Pending' || status == 'Under Review') {
            // Already submitted, go to home (will show in-progress message)
            await FCMService.initialize();
            setState(() {
              _initialScreen = const TravelerHomePage();
              _isLoading = false;
            });
          } else {
            // Not submitted yet, show identity verification
            setState(() {
              _initialScreen = const IdentityVerificationScreen();
              _isLoading = false;
            });
          }
        } else {
          // Verified traveler, go to home
          await FCMService.initialize();
          setState(() {
            _initialScreen = const TravelerHomePage();
            _isLoading = false;
          });
        }
      } else if (userRole == 'Requester') {
        // Requester doesn't need verification
        await FCMService.initialize();
        setState(() {
          _initialScreen = const RequesterHomePage();
          _isLoading = false;
        });
      } else {
        // No role set, show landing page
        setState(() {
          _initialScreen = const LandingPage();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking auth state: $e');
      // On error, show landing page
      setState(() {
        _initialScreen = const LandingPage();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return _initialScreen ?? const LandingPage();
  }
}
