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
            // Get available width
            final screenWidth = constraints.maxWidth;

            // Calculate responsive sizes
            final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

            return Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 26.0 * scaleFactor,
                    vertical: 20.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo - responsive size
                      Container(
                        width: 326 * scaleFactor,
                        height: 326 * scaleFactor,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(AppConstants.logoUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(height: 12 * scaleFactor),

                      // Title "Pasabay" - responsive font size
                      Text(
                        'Pasabay',
                        style: TextStyle(
                          fontSize: 64 * scaleFactor,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryColor,
                          letterSpacing: 1,
                          height: 1.0,
                        ),
                      ),
                      SizedBox(height: 10 * scaleFactor),

                      // Tagline - responsive
                      SizedBox(
                        width: 239 * scaleFactor,
                        child: Text(
                          '"Hatid ng kapwa biyahero"',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16 * scaleFactor,
                            color: AppConstants.textPrimaryColor,
                            height: 2.4,
                          ),
                        ),
                      ),
                      SizedBox(height: 50 * scaleFactor),

                      // Get Started Button - responsive
                      SizedBox(
                        width: (359 * scaleFactor).clamp(200, 359),
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

                      // Already have an account? Login - responsive
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
              ),
            );
          },
        ),
      ),
    );
  }
}
