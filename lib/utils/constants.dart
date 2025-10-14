import 'package:flutter/material.dart';

/// App-wide constants and configuration
class AppConstants {
  // Colors
  static const Color primaryColor = Color(0xFF00AAF3);
  static const Color secondaryColor = Color(0xFF0083B0);
  static const Color oldPrimaryColor = Color(0xFF009ADB);
  static const Color backgroundColor = Color(0xFFF9F9F9);
  static const Color textPrimaryColor = Color(0xFF101828);
  static const Color textSecondaryColor = Color(0xFF717182);

  // Typography
  static const String fontFamily = 'Inter';

  // Layout
  static const double baseWidth = 412.0;
  static const double maxContainerWidth = 412.0;
  static const double minScaleFactor = 0.7;
  static const double maxScaleFactor = 1.0;

  // Border Radius
  static const double defaultBorderRadius = 17.0;
  static const double headerBorderRadius = 30.0;
  static const double inputBorderRadius = 9.5;

  // Spacing
  static const double defaultPadding = 24.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 28.0;

  // API URLs (to be added later)
  static const String baseApiUrl = 'https://api.pasabay.com';

  // Asset URLs
  static const String logoUrl =
      'https://www.figma.com/api/mcp/asset/833ec9d8-708a-4f49-9b11-78f53b5ee4bf';
  static const String smallLogoUrl =
      'https://www.figma.com/api/mcp/asset/5f8ed6b7-e3d3-499d-baa9-7de40dd6d28c';
}

/// Gradient configurations
class AppGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
