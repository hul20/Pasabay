import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/gradient_header.dart';
import 'signup_page.dart';
import 'verify_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (_formKey.currentState!.validate()) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code sent!'),
          backgroundColor: AppConstants.primaryColor,
        ),
      );

      // Navigate to VerifyPage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerifyPage(email: _emailController.text),
        ),
      );
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
                              onPressed: _handleContinue,
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
                              child: Text(
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
