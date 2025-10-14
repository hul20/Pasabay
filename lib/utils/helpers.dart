import '../utils/constants.dart';

/// Validation utility functions
class Validators {
  /// Validates email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validates password (minimum 6 characters)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validates password confirmation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validates required fields
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter your $fieldName';
    }
    return null;
  }
}

/// Responsive scaling utility
class ResponsiveHelper {
  /// Calculates scale factor based on screen width
  static double getScaleFactor(double screenWidth) {
    return (screenWidth / AppConstants.baseWidth).clamp(
      AppConstants.minScaleFactor,
      AppConstants.maxScaleFactor,
    );
  }

  /// Scales a value based on screen width
  static double scale(double value, double screenWidth) {
    return value * getScaleFactor(screenWidth);
  }
}
