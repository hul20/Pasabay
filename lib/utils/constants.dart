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

  // Google Maps API Key
  static const String googleMapsApiKey =
      'AIzaSyA_NbVgJyqKX2HehA9Xkm4CZ6ItBXL7f4s';

  // Asset Paths
  static const String logoPath = 'assets/PasabayLogo.png';
  static const String smallLogoPath = 'assets/SmallLogo.png';

  // Asset URLs (Deprecated)
  static const String logoUrl =
      'https://czodfzjqkvpicbnhtqhv.supabase.co/storage/v1/object/sign/assets/PasabayLogo.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV9kNjliNjQzNy0yNzFmLTQzMTYtODczYS02NWYxN2Y1OWIzYTAiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJhc3NldHMvUGFzYWJheUxvZ28ucG5nIiwiaWF0IjoxNzYzNTY3MDQwLCJleHAiOjE3OTUxMDMwNDB9.gPvJ52aNEAbfRh9M7JX6sKRimacIw-4J6NsyON7UAtk';
  static const String smallLogoUrl =
      'https://czodfzjqkvpicbnhtqhv.supabase.co/storage/v1/object/sign/assets/SmallLogo.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV9kNjliNjQzNy0yNzFmLTQzMTYtODczYS02NWYxN2Y1OWIzYTAiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJhc3NldHMvU21hbGxMb2dvLnBuZyIsImlhdCI6MTc2MzU2NzA3NSwiZXhwIjoxNzk1MTAzMDc1fQ.Hml6lggzfhAn-VLdJOMz2Z5wC7Ev2oG6XoEJpOcnFkI';
}

/// Gradient configurations
class AppGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
