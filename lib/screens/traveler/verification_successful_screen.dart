import 'package:flutter/material.dart';
import 'package:pasabay_app/utils/helpers.dart';
import 'package:pasabay_app/utils/constants.dart';
import 'traveler_main_page.dart';

class VerificationSuccessfulScreen extends StatelessWidget {
  const VerificationSuccessfulScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

        return Scaffold(
          backgroundColor: const Color(0xFFF9F9F9),
          body: Column(
            children: [
              // Simple header with logo
              _buildHeader(scaleFactor),

              // Main content - centered
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: _buildContent(context, scaleFactor),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(double scaleFactor) {
    return Container(
      height: 77.883 * scaleFactor,
      padding: EdgeInsets.symmetric(horizontal: 28.61 * scaleFactor),
      child: Row(
        children: [
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
              fontSize: 16.235 * scaleFactor,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF00AAF3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, double scaleFactor) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28 * scaleFactor),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success icon - shield with checkmark
          Icon(
            Icons.verified_user,
            size: 170 * scaleFactor,
            color: const Color(0xFF00AAF3),
          ),

          SizedBox(height: 40 * scaleFactor),

          // Success message heading
          Text(
            'Successfully',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 48 * scaleFactor,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF00AAF3),
              height: 1.08,
            ),
          ),
          Text(
            'Submitted!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 48 * scaleFactor,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF00AAF3),
              height: 1.08,
            ),
          ),

          SizedBox(height: 8 * scaleFactor),

          // Timeline message
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 28 * scaleFactor),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 15 * scaleFactor,
                  color: Colors.black,
                  height: 1.33,
                ),
                children: const [
                  TextSpan(
                    text: 'You Will Be Notified within ',
                    style: TextStyle(fontWeight: FontWeight.normal),
                  ),
                  TextSpan(
                    text: '24 Hours',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 64 * scaleFactor),

          // Continue button
          SizedBox(
            width: double.infinity,
            height: 57.22 * scaleFactor,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TravelerMainPage(),
                  ),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00AAF3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.689 * scaleFactor),
                ),
                elevation: 0,
              ),
              child: Text(
                'Continue To Dashboard',
                style: TextStyle(
                  fontSize: 19.073 * scaleFactor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
