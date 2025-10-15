import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/firebase_service.dart';
import '../widgets/gradient_header.dart';
import 'login_page.dart';
import 'verify_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleInitialController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  final _firebaseService = FirebaseService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleInitialController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Create user account with Firebase
        await _firebaseService.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          middleInitial: _middleInitialController.text.trim().isEmpty
              ? null
              : _middleInitialController.text.trim(),
        );

        // Generate and send 4-digit OTP
        await _firebaseService.generateAndSendOTP(_emailController.text.trim());

        if (!mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! 4-digit code sent to your email.'),
            backgroundColor: AppConstants.primaryColor,
            duration: Duration(seconds: 4),
          ),
        );

        // Navigate to VerifyPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyPage(email: _emailController.text),
          ),
        );
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

          return Column(
            children: [
              // Header with gradient background
              GradientHeader(
                title: 'Sign Up',
                subtitle: 'Create your account and start\nyour journey',
                scaleFactor: scaleFactor,
                onBackPressed: () => Navigator.pop(context),
              ),

              // Form content
              Expanded(
                child: Container(
                  color: AppConstants.backgroundColor,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(
                      AppConstants.largePadding * scaleFactor,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // First Name and M.I. Row
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildInputField(
                                  label: 'First Name',
                                  hint: 'Enter First Name',
                                  controller: _firstNameController,
                                  validator: (value) =>
                                      Validators.validateRequired(
                                        value,
                                        'First Name',
                                      ),
                                  scaleFactor: scaleFactor,
                                ),
                              ),
                              SizedBox(width: 15 * scaleFactor),
                              Expanded(
                                flex: 2,
                                child: _buildInputField(
                                  label: 'M.I.',
                                  hint: 'e.g. C',
                                  controller: _middleInitialController,
                                  maxLength: 1,
                                  scaleFactor: scaleFactor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 22 * scaleFactor),

                          // Last Name
                          _buildInputField(
                            label: 'Last Name',
                            hint: 'Enter Last Name',
                            controller: _lastNameController,
                            validator: (value) =>
                                Validators.validateRequired(value, 'Last Name'),
                            scaleFactor: scaleFactor,
                          ),
                          SizedBox(height: 22 * scaleFactor),

                          // Password
                          _buildInputField(
                            label: 'Password',
                            hint: 'Enter Password',
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            validator: Validators.validatePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey,
                                size: 20 * scaleFactor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            scaleFactor: scaleFactor,
                          ),
                          SizedBox(height: 22 * scaleFactor),

                          // Confirm Password
                          _buildInputField(
                            label: 'Confirm Password',
                            hint: 'Re-enter Password',
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            validator: (value) =>
                                Validators.validateConfirmPassword(
                                  value,
                                  _passwordController.text,
                                ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey,
                                size: 20 * scaleFactor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                            scaleFactor: scaleFactor,
                          ),
                          SizedBox(height: 22 * scaleFactor),

                          // Email
                          _buildInputField(
                            label: 'Email',
                            hint: 'Enter Email',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: Validators.validateEmail,
                            scaleFactor: scaleFactor,
                          ),
                          SizedBox(height: 30 * scaleFactor),

                          // Continue Button
                          SizedBox(
                            width: double.infinity,
                            height: 57 * scaleFactor,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleContinue,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryColor,
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
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(height: 10 * scaleFactor),

                          // Already have an account
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  fontSize: 14 * scaleFactor,
                                  color: Colors.black,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginPage(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Login',
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
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required double scaleFactor,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return Container(
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
        border: Border.all(color: const Color(0xFFE1E1E1), width: 0),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 14 * scaleFactor,
          vertical: 10 * scaleFactor,
        ),
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
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    obscureText: obscureText,
                    keyboardType: keyboardType,
                    maxLength: maxLength,
                    validator: validator,
                    style: TextStyle(
                      fontSize: 16 * scaleFactor,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(
                        fontSize: 16 * scaleFactor,
                        fontWeight: FontWeight.w300,
                        color: const Color(0xFFB7B7C0),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      counterText: '',
                      errorStyle: TextStyle(
                        fontSize: 11 * scaleFactor,
                        height: 0.5,
                      ),
                    ),
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
