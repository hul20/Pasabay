import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/supabase_service.dart';
import '../widgets/gradient_header.dart';
import 'role_selection_page.dart';

class VerifyPage extends StatefulWidget {
  final String? email;

  const VerifyPage({super.key, this.email});

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  final List<TextEditingController> _controllers = List.generate(
    6, // Supabase OTP is 6 digits
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _supabaseService = SupabaseService();

  int _secondsRemaining = 15;
  Timer? _timer;
  bool _canResend = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _navigateToRoleSelection() async {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const RoleSelectionPage()),
    );
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 15;
      _canResend = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _resendCode() async {
    if (_canResend && widget.email != null) {
      try {
        await _supabaseService.sendOTP(widget.email!);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New verification code sent to your email!'),
            backgroundColor: AppConstants.primaryColor,
          ),
        );
        _startTimer();
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _verifyCode() async {
    // Collect the 6-digit code from all text fields
    String code = _controllers.map((c) => c.text).join();

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 6-digit code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email address is missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      await _supabaseService.verifyOTP(email: widget.email!, token: code);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification successful!'),
          backgroundColor: Colors.green,
        ),
      );

      _navigateToRoleSelection();
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'Verification failed';

      // Provide specific error messages
      if (e.toString().contains('expired')) {
        errorMessage = 'Code has expired. Please request a new code.';
      } else if (e.toString().contains('already been used')) {
        errorMessage = 'Code has already been used. Please request a new code.';
      } else if (e.toString().contains('Invalid')) {
        errorMessage = 'Invalid code. Please check and try again.';
      } else if (e.toString().contains('not found')) {
        errorMessage = 'No verification code found. Please request a new code.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );

      // Clear the input fields on error
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = ResponsiveHelper.getScaleFactor(screenWidth);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Column(
        children: [
          // Header with gradient background
          GradientHeader(
            title: 'Verify',
            subtitle: 'Confirm your identity to keep\nyour account secure',
            scaleFactor: scaleFactor,
            onBackPressed: () => Navigator.pop(context),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(
                  AppConstants.defaultPadding * scaleFactor,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 24 * scaleFactor),

                    // Message
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14 * scaleFactor,
                          color: const Color(0xFF667085),
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: 'We have sent you a '),
                          TextSpan(
                            text: '6-PIN Verification',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const TextSpan(text: ' code to\n'),
                          TextSpan(
                            text: widget.email ?? 'your email',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppConstants.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32 * scaleFactor),

                    // PIN Input Fields (6 digits for Supabase OTP)
                    SizedBox(
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          return Expanded(
                            child: Container(
                              height: 100 * scaleFactor,
                              margin: EdgeInsets.symmetric(
                                horizontal: 6 * scaleFactor,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                  16 * scaleFactor,
                                ),
                                border: Border.all(
                                  color: const Color(0xFFE0E0E0),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: TextField(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  textAlign: TextAlign.center,
                                  textAlignVertical: TextAlignVertical.center,
                                  keyboardType: TextInputType.number,
                                  maxLength: 1,
                                  style: TextStyle(
                                    fontSize: 36 * scaleFactor,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  decoration: const InputDecoration(
                                    counterText: '',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  onChanged: (value) {
                                    if (value.isNotEmpty && index < 3) {
                                      _focusNodes[index + 1].requestFocus();
                                    } else if (value.isEmpty && index > 0) {
                                      _focusNodes[index - 1].requestFocus();
                                    }
                                  },
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    SizedBox(height: 32 * scaleFactor),

                    // Verify Button
                    SizedBox(
                      width: double.infinity,
                      height: 50 * scaleFactor,
                      child: ElevatedButton(
                        onPressed: _isVerifying ? null : _verifyCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              12 * scaleFactor,
                            ),
                          ),
                        ),
                        child: _isVerifying
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
                                'Enter Verification Code',
                                style: TextStyle(
                                  fontSize: 16 * scaleFactor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 16 * scaleFactor),

                    // Resend Timer
                    Center(
                      child: _canResend
                          ? GestureDetector(
                              onTap: _resendCode,
                              child: Text(
                                'Resend Code',
                                style: TextStyle(
                                  fontSize: 14 * scaleFactor,
                                  color: AppConstants.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 14 * scaleFactor,
                                  color: const Color(0xFF667085),
                                ),
                                children: [
                                  const TextSpan(text: 'Resend in '),
                                  TextSpan(
                                    text: '$_secondsRemaining Seconds',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppConstants.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
