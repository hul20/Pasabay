import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/supabase_service.dart';
import '../widgets/gradient_header.dart';
import 'signup_page.dart';
import 'verify_page.dart';
import 'role_selection_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabaseService = SupabaseService();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Sign in with Supabase
        await _supabaseService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (!mounted) return;

        // Get user data to check verification and role
        final userData = await _supabaseService.getUserData();

        if (userData == null) {
          throw 'Failed to fetch user data';
        }

        final isEmailVerified = userData['email_verified'] ?? false;

        if (!isEmailVerified) {
          // Send OTP via Supabase
          await _supabaseService.sendOTP(_emailController.text.trim());

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification code sent to your email.'),
              backgroundColor: AppConstants.primaryColor,
              duration: Duration(seconds: 3),
            ),
          );

          // Navigate to verification page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyPage(email: _emailController.text),
            ),
          );
          return;
        }

        final userRole = userData['role'];

        if (userRole == null) {
          // Navigate to role selection
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const RoleSelectionPage()),
          );
        } else {
          // Navigate to appropriate home page based on role
          if (userRole == 'Traveler') {
            Navigator.pushReplacementNamed(context, '/traveler-home');
          } else {
            Navigator.pushReplacementNamed(context, '/requester-home');
          }
        }
      } catch (e) {
        if (!mounted) return;

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

          return Form(
            key: _formKey,
            child: Column(
              children: [
                // Header with gradient background
                GradientHeader(
                  title: 'Login',
                  subtitle: 'Enter your credentials to access\nyour acconut',
                  scaleFactor: scaleFactor,
                  onBackPressed: () => Navigator.pop(context),
                ),

                // Form content
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(
                        AppConstants.defaultPadding * scaleFactor,
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: 20 * scaleFactor),

                          // Email field
                          _buildInputField(
                            label: 'Email',
                            placeholder: 'Enter Email',
                            controller: _emailController,
                            validator: Validators.validateEmail,
                            scaleFactor: scaleFactor,
                          ),

                          SizedBox(height: 22 * scaleFactor),

                          // Password field
                          _buildInputField(
                            label: 'Password',
                            placeholder: 'Enter Password',
                            controller: _passwordController,
                            validator: (value) =>
                                Validators.validateRequired(value, 'Password'),
                            obscureText: _obscurePassword,
                            scaleFactor: scaleFactor,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20 * scaleFactor,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),

                          SizedBox(height: 35 * scaleFactor),

                          // Continue button
                          SizedBox(
                            width: double.infinity,
                            height: 57 * scaleFactor,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleContinue,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.defaultBorderRadius *
                                        scaleFactor,
                                  ),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: 20 * scaleFactor,
                                      width: 20 * scaleFactor,
                                      child: const CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
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

                          SizedBox(height: 10 * scaleFactor),

                          // Don't have an account? Sign Up
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Don\'t have an account yet? ',
                                style: TextStyle(
                                  fontSize: 14.3 * scaleFactor,
                                  color: Colors.black,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SignUpPage(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    fontSize: 16.7 * scaleFactor,
                                    fontWeight: FontWeight.bold,
                                    color: AppConstants.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String placeholder,
    required TextEditingController controller,
    String? Function(String?)? validator,
    bool obscureText = false,
    required double scaleFactor,
    Widget? suffixIcon,
  }) {
    return Container(
      width: double.infinity,
      height: 70 * scaleFactor,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          AppConstants.inputBorderRadius * scaleFactor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.3 * scaleFactor),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14 * scaleFactor,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4 * scaleFactor),
                      TextFormField(
                        controller: controller,
                        validator: validator,
                        obscureText: obscureText,
                        style: TextStyle(
                          fontSize: 16 * scaleFactor,
                          fontWeight: FontWeight.w300,
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: placeholder,
                          hintStyle: TextStyle(
                            fontSize: 16 * scaleFactor,
                            fontWeight: FontWeight.w300,
                            color: AppConstants.textSecondaryColor.withOpacity(
                              0.5,
                            ),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          errorStyle: const TextStyle(height: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (suffixIcon != null) suffixIcon,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
