import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'signup_page.dart';
import 'login_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: 26.0 * scaleFactor,
                  vertical: 20.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ✅ Responsive logo (no fixed width/height)
                    Image.asset(
                      AppConstants.logoPath,
                      width: screenWidth * 0.6, // 60% of screen width
                      height: screenWidth * 0.6,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: 12 * scaleFactor),

                    // ✅ Title
                    Text(
                      'Pasabay',
                      style: TextStyle(
                        fontSize: (64 * scaleFactor).clamp(32, 64),
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                        letterSpacing: 1,
                        height: 1.0,
                      ),
                    ),
                    SizedBox(height: 10 * scaleFactor),

                    // ✅ Tagline
                    Text(
                      '"Hatid ng kapwa biyahero"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: (16 * scaleFactor).clamp(12, 16),
                        color: AppConstants.textPrimaryColor,
                        height: 2.4,
                      ),
                    ),
                    SizedBox(height: 50 * scaleFactor),

                    // ✅ Responsive button
                    SizedBox(
                      width: screenWidth * 0.85, // 85% of available width
                      height: (57 * scaleFactor).clamp(44, 57),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignUpPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.defaultBorderRadius * scaleFactor,
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: (20 * scaleFactor).clamp(16, 20),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 7 * scaleFactor),

                    // ✅ Already have an account? Login
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                            fontSize: (14.3 * scaleFactor).clamp(12, 14.3),
                            color: Colors.black,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                          child: Text(
                            'Login',
                            style: TextStyle(
                              fontSize: (16.7 * scaleFactor).clamp(14, 16.7),
                              fontWeight: FontWeight.bold,
                              color: AppConstants.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 28 * scaleFactor),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
