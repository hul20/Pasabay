import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/haptic_service.dart';
import '../utils/helpers.dart';
import '../utils/supabase_service.dart';
import 'traveler/identity_verification_screen.dart';
import 'requester/requester_main_page.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  final _supabaseService = SupabaseService();
  String _selectedRole = 'Traveler'; // Default selection
  bool _isLoading = false;

  Future<void> _handleContinue() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _supabaseService.currentUser;

      if (currentUser == null) {
        throw 'No user logged in';
      }

      // Save role to Supabase
      await _supabaseService.saveUserRole(role: _selectedRole);

      if (!mounted) return;

      // Navigate to appropriate page
      // Travelers go to identity verification first, requesters to their home page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => _selectedRole == 'Traveler'
              ? const IdentityVerificationScreen()
              : const RequesterMainPage(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and logo
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 28 * scaleFactor,
                vertical: 16 * scaleFactor,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: AppConstants.primaryColor,
                      size: 20 * scaleFactor,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 8 * scaleFactor),
                  // Logo
                  Container(
                    width: 46 * scaleFactor,
                    height: 46 * scaleFactor,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8 * scaleFactor),
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
                      fontSize: 16 * scaleFactor,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 28 * scaleFactor),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    Align(
                      alignment: Alignment.centerLeft,
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 48 * scaleFactor,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.primaryColor,
                            height: 1.1,
                          ),
                          children: const [
                            TextSpan(text: 'What\n'),
                            TextSpan(text: 'Are You?'),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 32 * scaleFactor),

                    // Role Selection Cards
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Column(
                          children: [
                            // Traveler Card
                            GestureDetector(
                              onTap: () {
                                HapticService.selectionClick();
                                setState(() {
                                  _selectedRole = 'Traveler';
                                });
                              },
                              child: Container(
                                width: double.infinity,
                                height: 128 * scaleFactor,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24 * scaleFactor,
                                  vertical: 7 * scaleFactor,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    12 * scaleFactor,
                                  ),
                                  border: Border.all(
                                    color: _selectedRole == 'Traveler'
                                        ? AppConstants.primaryColor
                                        : const Color(0xFFE1E1E1),
                                    width: _selectedRole == 'Traveler' ? 3 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'Traveler',
                                      style: TextStyle(
                                        fontSize: 24 * scaleFactor,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedRole == 'Traveler'
                                            ? AppConstants.primaryColor
                                            : Colors.black,
                                      ),
                                    ),
                                    if (_selectedRole == 'Traveler') ...[
                                      SizedBox(width: 8 * scaleFactor),
                                      Icon(
                                        Icons.check_circle,
                                        color: AppConstants.primaryColor,
                                        size: 21 * scaleFactor,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 14 * scaleFactor),

                            // Requester Card
                            GestureDetector(
                              onTap: () {
                                HapticService.selectionClick();
                                setState(() {
                                  _selectedRole = 'Requester';
                                });
                              },
                              child: Container(
                                width: double.infinity,
                                height: 128 * scaleFactor,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24 * scaleFactor,
                                  vertical: 7 * scaleFactor,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    12 * scaleFactor,
                                  ),
                                  border: Border.all(
                                    color: _selectedRole == 'Requester'
                                        ? AppConstants.primaryColor
                                        : const Color(0xFFE1E1E1),
                                    width: _selectedRole == 'Requester' ? 3 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'Requester',
                                      style: TextStyle(
                                        fontSize: 24 * scaleFactor,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedRole == 'Requester'
                                            ? AppConstants.primaryColor
                                            : Colors.black,
                                      ),
                                    ),
                                    if (_selectedRole == 'Requester') ...[
                                      SizedBox(width: 8 * scaleFactor),
                                      Icon(
                                        Icons.check_circle,
                                        color: AppConstants.primaryColor,
                                        size: 21 * scaleFactor,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Truck Icon (positioned absolutely)
                        Positioned(
                          right: 8 * scaleFactor,
                          top: -10 * scaleFactor,
                          child: SizedBox(
                            width: 146 * scaleFactor,
                            height: 146 * scaleFactor,
                            child: Image.asset(
                              'assets/TravelerIcon.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        // Bag Icon (positioned absolutely)
                        Positioned(
                          right: 18 * scaleFactor,
                          bottom: -10 * scaleFactor,
                          child: SizedBox(
                            width: 117 * scaleFactor,
                            height: 117 * scaleFactor,
                            child: Image.asset(
                              'assets/RequesterIcon.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 48 * scaleFactor),

                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: 57 * scaleFactor,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              17 * scaleFactor,
                            ),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20 * scaleFactor,
                                width: 20 * scaleFactor,
                                child: const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 19 * scaleFactor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
